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
    subcoordinator_profile_id uuid references profiles (id),
    coordinator_profile_id uuid not null references profiles (id),
    student_profile_id uuid not null references profiles (id) unique,
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

create table project_members (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_id bigint not null references projects (id),
    profile_id uuid not null references profiles (id),
    is_leader boolean not null default false,

    unique (project_id, profile_id),
    unique (profile_id)
);

create unique index idx_project_members_one_leader
on project_members (project_id)
where is_leader = true;

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
    previous_state_name text;
    new_state_name text;
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

    select project_state_name into previous_state_name
    from public.project_states
    where id = previous_progress.project_state_id
    limit 1;

    if new_phase.project_phase_order < previous_phase.project_phase_order then
        raise exception
            'Project progress validation failed. Phase cannot move backwards'
            using errcode = 'P0001';
    end if;

    if new_phase.project_phase_order > previous_phase.project_phase_order then
        if previous_state_name <> 'Aprobado por Coordinador' then
            raise exception
                'Cannot advance phase because previous phase is not approved. Current state: %',
                previous_state_name
                using errcode = 'P0001';
        end if;
    end if;

    if new_phase.project_phase_order = previous_phase.project_phase_order then
        select project_state_name into new_state_name
        from public.project_states
        where id = new.project_state_id;

        if previous_state_name = 'En revisión' then
            if new_state_name not in ('Aprobado por Subcoordinador', 'Aprobado por Coordinador', 'Rechazado para corrección') then
                raise exception 'Invalid state transition from En revisión to %', new_state_name;
            end if;
        elsif previous_state_name = 'Aprobado por Subcoordinador' then
            if new_state_name not in ('Aprobado por Coordinador', 'Rechazado para corrección') then
                raise exception 'Invalid state transition from Aprobado por Subcoordinador to %', new_state_name;
            end if;
        elsif previous_state_name = 'Rechazado para corrección' then
            if new_state_name <> 'En revisión' then
                raise exception 'Invalid state transition from Rechazado para corrección to %', new_state_name;
            end if;
        elsif previous_state_name = 'Aprobado por Coordinador' then
            if new_state_name <> 'En revisión' then
                raise exception 'Invalid state transition from Aprobado por Coordinador to %', new_state_name;
            end if;
        end if;

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

create trigger a_set_project_staff_on_insert
before insert on projects
for each row
execute procedure public.set_project_staff_on_insert();

create function public.validate_project_member_limits()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    current_count  integer;
    max_allowed    smallint;
    leader_school  bigint;
    member_school  bigint;
    has_progress   boolean;
    target_pid     bigint;
begin
    target_pid := coalesce(new.project_id, old.project_id);

    select exists (
        select 1 from public.project_progress
        where project_id = target_pid
    ) into has_progress;

    if has_progress then
        raise exception
            'Cannot modify members after project has begun'
            using errcode = 'P0001';
    end if;

    if tg_op = 'INSERT' then
        select s.id, f.max_members into leader_school, max_allowed
        from public.projects p
        join public.students st on st.profile_id = p.student_profile_id
        join public.schools s on s.id = st.school_id
        join public.faculties f on f.id = s.faculty_id
        where p.id = new.project_id;

        if not found then
            raise exception
                'Project % has no valid school', new.project_id
                using errcode = 'P0001';
        end if;

        select st.school_id into member_school
        from public.students st
        where st.profile_id = new.profile_id;

        if not found or member_school <> leader_school then
            raise exception
                'New member must belong to the same school as the project leader'
                using errcode = 'P0001';
        end if;

        select count(*) into current_count
        from public.project_members
        where project_id = new.project_id;

        if current_count + 1 > max_allowed then
            raise exception
                'Project % exceeds maximum members (%)', new.project_id, max_allowed
                using errcode = 'P0001';
        end if;
    end if;

    if tg_op = 'INSERT' then return new;
    elsif tg_op = 'UPDATE' then return new;
    else return old;
    end if;
end;
$$;

create trigger a_validate_project_member_limits
before insert or update or delete on project_members
for each row
execute procedure public.validate_project_member_limits();

call setup_audit(
    'institutions',
    'project_phases',
    'project_states',
    'project_progress',
    'projects',
    'project_members'
);
