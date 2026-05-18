create unique index idx_projects_unique_title
on projects (lower(trim(title)));

create function public.a_validate_project_document_pdf()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    if new.bucket_id = 'project' and new.storage_path !~* '\.pdf$' then
        raise exception 'Solo se aceptan archivos PDF para entregas de proyectos'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

create trigger a_validate_project_document_pdf
before insert on documents
for each row
execute procedure public.a_validate_project_document_pdf();
