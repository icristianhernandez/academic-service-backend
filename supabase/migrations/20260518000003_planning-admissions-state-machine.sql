create or replace function public.validate_project_progress_phase_transition()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
    reports_required_count smallint;
    new_phase public.project_phases;
    previous_progress public.project_progress;
    previous_phase public.project_phases;
    previous_state_name text;
    new_state_name text;
    is_valid_transition boolean := false;
begin
    select
        project_row.reports_required_count
    into reports_required_count
    from public.projects as project_row
    where project_row.id = new.project_id
    limit 1;

    if not found then
        raise exception 'Project progress validation failed. No faculty found for project_id %', new.project_id using errcode = 'P0001';
    end if;

    select phase_row.*
    into new_phase
    from public.project_phases as phase_row
    where phase_row.id = new.project_phase_id
    limit 1;

    if not found then
        raise exception 'Project progress validation failed. No project phase found for project_phase_id %', new.project_phase_id using errcode = 'P0001';
    end if;

    if new_phase.phase_kind = 'report' and new_phase.report_number > reports_required_count then
        raise exception 'Project progress validation failed. Faculty supports % reports, received report %', reports_required_count, new_phase.report_number using errcode = 'P0001';
    end if;

    select project_state_name into new_state_name
    from public.project_states
    where id = new.project_state_id;

    if TG_OP = 'INSERT' then
        if new_phase.phase_kind <> 'planning' and new.document_id is null then
            raise exception 'Project progress validation failed. Document ID is required for academic phases' using errcode = 'P0001';
        end if;

        if new_phase.phase_kind = 'planning' and new_state_name <> 'Consignado a Planeamiento y Admisión' then
            raise exception 'Project progress validation failed. Planning phase must start in Consignado a Planeamiento y Admisión' using errcode = 'P0001';
        end if;

        if new_phase.phase_kind <> 'planning' and new_state_name <> 'En revisión' then
            raise exception 'Project progress validation failed. Academic phase must start in En revisión' using errcode = 'P0001';
        end if;

        select progress_row.*
        into previous_progress
        from public.project_progress as progress_row
        where progress_row.project_id = new.project_id
        order by progress_row.created_at desc, progress_row.id desc
        limit 1;

        if previous_progress.id is null then
            if new_phase.phase_kind <> 'preproject' then
                raise exception 'Project progress validation failed. First phase must be Preproyecto' using errcode = 'P0001';
            end if;
            return new;
        end if;

        select phase_row.*
        into previous_phase
        from public.project_phases as phase_row
        where phase_row.id = previous_progress.project_phase_id
        limit 1;

        select project_state_name into previous_state_name
        from public.project_states
        where id = previous_progress.project_state_id
        limit 1;

        if new_phase.project_phase_order < previous_phase.project_phase_order then
            raise exception 'Project progress validation failed. Phase cannot move backwards' using errcode = 'P0001';
        end if;

        if new_phase.project_phase_order = previous_phase.project_phase_order then
            if previous_state_name = 'Rechazado para corrección' then
                return new;
            else
                raise exception 'Cannot insert new progress in the same phase unless previous was rejected. Current state: %', previous_state_name using errcode = 'P0001';
            end if;
        end if;

        if previous_state_name <> 'Aprobado por Coordinador' then
            raise exception 'Cannot advance phase because previous phase is not approved. Current state: %', previous_state_name using errcode = 'P0001';
        end if;

        if previous_phase.phase_kind = 'preproject' then
            if reports_required_count = 0 and new_phase.phase_kind = 'final_report' then
                is_valid_transition := true;
            end if;

            if reports_required_count > 0 and new_phase.phase_kind = 'report' and new_phase.report_number = 1 then
                is_valid_transition := true;
            end if;
        end if;

        if previous_phase.phase_kind = 'report' then
            if previous_phase.report_number < reports_required_count and new_phase.phase_kind = 'report' and new_phase.report_number = previous_phase.report_number + 1 then
                is_valid_transition := true;
            end if;

            if previous_phase.report_number = reports_required_count and new_phase.phase_kind = 'final_report' then
                is_valid_transition := true;
            end if;
        end if;

        if previous_phase.phase_kind = 'final_report' and new_phase.phase_kind = 'planning' then
            is_valid_transition := true;
        end if;

        if not is_valid_transition then
            raise exception 'Project progress validation failed. Invalid transition from % to % for faculty report count %', previous_phase.project_phase_name, new_phase.project_phase_name, reports_required_count using errcode = 'P0001';
        end if;

        return new;
    end if;

    if TG_OP = 'UPDATE' then
        if old.project_phase_id <> new.project_phase_id then
            raise exception 'Project progress validation failed. Cannot change phase during update' using errcode = 'P0001';
        end if;

        if new_phase.phase_kind <> 'planning' and new.document_id is null then
            raise exception 'Project progress validation failed. Document ID is required for academic phases' using errcode = 'P0001';
        end if;

        select project_state_name into previous_state_name
        from public.project_states
        where id = old.project_state_id;

        if previous_state_name = 'En revisión' then
            if new_state_name not in ('Aprobado por Subcoordinador', 'Aprobado por Coordinador', 'Rechazado para corrección') then
                raise exception 'Invalid state transition from En revisión to %', new_state_name;
            end if;
        elsif previous_state_name = 'Aprobado por Subcoordinador' then
            if new_state_name not in ('Aprobado por Coordinador', 'Rechazado para corrección') then
                raise exception 'Invalid state transition from Aprobado por Subcoordinador to %', new_state_name;
            end if;
        elsif previous_state_name = 'Consignado a Planeamiento y Admisión' then
            if new_state_name not in ('Aprobado por Planeamiento y Admisión', 'Rechazado para corrección') then
                raise exception 'Invalid state transition from Consignado a Planeamiento y Admisión to %', new_state_name;
            end if;
        elsif previous_state_name = 'Rechazado para corrección' then
            if new_state_name <> 'En revisión' then
                raise exception 'Invalid state transition from Rechazado para corrección to %', new_state_name;
            end if;
        elsif previous_state_name = 'Aprobado por Coordinador' then
            if new_state_name <> 'En revisión' then
                raise exception 'Invalid state transition from Aprobado por Coordinador to %', new_state_name;
            end if;
        elsif previous_state_name = 'Aprobado por Planeamiento y Admisión' then
            if new_state_name <> 'En revisión' then
                raise exception 'Invalid state transition from Aprobado por Planeamiento y Admisión to %', new_state_name;
            end if;
        end if;

        return new;
    end if;

    return new;
end;
$$;
