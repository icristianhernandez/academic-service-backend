create extension if not exists pg_cron;
create extension if not exists pg_net;

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

create or replace function public.claim_notifications_external_deliveries_queue(
    p_batch_size integer default 100
)
returns table (
    delivery_id bigint,
    notification_recipient_id bigint,
    recipient_id uuid,
    recipient_name text,
    recipient_email text,
    notification_event_id bigint,
    notification_type_key text,
    payload jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
begin
    return query
    with deliveries_to_claim as (
        select
            delivery.id,
            delivery.notification_recipient_id
        from public.notifications_external_deliveries as delivery
        where delivery.delivery_status = 'pending'
          and delivery.to_channel = 'email'
        order by delivery.created_at asc, delivery.id asc
        for update skip locked
        limit p_batch_size
    )
    update public.notifications_external_deliveries as delivery
    set
        delivery_status = 'processing',
        retry_count = delivery.retry_count + 1,
        processed_at = null,
        error_message = null,
        last_attempt = now()
    from deliveries_to_claim
    join public.notification_recipients as recipient
        on recipient.id = deliveries_to_claim.notification_recipient_id
    join public.notifications_events as notification_event
        on notification_event.id = recipient.notification_id
    join public.notification_types as notification_type
        on notification_type.id = notification_event.notification_type_id
    join public.profiles as recipient_profile
        on recipient_profile.id = recipient.recipient_id
    where delivery.id = deliveries_to_claim.id
    returning
        delivery.id,
        delivery.notification_recipient_id,
        recipient.recipient_id,
        concat_ws(
            ' ',
            recipient_profile.user_names,
            recipient_profile.user_last_names
        ) as recipient_name,
        recipient_profile.email,
        notification_event.id,
        notification_type.type_key,
        notification_event.payload;
end;
$$;

create or replace function
public.invoke_notifications_external_deliveries_worker(
    p_batch_size integer default 100
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    notifications_worker_url text;
    notifications_worker_api_key text;
    supabase_publishable_key text;
    request_id bigint;
begin
    notifications_worker_url := 'http://kong:8000/functions/v1/process-notifications-external-deliveries';
    notifications_worker_api_key := '123';
    supabase_publishable_key := 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

    request_id := net.http_post(
        url := notifications_worker_url,
        body := jsonb_build_object('batch_size', p_batch_size),
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || supabase_publishable_key,
            'apikey', supabase_publishable_key,
            'x-api-key', notifications_worker_api_key
        ),
        timeout_milliseconds := 5000
    );

    return request_id;
end;
$$;

create or replace function public.mark_notifications_external_delivery_sent(
    p_delivery_id bigint
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.notifications_external_deliveries
    set
        delivery_status = 'sent',
        processed_at = now(),
        error_message = null,
        last_attempt = now()
    where id = p_delivery_id
      and delivery_status = 'processing';

    return found;
end;
$$;

create or replace function public.mark_notifications_external_delivery_failed(
    p_delivery_id bigint,
    p_error_message text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.notifications_external_deliveries
    set
        delivery_status = 'failed',
        processed_at = null,
        error_message = left(coalesce(p_error_message, 'Unknown error'), 1000),
        last_attempt = now()
    where id = p_delivery_id
      and delivery_status = 'processing';

    return found;
end;
$$;

do $$
declare
    existing_job_id bigint;
begin
    select job.jobid
    into existing_job_id
    from cron.job as job
    where job.jobname = 'notifications-events-worker'
    limit 1;

    if existing_job_id is not null then
        perform cron.unschedule(existing_job_id);
    end if;

    perform cron.schedule(
        'notifications-events-worker',
        '* * * * *',
        'select public.process_notification_events_queue(100);'
    );
end;
$$;

do $$
declare
    existing_job_id bigint;
begin
    select job.jobid
    into existing_job_id
    from cron.job as job
    where job.jobname = 'notifications-external-deliveries-worker'
    limit 1;

    if existing_job_id is not null then
        perform cron.unschedule(existing_job_id);
    end if;

    perform cron.schedule(
        'notifications-external-deliveries-worker',
        '* * * * *',
        'select public.invoke_notifications_external_deliveries_worker(100);'
    );
end;
$$;
