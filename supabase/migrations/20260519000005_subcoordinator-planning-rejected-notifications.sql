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

-- Rule for Aprobado por Subcoordinador -> Rechazado para corrección
insert into public.notification_type_resolution_rules (
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
    295 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_state_id', subcoord_approved_state.id,
        'project_state_id', rejected_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.project_states as subcoord_approved_state
cross join public.project_states as rejected_state
where
    notification_type.type_key = 'project-review-to-rejected-same-phase'
    and subcoord_approved_state.project_state_name = 'Aprobado por Subcoordinador'
    and rejected_state.project_state_name = 'Rechazado para corrección'
on conflict (source_kind, operation_kind, notification_type_id, priority, match_context) do update
    set is_active = true;

-- Rule for Consignado a Planeamiento y Admisión -> Rechazado para corrección
insert into public.notification_type_resolution_rules (
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
    295 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_state_id', consigned_state.id,
        'project_state_id', rejected_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.project_states as consigned_state
cross join public.project_states as rejected_state
where
    notification_type.type_key = 'project-review-to-rejected-same-phase'
    and consigned_state.project_state_name = 'Consignado a Planeamiento y Admisión'
    and rejected_state.project_state_name = 'Rechazado para corrección'
on conflict (source_kind, operation_kind, notification_type_id, priority, match_context) do update
    set is_active = true;
