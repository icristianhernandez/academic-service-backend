alter table public.projects add column reports_required_count smallint not null default 3;
alter table public.projects add column min_members smallint not null default 1;
alter table public.projects add column max_members smallint not null default 1;

update public.projects p
set
  reports_required_count = f.reports_required_count,
  min_members = f.min_members,
  max_members = f.max_members
from public.students s
join public.schools sch on sch.id = s.school_id
join public.faculties f on f.id = sch.faculty_id
where s.profile_id = p.student_profile_id;

create or replace function public.set_project_staff_on_insert()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    v_school_id bigint;
    v_faculty_id bigint;
    v_subcoordinator_id uuid;
    v_coordinator_id uuid;
    v_reports_count smallint;
    v_min_m smallint;
    v_max_m smallint;
begin
    select
        school.id,
        faculty.id,
        school.subcoordinator_profile_id,
        faculty.reports_required_count,
        faculty.min_members,
        faculty.max_members
    into v_school_id, v_faculty_id, v_subcoordinator_id, v_reports_count, v_min_m, v_max_m
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
        select 1 from public.exonerations
        where student_profile_id = new.student_profile_id
    ) then
        raise exception
            'Project creation failed. Student already has an exoneration'
            using errcode = 'P0001';
    end if;

    select cs.coordinator_profile_id
    into v_coordinator_id
    from public.coordinator_schools cs
    where cs.school_id = v_school_id
    limit 1;

    if v_coordinator_id is null then
        select cs.coordinator_profile_id
        into v_coordinator_id
        from public.coordinator_schools cs
        join public.schools s on s.id = cs.school_id
        where s.faculty_id = v_faculty_id
        limit 1;
    end if;

    if v_coordinator_id is null then
        raise exception
            'Project creation failed. Faculty % has no coordinator assigned',
            v_faculty_id
            using errcode = 'P0001';
    end if;

    new.subcoordinator_profile_id := v_subcoordinator_id;
    new.coordinator_profile_id := v_coordinator_id;
    new.reports_required_count := coalesce(v_reports_count, 3);
    new.min_members := coalesce(v_min_m, 1);
    new.max_members := coalesce(v_max_m, 1);

    return new;
end;
$$;

create or replace function public.validate_project_member_limits()
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
        select s.id, p.max_members into leader_school, max_allowed
        from public.projects p
        join public.students st on st.profile_id = p.student_profile_id
        join public.schools s on s.id = st.school_id
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
