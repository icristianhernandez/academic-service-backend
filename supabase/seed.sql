-- seed accounts for local sign-in (email / password)
-- student@test.local / 123
-- administrative@test.local / 123
-- tutor@test.local / 123
-- coordinator@test.local / 123
-- dean@test.local / 123
-- sysadmin@test.local / 123
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

insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
)
select
    '00000000-0000-0000-0000-000000000000'::uuid as instance_id,
    seed_accounts.user_id,
    'authenticated' as aud,
    'authenticated' as role_name_value,
    seed_accounts.email,
    extensions.crypt('123', extensions.gen_salt('bf')) as encrypted_password,
    now() as email_confirmed_at,
    '{"provider":"email","providers":["email"]}'::jsonb as raw_app_meta_data,
    '{}'::jsonb as raw_user_meta_data,
    now() as created_at,
    now() as updated_at
from (
    values
    (
        '10000000-0000-0000-0000-000000000001'::uuid,
        'student@test.local'::text,
        'student'::text,
        'student'::text,
        'demo'::text,
        'nid-student'::text,
        '0001'::text
    ),
    (
        '10000000-0000-0000-0000-000000000002'::uuid,
        'administrative@test.local'::text,
        'administrative'::text,
        'administrative'::text,
        'demo'::text,
        'nid-administrative'::text,
        '0002'::text
    ),
    (
        '10000000-0000-0000-0000-000000000003'::uuid,
        'tutor@test.local'::text,
        'tutor'::text,
        'tutor'::text,
        'demo'::text,
        'nid-tutor'::text,
        '0003'::text
    ),
    (
        '10000000-0000-0000-0000-000000000004'::uuid,
        'coordinator@test.local'::text,
        'coordinator'::text,
        'coordinator'::text,
        'demo'::text,
        'nid-coordinator'::text,
        '0004'::text
    ),
    (
        '10000000-0000-0000-0000-000000000005'::uuid,
        'dean@test.local'::text,
        'dean'::text,
        'dean'::text,
        'demo'::text,
        'nid-dean'::text,
        '0005'::text
    ),
    (
        '10000000-0000-0000-0000-000000000006'::uuid,
        'sysadmin@test.local'::text,
        'sysadmin'::text,
        'sysadmin'::text,
        'demo'::text,
        'nid-sysadmin'::text,
        '0006'::text
    )
)
    as seed_accounts (
        user_id,
        email,
        role_name,
        first_name,
        last_name,
        national_id,
        primary_contact
    )
on conflict (id) do update
    set
        instance_id = excluded.instance_id,
        email = excluded.email,
        encrypted_password = excluded.encrypted_password,
        email_confirmed_at = excluded.email_confirmed_at,
        updated_at = now();
insert into auth.identities (
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
)
select
    seed_accounts.user_id::text,
    seed_accounts.user_id,
    jsonb_build_object(
        'sub',
        seed_accounts.user_id::text,
        'email',
        seed_accounts.email,
        'email_verified',
        true
    ) as identity_data,
    'email' as provider_name,
    now() as last_sign_in_at,
    now() as created_at,
    now() as updated_at
from (
    values
    (
        '10000000-0000-0000-0000-000000000001'::uuid,
        'student@test.local'::text
    ),
    (
        '10000000-0000-0000-0000-000000000002'::uuid,
        'administrative@test.local'::text
    ),
    (
        '10000000-0000-0000-0000-000000000003'::uuid,
        'tutor@test.local'::text
    ),
    (
        '10000000-0000-0000-0000-000000000004'::uuid,
        'coordinator@test.local'::text
    ),
    (
        '10000000-0000-0000-0000-000000000005'::uuid,
        'dean@test.local'::text
    ),
    (
        '10000000-0000-0000-0000-000000000006'::uuid,
        'sysadmin@test.local'::text
    )
) as seed_accounts (user_id, email)
on conflict (provider_id, provider) do update
    set
        user_id = excluded.user_id,
        identity_data = excluded.identity_data,
        updated_at = now();
insert into profiles (
    id,
    first_name,
    last_name,
    national_id,
    email,
    primary_contact,
    secondary_contact,
    role_id
)
select
    seed_accounts.user_id,
    seed_accounts.first_name,
    seed_accounts.last_name,
    seed_accounts.national_id,
    seed_accounts.email,
    seed_accounts.primary_contact,
    null::text as secondary_contact,
    role_lookup.id
from (
    values
    (
        '10000000-0000-0000-0000-000000000001'::uuid,
        'student@test.local'::text,
        'student'::text,
        'student'::text,
        'demo'::text,
        'nid-student'::text,
        '0001'::text
    ),
    (
        '10000000-0000-0000-0000-000000000002'::uuid,
        'administrative@test.local'::text,
        'administrative'::text,
        'administrative'::text,
        'demo'::text,
        'nid-administrative'::text,
        '0002'::text
    ),
    (
        '10000000-0000-0000-0000-000000000003'::uuid,
        'tutor@test.local'::text,
        'tutor'::text,
        'tutor'::text,
        'demo'::text,
        'nid-tutor'::text,
        '0003'::text
    ),
    (
        '10000000-0000-0000-0000-000000000004'::uuid,
        'coordinator@test.local'::text,
        'coordinator'::text,
        'coordinator'::text,
        'demo'::text,
        'nid-coordinator'::text,
        '0004'::text
    ),
    (
        '10000000-0000-0000-0000-000000000005'::uuid,
        'dean@test.local'::text,
        'dean'::text,
        'dean'::text,
        'demo'::text,
        'nid-dean'::text,
        '0005'::text
    ),
    (
        '10000000-0000-0000-0000-000000000006'::uuid,
        'sysadmin@test.local'::text,
        'sysadmin'::text,
        'sysadmin'::text,
        'demo'::text,
        'nid-sysadmin'::text,
        '0006'::text
    )
)
    as seed_accounts (
        user_id,
        email,
        role_name,
        first_name,
        last_name,
        national_id,
        primary_contact
    )
inner join roles as role_lookup
    on seed_accounts.role_name = role_lookup.role_name
on conflict (id) do update
    set
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        national_id = excluded.national_id,
        email = excluded.email,
        primary_contact = excluded.primary_contact,
        secondary_contact = excluded.secondary_contact,
        role_id = excluded.role_id,
        updated_at = now();

insert into students (
    profile_id,
    school_id,
    semester,
    shift,
    section
)
select
    profile.id as profile_id,
    school.id as school_id,
    '1'::semester_enum as semester,
    'MORNING'::shift_enum as shift,
    'A'::section_enum as section
from profiles as profile
inner join schools as school
    on true
inner join degrees as degree
    on school.degree_id = degree.id
inner join faculties as faculty
    on school.faculty_id = faculty.id
where
    profile.email = 'student@test.local'
    and degree.degree_name = 'Ingenieria de Sistemas'
    and faculty.faculty_name = 'Facultad de Ingenieria'
    and school.tutor_profile_id is null
    and not exists (
        select 1
        from students
        where students.profile_id = profile.id
    );
