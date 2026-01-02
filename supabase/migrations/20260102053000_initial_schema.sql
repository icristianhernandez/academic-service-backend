create extension if not exists "pgcrypto";

create type public.app_role as enum (
  'rectoria',
  'vicerrectorado',
  'planeamiento',
  'decano',
  'director_escuela',
  'coordinador',
  'tutor',
  'student'
);

create table public.faculties (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid not null references public.faculties(id),
  name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (faculty_id, name)
);

create table public.user_profiles (
  user_id uuid primary key references auth.users(id),
  full_name text not null,
  role public.app_role not null default 'student',
  faculty_id uuid references public.faculties(id),
  school_id uuid references public.schools(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (school_id is null or faculty_id is not null)
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id),
  first_name text not null,
  last_name text not null,
  ci text not null unique,
  email text not null unique,
  contacts text[] not null default '{}',
  faculty_id uuid not null references public.faculties(id),
  school_id uuid not null references public.schools(id),
  semester smallint not null check (semester between 1 and 12),
  shift text not null,
  section text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (coalesce(array_length(contacts, 1), 0) <= 2),
  check (
    school_id in (
      select id from public.schools where faculty_id = students.faculty_id
    )
  )
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  coordinator_id uuid not null references public.user_profiles(user_id),
  tutor_id uuid not null references public.user_profiles(user_id),
  name text not null,
  general_objective text not null,
  specific_objectives text[] not null default '{}',
  justification text,
  introduction text,
  summary text,
  institution text not null,
  start_date date not null,
  end_date date,
  preproject_approved boolean not null default false,
  preproject_approved_at date,
  project_received boolean not null default false,
  project_received_at date,
  final_approved boolean not null default false,
  final_approved_at date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (coalesce(array_length(specific_objectives, 1), 0) <= 4),
  check (end_date is null or start_date <= end_date),
  check (not preproject_approved or preproject_approved_at is not null),
  check (not project_received or project_received_at is not null),
  check (not final_approved or final_approved_at is not null),
  check (
    coordinator_id in (
      select user_id from public.user_profiles where role = 'coordinador'
    )
  ),
  check (
    tutor_id in (
      select user_id from public.user_profiles where role = 'tutor'
    )
  ),
  check (
    preproject_approved_at is null
    or project_received_at is null
    or preproject_approved_at <= project_received_at
  ),
  check (
    project_received_at is null
    or final_approved_at is null
    or project_received_at <= final_approved_at
  )
);

create table public.audit_log (
  id bigserial primary key,
  table_name text not null,
  record_id text not null,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  performed_by uuid,
  created_at timestamptz not null default timezone('utc', now())
);

create index audit_log_table_name_idx on public.audit_log(table_name);
create index schools_faculty_id_idx on public.schools(faculty_id, id);
create index user_profiles_role_user_idx on public.user_profiles(role, user_id);

create or replace function public.get_claim_text(claim text)
returns text
language sql
stable
as $$
select coalesce(
  nullif(auth.jwt() ->> claim, ''),
  nullif(current_setting('request.jwt.claims', true)::json ->> claim, '')
);
$$;

create or replace function public.current_app_role()
returns text
language sql
stable
as $$
select coalesce(
  public.get_claim_text('app_role'),
  (select role::text from public.user_profiles where user_id = auth.uid())
);
$$;

create or replace function public.staff_roles()
returns text[]
language sql
stable
as $$
select array['rectoria', 'vicerrectorado', 'planeamiento', 'decano', 'director_escuela', 'coordinador'];
$$;

create or replace function public.has_role(role_list text[])
returns boolean
language sql
stable
as $$
select coalesce(public.current_app_role() = any(role_list), false);
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.prevent_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Deletes are not allowed on table %', tg_table_name;
end;
$$;

create or replace function public.handle_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rec_id text;
begin
  rec_id := coalesce(
    to_jsonb(new)->>'id',
    to_jsonb(old)->>'id',
    to_jsonb(new)->>'user_id',
    to_jsonb(old)->>'user_id',
    'UNKNOWN'
  );

  insert into public.audit_log(table_name, record_id, action, old_data, new_data, performed_by)
  values (tg_table_name, rec_id, tg_op, to_jsonb(old), to_jsonb(new), auth.uid());

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

create trigger set_faculties_updated_at before update on public.faculties for each row execute function public.set_updated_at();
create trigger set_schools_updated_at before update on public.schools for each row execute function public.set_updated_at();
create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute function public.set_updated_at();
create trigger set_students_updated_at before update on public.students for each row execute function public.set_updated_at();
create trigger set_projects_updated_at before update on public.projects for each row execute function public.set_updated_at();

create trigger prevent_faculties_delete before delete on public.faculties for each row execute function public.prevent_delete();
create trigger prevent_schools_delete before delete on public.schools for each row execute function public.prevent_delete();
create trigger prevent_user_profiles_delete before delete on public.user_profiles for each row execute function public.prevent_delete();
create trigger prevent_students_delete before delete on public.students for each row execute function public.prevent_delete();
create trigger prevent_projects_delete before delete on public.projects for each row execute function public.prevent_delete();
create trigger prevent_audit_log_delete before delete on public.audit_log for each row execute function public.prevent_delete();

create trigger audit_faculties after insert or update on public.faculties for each row execute function public.handle_audit();
create trigger audit_schools after insert or update on public.schools for each row execute function public.handle_audit();
create trigger audit_user_profiles after insert or update on public.user_profiles for each row execute function public.handle_audit();
create trigger audit_students after insert or update on public.students for each row execute function public.handle_audit();
create trigger audit_projects after insert or update on public.projects for each row execute function public.handle_audit();

alter table public.faculties enable row level security;
alter table public.schools enable row level security;
alter table public.user_profiles enable row level security;
alter table public.students enable row level security;
alter table public.projects enable row level security;
alter table public.audit_log enable row level security;

create policy faculties_select on public.faculties
for select
using (public.has_role(public.staff_roles()) or public.has_role(array['student']));

create policy faculties_insert on public.faculties
for insert
with check (public.has_role(public.staff_roles()));

create policy faculties_update on public.faculties
for update
using (public.has_role(public.staff_roles()))
with check (public.has_role(public.staff_roles()));

create policy faculties_no_delete on public.faculties
for delete
using (false);

create policy schools_select on public.schools
for select
using (public.has_role(public.staff_roles()) or public.has_role(array['student']));

create policy schools_insert on public.schools
for insert
with check (public.has_role(public.staff_roles()));

create policy schools_update on public.schools
for update
using (public.has_role(public.staff_roles()))
with check (public.has_role(public.staff_roles()));

create policy schools_no_delete on public.schools
for delete
using (false);

create policy user_profiles_select on public.user_profiles
for select
using (auth.uid() = user_id or public.has_role(public.staff_roles()));

create policy user_profiles_insert on public.user_profiles
for insert
with check (public.has_role(public.staff_roles()));

create policy user_profiles_update on public.user_profiles
for update
using (auth.uid() = user_id or public.has_role(public.staff_roles()))
with check (auth.uid() = user_id or public.has_role(public.staff_roles()));

create policy user_profiles_no_delete on public.user_profiles
for delete
using (false);

create policy students_select on public.students
for select
using (public.has_role(public.staff_roles()) or auth.uid() = user_id);

create policy students_insert on public.students
for insert
with check (public.has_role(public.staff_roles()) or auth.uid() = user_id);

create policy students_update on public.students
for update
using (public.has_role(public.staff_roles()) or auth.uid() = user_id)
with check (public.has_role(public.staff_roles()) or auth.uid() = user_id);

create policy students_no_delete on public.students
for delete
using (false);

create policy projects_select on public.projects
for select
using (
  public.has_role(public.staff_roles())
  or exists (
    select 1 from public.students s
    where s.id = public.projects.student_id
    and s.user_id = auth.uid()
  )
);

create policy projects_insert on public.projects
for insert
with check (
  public.has_role(public.staff_roles())
  or exists (
    select 1 from public.students s
    where s.id = public.projects.student_id
    and s.user_id = auth.uid()
  )
);

create policy projects_update on public.projects
for update
using (
  public.has_role(public.staff_roles())
  or exists (
    select 1 from public.students s
    where s.id = public.projects.student_id
    and s.user_id = auth.uid()
  )
)
with check (
  public.has_role(public.staff_roles())
  or exists (
    select 1 from public.students s
    where s.id = public.projects.student_id
    and s.user_id = auth.uid()
  )
);

create policy projects_no_delete on public.projects
for delete
using (false);

create policy audit_log_select on public.audit_log
for select
using (public.has_role(public.staff_roles()));

create policy audit_log_insert on public.audit_log
for insert
with check (true);

create policy audit_log_no_update on public.audit_log
for update
using (false);

create policy audit_log_no_delete on public.audit_log
for delete
using (false);
