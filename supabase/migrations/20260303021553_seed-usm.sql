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
values
('Ingenieria de Sistemas'),
('Arquitectura'),
('Ingenieria Industrial'),
('Ingenieria Civil'),
('Ingenieria en Telecomunicaciones'),
('Derecho'),
('Estudios Internacionales'),
('Comunicacion Social'),
('Administracion'),
('Economia'),
('Contaduria Publica'),
('Odontologia'),
('Farmacia')
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
    faculty_data.faculty_name,
    faculty_data.reports_required_count,
    null as dean_profile_id,
    null as coordinator_profile_id
from (
    values
    ('Facultad de Ingenieria', 3::smallint),
    ('Facultad de Derecho', 1::smallint),
    ('Facultad de Ciencias Economicas y Sociales', 0::smallint),
    ('Facultad de Odontologia', 3::smallint),
    ('Facultad de Farmacia', 3::smallint)
) as faculty_data (faculty_name, reports_required_count)
cross join campuses as campus
where campus.campus_name = 'Universidad Santa Maria - La Florencia'
on conflict (faculty_name) do update
    set
        campus_id = excluded.campus_id,
        reports_required_count = excluded.reports_required_count,
        dean_profile_id = excluded.dean_profile_id,
        coordinator_profile_id = excluded.coordinator_profile_id;

insert into schools (degree_id, faculty_id, tutor_profile_id)
select
    d.id as degree_id,
    f.id as faculty_id,
    null as tutor_profile_id
from (
    values
    ('Ingenieria de Sistemas', 'Facultad de Ingenieria'),
    ('Arquitectura', 'Facultad de Ingenieria'),
    ('Ingenieria Industrial', 'Facultad de Ingenieria'),
    ('Ingenieria Civil', 'Facultad de Ingenieria'),
    ('Ingenieria en Telecomunicaciones', 'Facultad de Ingenieria'),
    ('Derecho', 'Facultad de Derecho'),
    ('Estudios Internacionales', 'Facultad de Derecho'),
    ('Comunicacion Social', 'Facultad de Ciencias Economicas y Sociales'),
    ('Administracion', 'Facultad de Ciencias Economicas y Sociales'),
    ('Economia', 'Facultad de Ciencias Economicas y Sociales'),
    ('Contaduria Publica', 'Facultad de Ciencias Economicas y Sociales'),
    ('Odontologia', 'Facultad de Odontologia'),
    ('Farmacia', 'Facultad de Farmacia')
) as school_data (degree_name, faculty_name)
inner join degrees as d on school_data.degree_name = d.degree_name
inner join faculties as f on school_data.faculty_name = f.faculty_name
where not exists (
    select 1
    from schools as s
    where
        s.degree_id = d.id
        and s.faculty_id = f.id
        and s.tutor_profile_id is null
);
