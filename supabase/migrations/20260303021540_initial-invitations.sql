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
    token text not null,
    is_active boolean default true
);
create or replace function get_invitation_rol(p_email text, p_token text)
returns text as $$
    select role.role_name
    from public.invitations invitation
    join public.roles role on role.id = invitation.role_to_have_id
    where invitation.email = p_email
        -- and invitation.token = p_token
        and invitation.is_active = true
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

create trigger a_set_invited_by_profile_id
before insert on invitations
for each row
execute function set_invited_by_profile_id();

call setup_audit(
    'invitations'
);
