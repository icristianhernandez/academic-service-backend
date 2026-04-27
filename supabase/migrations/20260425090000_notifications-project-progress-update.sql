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

insert into notification_types (type_key)
select seed_type.type_key
from (
    values
    ('project-review-to-rejected-same-phase')
) as seed_type (type_key)
where not exists (
    select 1
    from notification_types as existing_type
    where existing_type.type_key = seed_type.type_key
);

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
    295 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_state_id', review_state.id,
        'project_state_id', waiting_state.id
    ) as match_context
from notification_types as notification_type
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
    set is_active = true;

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
        'has_previous_progress', true,
        'phase_advanced', true,
        'state_changed', true,
        'project_state_id', review_state.id
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
    set is_active = true;

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
    295 as priority,
    jsonb_build_object(
        'has_previous_progress', true,
        'same_phase', true,
        'state_changed', true,
        'old_project_state_id', review_state.id,
        'project_state_id', rejected_state.id
    ) as match_context
from notification_types as notification_type
cross join project_states as review_state
cross join project_states as rejected_state
where
    notification_type.type_key = 'project-review-to-rejected-same-phase'
    and review_state.project_state_name = 'En Revisión'
    and rejected_state.project_state_name = 'Cancelado'
on conflict (
    source_kind,
    operation_kind,
    notification_type_id,
    priority,
    match_context
) do update
    set is_active = true;

insert into notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::notification_rule_target_kind_enum,
    'student_profile_id' as recipient_target
from notification_types as notification_type
where notification_type.type_key = 'project-review-to-rejected-same-phase'
on conflict (
    notification_type_id,
    rule_target_kind,
    recipient_target
) do nothing;

create or replace function public.enqueue_project_progress_notification_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    project_staff public.projects;
    previous_progress public.project_progress;
    notification_payload jsonb;
    resolution_context jsonb;
    resolved_notification_type_id bigint;
    has_previous_progress boolean;
    phase_advanced boolean := false;
    same_phase boolean := false;
    state_changed boolean := false;
    new_phase_order smallint;
    old_phase_order smallint;
    effective_actor_id uuid;
begin
    if tg_op = 'UPDATE'
       and new.project_state_id is not distinct from old.project_state_id
       and new.project_phase_id is not distinct from old.project_phase_id then
        return new;
    end if;

    select project_row.*
    into project_staff
    from public.projects as project_row
    where project_row.id = new.project_id
    limit 1;

    if not found then
        raise exception
            'Notification event creation failed. No project found for project_id %',
            new.project_id
            using errcode = 'P0001';
    end if;

    if tg_op = 'UPDATE' then
        previous_progress := old;
        has_previous_progress := true;
    else
        select progress_row.*
        into previous_progress
        from public.project_progress as progress_row
        where progress_row.project_id = new.project_id
          and progress_row.id <> new.id
        order by progress_row.created_at desc, progress_row.id desc
        limit 1;

        has_previous_progress := previous_progress.id is not null;
    end if;

    select phase_row.project_phase_order
    into new_phase_order
    from public.project_phases as phase_row
    where phase_row.id = new.project_phase_id
    limit 1;

    if not found then
        raise exception
            'Notification event creation failed. No project phase found for project_phase_id %',
            new.project_phase_id
            using errcode = 'P0001';
    end if;

    if has_previous_progress then
        select phase_row.project_phase_order
        into old_phase_order
        from public.project_phases as phase_row
        where phase_row.id = previous_progress.project_phase_id
        limit 1;

        if not found then
            raise exception
                'Notification event creation failed. No previous project phase found for project_phase_id %',
                previous_progress.project_phase_id
                using errcode = 'P0001';
        end if;
    end if;

    phase_advanced := new_phase_order > coalesce(old_phase_order, 0);
    same_phase := coalesce(previous_progress.project_phase_id, new.project_phase_id) = new.project_phase_id;
    state_changed := coalesce(previous_progress.project_state_id, 0) <> new.project_state_id;

    if has_previous_progress then
        resolution_context := jsonb_build_object(
            'project_id', new.project_id,
            'author_profile_id', new.author_profile_id,
            'has_previous_progress', true,
            'is_first_progress', false,
            'phase_advanced', phase_advanced,
            'same_phase', same_phase,
            'state_changed', state_changed,
            'project_phase_id', new.project_phase_id,
            'project_state_id', new.project_state_id,
            'old_project_phase_id', previous_progress.project_phase_id,
            'old_project_state_id', coalesce(previous_progress.project_state_id, 0)
        );
        resolved_notification_type_id := public.resolve_notification_type_id(
            'project_progress',
            'update',
            resolution_context
        );
    else
        resolution_context := jsonb_build_object(
            'project_id', new.project_id,
            'author_profile_id', new.author_profile_id,
            'has_previous_progress', false,
            'is_first_progress', true,
            'phase_advanced', phase_advanced,
            'same_phase', true,
            'state_changed', state_changed,
            'project_phase_id', new.project_phase_id,
            'project_state_id', new.project_state_id,
            'old_project_phase_id', 0,
            'old_project_state_id', 1
        );
        resolved_notification_type_id := public.resolve_notification_type_id(
            'project_progress',
            'update',
            resolution_context
        );
    end if;

    effective_actor_id := coalesce(auth.uid(), new.author_profile_id);

    notification_payload := jsonb_build_object(
        'tutor_profile_id', project_staff.tutor_profile_id,
        'coordinator_profile_id', project_staff.coordinator_profile_id,
        'student_profile_id', project_staff.student_profile_id,
        'project_phase_id', new.project_phase_id,
        'project_state_id', new.project_state_id
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
        'project_progress',
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

drop trigger if exists b_enqueue_proj_progress_notif on public.project_progress;

create trigger b_enqueue_proj_progress_notif
after insert or update on public.project_progress
for each row
execute function public.enqueue_project_progress_notification_event();
