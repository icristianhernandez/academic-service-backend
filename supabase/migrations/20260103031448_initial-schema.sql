CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS plpgsql_check;

CREATE TABLE audit_meta (
    created_at timestamptz DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid()
);

CREATE OR REPLACE FUNCTION handle_audit_update()
RETURNS trigger
AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TABLE countries (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_name text NOT NULL UNIQUE
);


CREATE TABLE states (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id uuid NOT NULL REFERENCES countries (id),
    state_name text NOT NULL UNIQUE
);


CREATE TABLE cities (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id uuid NOT NULL REFERENCES states (id),
    city_name text NOT NULL UNIQUE
);


CREATE TABLE locations (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    city_id uuid NOT NULL REFERENCES cities (id),
    address text NOT NULL
);


CREATE TABLE campuses (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    campus_name text NOT NULL UNIQUE
);

CREATE TABLE faculties (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id uuid NOT NULL REFERENCES campuses (id),
    faculty_name text NOT NULL UNIQUE
);

CREATE TABLE schools (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id uuid NOT NULL REFERENCES faculties (id),
    school_name text NOT NULL UNIQUE
);

CREATE TABLE roles (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name text NOT NULL UNIQUE,
    permission_level integer NOT NULL
);

CREATE TABLE semesters (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semester_name varchar(12) NOT NULL UNIQUE
);

CREATE TABLE shifts (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_name varchar(12) NOT NULL UNIQUE
);

CREATE TABLE sections (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    section_name varchar(12) NOT NULL UNIQUE
);

CREATE TABLE users (
    LIKE audit_meta INCLUDING ALL,
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
);

CREATE TABLE institutions (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    contact_person_id uuid REFERENCES users (id),
    institution_name text NOT NULL UNIQUE
);

CREATE TABLE projects (
    LIKE audit_meta INCLUDING ALL,
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
);

CREATE TABLE documents (
    LIKE audit_meta INCLUDING ALL,
    -- that can have a display name, and size, type metadata, but I'm unsure
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_path text NOT NULL UNIQUE,
    uploaded_by uuid REFERENCES users (id) ON DELETE CASCADE NOT NULL
);

-- I need to think better about the following table workflow/names...
CREATE TABLE stages (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    stage_name text NOT NULL UNIQUE
);

CREATE TABLE project_stages (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid REFERENCES projects (id) ON DELETE CASCADE NOT NULL,
    stage_id uuid REFERENCES stages (id) NOT NULL,
    document_id uuid REFERENCES documents (id),
    observations text,
    reached_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE invitations (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invited_by uuid REFERENCES users (id),
    email text NOT NULL UNIQUE,
    role_id uuid REFERENCES roles (id),
    token text NOT NULL,
    is_active boolean DEFAULT true
);

CREATE TABLE audit_logs (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name text NOT NULL,
    operation_type text NOT NULL,
    record_id uuid,
    old_values jsonb,
    new_values jsonb
);

CREATE OR REPLACE FUNCTION enable_audit_tracking(
    VARIADIC target_table_names text []
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    current_table_name text;
    dynamic_trigger_name text;
    trigger_definition_sql text;
BEGIN
    FOREACH current_table_name IN ARRAY target_table_names
    LOOP
        dynamic_trigger_name := format('trg_audit_update_%s', current_table_name);

        trigger_definition_sql := format(
            'CREATE OR REPLACE TRIGGER %I
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION handle_audit_update()',
            dynamic_trigger_name,
            current_table_name
        );

        EXECUTE trigger_definition_sql;
    END LOOP;
END;
$$;

SELECT enable_audit_tracking(
    'countries',
    'states',
    'cities',
    'locations',
    'campuses',
    'faculties',
    'schools',
    'roles',
    'semesters',
    'shifts',
    'sections',
    'users',
    'institutions',
    'projects',
    'documents',
    'stages',
    'project_stages',
    'invitations',
    'audit_logs'
);
