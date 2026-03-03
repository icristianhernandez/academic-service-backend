create table audit_meta (
    created_at timestamptz default now() not null,
    created_by uuid default auth.uid() not null,
    updated_at timestamptz default now() not null,
    updated_by uuid default auth.uid()
);

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

-- create or replace function auth_permission_level()
-- returns integer
-- language sql
-- security definer
-- stable
-- set search_path = pg_catalog, public
-- as $$
--     select coalesce(max(role.permission_level), 0)
--     from public.profiles profile
--     join public.roles role on role.id = profile.role_id
--     where profile.id = auth.uid()
-- $$;
--
-- -- TODO: that's just a mock placeholder
-- alter table audit_logs enable row level security;
-- create policy read_only_audit_logs
-- on audit_logs
-- for select
-- to authenticated
-- using (
--     auth_permission_level() >= (
--         select permission_level
--         from public.roles
--         where role_name = 'dean'
--     )
--     or (
--         table_name = 'profiles'
--         and record_id = auth.uid()::text
--     )
--     or (
--         table_name = 'projects'
--         and (
--             new_data ->> 'student_profile_id' = auth.uid()::text
--             or old_data ->> 'student_profile_id' = auth.uid()::text
--             or (
--                 auth_permission_level() > (
--                     select permission_level
--                     from public.roles
--                     where role_name = 'student'
--                 )
--                 and (
--                     new_data ->> 'tutor_profile_id' = auth.uid()::text
--                  or new_data ->> 'coordinator_profile_id' = auth.uid()::text
--                     or old_data ->> 'tutor_profile_id' = auth.uid()::text
--                  or old_data ->> 'coordinator_profile_id' = auth.uid()::text
--                 )
--             )
--         )
--     )
-- );
-- create index idx_audit_logs_table_record on audit_logs (
--     table_name,
--     record_id,
--     created_at desc
-- );
-- create index idx_audit_logs_created on audit_logs (created_at);

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
