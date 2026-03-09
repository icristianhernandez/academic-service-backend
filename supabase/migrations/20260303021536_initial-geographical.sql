create table countries (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    country_name text not null unique
);

create table states (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    country_id bigint not null references countries (id),
    state_name text not null unique
);

create table cities (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    state_id bigint not null references states (id),
    city_name text not null unique
);

create table locations (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    city_id bigint not null references cities (id),
    address text not null
);

call setup_audit(
    'countries',
    'states',
    'cities',
    'locations'
);
