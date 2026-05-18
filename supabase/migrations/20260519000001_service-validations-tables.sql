create table service_validations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    student_profile_id uuid not null references profiles (id),
    coordinator_profile_id uuid not null references profiles (id),
    achievement_title text,
    grade_document_id bigint references documents (id),
    certificate_document_id bigint not null references documents (id)
);

create table service_validation_progress (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    service_validation_id bigint not null references service_validations (id),
    validacion_state_id bigint not null references validacion_states (id),
    author_profile_id uuid not null references profiles (id),
    document_id bigint references documents (id),
    observations text
);

create index idx_service_validation_progress_lookup
on service_validation_progress (
    service_validation_id, created_at desc, id desc
);

create function public.set_service_validation_staff_on_insert()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    coordinator_id uuid;
begin
    select faculty.coordinator_profile_id
    into coordinator_id
    from public.students as student
    join public.schools as school on school.id = student.school_id
    join public.faculties as faculty on faculty.id = school.faculty_id
    where student.profile_id = new.student_profile_id
    limit 1;

    if not found then
        raise exception
            'Convalidation creation failed. No student found for profile_id %',
            new.student_profile_id
            using errcode = 'P0001';
    end if;

    if coordinator_id is null then
        raise exception
            'Convalidation creation failed. Faculty has no coordinator assigned for student profile_id %',
            new.student_profile_id
            using errcode = 'P0001';
    end if;

    new.coordinator_profile_id := coordinator_id;

    return new;
end;
$$;

create trigger a_set_service_validation_staff_on_insert
before insert on service_validations
for each row
execute function public.set_service_validation_staff_on_insert();

create or replace function public.set_project_staff_on_insert()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    school_id bigint;
    faculty_id bigint;
    subcoordinator_id uuid;
    coordinator_id uuid;
begin
    select
        school.id,
        faculty.id,
        school.subcoordinator_profile_id,
        faculty.coordinator_profile_id
    into school_id, faculty_id, subcoordinator_id, coordinator_id
    from public.students student
    join public.schools school on school.id = student.school_id
    join public.faculties faculty on faculty.id = school.faculty_id
    where student.profile_id = new.student_profile_id
    limit 1;

    if not found then
        raise exception
            'Project creation failed. No student found for profile_id %',
            new.student_profile_id
            using errcode = 'P0001';
    end if;

    if exists (
        select 1 from public.project_members
        where profile_id = new.student_profile_id
    ) then
        raise exception
            'Project creation failed. Student is already a member of another project'
            using errcode = 'P0001';
    end if;

    if exists (
        select 1 from public.service_validations
        where student_profile_id = new.student_profile_id
    ) then
        raise exception
            'Project creation failed. Student already has a convalidation'
            using errcode = 'P0001';
    end if;

    if coordinator_id is null then
        raise exception
            'Project creation failed. Faculty % has no coordinator assigned',
            faculty_id
            using errcode = 'P0001';
    end if;

    new.subcoordinator_profile_id := subcoordinator_id;
    new.coordinator_profile_id := coordinator_id;

    return new;
end;
$$;

create function public.validate_service_validation_no_project()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    if exists (
        select 1 from public.projects
        where student_profile_id = new.student_profile_id
    ) then
        raise exception
            'Cannot create convalidation: student already has a project'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

create trigger a_validate_service_validation_no_project
before insert or update on service_validations
for each row
execute function public.validate_service_validation_no_project();

create function public.validate_service_validation_progress_transition()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    previous_progress public.service_validation_progress;
    previous_state_name text;
    new_state_name text;
begin
    select progress_row.*
    into previous_progress
    from public.service_validation_progress as progress_row
    where progress_row.service_validation_id = new.service_validation_id
    order by progress_row.created_at desc, progress_row.id desc
    limit 1;

    if previous_progress.id is null then
        return new;
    end if;

    select validacion_state_name into previous_state_name
    from public.validacion_states
    where id = previous_progress.validacion_state_id
    limit 1;

    if not found then
        raise exception
            'Convalidation progress validation failed. No previous state found for id %',
            previous_progress.validacion_state_id
            using errcode = 'P0001';
    end if;

    select validacion_state_name into new_state_name
    from public.validacion_states
    where id = new.validacion_state_id
    limit 1;

    if not found then
        raise exception
            'Convalidation progress validation failed. No new state found for id %',
            new.validacion_state_id
            using errcode = 'P0001';
    end if;

    if previous_state_name = 'En revisión' then
        if new_state_name not in ('Validado por Coordinador', 'Rechazado para corrección') then
            raise exception 'Invalid state transition from En revisión to %', new_state_name;
        end if;
    elsif previous_state_name = 'Validado por Coordinador' then
        if new_state_name not in ('Consignado a Planeamiento y Admisión', 'Rechazado para corrección') then
            raise exception 'Invalid state transition from Validado por Coordinador to %', new_state_name;
        end if;
    elsif previous_state_name = 'Consignado a Planeamiento y Admisión' then
        if new_state_name not in ('Aprobado por Planeamiento y Admisión', 'Rechazado para corrección', 'En revisión') then
            raise exception 'Invalid state transition from Consignado a Planeamiento y Admisión to %', new_state_name;
        end if;
    elsif previous_state_name = 'Aprobado por Planeamiento y Admisión' then
        if new_state_name <> 'En revisión' then
            raise exception 'Invalid state transition from Aprobado por Planeamiento y Admisión to %', new_state_name;
        end if;
    elsif previous_state_name = 'Rechazado para corrección' then
        if new_state_name <> 'En revisión' then
            raise exception 'Invalid state transition from Rechazado para corrección to %', new_state_name;
        end if;
    end if;

    return new;
end;
$$;

create trigger a_validate_service_validation_progress_transition
before insert on service_validation_progress
for each row
execute function public.validate_service_validation_progress_transition();

call setup_audit(
    'service_validations',
    'service_validation_progress'
);
