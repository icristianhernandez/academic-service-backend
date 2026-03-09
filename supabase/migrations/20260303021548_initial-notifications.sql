create type notification_channel_enum as
enum ('in_app', 'email');

create type notification_delivery_status_enum as
enum ('pending', 'processing', 'sent', 'failed', 'skipped');

create table notification_preferences (
    like audit_meta including all,
    id uuid default gen_random_uuid() primary key,
    profile_id uuid not null references profiles (id),
    event_type text not null,
    channel notification_channel_enum not null,
    enabled boolean not null default true,
    unique (profile_id, event_type, channel)
);

create table notification_events (
    like audit_meta including all,
    id uuid default gen_random_uuid() primary key,
    event_type text not null,
    recipient_profile_id uuid not null references profiles (id),
    actor_profile_id uuid references profiles (id),
    payload jsonb,
    dedupe_key text unique,
    available_at timestamptz default now() not null,
    processed_at timestamptz
);

create table notification_deliveries (
    like audit_meta including all,
    id uuid default gen_random_uuid() primary key,
    event_id uuid not null
    references notification_events (id)
    on delete cascade,
    channel notification_channel_enum not null,
    status notification_delivery_status_enum not null default 'pending',
    attempt_count integer not null default 0,
    last_attempt_at timestamptz,
    sent_at timestamptz,
    error_message text,
    unique (event_id, channel)
);

create table notifications (
    like audit_meta including all,
    id uuid default gen_random_uuid() primary key,
    profile_id uuid not null references profiles (id),
    event_id uuid references notification_events (id),
    notification_type text not null,
    payload jsonb,
    read_at timestamptz
);

-- create index idx_notification_events_available
-- on notification_events (available_at)
-- where processed_at is null;
--
-- create index idx_notification_deliveries_status
-- on notification_deliveries (status, last_attempt_at);
--
-- create index idx_notifications_profile_created
-- on notifications (profile_id, created_at desc);
--
-- create index idx_notifications_profile_unread
-- on notifications (profile_id, created_at desc)
-- where read_at is null;

call enable_audit_tracking(
    'notification_preferences',
    'notification_events',
    'notification_deliveries',
    'notifications'
);

-- alter table notification_preferences enable row level security;
-- alter table notification_events enable row level security;
-- alter table notification_deliveries enable row level security;
-- alter table notifications enable row level security;
--
-- create policy notification_preferences_select_own
-- on notification_preferences
-- for select
-- to authenticated
-- using (profile_id = auth.uid());
--
-- create policy notification_preferences_insert_own
-- on notification_preferences
-- for insert
-- to authenticated
-- with check (profile_id = auth.uid());
--
-- create policy notification_preferences_update_own
-- on notification_preferences
-- for update
-- to authenticated
-- using (profile_id = auth.uid())
-- with check (profile_id = auth.uid());
--
-- create policy notification_preferences_delete_own
-- on notification_preferences
-- for delete
-- to authenticated
-- using (profile_id = auth.uid());
--
-- create policy notifications_select_own
-- on notifications
-- for select
-- to authenticated
-- using (profile_id = auth.uid());
--
-- create policy notifications_update_own
-- on notifications
-- for update
-- to authenticated
-- using (profile_id = auth.uid())
-- with check (profile_id = auth.uid());
