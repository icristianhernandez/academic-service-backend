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
            on conflict (notification_id, recipient_id) do nothing;

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
