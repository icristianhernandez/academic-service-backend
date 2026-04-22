create table institutions (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint references locations (id),
    contact_person_profile_id uuid references profiles (id),
    institution_name text not null unique
);

create table project_phases (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_phase_name text not null unique,
    project_phase_order smallint not null unique,
    phase_kind text not null,
    report_number smallint,

    check (
        phase_kind in (
            'preproject',
            'report',
            'final_report',
            'approved'
        )
    ),
    check (
        (
            phase_kind = 'report'
            and report_number is not null
            and report_number between 1 and 10
        )
        or (
            phase_kind <> 'report'
            and report_number is null
        )
    )
);

create table project_states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_state_name text not null unique
);

create table projects (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    tutor_profile_id uuid not null references profiles (id),
    coordinator_profile_id uuid not null references profiles (id),
    student_profile_id uuid not null references profiles (id),
    institution_id bigint not null references institutions (id),
    title text not null,
    abstract text
);

create table project_progress (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_id bigint not null references projects (id),
    project_phase_id bigint not null references project_phases (id),
    project_state_id bigint not null references project_states (id),
    author_profile_id uuid not null references profiles (id),
    document_id bigint not null references documents (id),
    observations text
);

create index idx_project_progress_project_created
on project_progress (project_id, created_at desc, id desc);

create function public.validate_project_progress_phase_transition()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    reports_required_count smallint;
    new_phase public.project_phases;
    previous_progress public.project_progress;
    previous_phase public.project_phases;
    is_valid_transition boolean := false;
begin
    select
        faculty.reports_required_count
    into reports_required_count
    from public.projects as project_row
    join public.students as student
        on student.profile_id = project_row.student_profile_id
    join public.schools as school
        on school.id = student.school_id
    join public.faculties as faculty
        on faculty.id = school.faculty_id
    where project_row.id = new.project_id
    limit 1;

    if not found then
        raise exception
            'Project progress validation failed. No faculty found for project_id %',
            new.project_id
            using errcode = 'P0001';
    end if;

    select phase_row.*
    into new_phase
    from public.project_phases as phase_row
    where phase_row.id = new.project_phase_id
    limit 1;

    if not found then
        raise exception
            'Project progress validation failed. No project phase found for project_phase_id %',
            new.project_phase_id
            using errcode = 'P0001';
    end if;

    if new_phase.phase_kind = 'report'
        and new_phase.report_number > reports_required_count then
        raise exception
            'Project progress validation failed. Faculty supports % reports, received report %',
            reports_required_count,
            new_phase.report_number
            using errcode = 'P0001';
    end if;

    select progress_row.*
    into previous_progress
    from public.project_progress as progress_row
    where progress_row.project_id = new.project_id
    order by progress_row.created_at desc, progress_row.id desc
    limit 1;

    if previous_progress.id is null then
        if new_phase.phase_kind <> 'preproject' then
            raise exception
                'Project progress validation failed. First phase must be Preproyecto'
                using errcode = 'P0001';
        end if;

        return new;
    end if;

    select phase_row.*
    into previous_phase
    from public.project_phases as phase_row
    where phase_row.id = previous_progress.project_phase_id
    limit 1;

    if not found then
        raise exception
            'Project progress validation failed. No previous phase found for project_phase_id %',
            previous_progress.project_phase_id
            using errcode = 'P0001';
    end if;

    if new_phase.project_phase_order < previous_phase.project_phase_order then
        raise exception
            'Project progress validation failed. Phase cannot move backwards'
            using errcode = 'P0001';
    end if;

    if new_phase.project_phase_order = previous_phase.project_phase_order then
        return new;
    end if;

    if previous_phase.phase_kind = 'preproject' then
        if reports_required_count = 0 and new_phase.phase_kind = 'final_report' then
            is_valid_transition := true;
        end if;

        if reports_required_count > 0
            and new_phase.phase_kind = 'report'
            and new_phase.report_number = 1 then
            is_valid_transition := true;
        end if;
    end if;

    if previous_phase.phase_kind = 'report' then
        if previous_phase.report_number < reports_required_count
            and new_phase.phase_kind = 'report'
            and new_phase.report_number = previous_phase.report_number + 1 then
            is_valid_transition := true;
        end if;

        if previous_phase.report_number = reports_required_count
            and new_phase.phase_kind = 'final_report' then
            is_valid_transition := true;
        end if;
    end if;

    if previous_phase.phase_kind = 'final_report'
        and new_phase.phase_kind = 'approved' then
        is_valid_transition := true;
    end if;

    if not is_valid_transition then
        raise exception
            'Project progress validation failed. Invalid transition from % to % for faculty report count %',
            previous_phase.project_phase_name,
            new_phase.project_phase_name,
            reports_required_count
            using errcode = 'P0001';
    end if;

    return new;
end;
$$;

create trigger b_validate_project_progress_phase_transition
before insert on project_progress
for each row
execute procedure public.validate_project_progress_phase_transition();

create function public.set_project_staff_on_insert()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    school_id bigint;
    faculty_id bigint;
    tutor_id uuid;
    coordinator_id uuid;
begin
    select
        school.id,
        faculty.id,
        school.tutor_profile_id,
        faculty.coordinator_profile_id
    into school_id, faculty_id, tutor_id, coordinator_id
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

    if tutor_id is null then
        raise exception
            'Project creation failed. School % has no tutor assigned',
            school_id
            using errcode = 'P0001';
    end if;

    if coordinator_id is null then
        raise exception
            'Project creation failed. Faculty % has no coordinator assigned',
            faculty_id
            using errcode = 'P0001';
    end if;

    new.tutor_profile_id := tutor_id;
    new.coordinator_profile_id := coordinator_id;

    return new;
end;
$$;

create trigger a_set_project_staff_on_insert
before insert on projects
for each row
execute procedure public.set_project_staff_on_insert();

call setup_audit(
    'institutions',
    'project_phases',
    'project_states',
    'project_progress',
    'projects'
);
