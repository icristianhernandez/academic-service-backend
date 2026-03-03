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

insert into invitations (
    email,
    role_to_have_id,
    token,
    is_active,
    faculty_to_be_coordinator,
    school_to_be_tutor
)
values
('student@test.local', 1, '1', true, null, null),
('administrative@test.local', 2, '1', true, null, null),
('tutor@test.local', 3, '1', true, null, 1),
('coordinator@test.local', 4, '1', true, 1, null),
('dean@test.local', 5, '1', true, null, null),
('sysadmin@test.local', 6, '1', true, null, null)
on conflict (email) do update
    set
        role_to_have_id = excluded.role_to_have_id,
        token = excluded.token,
        is_active = excluded.is_active,
        faculty_to_be_coordinator = excluded.faculty_to_be_coordinator,
        school_to_be_tutor = excluded.school_to_be_tutor;
