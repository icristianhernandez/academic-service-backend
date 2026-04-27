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
    c.id as country_id,
    s.state_name
from (
    values
    ('Amazonas'),
    ('Anzoategui'),
    ('Apure'),
    ('Aragua'),
    ('Barinas'),
    ('Bolivar'),
    ('Carabobo'),
    ('Cojedes'),
    ('Delta Amacuro'),
    ('Distrito Capital'),
    ('Falcon'),
    ('Guarico'),
    ('La Guaira'),
    ('Lara'),
    ('Merida'),
    ('Miranda'),
    ('Monagas'),
    ('Nueva Esparta'),
    ('Portuguesa'),
    ('Sucre'),
    ('Tachira'),
    ('Trujillo'),
    ('Yaracuy'),
    ('Zulia')
) as s (state_name)
cross join countries as c
where c.country_name = 'Venezuela'
on conflict (state_name) do update
    set country_id = excluded.country_id;

insert into cities (state_id, city_name)
select
    st.id as state_id,
    c.city_name
from (
    values
    ('Amazonas', 'Puerto Ayacucho'),
    ('Anzoategui', 'Barcelona'),
    ('Anzoategui', 'Puerto La Cruz'),
    ('Anzoategui', 'El Tigre'),
    ('Anzoategui', 'Anaco'),
    ('Anzoategui', 'Lecheria'),
    ('Apure', 'San Fernando de Apure'),
    ('Aragua', 'Maracay'),
    ('Aragua', 'Turmero'),
    ('Aragua', 'Cagua'),
    ('Aragua', 'La Victoria'),
    ('Aragua', 'Palo Negro'),
    ('Aragua', 'El Limon'),
    ('Barinas', 'Barinas'),
    ('Bolivar', 'Ciudad Bolivar'),
    ('Bolivar', 'Ciudad Guayana'),
    ('Bolivar', 'Upata'),
    ('Carabobo', 'Valencia'),
    ('Carabobo', 'Puerto Cabello'),
    ('Carabobo', 'Naguanagua'),
    ('Carabobo', 'San Diego'),
    ('Carabobo', 'Guacara'),
    ('Carabobo', 'Los Guayos'),
    ('Cojedes', 'San Carlos'),
    ('Delta Amacuro', 'Tucupita'),
    ('Distrito Capital', 'Caracas'),
    ('Falcon', 'Coro'),
    ('Falcon', 'Punto Fijo'),
    ('Guarico', 'San Juan de los Morros'),
    ('Guarico', 'Calabozo'),
    ('Guarico', 'Valle de la Pascua'),
    ('Guarico', 'Zaraza'),
    ('La Guaira', 'La Guaira'),
    ('Lara', 'Barquisimeto'),
    ('Lara', 'Cabudare'),
    ('Lara', 'Carora'),
    ('Merida', 'Merida'),
    ('Merida', 'El Vigia'),
    ('Merida', 'Ejido'),
    ('Miranda', 'Los Teques'),
    ('Miranda', 'Petare'),
    ('Miranda', 'Charallave'),
    ('Miranda', 'Guarenas'),
    ('Miranda', 'Guatire'),
    ('Miranda', 'Cua'),
    ('Miranda', 'Ocumare del Tuy'),
    ('Miranda', 'Santa Teresa del Tuy'),
    ('Miranda', 'Carrizal'),
    ('Monagas', 'Maturin'),
    ('Nueva Esparta', 'La Asuncion'),
    ('Nueva Esparta', 'Porlamar'),
    ('Nueva Esparta', 'Pampatar'),
    ('Portuguesa', 'Guanare'),
    ('Portuguesa', 'Acarigua'),
    ('Portuguesa', 'Araure'),
    ('Sucre', 'Cumana'),
    ('Sucre', 'Carupano'),
    ('Tachira', 'San Cristobal'),
    ('Trujillo', 'Trujillo'),
    ('Trujillo', 'Valera'),
    ('Yaracuy', 'San Felipe'),
    ('Zulia', 'Maracaibo'),
    ('Zulia', 'Cabimas'),
    ('Zulia', 'Ciudad Ojeda'),
    ('Zulia', 'Machiques')
) as c (state_name, city_name)
inner join states as st on c.state_name = st.state_name
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
