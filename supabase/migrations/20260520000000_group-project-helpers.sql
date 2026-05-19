-- Migration: Helper functions for group/couple project validation and limits
-- Created at: 2026-05-20T00:00:00Z

create or replace function public.find_student_by_national_id(p_national_id text)
returns table (
  profile_id uuid,
  full_name text,
  school_name text,
  already_in_project boolean
)
language plpgsql
security definer set search_path = ''
as $$
declare
  v_profile_id uuid;
  v_names text;
  v_last_names text;
  v_school_name text;
  v_already boolean;
begin
  -- Find the profile & check if student
  select p.id, p.user_names, p.user_last_names, d.degree_name
  into v_profile_id, v_names, v_last_names, v_school_name
  from public.profiles p
  join public.students s on s.profile_id = p.id
  join public.schools sch on sch.id = s.school_id
  join public.degrees d on d.id = sch.degree_id
  where lower(replace(p.national_id, ' ', '')) = lower(replace(p_national_id, ' ', ''))
  limit 1;

  if v_profile_id is null then
    return;
  end if;

  -- Check if already in any project
  select exists (
    select 1 from public.project_members pm
    where pm.profile_id = v_profile_id
  ) or exists (
    select 1 from public.projects pr
    where pr.student_profile_id = v_profile_id
  ) into v_already;

  profile_id := v_profile_id;
  full_name := trim(coalesce(v_names, '') || ' ' || coalesce(v_last_names, ''));
  school_name := v_school_name;
  already_in_project := v_already;
  return next;
end;
$$;

create or replace function public.get_student_faculty_member_limits(p_profile_id uuid)
returns table (
  min_members smallint,
  max_members smallint
)
language plpgsql
security definer set search_path = ''
as $$
begin
  return query
  select f.min_members, f.max_members
  from public.students s
  join public.schools sch on sch.id = s.school_id
  join public.faculties f on f.id = sch.faculty_id
  where s.profile_id = p_profile_id
  limit 1;
end;
$$;
