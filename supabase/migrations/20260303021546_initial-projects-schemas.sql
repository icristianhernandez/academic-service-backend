create table institutions (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint references locations (id),
    contact_person_profile_id uuid references profiles (id),
    institution_name text not null unique
);

create table documents (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    bucket_id text not null default 'project' references storage.buckets (id),
    storage_path text not null,
    uploaded_by_profile_id uuid references profiles (
        id
    ) on delete cascade not null,
    unique (bucket_id, storage_path)
);

insert into storage.buckets (id, name, public)
values ('project', 'project', true);

create policy project_documents_read
on storage.objects
for select
to authenticated
using (bucket_id = 'project');

create policy project_documents_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'project');

create policy project_documents_update
on storage.objects
for update
to authenticated
using (bucket_id = 'project')
with check (bucket_id = 'project');

create policy project_documents_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'project');

create table project_phases (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_phase_name text not null
);

create table project_states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_state_name text not null
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
    'documents',
    'project_phases',
    'project_states',
    'project_progress',
    'projects'
);
