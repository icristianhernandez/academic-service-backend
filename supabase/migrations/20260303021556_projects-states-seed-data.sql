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

insert into projects_states (project_state_name, normal_flow_state)
select
    seed_state.project_state_name,
    seed_state.normal_flow_state
from (
    values
    ('Preproyecto En Revision', true),
    ('En Desarrollo', true),
    ('Reporte Final En Revision', true),
    ('Aprobado', true),
    ('En Correccion', false),
    ('Denegado', false)
) as seed_state (project_state_name, normal_flow_state)
where not exists (
    select 1
    from projects_states as existing_state
    where existing_state.project_state_name = seed_state.project_state_name
);

insert into projects_states_flow (from_state, to_state)
select
    from_state.id as from_state_id,
    to_state.id as to_state_id
from (
    values
    ('Preproyecto En Revision', 'En Desarrollo'),
    ('Preproyecto En Revision', 'En Correccion'),
    ('Preproyecto En Revision', 'Denegado'),
    ('En Desarrollo', 'Reporte Final En Revision'),
    ('En Desarrollo', 'En Correccion'),
    ('En Desarrollo', 'Denegado'),
    ('Reporte Final En Revision', 'Aprobado'),
    ('Reporte Final En Revision', 'En Correccion'),
    ('Reporte Final En Revision', 'Denegado')
) as flow_definition (from_state_name, to_state_name)
inner join projects_states as from_state
    on flow_definition.from_state_name = from_state.project_state_name
inner join projects_states as to_state
    on flow_definition.to_state_name = to_state.project_state_name
where not exists (
    select 1
    from projects_states_flow as existing_flow
    where
        existing_flow.from_state = from_state.id
        and existing_flow.to_state = to_state.id
);
