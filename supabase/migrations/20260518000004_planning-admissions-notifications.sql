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
('project-consigned-to-planning-admissions'),
('project-planning-admissions-approved')
on conflict (type_key) do nothing;

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
    265 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'phase_advanced', true,
        'same_phase', false,
        'state_changed', true,
        'old_project_state_id', coord_state.id,
        'project_state_id', consigned_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.project_states as coord_state
cross join public.project_states as consigned_state
where
    notification_type.type_key = 'project-consigned-to-planning-admissions'
    and coord_state.project_state_name = 'Aprobado por Coordinador'
    and consigned_state.project_state_name
    = 'Consignado a Planeamiento y Admisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set is_active = true;

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
    260 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_state_id', consigned_state.id,
        'project_state_id', approved_state.id
    ) as match_context
from public.notification_types as notification_type
cross join public.project_states as consigned_state
cross join public.project_states as approved_state
where
    notification_type.type_key = 'project-planning-admissions-approved'
    and consigned_state.project_state_name
    = 'Consignado a Planeamiento y Admisión'
    and approved_state.project_state_name
    = 'Aprobado por Planeamiento y Admisión'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set is_active = true;

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
where notification_type.type_key = 'project-consigned-to-planning-admissions'
on conflict (
    notification_type_id,
    rule_target_kind,
    recipient_target
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
where notification_type.type_key = 'project-planning-admissions-approved'
on conflict (
    notification_type_id,
    rule_target_kind,
    recipient_target
) do nothing;

create or replace function public.process_notification_events_queue(
    p_batch_size integer default 100
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    worker_profile_id constant uuid := '00000000-0000-0000-0000-000000000001';
    queued_event public.notifications_events;
    processed_count integer := 0;
begin
    for queued_event in
        with events_to_claim as (
            select notification_event.id
            from public.notifications_events as notification_event
            where notification_event.processed_status = 'pending'
            order by notification_event.created_at asc, notification_event.id asc
            for update skip locked
            limit p_batch_size
        )
        update public.notifications_events as notification_event
        set
            processed_status = 'processing',
            retry_count = notification_event.retry_count + 1,
            error_message = null,
            last_attempt = now()
        from events_to_claim
        where notification_event.id = events_to_claim.id
        returning notification_event.*
    loop
        begin
            insert into public.notification_recipients (
                notification_id,
                recipient_id,
                created_by,
                updated_by
            )
            select
                queued_event.id,
                recipient_profile.id,
                worker_profile_id,
                worker_profile_id
            from public.notification_recipients_rules as recipient_rule
            join public.profiles as recipient_profile
                on recipient_profile.id = case
                    when
                        queued_event.payload ? recipient_rule.recipient_target
                        and (
                            queued_event.payload ->> recipient_rule.recipient_target
                        ) ~* (
                            '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}'
                            || '-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
                        )
                    then (
                        queued_event.payload ->> recipient_rule.recipient_target
                    )::uuid
                    else null
                end
            where recipient_rule.notification_type_id = queued_event.notification_type_id
              and recipient_rule.rule_target_kind = 'payload'
              and (
                  queued_event.actor_id is null
                  or recipient_profile.id <> queued_event.actor_id
              )
            on conflict (notification_id, recipient_id) do nothing;

            insert into public.notification_recipients (
                notification_id,
                recipient_id,
                created_by,
                updated_by
            )
            select
                queued_event.id,
                pm.profile_id,
                worker_profile_id,
                worker_profile_id
            from public.notification_recipients_rules as recipient_rule
            join public.project_progress as pp 
                on pp.id = queued_event.source_record_id::bigint
            join public.project_members as pm 
                on pm.project_id = pp.project_id
            where recipient_rule.notification_type_id = queued_event.notification_type_id
              and recipient_rule.rule_target_kind = 'payload'
              and recipient_rule.recipient_target = 'student_profile_id'
              and queued_event.source_kind = 'project_progress'
              and (
                  queued_event.actor_id is null
                  or pm.profile_id <> queued_event.actor_id
              )
            on conflict (notification_id, recipient_id) do nothing;

            insert into public.notification_recipients (
                notification_id,
                recipient_id,
                created_by,
                updated_by
            )
            select
                queued_event.id,
                recipient_profile.id,
                worker_profile_id,
                worker_profile_id
            from public.notification_recipients_rules as recipient_rule
            join public.profiles as recipient_profile
                on recipient_profile.role_id = (
                    select role_row.id
                    from public.roles as role_row
                    where role_row.role_name = recipient_rule.recipient_target
                )
            where recipient_rule.notification_type_id = queued_event.notification_type_id
              and recipient_rule.rule_target_kind = 'role'
              and (
                  queued_event.actor_id is null
                  or recipient_profile.id <> queued_event.actor_id
              )
            on conflict (notification_id, recipient_id) do nothing;

            insert into public.user_inbox (
                notification_recipient_id,
                created_by,
                updated_by
            )
            select
                recipient.id,
                worker_profile_id,
                worker_profile_id
            from public.notification_recipients as recipient
            where recipient.notification_id = queued_event.id
            on conflict (notification_recipient_id) do nothing;

            insert into public.notifications_external_deliveries (
                notification_recipient_id,
                to_channel,
                created_by,
                updated_by
            )
            select
                recipient.id,
                'email'::public.notification_channel_enum,
                worker_profile_id,
                worker_profile_id
            from public.notification_recipients as recipient
            where recipient.notification_id = queued_event.id
            on conflict (notification_recipient_id, to_channel) do nothing;

            update public.notifications_events
            set
                processed_status = 'processed',
                processed_at = now(),
                error_message = null,
                last_attempt = now()
            where id = queued_event.id;

            processed_count := processed_count + 1;
        exception
            when others then
                update public.notifications_events
                set
                    processed_status = 'failed',
                    processed_at = null,
                    error_message = sqlerrm,
                    last_attempt = now()
                where id = queued_event.id;
        end;
    end loop;

    return processed_count;
end;
$$;
