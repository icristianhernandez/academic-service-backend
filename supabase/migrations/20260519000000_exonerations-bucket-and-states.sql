insert into storage.buckets (id, name, public)
values ('exonerations', 'exonerations', true);

create policy exonerations_documents_read
on storage.objects
for select
to authenticated
using (bucket_id = 'exonerations');

create policy exonerations_documents_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'exonerations');

create policy exonerations_documents_update
on storage.objects
for update
to authenticated
using (bucket_id = 'exonerations')
with check (bucket_id = 'exonerations');

create policy exonerations_documents_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'exonerations');

create or replace function public.a_validate_project_document_pdf()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    if new.bucket_id in ('project', 'exonerations')
        and new.storage_path !~* '\.pdf$' then
        raise exception 'Solo se aceptan archivos PDF para entregas'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

create table exoneration_states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    exoneration_state_name text not null unique
);

select set_config(
    'request.jwt.claims',
    json_build_object(
        'role',
        'authenticated',
        'sub',
        '00000000-0000-0000-0000-000000000001',
        'email',
        'seed-worker@usm.local'
    )::text,
    true
);

insert into public.exoneration_states (exoneration_state_name)
values
('En revisión'),
('Validado por Coordinador'),
('Consignado a Planeamiento y Admisión'),
('Aprobado por Planeamiento y Admisión'),
('Rechazado para corrección')
on conflict (exoneration_state_name) do nothing;

call setup_audit(
    'exoneration_states'
);
