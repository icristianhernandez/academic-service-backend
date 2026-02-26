insert into roles (role_name, permission_level, created_by, updated_by)
values
(
    'student',
    1,
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
),
(
    'tutor',
    2,
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
),
(
    'coordinator',
    2,
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
),
(
    'dean',
    3,
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
)
on conflict (role_name) do update
    set
        permission_level = excluded.permission_level,
        updated_by = excluded.updated_by;
