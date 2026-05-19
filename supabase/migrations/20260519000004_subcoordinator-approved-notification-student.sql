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

insert into public.notification_recipients_rules (
    notification_type_id,
    rule_target_kind,
    recipient_target
)
select
    notification_type.id,
    'payload'::notification_rule_target_kind_enum,
    'student_profile_id'
from public.notification_types as notification_type
where notification_type.type_key = 'project-subcoordinator-approved-to-coordinator'
on conflict (notification_type_id, rule_target_kind, recipient_target) do nothing;
