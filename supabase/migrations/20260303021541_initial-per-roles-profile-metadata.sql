create type semester_enum as
enum ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10');

create type section_enum as enum ('A', 'B', 'C', 'D', 'E', 'F');

create type shift_enum as enum ('MORNING', 'EVENING');

create table students (
    like audit_meta including all,
    id bigint generated always as identity primary key,
    profile_id uuid not null references profiles (id),
    school_id bigint not null references schools (id),
    semester semester_enum,
    shift shift_enum,
    section section_enum
);

call setup_audit(
    'students'
);
