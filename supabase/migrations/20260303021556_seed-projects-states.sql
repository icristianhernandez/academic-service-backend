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

insert into project_phases (project_phase_name, project_phase_order)
select
    seed_phase.project_phase_name,
    seed_phase.project_phase_order
from (
    values
    ('Preproyecto', 1),
    ('Reporte 1', 2),
    ('Reporte 2', 3),
    ('Reporte 3', 4),
    ('Reporte Final', 5),
    ('Aprobado', 6)
) as seed_phase (project_phase_name, project_phase_order)
where not exists (
    select 1
    from project_phases as existing_phase
    where existing_phase.project_phase_name = seed_phase.project_phase_name
);

insert into project_states (project_state_name)
select seed_state.project_state_name
from (
    values
    ('En Espera'),
    ('En Revisión'),
    ('Cancelado')
) as seed_state (project_state_name)
where not exists (
    select 1
    from project_states as existing_state
    where existing_state.project_state_name = seed_state.project_state_name
);

insert into notification_types (type_key)
select seed_type.type_key
from (
    values
    ('project-update-fallback-no-recipient'),
    ('project-phase-advanced-to-review'),
    ('project-phase-advanced'),
    ('project-state-to-review'),
    ('project-review-to-wait-same-phase')
) as seed_type (type_key)
where not exists (
    select 1
    from notification_types as existing_type
    where existing_type.type_key = seed_type.type_key
);

insert into notification_type_defaults (
    source_kind,
    operation_kind,
    notification_type_id
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id
from notification_types as notification_type
where notification_type.type_key = 'project-update-fallback-no-recipient'
on conflict (source_kind, operation_kind) do update
    set notification_type_id = excluded.notification_type_id;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    300 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'phase_advanced', true,
        'old_project_phase_id', old_phase.id,
        'project_phase_id', new_phase.id
    ) as match_context
from notification_types as notification_type
cross join project_phases as old_phase
cross join project_phases as new_phase
where
    notification_type.type_key = 'project-phase-advanced'
    and new_phase.project_phase_order > old_phase.project_phase_order
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    260 as priority,
    jsonb_build_object(
        'has_previous_progress', false,
        'is_first_progress', true,
        'state_changed', true,
        'project_state_id', review_state.id,
        'old_project_state_id', (
            select project_state.id
            from public.project_states as project_state
            where project_state.project_state_name = 'En Espera'
        )
    ) as match_context
from notification_types as notification_type
cross join project_states as review_state
where
    notification_type.type_key = 'project-state-to-review'
    and review_state.project_state_name = 'En Revisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    350 as priority,
    jsonb_build_object(
        'has_previous_progress', false,
        'is_first_progress', true,
        'phase_advanced', true,
        'state_changed', true,
        'project_state_id', review_state.id,
        'old_project_state_id', (
            select project_state.id
            from public.project_states as project_state
            where project_state.project_state_name = 'En Espera'
        )
    ) as match_context
from notification_types as notification_type
cross join project_states as review_state
where
    notification_type.type_key = 'project-phase-advanced-to-review'
    and review_state.project_state_name = 'En Revisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    300 as priority,
    jsonb_build_object(
        'has_previous_progress', false,
        'is_first_progress', true,
        'phase_advanced', true,
        'old_project_phase_id', 0,
        'project_phase_id', new_phase.id
    ) as match_context
from notification_types as notification_type
cross join project_phases as new_phase
where
    notification_type.type_key = 'project-phase-advanced'
    and new_phase.project_phase_order > 1
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    250 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'old_project_state_id', old_state.id,
        'project_state_id', review_state.id
    ) as match_context
from notification_types as notification_type
cross join project_states as old_state
cross join project_states as review_state
where
    notification_type.type_key = 'project-state-to-review'
    and review_state.project_state_name = 'En Revisión'
    and old_state.id <> review_state.id
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'project_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    275 as priority,
    jsonb_build_object(
        'has_previous_progress', false,
        'is_first_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_phase_id', phase.id,
        'project_phase_id', phase.id,
        'old_project_state_id', review_state.id,
        'project_state_id', waiting_state.id
    ) as match_context
from notification_types as notification_type
cross join project_phases as phase
cross join project_states as review_state
cross join project_states as waiting_state
where
    notification_type.type_key = 'project-review-to-wait-same-phase'
    and review_state.project_state_name = 'En Revisión'
    and waiting_state.project_state_name = 'En Espera'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set
        is_active = true;

insert into notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::notification_rule_target_kind_enum,
    recipient_targets.recipient_target
from notification_types as notification_type
cross join (
    values
    ('project-phase-advanced', 'student_profile_id'),
    ('project-phase-advanced', 'coordinator_profile_id'),
    ('project-state-to-review', 'tutor_profile_id'),
    ('project-review-to-wait-same-phase', 'student_profile_id')
) as recipient_targets (type_key, recipient_target)
where
    notification_type.type_key = recipient_targets.type_key
on conflict (
    notification_type_id, rule_target_kind, recipient_target
) do nothing;

insert into notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::notification_rule_target_kind_enum,
    recipient_targets.recipient_target
from notification_types as notification_type
cross join (
    values
    ('student_profile_id'),
    ('coordinator_profile_id'),
    ('tutor_profile_id')
) as recipient_targets (recipient_target)
where notification_type.type_key = 'project-phase-advanced-to-review'
on conflict (
    notification_type_id, rule_target_kind, recipient_target
) do nothing;
