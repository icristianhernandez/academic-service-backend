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

insert into public.project_states (project_state_name)
values
('Consignado a Planeamiento y Admisión'),
('Aprobado por Planeamiento y Admisión')
on conflict (project_state_name) do nothing;
