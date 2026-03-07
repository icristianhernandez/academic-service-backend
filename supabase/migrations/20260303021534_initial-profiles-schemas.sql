create table roles (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    role_name text not null unique,
    permission_level integer not null
);

create table profiles (
    like audit_meta including all,
    id uuid references auth.users not null primary key,
    user_names text not null,
    user_last_names text not null,
    national_id text not null unique,
    primary_contact text not null,
    secondary_contact text,
    email text not null unique,
    role_id bigint references roles (id)
);

do $$
declare
    seed_user_id constant uuid := '00000000-0000-0000-0000-000000000001';
begin
    perform set_config(
        'request.jwt.claims',
        json_build_object(
            'role', 'authenticated',
            'sub', seed_user_id,
            'email', 'seed-worker@usm.local'
        )::text,
        true
    );

    insert into auth.users (
        id,
        email,
        instance_id,
        aud,
        role,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        created_at,
        updated_at
    )
    values (
        seed_user_id,
        'seed-worker@usm.local',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        crypt(gen_random_uuid()::text, gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
            'display_name', 'Seed Service Worker',
            'user_names', 'Seed',
            'user_last_names', 'Worker',
            'primary_contact', '04241111111',
            'secondary_contact', '04241111111'
        ),
        '',
        '',
        '',
        '',
        now(),
        now()
    );

    insert into auth.identities (
        provider_id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    )
    values (
        seed_user_id::text,
        seed_user_id,
        jsonb_build_object(
            'sub', seed_user_id::text,
            'email', 'seed-worker@usm.local',
            'email_verified', false,
            'phone_verified', false
        ),
        'email',
        now(),
        now(),
        now()
    );

    insert into public.profiles (
        id,
        user_names,
        user_last_names,
        national_id,
        primary_contact,
        secondary_contact,
        email,
        role_id
    )
    values (
        seed_user_id,
        'Seed',
        'Worker',
        'V-00000001',
        '04241111111',
        '04241111111',
        'seed-worker@usm.local',
        null
    );
end;
$$;

create or replace function public.validate_invitation_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    perform 1
    from public.invitations
    where email = new.email 
      and is_active = true
    limit 1;

    if not found then
        raise exception 'Signup failed. No active invitation found for email: %', new.email 
            using errcode = 'P0001';
    end if;

    return new;
end;
$$;

create or replace function public.handle_new_profile()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    invitation_role_id bigint;
    actor_id uuid;
begin
    select role_to_have_id
    into invitation_role_id
    from public.invitations
    where email = new.email
      and is_active = true
    limit 1;

    actor_id := coalesce(auth.uid(), new.id);

    insert into public.profiles (
        id,
        user_names,
        user_last_names,
        national_id,
        primary_contact,
        secondary_contact,
        email,
        role_id,
        created_by,
        updated_by
    )
    values (
        new.id,
        new.raw_user_meta_data ->> 'user_names',
        new.raw_user_meta_data ->> 'user_last_names',
        new.raw_user_meta_data ->> 'national_id',
        new.raw_user_meta_data ->> 'primary_contact',
        new.raw_user_meta_data ->> 'secondary_contact',
        new.email,
        invitation_role_id,
        actor_id,
        actor_id
    );

    return new;
end;
$$;

create function public.handle_new_student_profile()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    actor_id uuid;
    is_student_role boolean;
    school_id bigint;
    v_degree_name text;
    v_faculty_name text;
    v_campus_name text;
begin
    select exists(
        select 1
        from public.invitations invitation
        join public.roles role on role.id = invitation.role_to_have_id
        where invitation.email = new.email
          and invitation.is_active = true
          and role.role_name = 'student'
    )
    into is_student_role;

    if not is_student_role then
        return new;
    end if;

    v_degree_name := new.raw_user_meta_data ->> 'degree_name';
    v_faculty_name := new.raw_user_meta_data ->> 'faculty_name';
    v_campus_name := new.raw_user_meta_data ->> 'campus_name';

    select school.id
    into school_id
    from public.schools school
    join public.degrees degree on degree.id = school.degree_id
    join public.faculties faculty on faculty.id = school.faculty_id
    join public.campuses campus on campus.id = faculty.campus_id
    where degree.degree_name = v_degree_name
      and faculty.faculty_name = v_faculty_name
      and campus.campus_name = v_campus_name
    limit 1;

    if not found then
        raise exception
            'Signup failed. No school found for degree_name %, faculty_name %, campus_name %',
            v_degree_name,
            v_faculty_name,
            v_campus_name
            using errcode = 'P0001';
    end if;

    actor_id := coalesce(auth.uid(), new.id);

    insert into public.students (
        profile_id,
        school_id,
        semester,
        shift,
        section,
        created_by,
        updated_by
    )
    values (
        new.id,
        school_id,
        (new.raw_user_meta_data ->> 'semester')::public.semester_enum,
        (new.raw_user_meta_data ->> 'shift')::public.shift_enum,
        (new.raw_user_meta_data ->> 'section')::public.section_enum,
        actor_id,
        actor_id
    );

    return new;
end;
$$;

create function public.assign_faculty_to_coordinator_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    faculty_id bigint;
    role_name text;
begin
    select invitation.faculty_to_be_coordinator, role.role_name
    into faculty_id, role_name
    from public.invitations invitation
    join public.roles role on role.id = invitation.role_to_have_id
    where invitation.email = new.email
      and invitation.is_active = true
    limit 1;

    if role_name is distinct from 'coordinator' then
        return new;
    end if;

    if exists (
        select 1
        from public.faculties faculty
        where faculty.id = faculty_id
          and faculty.coordinator_profile_id is not null
    ) then
        raise exception
            'Signup failed. Faculty % already has a coordinator assigned',
            faculty_id
            using errcode = 'P0001';
    end if;

    update public.faculties
    set coordinator_profile_id = new.id
    where id = faculty_id;

    return new;
end;
$$;

create function public.assign_school_to_teacher_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    school_id bigint;
    role_name text;
begin
    select invitation.school_to_be_tutor, role.role_name
    into school_id, role_name
    from public.invitations invitation
    join public.roles role on role.id = invitation.role_to_have_id
    where invitation.email = new.email
        and invitation.is_active = true
    limit 1;

    if role_name is distinct from 'tutor' then
        return new;
    end if;

    if exists (
        select 1
        from public.schools school
        where school.id = school_id
          and school.tutor_profile_id is not null
    ) then
        raise exception
            'Signup failed. School % already has a tutor assigned',
            school_id
            using errcode = 'P0001';
    end if;

    update public.schools
    set tutor_profile_id = new.id
    where id = school_id;

    return new;
end;
$$;

create function public.deactivate_invitation_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    update public.invitations
    set is_active = false
    where email = new.email;

    return new;
end;
$$;

create trigger a_validate_invitation_on_signup
before insert on auth.users
for each row
execute procedure public.validate_invitation_on_signup();

create trigger b_handle_new_profile
after insert on auth.users
for each row
execute procedure public.handle_new_profile();

create trigger c_handle_new_student_profile
after insert on auth.users
for each row
execute procedure public.handle_new_student_profile();

create trigger d_assign_faculty_to_coordinator_on_signup
after insert on auth.users
for each row
execute procedure public.assign_faculty_to_coordinator_on_signup();

create trigger e_assign_faculty_to_coordinator_on_signup
after insert on auth.users
for each row
execute procedure public.assign_school_to_teacher_on_signup();

create trigger z_deactivate_invitation_on_signup
after insert on auth.users
for each row
execute procedure public.deactivate_invitation_on_signup();

call setup_audit(
    'roles',
    'profiles'
);
