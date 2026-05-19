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

update public.roles
set permission_level = permission_level + 1
where role_name in ('dean', 'subcoordinator', 'coordinator', 'sysadmin');

insert into public.roles (role_name, permission_level)
values 
('planning_admissions', 3),
('director_general', 6)
on conflict (role_name) do update
    set permission_level = excluded.permission_level;
