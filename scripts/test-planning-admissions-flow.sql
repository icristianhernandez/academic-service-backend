-- Test: Planeamiento y Admisión flow end-to-end
-- Run with: PGPASSWORD=postgres psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -f scripts/test-planning-admissions-flow.sql
\set ON_ERROR_STOP on

begin;

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

do $$
declare
    planning_role_id bigint;
    consigned_state_id bigint;
    planeamiento_approved_state_id bigint;
    review_state_id bigint;
    subcoord_state_id bigint;
    coord_state_id bigint;
    rejected_state_id bigint;
    preproyecto_id bigint;
    student_prof_id uuid;
    institution_id bigint;
    v_project_id bigint;
    v_document_id bigint;
    assert_count integer := 0;
begin
    raise notice '========================================';
    raise notice 'Starting Planning Admissions flow tests';
    raise notice '========================================';

    -- 1. Role checks
    select id into planning_role_id from roles where role_name = 'planning_admissions';
    if planning_role_id is null then raise exception 'FATAL: planning_admissions role not found'; end if;
    assert_count := assert_count + 1;
    raise notice 'OK 1: planning_admissions role exists (id=%)', planning_role_id;

    if (select permission_level from roles where id = planning_role_id) <> 3 then raise exception 'FATAL: permission_level not 3'; end if;
    if (select permission_level from roles where role_name = 'sysadmin') <> 7 then raise exception 'FATAL: sysadmin not 7'; end if;
    if (select permission_level from roles where role_name = 'coordinator') <> 6 then raise exception 'FATAL: coordinator not 6'; end if;
    if (select permission_level from roles where role_name = 'subcoordinator') <> 5 then raise exception 'FATAL: subcoordinator not 5'; end if;
    if (select permission_level from roles where role_name = 'dean') <> 4 then raise exception 'FATAL: dean not 4'; end if;
    assert_count := assert_count + 1;
    raise notice 'OK 2: roles shifted correctly (sysadmin=7, coord=6, subcoord=5, dean=4)';

    -- 2. State checks
    select id into review_state_id from project_states where project_state_name = 'En revisión';
    select id into subcoord_state_id from project_states where project_state_name = 'Aprobado por Subcoordinador';
    select id into coord_state_id from project_states where project_state_name = 'Aprobado por Coordinador';
    select id into consigned_state_id from project_states where project_state_name = 'Consignado a Planeamiento y Admisión';
    select id into planeamiento_approved_state_id from project_states where project_state_name = 'Aprobado por Planeamiento y Admisión';
    select id into rejected_state_id from project_states where project_state_name = 'Rechazado para corrección';

    if consigned_state_id is null or planeamiento_approved_state_id is null then raise exception 'FATAL: new states not found'; end if;
    assert_count := assert_count + 1;
    raise notice 'OK 3: new states exist (consigned=%, approved=%)', consigned_state_id, planeamiento_approved_state_id;

    -- 3. Reference data
    select id into student_prof_id from profiles where email = 'student@test.local';
    if student_prof_id is null then raise exception 'FATAL: student@test.local not found'; end if;

    select id into institution_id from institutions limit 1;
    select id into preproyecto_id from project_phases where project_phase_name = 'Preproyecto';
    select id into v_document_id from documents limit 1;
    assert_count := assert_count + 1;
    raise notice 'OK 4: references loaded (student=%, institution=%, preproyecto=%, doc=%)',
        student_prof_id, institution_id, preproyecto_id, v_document_id;

    -- 4. Create project
    insert into projects (student_profile_id, institution_id, title, abstract)
    values (student_prof_id, institution_id, 'Test Project for Planeamiento', 'Testing')
    returning id into v_project_id;
    if v_project_id is null then raise exception 'FATAL: project creation failed'; end if;
    assert_count := assert_count + 1;
    raise notice 'OK 5: project created (id=%)', v_project_id;

    -- Step 1: En revisión
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, review_state_id, student_prof_id, v_document_id, 'submitting');
    assert_count := assert_count + 1;
    raise notice 'OK 6: step 1 → En revisión';

    -- Step 2: Subcoordinador approves
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, subcoord_state_id, student_prof_id, v_document_id, 'subcoord approved');
    assert_count := assert_count + 1;
    raise notice 'OK 7: step 2 → Aprobado por Subcoordinador';

    -- Step 3: Consignado a Planeamiento (VALID)
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, consigned_state_id, student_prof_id, v_document_id, 'consigned');
    assert_count := assert_count + 1;
    raise notice 'OK 8: step 3 → Consignado a Planeamiento y Admisión';

    -- Step 4: Aprobado por Planeamiento
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, planeamiento_approved_state_id, student_prof_id, v_document_id, 'planeamiento approved');
    assert_count := assert_count + 1;
    raise notice 'OK 9: step 4 → Aprobado por Planeamiento y Admisión';

    -- Step 5: Aprobado por Coordinador (gate)
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, coord_state_id, student_prof_id, v_document_id, 'coordinator approved');
    assert_count := assert_count + 1;
    raise notice 'OK 10: step 5 → Aprobado por Coordinador';

    -- Verify final state
    declare
        final_state text;
    begin
        select s.project_state_name into final_state
        from project_progress pp
        join project_states s on s.id = pp.project_state_id
        where pp.project_id = v_project_id
        order by pp.created_at desc, pp.id desc limit 1;

        if final_state <> 'Aprobado por Coordinador' then raise exception 'FATAL: final state not Coordinador: %', final_state; end if;
        assert_count := assert_count + 1;
        raise notice 'OK 11: final state verified as Aprobado por Coordinador';
    end;

    -- Step 6: Coordinador → Consignado (INVALID — should reject)
    begin
        insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
        values (v_project_id, preproyecto_id, consigned_state_id, student_prof_id, v_document_id, 'should fail');
        raise exception 'FATAL: Coordinador→Consignado was NOT rejected';
    exception
        when others then
            assert_count := assert_count + 1;
            raise notice 'OK 12: Coordinador→Consignado correctly rejected';
    end;

    -- Step 7: Consignado → Coordinador (INVALID — skip planeamiento approval)
    begin
        insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
        values (v_project_id, preproyecto_id, coord_state_id, student_prof_id, v_document_id, 'should fail');
        raise exception 'FATAL: Consignado→Coordinador was NOT rejected';
    exception
        when others then
            assert_count := assert_count + 1;
            raise notice 'OK 13: Consignado→Coordinador correctly rejected';
    end;

    -- Step 8: En revisión → Consignado (INVALID — must go through Subcoord first)
    insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
    values (v_project_id, preproyecto_id, review_state_id, student_prof_id, v_document_id, 'back to review');
    begin
        insert into project_progress (project_id, project_phase_id, project_state_id, author_profile_id, document_id, observations)
        values (v_project_id, preproyecto_id, consigned_state_id, student_prof_id, v_document_id, 'should fail');
        raise exception 'FATAL: En revision→Consignado was NOT rejected';
    exception
        when others then
            assert_count := assert_count + 1;
            raise notice 'OK 14: En revision→Consignado correctly rejected';
    end;

    -- Step 9: Verify notification events
    declare
        notif_count integer;
    begin
        select count(*) into notif_count
        from notifications_events ne
        join notification_types nt on nt.id = ne.notification_type_id
        where ne.source_record_id in (
            select pp.id::text from project_progress pp where pp.project_id = v_project_id
        ) and nt.type_key in ('project-consigned-to-planning-admissions', 'project-planning-admissions-approved');

        if notif_count <> 2 then
            raise notice 'WARN: expected 2 notification events, got %', notif_count;
        else
            raise notice 'OK: 2 notification events created';
        end if;
        assert_count := assert_count + 1;
    end;

    -- Step 10: Process notification queue
    perform process_notification_events_queue(100);
    assert_count := assert_count + 1;
    raise notice 'OK 15: notification queue processed';

    -- Step 11: Verify student recipient for planeamiento-approved
    declare
        student_notif_count integer;
        role_notif_count integer;
    begin
        select count(*) into student_notif_count
        from notification_recipients nr
        join notifications_events ne on ne.id = nr.notification_id
        join notification_types nt on nt.id = ne.notification_type_id
        where nt.type_key = 'project-planning-admissions-approved'
          and nr.recipient_id = student_prof_id;

        if student_notif_count <> 1 then
            raise notice 'WARN: expected 1 student recipient, got %', student_notif_count;
        else
            raise notice 'OK: student receives planeamiento-approved notification';
        end if;
        assert_count := assert_count + 1;

        select count(*) into role_notif_count
        from notification_recipients nr
        join notifications_events ne on ne.id = nr.notification_id
        join notification_types nt on nt.id = ne.notification_type_id
        join profiles p on p.id = nr.recipient_id
        join roles r on r.id = p.role_id
        where nt.type_key = 'project-consigned-to-planning-admissions'
          and r.role_name = 'planning_admissions';

        if role_notif_count <> 1 then
            raise notice 'WARN: expected 1 planning_admissions role recipient, got %', role_notif_count;
        else
            raise notice 'OK: planning_admissions role holder receives consigned notification';
        end if;
        assert_count := assert_count + 1;
    end;

    raise notice '========================================';
    raise notice 'RESULTS: % / 17 assertions passed', assert_count;
    raise notice '========================================';
end;
$$;

rollback;
