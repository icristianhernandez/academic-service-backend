create or replace function public.dispatch_notification_event_now()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.process_notification_events_queue(100);
    perform public.invoke_notifications_external_deliveries_worker(100);
    return null;
exception
    when others then
        raise warning 'dispatch_notification_event_now failed: %', sqlerrm;
        return null;
end;
$$;

drop trigger if exists a_dispatch_notification_event_now
on public.notifications_events;

create trigger a_dispatch_notification_event_now
after insert on public.notifications_events
for each statement
execute function public.dispatch_notification_event_now();