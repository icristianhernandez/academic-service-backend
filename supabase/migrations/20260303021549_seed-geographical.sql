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

insert into countries (country_name)
values ('Venezuela')
on conflict (country_name) do nothing;

insert into states (country_id, state_name)
select
    countries.id as country_id,
    'Distrito Capital' as state_name
from countries
where countries.country_name = 'Venezuela'
on conflict (state_name) do update
    set country_id = excluded.country_id;

insert into cities (state_id, city_name)
select
    states.id as state_id,
    'Caracas' as city_name
from states
where states.state_name = 'Distrito Capital'
on conflict (city_name) do update
    set state_id = excluded.state_id;

insert into locations (city_id, address)
select
    cities.id as city_id,
    location_seed.address
from cities
cross join (
    values (
        'La Florencia - Caracas. Km. 3 de la carretera '
        || 'Petare-Santa Lucia, Distrito Capital.'
    )
) as location_seed (address)
where
    cities.city_name = 'Caracas'
    and not exists (
        select 1
        from locations
        where
            locations.city_id = cities.id
            and locations.address = location_seed.address
    );
