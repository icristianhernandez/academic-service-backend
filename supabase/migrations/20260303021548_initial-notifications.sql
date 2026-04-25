create type notification_channel_enum as
enum (
    'email'
);

create type notification_delivery_status_enum as
enum (
    'pending',
    'processing',
    'sent',
    'failed',
    'skipped'
);

create type notification_event_status_enum as
enum (
    'pending',
    'processing',
    'processed',
    'failed'
);

create type notification_rule_target_kind_enum as
enum (
    'actor',
    'event_schema',
    'role',
    'permission_level',
    'explicit_profile',
    'payload'
);

create table notification_types (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    type_key text not null unique
);

create table notification_recipients_rules (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    notification_type_id bigint not null references notification_types (id),
    rule_target_kind notification_rule_target_kind_enum not null,
    recipient_target text not null,

    unique (notification_type_id, rule_target_kind, recipient_target)
);

create table notification_type_resolution_rules (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    source_kind text not null,
    operation_kind text not null,
    notification_type_id bigint not null references notification_types (id),
    priority integer not null default 100,
    is_active boolean not null default true,
    match_context jsonb not null default '{}'::jsonb,

    check (jsonb_typeof(match_context) = 'object'),
    unique (
        source_kind,
        operation_kind,
        notification_type_id,
        priority,
        match_context
    )
);

create table notification_type_defaults (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    source_kind text not null,
    operation_kind text not null,
    notification_type_id bigint not null references notification_types (id),

    unique (source_kind, operation_kind),
    unique (notification_type_id)
);

create table notifications_events (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    notification_type_id bigint not null references notification_types (id),
    source_kind text not null,
    operation_kind text not null,
    source_record_id text not null,
    payload jsonb not null,
    actor_id uuid references public.profiles,
    processed_status notification_event_status_enum not null default 'pending',
    retry_count integer not null default 0,
    processed_at timestamptz default null,
    error_message text default null,
    last_attempt timestamptz default null
);

create table notification_recipients (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    notification_id bigint not null references notifications_events (id),
    recipient_id uuid not null references public.profiles,

    unique (notification_id, recipient_id)
);

create table user_inbox (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    notification_recipient_id bigint not null
    references notification_recipients (id),
    read_at timestamptz default null,

    unique (notification_recipient_id)
);

create table notifications_external_deliveries (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    notification_recipient_id bigint not null
    references notification_recipients (id),
    to_channel notification_channel_enum not null,
    delivery_status notification_delivery_status_enum not null
    default 'pending',
    retry_count integer not null default 0,
    processed_at timestamptz default null,
    error_message text default null,
    last_attempt timestamptz default null,

    unique (notification_recipient_id, to_channel)
);

create index idx_notification_recipients_rules_lookup
on notification_recipients_rules (notification_type_id, rule_target_kind);

create index idx_notification_type_resolution_rules_lookup
on notification_type_resolution_rules (
    source_kind,
    operation_kind,
    is_active,
    priority desc
);

create index idx_notifications_events_queue
on notifications_events (processed_status, created_at, id);

create index idx_notifications_events_source
on notifications_events (source_kind, operation_kind, source_record_id);

create index idx_notification_recipients_recipient
on notification_recipients (recipient_id, created_at);

create index idx_user_inbox_unread
on user_inbox (read_at)
where read_at is null;

create index idx_notifications_external_deliveries_queue
on notifications_external_deliveries (delivery_status, created_at, id);

create or replace function public.resolve_notification_type_id(
    p_source_kind text,
    p_operation_kind text,
    p_context jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    resolved_notification_type_id bigint;
begin
    select resolution_rule.notification_type_id
    into resolved_notification_type_id
    from public.notification_type_resolution_rules as resolution_rule
    where resolution_rule.source_kind = p_source_kind
      and resolution_rule.operation_kind = p_operation_kind
      and resolution_rule.is_active
      and p_context @> resolution_rule.match_context
    order by
        resolution_rule.priority desc,
        resolution_rule.id asc
    limit 1;

    if resolved_notification_type_id is null then
        select default_rule.notification_type_id
        into resolved_notification_type_id
        from public.notification_type_defaults as default_rule
        where default_rule.source_kind = p_source_kind
          and default_rule.operation_kind = p_operation_kind
        limit 1;
    end if;

    if resolved_notification_type_id is null then
        raise exception
            'Missing fallback notification type. source_kind %, operation_kind %',
            p_source_kind,
            p_operation_kind
            using errcode = 'P0001';
    end if;

    return resolved_notification_type_id;
end;
$$;

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
begin
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

    select progress_row.*
    into previous_progress
    from public.project_progress as progress_row
    where progress_row.project_id = new.project_id
      and progress_row.id <> new.id
    order by progress_row.created_at desc, progress_row.id desc
    limit 1;

    has_previous_progress := previous_progress.id is not null;

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
        new.author_profile_id,
        coalesce(auth.uid(), new.author_profile_id),
        coalesce(auth.uid(), new.author_profile_id)
    );

    return new;
end;
$$;

create trigger b_enqueue_project_progress_notification_event
after insert on public.project_progress
for each row
execute function public.enqueue_project_progress_notification_event();

call setup_audit(
    'notification_types',
    'notification_recipients_rules',
    'notification_type_resolution_rules',
    'notification_type_defaults',
    'notifications_events',
    'notification_recipients',
    'user_inbox',
    'notifications_external_deliveries'
);


begin;
  alter publication supabase_realtime add table public.notification_recipients;
  alter publication supabase_realtime add table public.user_inbox;
commit;
