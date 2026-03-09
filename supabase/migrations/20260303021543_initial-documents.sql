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

insert into storage.buckets (id, name, public)
values ('guides', 'guides', true);

insert into storage.buckets (id, name, public)
values ('pfps', 'pfps', true);

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

create policy guides_documents_read
on storage.objects
for select
to authenticated
using (bucket_id = 'guides');

create policy guides_documents_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'guides');

create policy guides_documents_update
on storage.objects
for update
to authenticated
using (bucket_id = 'guides')
with check (bucket_id = 'guides');

create policy guides_documents_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'guides');

create policy pfps_documents_read
on storage.objects
for select
to authenticated
using (bucket_id = 'pfps');

create policy pfps_documents_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'pfps');

create policy pfps_documents_update
on storage.objects
for update
to authenticated
using (bucket_id = 'pfps')
with check (bucket_id = 'pfps');

create policy pfps_documents_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'pfps');

call setup_audit(
    'documents'
);
