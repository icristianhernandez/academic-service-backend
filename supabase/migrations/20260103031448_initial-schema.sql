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

create table users (
    like audit_meta including all,
    id uuid references auth.users not null primary key,
    first_name text not null,
    last_name text not null,
    national_id text not null unique,
    email text not null unique,
    primary_contact text not null,
    secondary_contact text,
    role_id bigint references roles (id)
);

create table campuses (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint not null references locations (id),
    campus_name text not null unique,
    president_id uuid not null references users (id)
);

create table faculties (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    campus_id bigint not null references campuses (id),
    faculty_name text not null unique,
    dean_id uuid not null references users (id),
    coordinator_id uuid not null references users (id)
);

create table schools (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    faculty_id bigint not null references faculties (id),
    school_name text not null unique,
    tutor_id uuid not null references users (id)
);

create table students (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    user_id uuid not null references users (id),
    faculty_id bigint not null references faculties (id),
    school_id bigint not null references schools (id),
    semester semester_enum,
    shift shift_enum,
    section section_enum
);

create table institutions (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint references locations (id),
    contact_person_id uuid references users (id),
    institution_name text not null unique
);

create table documents (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    bucket_id text not null default 'project' references storage.buckets (id),
    storage_path text not null,
    uploaded_by uuid references users (id) on delete cascade not null,
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

create table projects (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    tutor_id uuid not null references users (id),
    coordinator_id uuid not null references users (id),
    student_id uuid not null references users (id),
    institution_id bigint not null references institutions (id),
    title text not null,
    abstract text,

    pre_project_document_id bigint not null references documents (id),
    pre_project_observations text,
    pre_project_approved_at timestamptz,

    project_document_id bigint references documents (id),
    project_observations text,
    project_received_at timestamptz,

    final_project_approved_at timestamptz
);

create table invitations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    invited_by uuid references users (id),
    email text not null unique,
    role_id bigint references roles (id),
    token text not null,
    is_active boolean default true
);

-- https://wiki.postgresql.org/wiki/Audit_trigger
create table audit_logs (
    id bigint generated always as identity primary key,
    schema_name text not null,
    table_name text not null,
    operation_name text not null,
    auth_uid uuid default auth.uid(),
    payload jsonb,
    created_at timestamptz default now()
);
alter table audit_logs enable row level security;
-- all visible and that's a security risk, at least other operations are blocked
create policy read_only_audit_logs
on audit_logs
for select
to authenticated
using (
    true
);
create index idx_audit_logs_table on audit_logs (table_name);
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
    change_payload jsonb;
begin
    if tg_op = 'DELETE' then
        change_payload := jsonb_build_object('old_record', to_jsonb(old));
    elsif tg_op = 'UPDATE' then
        change_payload := jsonb_build_object(
            'old_record', to_jsonb(old),
            'new_record', to_jsonb(new)
        );
    elsif tg_op = 'INSERT' then
        change_payload := jsonb_build_object('new_record', to_jsonb(new));
    end if;

    insert into public.audit_logs (
        schema_name,
        table_name,
        operation_name,
        auth_uid,
        payload
    ) values (
        tg_table_schema,
        tg_table_name,
        tg_op,
        auth.uid(),
        change_payload
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
    'users',
    'students',
    'institutions',
    'projects',
    'documents',
    'invitations'
);
