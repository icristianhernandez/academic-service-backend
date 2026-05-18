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

insert into public.notification_types (type_key)
values
('validation-submitted-for-review'),
('validation-coordinator-validated'),
('validation-consigned-to-planning'),
('validation-planning-approved'),
('validation-rejected-for-correction'),
('validation-update-fallback')
on conflict (type_key) do nothing;

-- Fallback default
insert into public.notification_type_defaults (
    source_kind,
    operation_kind,
    notification_type_id
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id
from public.notification_types as notification_type
where notification_type.type_key = 'validation-update-fallback'
on conflict (source_kind, operation_kind) do update
    set notification_type_id = excluded.notification_type_id;

-- First progress: submitted for review
insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    300 as priority,
    jsonb_build_object(
        'has_previous_progress', false,
        'is_first_progress', true,
        'state_changed', true,
        'validacion_state_id', review_state.id,
        'old_validacion_state_id', 0
    ) as match_context
from public.notification_types as notification_type
cross join public.validacion_states as review_state
where
    notification_type.type_key = 'validation-submitted-for-review'
    and review_state.validacion_state_name = 'En revisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;

-- Coordinator validated
insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    280 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'validacion_state_id', validated_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.validacion_states as validated_state
where
    notification_type.type_key = 'validation-coordinator-validated'
    and validated_state.validacion_state_name = 'Validado por Coordinador'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;

-- Consigned to planning
insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    275 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'validacion_state_id', consigned_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.validacion_states as consigned_state
where
    notification_type.type_key = 'validation-consigned-to-planning'
    and consigned_state.validacion_state_name
    = 'Consignado a Planeamiento y Admisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;

-- Planning approved
insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    270 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'validacion_state_id', approved_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.validacion_states as approved_state
where
    notification_type.type_key = 'validation-planning-approved'
    and approved_state.validacion_state_name
    = 'Aprobado por Planeamiento y Admisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;

-- Rejected for correction
insert into public.notification_type_resolution_rules (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
)
select
    'service_validation_progress' as source_kind,
    'update' as operation_kind,
    notification_type.id as notification_type_id,
    290 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'state_changed', true,
        'validacion_state_id', rejected_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.validacion_states as rejected_state
where
    notification_type.type_key = 'validation-rejected-for-correction'
    and rejected_state.validacion_state_name = 'Rechazado para corrección'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update set is_active = true;

-- Recipient rules
insert into public.notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::public.notification_rule_target_kind_enum,
    'coordinator_profile_id' as recipient_target
from public.notification_types as notification_type
where notification_type.type_key = 'validation-submitted-for-review'
on conflict (
    notification_type_id, rule_target_kind, recipient_target
) do nothing;

insert into public.notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::public.notification_rule_target_kind_enum,
    'student_profile_id' as recipient_target
from public.notification_types as notification_type
where
    notification_type.type_key in (
        'validation-coordinator-validated',
        'validation-planning-approved',
        'validation-rejected-for-correction'
    )
on conflict (
    notification_type_id, rule_target_kind, recipient_target
) do nothing;

insert into public.notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'role'::public.notification_rule_target_kind_enum,
    'planning_admissions' as recipient_target
from public.notification_types as notification_type
where notification_type.type_key = 'validation-consigned-to-planning'
on conflict (
    notification_type_id, rule_target_kind, recipient_target
) do nothing;

-- Notification enqueue trigger function
create function public.enqueue_validation_progress_notification_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    validation_row public.service_validations;
    previous_progress public.service_validation_progress;
    notification_payload jsonb;
    resolution_context jsonb;
    resolved_notification_type_id bigint;
    has_previous_progress boolean;
    state_changed boolean := false;
    effective_actor_id uuid;
begin
    if tg_op = 'UPDATE'
        and new.validacion_state_id is not distinct from old.validacion_state_id then
        return new;
    end if;

    select validation.*
    into validation_row
    from public.service_validations as validation
    where validation.id = new.service_validation_id
    limit 1;

    if not found then
        raise exception
            'Notification event creation failed. No convalidation found for id %',
            new.service_validation_id
            using errcode = 'P0001';
    end if;

    if tg_op = 'UPDATE' then
        previous_progress := old;
        has_previous_progress := true;
    else
        select progress_row.*
        into previous_progress
        from public.service_validation_progress as progress_row
        where progress_row.service_validation_id = new.service_validation_id
          and progress_row.id <> new.id
        order by progress_row.created_at desc, progress_row.id desc
        limit 1;

        has_previous_progress := previous_progress.id is not null;
    end if;

    state_changed := coalesce(previous_progress.validacion_state_id, 0)
        <> new.validacion_state_id;

    if has_previous_progress then
        resolution_context := jsonb_build_object(
            'service_validation_id', new.service_validation_id,
            'has_previous_progress', true,
            'is_first_progress', false,
            'state_changed', state_changed,
            'validacion_state_id', new.validacion_state_id,
            'old_validacion_state_id', previous_progress.validacion_state_id
        );
        resolved_notification_type_id := public.resolve_notification_type_id(
            'service_validation_progress',
            'update',
            resolution_context
        );
    else
        resolution_context := jsonb_build_object(
            'service_validation_id', new.service_validation_id,
            'has_previous_progress', false,
            'is_first_progress', true,
            'state_changed', true,
            'validacion_state_id', new.validacion_state_id,
            'old_validacion_state_id', 0
        );
        resolved_notification_type_id := public.resolve_notification_type_id(
            'service_validation_progress',
            'update',
            resolution_context
        );
    end if;

    effective_actor_id := coalesce(auth.uid(), new.author_profile_id);

    notification_payload := jsonb_build_object(
        'student_profile_id', validation_row.student_profile_id,
        'coordinator_profile_id', validation_row.coordinator_profile_id,
        'validacion_state_id', new.validacion_state_id
    );

    insert into public.notifications_events (
        notification_type_id,
        source_kind,
        operation_kind,
        source_record_id,
        payload,
        actor_id,
        created_by,
        updated_by
    )
    values (
        resolved_notification_type_id,
        'service_validation_progress',
        'update',
        new.id::text,
        notification_payload,
        effective_actor_id,
        effective_actor_id,
        effective_actor_id
    );

    return new;
end;
$$;

create trigger b_enqueue_validation_progress_notification_event
after insert or update on public.service_validation_progress
for each row
execute function public.enqueue_validation_progress_notification_event();
