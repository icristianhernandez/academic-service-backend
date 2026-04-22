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

insert into campuses (location_id, campus_name, president_profile_id)
select
    location_row.id as location_id,
    'Universidad Santa Maria - La Florencia' as campus_name,
    null as president_profile_id
from locations as location_row
where
    location_row.address
    = (
        'La Florencia - Caracas. Km. 3 de la carretera '
        || 'Petare-Santa Lucia, Distrito Capital.'
    )
on conflict (campus_name) do update
    set
        location_id = excluded.location_id,
        president_profile_id = excluded.president_profile_id;

insert into degrees (degree_name)
values ('Ingenieria de Sistemas')
on conflict (degree_name) do nothing;

insert into faculties (
    campus_id,
    faculty_name,
    reports_required_count,
    dean_profile_id,
    coordinator_profile_id
)
select
    campus.id as campus_id,
    'Facultad de Ingenieria' as faculty_name,
    3 as reports_required_count,
    null as dean_profile_id,
    null as coordinator_profile_id
from campuses as campus
where campus.campus_name = 'Universidad Santa Maria - La Florencia'
on conflict (faculty_name) do update
    set
        campus_id = excluded.campus_id,
        reports_required_count = excluded.reports_required_count,
        dean_profile_id = excluded.dean_profile_id,
        coordinator_profile_id = excluded.coordinator_profile_id;

insert into schools (degree_id, faculty_id, tutor_profile_id)
select
    degree.id as degree_id,
    faculty.id as faculty_id,
    null as tutor_profile_id
from degrees as degree
cross join faculties as faculty
where
    degree.degree_name = 'Ingenieria de Sistemas'
    and faculty.faculty_name = 'Facultad de Ingenieria'
    and not exists (
        select 1
        from schools
        where
            schools.degree_id = degree.id
            and schools.faculty_id = faculty.id
            and schools.tutor_profile_id is null
    );
