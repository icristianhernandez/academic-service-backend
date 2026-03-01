create extension if not exists plpgsql_check;

create type semester_enum as
enum ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10');

create type section_enum as enum ('A', 'B', 'C', 'D', 'E', 'F');

create type shift_enum as enum ('MORNING', 'EVENING');

create table audit_meta (
    created_at timestamptz default now() not null,
    created_by uuid default auth.uid() not null,
    updated_at timestamptz default now() not null,
    updated_by uuid default auth.uid()
);

create table countries (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    country_name text not null unique
);

create table states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    country_id bigint not null references countries (id),
    state_name text not null unique
);

create table cities (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    state_id bigint not null references states (id),
    city_name text not null unique
);

create table locations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    city_id bigint not null references cities (id),
    address text not null
);

create table roles (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    role_name text not null unique,
    permission_level integer not null
);

create table profiles (
    like audit_meta including all,
    id uuid references auth.users not null primary key,
    first_name text not null,
    last_name text not null,
    primary_contact text not null,
    secondary_contact text,
    role_id bigint references roles (id)
);

do $$
declare
    seed_user_id constant uuid := '00000000-0000-0000-0000-000000000001';
begin
    perform set_config(
        'request.jwt.claims',
        json_build_object(
            'role', 'authenticated',
            'sub', seed_user_id,
            'email', 'seed-worker@usm.local'
        )::text,
        true
    );

    insert into auth.users (
        id,
        email,
        instance_id,
        aud,
        role,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        created_at,
        updated_at
    )
    values (
        seed_user_id,
        'seed-worker@usm.local',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        crypt(gen_random_uuid()::text, gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
            'display_name', 'Seed Service Worker',
            'first_name', 'Seed',
            'last_name', 'Worker',
            'primary_contact', '04241111111',
            'secondary_contact', '04241111111'
        ),
        '',
        '',
        '',
        '',
        now(),
        now()
    )
    on conflict (id) do update
    set
        email = excluded.email,
        instance_id = excluded.instance_id,
        raw_app_meta_data = excluded.raw_app_meta_data,
        raw_user_meta_data = excluded.raw_user_meta_data,
        confirmation_token = excluded.confirmation_token,
        recovery_token = excluded.recovery_token,
        email_change_token_new = excluded.email_change_token_new,
        email_change = excluded.email_change,
        updated_at = now();

    insert into public.profiles (
        id,
        first_name,
        last_name,
        primary_contact,
        secondary_contact,
        role_id
    )
    values (
        seed_user_id,
        'Seed',
        'Worker',
        '04241111111',
        '04241111111',
        null
    )
    on conflict (id) do update
    set
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        primary_contact = excluded.primary_contact,
        secondary_contact = excluded.secondary_contact,
        role_id = excluded.role_id;

    insert into auth.identities (
        provider_id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    )
    values (
        seed_user_id::text,
        seed_user_id,
        jsonb_build_object(
            'sub', seed_user_id::text,
            'email', 'seed-worker@usm.local',
            'email_verified', false,
            'phone_verified', false
        ),
        'email',
        now(),
        now(),
        now()
    )
    on conflict (provider_id, provider) do update
    set
        user_id = excluded.user_id,
        identity_data = excluded.identity_data,
        last_sign_in_at = excluded.last_sign_in_at,
        updated_at = excluded.updated_at;
end;
$$;

create or replace function public.validate_invitation_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    perform 1
    from public.invitations
    where email = new.email 
      and is_active = true
    limit 1;

    if not found then
        raise exception 'Signup failed. No active invitation found for email: %', new.email 
            using errcode = 'P0001';
    end if;

    return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    invitation_role_id bigint;
    actor_id uuid;
begin
    select role_to_have_id
    into invitation_role_id
    from public.invitations
    where email = new.email
      and is_active = true
    limit 1;

    actor_id := coalesce(auth.uid(), new.id);

    insert into public.profiles (
        id,
        first_name,
        last_name,
        primary_contact,
        secondary_contact,
        role_id,
        created_by,
        updated_by
    )
    values (
        new.id,
        new.raw_user_meta_data ->> 'first_name',
        new.raw_user_meta_data ->> 'last_name',
        new.raw_user_meta_data ->> 'primary_contact',
        new.raw_user_meta_data ->> 'secondary_contact',
        invitation_role_id,
        actor_id,
        actor_id
    );

    return new;
end;
$$;

create function public.deactivate_invitation_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    update public.invitations
    set is_active = false
    where email = new.email;

    return new;
end;
$$;

create trigger a_validate_invitation_on_signup
before insert on auth.users
for each row
execute procedure public.validate_invitation_on_signup();

create trigger b_handle_new_user
after insert on auth.users
for each row
execute procedure public.handle_new_user();

create trigger c_deactivate_invitation_on_signup
after insert on auth.users
for each row
execute procedure public.deactivate_invitation_on_signup();

create table campuses (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint not null references locations (id),
    campus_name text not null unique,
    president_profile_id uuid references profiles (id)
);

create table faculties (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    campus_id bigint not null references campuses (id),
    faculty_name text not null unique,
    dean_profile_id uuid references profiles (id),
    coordinator_profile_id uuid references profiles (id)
);

create table degrees (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    degree_name text not null unique
);

create table schools (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    degree_id bigint not null references degrees (id),
    faculty_id bigint not null references faculties (id),
    tutor_profile_id uuid references profiles (id)
);

create table students (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    profile_id uuid not null references profiles (id),
    school_id bigint not null references schools (id),
    semester semester_enum,
    shift shift_enum,
    section section_enum
);

create table institutions (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint references locations (id),
    contact_person_profile_id uuid references profiles (id),
    institution_name text not null unique
);

create table documents (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    bucket_id text not null default 'project' references storage.buckets (id),
    storage_path text not null,
    uploaded_by_profile_id uuid references profiles (
        id
    ) on delete cascade not null,
    unique (bucket_id, storage_path)
);

insert into storage.buckets (id, name, public)
values ('project', 'project', true);

create policy project_documents_read
on storage.objects
for select
to authenticated
using (bucket_id = 'project');

create policy project_documents_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'project');

create policy project_documents_update
on storage.objects
for update
to authenticated
using (bucket_id = 'project')
with check (bucket_id = 'project');

create policy project_documents_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'project');

create table projects_states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_state_name text not null,
    normal_flow_state boolean not null default true
);

create table projects_states_flow (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    from_state bigint not null references projects_states (id),
    to_state bigint not null references projects_states (id)
);

create table projects (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    tutor_profile_id uuid not null references profiles (id),
    coordinator_profile_id uuid not null references profiles (id),
    student_profile_id uuid not null references profiles (id),
    institution_id bigint not null references institutions (id),
    title text not null,
    abstract text,

    last_normal_state_id bigint not null references projects_states (id),
    current_state_id bigint not null references projects_states (id),
    state_doc_id bigint not null references documents (id),
    state_metadata text
);

create table invitations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    -- why I don't do, to the following: default auth.uid() ? I do that with
    -- audit logs, but is not a reference. Why audit_logs is not a reference?
    -- mmm
    invited_by_profile_id uuid references profiles (id),
    email text not null unique,
    role_to_have_id bigint references roles (id),
    token text not null,
    is_active boolean default true
);

create or replace function set_invited_by_profile_id()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    new.invited_by_profile_id := auth.uid();
    return new;
end;
$$;

create trigger a_set_invited_by_profile_id
before insert on invitations
for each row
execute function set_invited_by_profile_id();

-- https://wiki.postgresql.org/wiki/Audit_trigger
create table audit_logs (
    id bigint generated always as identity primary key,
    schema_name text not null,
    table_name text not null,
    record_id text,
    operation_name text not null,
    auth_uid uuid default auth.uid(),
    old_data jsonb,
    new_data jsonb,
    created_at timestamptz default now()
);

create or replace function auth_permission_level()
returns integer
language sql
security definer
stable
set search_path = pg_catalog, public
as $$
    select coalesce(max(role.permission_level), 0)
    from public.profiles profile
    join public.roles role on role.id = profile.role_id
    where profile.id = auth.uid()
$$;

-- TODO: that's just a mock placeholder
alter table audit_logs enable row level security;
create policy read_only_audit_logs
on audit_logs
for select
to authenticated
using (
    auth_permission_level() >= (
        select permission_level
        from public.roles
        where role_name = 'dean'
    )
    or (
        table_name = 'profiles'
        and record_id = auth.uid()::text
    )
    or (
        table_name = 'projects'
        and (
            new_data ->> 'student_profile_id' = auth.uid()::text
            or old_data ->> 'student_profile_id' = auth.uid()::text
            or (
                auth_permission_level() > (
                    select permission_level
                    from public.roles
                    where role_name = 'student'
                )
                and (
                    new_data ->> 'tutor_profile_id' = auth.uid()::text
                    or new_data ->> 'coordinator_profile_id' = auth.uid()::text
                    or old_data ->> 'tutor_profile_id' = auth.uid()::text
                    or old_data ->> 'coordinator_profile_id' = auth.uid()::text
                )
            )
        )
    )
);
create index idx_audit_logs_table_record on audit_logs (
    table_name,
    record_id,
    created_at desc
);
create index idx_audit_logs_created on audit_logs (created_at);

create or replace function handle_audit_update()
returns trigger
as $$
begin
    new := jsonb_populate_record(
        new,
        jsonb_build_object(
            'updated_at', now(),
            'updated_by', auth.uid()
        )
    );
    return new;
end;
$$
language plpgsql;

create or replace procedure enable_audit_tracking(
    variadic target_table_names text []
)
language plpgsql
as $$
declare
    current_table_name text;
    dynamic_trigger_name text;
begin
    foreach current_table_name in array target_table_names
    loop
        dynamic_trigger_name := format('trg_audit_update_%s', current_table_name);

        execute format(
            'create trigger %I
             before update on %I
             for each row
             execute function handle_audit_update()',
            dynamic_trigger_name,
            current_table_name
        );
    end loop;
end;
$$;

create or replace function log_changes()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, extensions
as $$
declare
    old_data jsonb;
    new_data jsonb;
    record_id_value text;
begin
    if tg_op = 'DELETE' then
        old_data := to_jsonb(old);
    elsif tg_op = 'UPDATE' then
        old_data := to_jsonb(old);
        new_data := to_jsonb(new);
    elsif tg_op = 'INSERT' then
        new_data := to_jsonb(new);
    end if;

    record_id_value := coalesce(
        new_data ->> 'id',
        old_data ->> 'id'
    );

    insert into public.audit_logs (
        schema_name,
        table_name,
        record_id,
        operation_name,
        auth_uid,
        old_data,
        new_data
    ) values (
        tg_table_schema,
        tg_table_name,
        record_id_value,
        tg_op,
        auth.uid(),
        old_data,
        new_data
    );

    return null;
end;
$$;

create or replace procedure attach_audit_triggers(
    variadic table_names text []
)
language plpgsql
as $$
declare
    table_name text;
    trigger_name text;
begin
    foreach table_name in array table_names
    loop
        trigger_name := format('audit_%s_changes', table_name);

        execute format(
            'create trigger %I
             after insert or update or delete on %I
             for each row execute function log_changes();',
            trigger_name,
            table_name
        );
    end loop;
end;
$$;

create or replace procedure setup_audit(
    variadic table_names text []
)
language plpgsql
as $$
begin
    call enable_audit_tracking(variadic table_names);
    call attach_audit_triggers(variadic table_names);
end;
$$;

call setup_audit(
    'countries',
    'states',
    'cities',
    'locations',
    'campuses',
    'faculties',
    'schools',
    'roles',
    'profiles',
    'students',
    'institutions',
    'projects',
    'documents',
    'invitations',
    'projects_states',
    'projects_states_flow'
);
