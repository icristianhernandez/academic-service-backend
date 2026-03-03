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

insert into roles (role_name, permission_level)
values
('student', 1),
('administrative', 2),
('tutor', 3),
('coordinator', 4),
('dean', 5),
('sysadmin', 6)
on conflict (role_name) do update
    set permission_level = excluded.permission_level;

update public.profiles
set role_id = 6
where id = '00000000-0000-0000-0000-000000000001';
