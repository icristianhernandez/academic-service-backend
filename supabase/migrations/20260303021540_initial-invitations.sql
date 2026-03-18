create extension if not exists pg_net;
-- create extension if not exists supabase_vault with schema vault;

create table invitations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    -- why I don't do, to the following: default auth.uid() ? I do that with
    -- audit logs, but is not a reference. Why audit_logs is not a reference?
    -- mmm
    invited_by_profile_id uuid references profiles (id),
    faculty_to_be_coordinator bigint references faculties (id),
    school_to_be_tutor bigint references schools (id),
    role_to_have_id bigint references roles (id),
    email text not null unique,
    -- TODO: logic to enforces/set the next things aren't implemented yet
    hashed_token text not null,
    failed_attemps integer default 0,
    token_expires_at timestamptz default (now() + interval '7 days'),
    reclaimed_at timestamptz default null
);

create or replace function get_invitation_rol(p_email text, p_token text)
returns text as $$
    select role.role_name
    from public.invitations invitation
    join public.roles role on role.id = invitation.role_to_have_id
    where invitation.email = p_email
        and invitation.reclaimed_at is null
        and (
            invitation.hashed_token = extensions.crypt(p_token, invitation.hashed_token)
        )
    limit 1;
$$ language sql;

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

create or replace function generate_invitation_token()
returns text
language plpgsql
security definer set search_path = ''
as $$
begin
    return lpad((floor(random() * 1000000))::int::text, 6, '0');
end;
$$;

create or replace function hash_invitation_token(token text)
returns text
language plpgsql
security definer set search_path = ''
as $$
begin
    return extensions.crypt(token, extensions.gen_salt('bf'));
end;
$$;

create or replace function assign_invitation_token()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    raw_token text;
    invited_to_role_name text;
    invitation_edge_url text;
    invitation_edge_api_key text;
    supabase_publishable_key text;
begin
    raw_token := public.generate_invitation_token();
    new.hashed_token := public.hash_invitation_token(raw_token);

    -- select secret.decrypted_secret
    -- into invitation_edge_url
    -- from vault.decrypted_secrets secret
    -- where secret.name = 'invitation_edge_url'
    -- order by secret.created_at desc
    -- limit 1;
    --
    -- if invitation_edge_url is null then
    --     raise exception
    --         'Missing Vault secret "invitation_edge_url". Set it before creating invitations.'
    --         using errcode = 'P0001';
    -- end if;

    -- SELECT decrypted_secret INTO invitation_edge_api_key 
    -- FROM vault.decrypted_secrets
    -- WHERE name = 'invitation_edge_api_key'
    -- ORDER BY created_at DESC
    -- LIMIT 1;

    -- if invitation_edge_api_key is null then
    --     raise exception
    --         'Missing Vault secret "invitation_edge_api_key". Set it before creating invitations.'
    --         using errcode = 'P0001';
    -- end if;

    -- TODO: hardcoded the following 4 values
    invitation_edge_url := 'http://kong:8000/functions/v1/send-email-invitation-token';
    invitation_edge_api_key := '123';
    supabase_publishable_key := 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

    invited_to_role_name := (select role_name from public.roles where roles.id = new.role_to_have_id);

    perform net.http_post(
        url := invitation_edge_url,
        body := jsonb_build_object(
            'email', new.email,
            'token', raw_token,
            'role', invited_to_role_name,
            'expires_at', new.token_expires_at
        ),
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || supabase_publishable_key,
            'apikey', supabase_publishable_key,
            'x-api-key', invitation_edge_api_key
        ),
        -- that's the current default (date: 17/03/2026 )
        timeout_milliseconds := 2000
    );

    return new;
end;
$$;

create trigger a_generate_invitation_token
before insert on public.invitations
for each row
execute function assign_invitation_token();

create trigger b_set_invited_by_profile_id
before insert on public.invitations
for each row
execute function set_invited_by_profile_id();

call setup_audit(
    'invitations'
);
