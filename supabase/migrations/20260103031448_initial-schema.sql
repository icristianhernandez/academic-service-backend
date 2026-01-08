CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE audit_meta (
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    created_by uuid,
    updated_by uuid
);

CREATE TABLE countries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE states (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id uuid NOT NULL REFERENCES countries (id),
    state_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE cities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id uuid NOT NULL REFERENCES states (id),
    city_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE locations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    city_id uuid NOT NULL REFERENCES cities (id),
    address text NOT NULL
) INHERITS (audit_meta);

CREATE TABLE campuses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    campus_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE faculties (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id uuid NOT NULL REFERENCES campuses (id),
    faculty_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE schools (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id uuid NOT NULL REFERENCES faculties (id),
    school_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name text NOT NULL UNIQUE,
    permission_level integer NOT NULL
) INHERITS (audit_meta);

CREATE TABLE semesters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semester_name varchar(12) NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE shifts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_name varchar(12) NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE sections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    section_name varchar(12) NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE users (
    id uuid PRIMARY KEY,
    first_name varchar(20) NOT NULL,
    last_name varchar(20) NOT NULL,
    national_id varchar(12) NOT NULL UNIQUE,
    email varchar(50) NOT NULL UNIQUE,
    primary_contact text NOT NULL,
    secondary_contact text,
    role_id uuid REFERENCES roles (id),
    school_id uuid REFERENCES schools (id),
    semester_id uuid REFERENCES semesters (id),
    shift_id uuid REFERENCES shifts (id),
    section_id uuid REFERENCES sections (id)
) INHERITS (audit_meta);

CREATE TABLE institutions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    contact_person_id uuid REFERENCES users (id),
    institution_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id uuid REFERENCES users (id),
    coordinator_id uuid REFERENCES users (id),
    student_id uuid REFERENCES users (id),
    institution_id uuid REFERENCES institutions (id),
    title text NOT NULL,
    general_objective text NOT NULL,
    specific_objective_1 text,
    specific_objective_2 text,
    specific_objective_3 text,
    specific_objective_4 text,
    justification text,
    introduction text,
    abstract text
) INHERITS (audit_meta);

CREATE TABLE documents (
    -- that can have a display name, and size, type metadata, but I'm unsure
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_path text NOT NULL UNIQUE,
    uploaded_by uuid REFERENCES users (id) ON DELETE CASCADE NOT NULL
) INHERITS (audit_meta);

-- I need to think better about the following table workflow/names...
CREATE TABLE stages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    stage_name text NOT NULL UNIQUE
) INHERITS (audit_meta);

CREATE TABLE project_stages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid REFERENCES projects (id) ON DELETE CASCADE NOT NULL,
    stage_id uuid REFERENCES stages (id) NOT NULL,
    document_id uuid REFERENCES documents (id),
    observations text,
    reached_at timestamptz DEFAULT now() NOT NULL
) INHERITS (audit_meta);

CREATE TABLE invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invited_by uuid REFERENCES users (id),
    email text NOT NULL UNIQUE,
    role_id uuid REFERENCES roles (id),
    token text NOT NULL,
    is_active boolean DEFAULT true
) INHERITS (audit_meta);

CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name text NOT NULL,
    operation_type text NOT NULL,
    record_id uuid,
    old_values jsonb,
    new_values jsonb
) INHERITS (audit_meta);

