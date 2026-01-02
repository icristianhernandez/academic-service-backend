-- Migration: service schema and auditing
-- Aligns with 5NF-friendly design for academic service requirements.

-- Lookup tables
create table if not exists public.faculties (
  id bigserial primary key,
  name text not null unique,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.schools (
  id bigserial primary key,
  faculty_id bigint not null references public.faculties(id),
  name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (faculty_id, name),
  unique (id, faculty_id)
);

create table if not exists public.semesters (
  id smallserial primary key,
  term_number smallint not null unique check (term_number > 0),
  label text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.turns (
  id smallserial primary key,
  code text not null unique,
  display_name text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sections (
  id smallserial primary key,
  code text not null unique,
  description text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.milestone_types (
  id smallserial primary key,
  key text not null unique,
  description text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.supervisor_roles (
  id smallserial primary key,
  key text not null unique,
  description text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.access_roles (
  id smallserial primary key,
  role_key text not null unique,
  display_name text not null,
  description text,
  created_at timestamptz not null default timezone('utc', now())
);

-- Core person data
create table if not exists public.people (
  id bigserial primary key,
  last_names text not null,
  first_names text not null,
  national_id text not null unique,
  email text not null unique,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.person_contacts (
  id bigserial primary key,
  person_id bigint not null references public.people(id),
  contact_order smallint not null check (contact_order in (1, 2)),
  phone_number text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (person_id, contact_order)
);

create table if not exists public.service_enrollments (
  id bigserial primary key,
  person_id bigint not null references public.people(id),
  faculty_id bigint not null references public.faculties(id),
  school_id bigint not null references public.schools(id),
  semester_id smallint not null references public.semesters(id),
  turn_id smallint not null references public.turns(id),
  section_id smallint not null references public.sections(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint service_enrollments_school_faculty_fk foreign key (school_id, faculty_id) references public.schools(id, faculty_id),
  unique (person_id)
);

create table if not exists public.institutions (
  id bigserial primary key,
  name text not null unique,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Project data
create table if not exists public.projects (
  id bigserial primary key,
  enrollment_id bigint not null references public.service_enrollments(id),
  institution_id bigint not null references public.institutions(id),
  project_name text not null,
  general_objective text not null,
  justification text,
  introduction text,
  summary text,
  start_date date not null,
  approximate_end_date date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (enrollment_id)
);

create table if not exists public.project_specific_objectives (
  id bigserial primary key,
  project_id bigint not null references public.projects(id),
  seq smallint not null check (seq between 1 and 4),
  objective text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (project_id, seq)
);

create table if not exists public.project_supervisors (
  id bigserial primary key,
  project_id bigint not null references public.projects(id),
  supervisor_role_id smallint not null references public.supervisor_roles(id),
  full_name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (project_id, supervisor_role_id)
);

create table if not exists public.project_milestones (
  id bigserial primary key,
  project_id bigint not null references public.projects(id),
  milestone_type_id smallint not null references public.milestone_types(id),
  approved boolean not null,
  decision_date date not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (project_id, milestone_type_id)
);

-- Access scaffolding
create table if not exists public.user_roles (
  id bigserial primary key,
  user_id uuid not null references auth.users(id),
  access_role_id smallint not null references public.access_roles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, access_role_id)
);

-- Audit log
create table if not exists public.audit_log (
  id bigserial primary key,
  table_name text not null,
  record_id text,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  changed_at timestamptz not null default timezone('utc', now()),
  actor_id uuid,
  old_data jsonb,
  new_data jsonb
);

-- Functions
create or replace function public.set_updated_at() returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

create or replace function public.log_audit() returns trigger as $$
declare
  pk text;
  snapshot jsonb;
begin
  -- Assumes audited tables expose an `id` primary key; update if auditing tables with different PK names.
  snapshot := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  pk := coalesce(snapshot->>'id', '');
  insert into public.audit_log(table_name, record_id, action, actor_id, old_data, new_data)
  values (
    tg_table_name,
    pk,
    tg_op,
    auth.uid(),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$ language plpgsql;

create or replace function public.prevent_delete() returns trigger as $$
begin
  raise exception 'Deletion is not allowed on table %', tg_table_name;
  return null;
end;
$$ language plpgsql;

-- Trigger attachments (update timestamps)
create trigger set_people_updated_at before update on public.people
  for each row execute function public.set_updated_at();
create trigger set_person_contacts_updated_at before update on public.person_contacts
  for each row execute function public.set_updated_at();
create trigger set_service_enrollments_updated_at before update on public.service_enrollments
  for each row execute function public.set_updated_at();
create trigger set_institutions_updated_at before update on public.institutions
  for each row execute function public.set_updated_at();
create trigger set_projects_updated_at before update on public.projects
  for each row execute function public.set_updated_at();
create trigger set_project_specific_objectives_updated_at before update on public.project_specific_objectives
  for each row execute function public.set_updated_at();
create trigger set_project_supervisors_updated_at before update on public.project_supervisors
  for each row execute function public.set_updated_at();
create trigger set_project_milestones_updated_at before update on public.project_milestones
  for each row execute function public.set_updated_at();
create trigger set_user_roles_updated_at before update on public.user_roles
  for each row execute function public.set_updated_at();

-- Trigger attachments (audit)
create trigger audit_people after insert or update on public.people
  for each row execute function public.log_audit();
create trigger audit_person_contacts after insert or update on public.person_contacts
  for each row execute function public.log_audit();
create trigger audit_service_enrollments after insert or update on public.service_enrollments
  for each row execute function public.log_audit();
create trigger audit_institutions after insert or update on public.institutions
  for each row execute function public.log_audit();
create trigger audit_projects after insert or update on public.projects
  for each row execute function public.log_audit();
create trigger audit_project_specific_objectives after insert or update on public.project_specific_objectives
  for each row execute function public.log_audit();
create trigger audit_project_supervisors after insert or update on public.project_supervisors
  for each row execute function public.log_audit();
create trigger audit_project_milestones after insert or update on public.project_milestones
  for each row execute function public.log_audit();
create trigger audit_user_roles after insert or update on public.user_roles
  for each row execute function public.log_audit();

-- Trigger attachments (prevent delete)
create trigger no_delete_people before delete on public.people
  for each row execute function public.prevent_delete();
create trigger no_delete_person_contacts before delete on public.person_contacts
  for each row execute function public.prevent_delete();
create trigger no_delete_service_enrollments before delete on public.service_enrollments
  for each row execute function public.prevent_delete();
create trigger no_delete_institutions before delete on public.institutions
  for each row execute function public.prevent_delete();
create trigger no_delete_projects before delete on public.projects
  for each row execute function public.prevent_delete();
create trigger no_delete_project_specific_objectives before delete on public.project_specific_objectives
  for each row execute function public.prevent_delete();
create trigger no_delete_project_supervisors before delete on public.project_supervisors
  for each row execute function public.prevent_delete();
create trigger no_delete_project_milestones before delete on public.project_milestones
  for each row execute function public.prevent_delete();
create trigger no_delete_user_roles before delete on public.user_roles
  for each row execute function public.prevent_delete();

-- Seed reference data
insert into public.turns (code, display_name) values
  ('morning', 'Morning'),
  ('afternoon', 'Afternoon'),
  ('evening', 'Evening')
on conflict (code) do nothing;

insert into public.sections (code, description) values
  ('A', 'Section A'),
  ('B', 'Section B'),
  ('C', 'Section C')
on conflict (code) do nothing;

insert into public.semesters (term_number, label) values
  (1, 'Semester 1'),
  (2, 'Semester 2'),
  (3, 'Semester 3'),
  (4, 'Semester 4'),
  (5, 'Semester 5'),
  (6, 'Semester 6'),
  (7, 'Semester 7'),
  (8, 'Semester 8'),
  (9, 'Semester 9'),
  (10, 'Semester 10')
on conflict (term_number) do nothing;

insert into public.supervisor_roles (key, description) values
  ('coordinator', 'Academic coordinator'),
  ('tutor', 'Tutor')
on conflict (key) do nothing;

insert into public.milestone_types (key, description) values
  ('anteproyecto_aprobado', 'Anteproyecto aprobado'),
  ('proyecto_recibido', 'Proyecto recibido'),
  ('proyecto_final_aprobado', 'Proyecto final aprobado')
on conflict (key) do nothing;

insert into public.access_roles (role_key, display_name, description) values
  ('rectoria', 'Rectoría', 'Rectoría access'),
  ('vicerrectorado_academico', 'Vicerrectorado Académico', 'Academic vice-rectorate'),
  ('planeamiento_admision', 'Dirección de planeamiento y admisión', 'Planning and admissions'),
  ('direccion_general', 'Dirección', 'General direction'),
  ('decano', 'Decano', 'Faculty dean'),
  ('director_escuela', 'Director de Escuela', 'School director'),
  ('coordinador', 'Coordinador', 'Coordinator')
on conflict (role_key) do nothing;
