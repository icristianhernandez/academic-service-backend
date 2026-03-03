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

create table projects_states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    project_state_name text not null,
    normal_flow_state boolean not null default true
);

create table projects_states_flow (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    from_state bigint not null references projects_states (id),
    to_state bigint not null references projects_states (id)
);

create table projects (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    tutor_profile_id uuid not null references profiles (id),
    coordinator_profile_id uuid not null references profiles (id),
    student_profile_id uuid not null references profiles (id),
    institution_id bigint not null references institutions (id),
    title text not null,
    abstract text,

    last_normal_state_id bigint not null references projects_states (id),
    current_state_id bigint not null references projects_states (id),
    state_doc_id bigint not null references documents (id),
    state_metadata text
);

call setup_audit(
    'institutions',
    'documents',
    'projects_states',
    'projects_states_flow',
    'projects'
);
