-- seed invitations for the next accounts:
-- student@test.local / 123
-- administrative@test.local / 123
-- tutor@test.local / 123
-- coordinator@test.local / 123
-- dean@test.local / 123
-- sysadmin@test.local / 123

select set_config(
    'request.jwt.claims',
    json_build_object(
        'role',
        'authenticated',
        'sub',
        '00000000-0000-0000-0000-000000000001',
        'email',
        'seed-worker@usm.local'
    )::text,
    true
);

insert into invitations (email, role_to_have_id, token, is_active)
values
('student@test.local', 1, '1', true),
('administrative@test.local', 2, '1', true),
('tutor@test.local', 3, '1', true),
('coordinator@test.local', 4, '1', true),
('dean@test.local', 5, '1', true),
('sysadmin@test.local', 6, '1', true)
on conflict (email) do update
    set
        role_to_have_id = excluded.role_to_have_id,
        token = excluded.token,
        is_active = excluded.is_active;
