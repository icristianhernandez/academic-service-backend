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

insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'exoneration_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    295 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'exoneration_state_id', review_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.exoneration_states as review_state
where
    notification_type.type_key = 'exoneration-submitted-for-review'
    and review_state.exoneration_state_name = 'En revisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;
