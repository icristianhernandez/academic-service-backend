create table campuses (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    location_id bigint not null references locations (id),
    campus_name text not null unique,
    rector_profile_id uuid references profiles (id),
    vicerector_administrativo_profile_id uuid references profiles (id),
    vicerector_academico_profile_id uuid references profiles (id)
);

create table faculties (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    campus_id bigint not null references campuses (id),
    faculty_name text not null unique,
    reports_required_count smallint not null default 3,
    min_members smallint not null default 1,
    max_members smallint not null default 1,
    dean_profile_id uuid references profiles (id),
    coordinator_profile_id uuid references profiles (id),

    check (reports_required_count between 0 and 10),
    check (min_members between 1 and 20),
    check (max_members between 1 and 20),
    check (min_members <= max_members)
);

create table degrees (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    degree_name text not null unique
);

create table schools (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    degree_id bigint not null references degrees (id),
    faculty_id bigint not null references faculties (id),
    subcoordinator_profile_id uuid references profiles (id),
    unique (degree_id, faculty_id)
);

call setup_audit(
    'campuses',
    'faculties',
    'degrees',
    'schools'
);
