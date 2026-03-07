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

insert into project_phases (project_phase_name)
select seed_phase.project_phase_name
from (
    values
    ('Preproyecto'),
    ('Reporte 1'),
    ('Reporte 2'),
    ('Reporte 3'),
    ('Reporte Final'),
    ('Aprobado')
) as seed_phase (project_phase_name)
where not exists (
    select 1
    from project_phases as existing_phase
    where existing_phase.project_phase_name = seed_phase.project_phase_name
);

insert into project_states (project_state_name)
select seed_state.project_state_name
from (
    values
    ('En Revisión'),
    ('Cancelado'),
    ('En Espera')
) as seed_state (project_state_name)
where not exists (
    select 1
    from project_states as existing_state
    where existing_state.project_state_name = seed_state.project_state_name
);
