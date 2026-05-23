create table public.coordinator_schools (
    id bigint generated always as identity primary key,
    coordinator_profile_id uuid not null references public.profiles(id) on delete cascade,
    school_id bigint not null references public.schools(id) on delete cascade,
    created_at timestamp with time zone default now(),
    unique(coordinator_profile_id, school_id)
);

call public.setup_audit('coordinator_schools');

alter table public.invitations add column schools_to_be_coordinator bigint[];

insert into public.coordinator_schools (coordinator_profile_id, school_id)
select f.coordinator_profile_id, s.id
from public.faculties f
join public.schools s on s.faculty_id = f.id
where f.coordinator_profile_id is not null;

alter table public.faculties drop column coordinator_profile_id;

create or replace function public.assign_faculty_to_coordinator_on_signup()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    v_school_ids bigint[];
    role_name text;
    v_school_id bigint;
begin
    select invitation.schools_to_be_coordinator, role.role_name
    into v_school_ids, role_name
    from public.invitations invitation
    join public.roles role on role.id = invitation.role_to_have_id
    where invitation.email = new.email
      and invitation.reclaimed_at is null
    limit 1;

    if role_name is distinct from 'coordinator' then
        return new;
    end if;

    if v_school_ids is not null then
        foreach v_school_id in array v_school_ids loop
            if v_school_id is not null then
                insert into public.coordinator_schools (coordinator_profile_id, school_id)
                values (new.id, v_school_id)
                on conflict (coordinator_profile_id, school_id) do nothing;
            end if;
        end loop;
    end if;

    return new;
end;
$$;

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
begin
    select
        school.id,
        faculty.id,
        school.subcoordinator_profile_id
    into v_school_id, v_faculty_id, v_subcoordinator_id
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

    return new;
end;
$$;

create or replace function public.set_exoneration_staff_on_insert()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    v_school_id bigint;
    v_faculty_id bigint;
    v_coordinator_id uuid;
begin
    select
        school.id,
        faculty.id
    into v_school_id, v_faculty_id
    from public.students as student
    join public.schools as school on school.id = student.school_id
    join public.faculties as faculty on faculty.id = school.faculty_id
    where student.profile_id = new.student_profile_id
    limit 1;

    if not found then
        raise exception
            'Exoneration creation failed. No student found for profile_id %',
            new.student_profile_id
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
            'Exoneration creation failed. Faculty has no coordinator assigned for student profile_id %',
            new.student_profile_id
            using errcode = 'P0001';
    end if;

    new.coordinator_profile_id := v_coordinator_id;

    return new;
end;
$$;

create or replace function public.update_project_and_exoneration_coordinator()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    update public.projects p
    set coordinator_profile_id = new.coordinator_profile_id
    from public.students s
    where p.student_profile_id = s.profile_id
      and s.school_id = new.school_id;

    update public.exonerations ex
    set coordinator_profile_id = new.coordinator_profile_id
    from public.students s
    where ex.student_profile_id = s.profile_id
      and s.school_id = new.school_id;
      
    return null;
end;
$$;

drop trigger if exists trg_update_coordinator_on_school_change on public.coordinator_schools;

create trigger trg_update_coordinator_on_school_change
after insert or update
on public.coordinator_schools
for each row
execute procedure public.update_project_and_exoneration_coordinator();

create or replace function public.update_project_subcoordinator()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    update public.projects p
    set subcoordinator_profile_id = new.subcoordinator_profile_id
    from public.students s
    where p.student_profile_id = s.profile_id
      and s.school_id = new.id;
    return null;
end;
$$;

create or replace trigger trg_update_subcoordinator_on_school_change
after update of subcoordinator_profile_id
on public.schools
for each row
execute procedure public.update_project_subcoordinator();
