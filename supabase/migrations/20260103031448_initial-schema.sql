CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS plpgsql_check;

CREATE TYPE semester_enum AS
ENUM ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10');

CREATE TYPE section_enum AS ENUM ('A', 'B', 'C', 'D', 'E', 'F');

CREATE TYPE shift_enum AS ENUM ('MORNING', 'EVENING');

CREATE TABLE audit_meta (
    created_at timestamptz DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid()
);

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

CREATE TABLE roles (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name text NOT NULL UNIQUE,
    permission_level integer NOT NULL
);

CREATE TABLE users (
    LIKE audit_meta INCLUDING ALL,
    id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    first_name varchar(20) NOT NULL,
    last_name varchar(20) NOT NULL,
    national_id varchar(12) NOT NULL UNIQUE,
    email varchar(50) NOT NULL UNIQUE,
    primary_contact text NOT NULL,
    secondary_contact text,
    role_id uuid REFERENCES roles (id)
);

CREATE TABLE campuses (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    campus_name text NOT NULL UNIQUE,
    president_id uuid REFERENCES users (id)
);

CREATE TABLE faculties (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id uuid NOT NULL REFERENCES campuses (id),
    faculty_name text NOT NULL UNIQUE,
    dean_id uuid REFERENCES users (id),
    coordinator_id uuid REFERENCES users (id)
);

CREATE TABLE schools (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id uuid NOT NULL REFERENCES faculties (id),
    school_name text NOT NULL UNIQUE,
    tutor_id uuid REFERENCES users (id)
);

CREATE TABLE students (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES users (id),
    faculty_id uuid REFERENCES faculties (id),
    school_id uuid REFERENCES schools (id),
    semester semester_enum,
    shift shift_enum,
    section section_enum
);

CREATE TABLE institutions (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id uuid REFERENCES locations (id),
    contact_person_id uuid REFERENCES users (id),
    institution_name text NOT NULL UNIQUE
);

CREATE TABLE documents (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket_id text NOT NULL DEFAULT 'project' REFERENCES storage.buckets (id),
    storage_path text NOT NULL,
    uploaded_by uuid REFERENCES users (id) ON DELETE CASCADE NOT NULL,
    UNIQUE (bucket_id, storage_path)
);

INSERT INTO storage.buckets (id, name, public)
VALUES ('project', 'project', TRUE);

CREATE POLICY project_documents_read
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'project');

CREATE POLICY project_documents_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'project');

CREATE POLICY project_documents_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'project')
WITH CHECK (bucket_id = 'project');

CREATE POLICY project_documents_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'project');

CREATE TABLE projects (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id uuid REFERENCES users (id),
    coordinator_id uuid REFERENCES users (id),
    student_id uuid REFERENCES users (id),
    institution_id uuid REFERENCES institutions (id),
    title text NOT NULL,
    abstract text,

    pre_project_document_id uuid REFERENCES documents (id),
    pre_project_observations text,
    pre_project_approved_at timestamptz DEFAULT NULL,

    project_document_id uuid REFERENCES documents (id),
    project_observations text,
    project_received_at timestamptz DEFAULT NULL,

    final_project_approved_at timestamptz
);

CREATE TABLE invitations (
    LIKE audit_meta INCLUDING ALL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invited_by uuid REFERENCES users (id),
    email text NOT NULL UNIQUE,
    role_id uuid REFERENCES roles (id),
    token text NOT NULL,
    is_active boolean DEFAULT TRUE
);

-- https://wiki.postgresql.org/wiki/Audit_trigger
CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name text NOT NULL,
    table_name text NOT NULL,
    operation_name text NOT NULL,
    auth_uid uuid DEFAULT auth.uid(),
    payload jsonb,
    created_at timestamptz DEFAULT now()
);
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
-- all visible and that's a security risk, at least other operations are blocked
CREATE POLICY read_only_audit_logs
ON audit_logs
FOR SELECT
TO authenticated
USING (
    TRUE
);
CREATE INDEX idx_audit_logs_table ON audit_logs (table_name);
CREATE INDEX idx_audit_logs_created ON audit_logs (created_at);

CREATE OR REPLACE FUNCTION handle_audit_update()
RETURNS trigger
AS $$
BEGIN
  NEW := jsonb_populate_record(
    NEW,
    jsonb_build_object(
      'updated_at', now(),
      'updated_by', auth.uid()
    )
  );
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE enable_audit_tracking(
    VARIADIC target_table_names text []
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_table_name text;
    dynamic_trigger_name text;
BEGIN
    FOREACH current_table_name IN ARRAY target_table_names
    LOOP
        dynamic_trigger_name := format('trg_audit_update_%s', current_table_name);

        EXECUTE format(
            'CREATE TRIGGER %I
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION handle_audit_update()',
            dynamic_trigger_name,
            current_table_name
        );
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION log_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, extensions
AS $$
DECLARE
  change_payload jsonb;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    change_payload := jsonb_build_object('old_record', to_jsonb(OLD));
  ELSIF (TG_OP = 'UPDATE') THEN
    change_payload := jsonb_build_object(
      'old_record', to_jsonb(OLD),
      'new_record', to_jsonb(NEW)
    );
  ELSIF (TG_OP = 'INSERT') THEN
    change_payload := jsonb_build_object('new_record', to_jsonb(NEW));
  END IF;

  INSERT INTO public.audit_logs (
    schema_name,
    table_name,
    operation_name,
    auth_uid,
    payload
  ) VALUES (
    TG_TABLE_SCHEMA,
    TG_TABLE_NAME,
    TG_OP,
    auth.uid(),
    change_payload
  );

  RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE attach_audit_triggers(
    VARIADIC table_names text []
)
LANGUAGE plpgsql
AS $$
DECLARE
    t_name text;
    trigger_name text;
BEGIN
    FOREACH t_name IN ARRAY table_names
    LOOP
        trigger_name := format('audit_%s_changes', t_name);

        EXECUTE format('
            CREATE TRIGGER %I
            AFTER INSERT OR UPDATE OR DELETE ON %I
            FOR EACH ROW EXECUTE FUNCTION log_changes();', 
            trigger_name, t_name);
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE setup_audit_triggers(
    VARIADIC table_names text []
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_table_name text;
    audit_trigger_name text;
    log_trigger_name text;
BEGIN
    FOREACH current_table_name IN ARRAY table_names
    LOOP
        audit_trigger_name := format('trg_audit_update_%s', current_table_name);
        log_trigger_name := format('audit_%s_changes', current_table_name);

        EXECUTE format(
            'CREATE TRIGGER %I
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION handle_audit_update()',
            audit_trigger_name,
            current_table_name
        );

        EXECUTE format('
            CREATE TRIGGER %I
            AFTER INSERT OR UPDATE OR DELETE ON %I
            FOR EACH ROW EXECUTE FUNCTION log_changes();', 
            log_trigger_name,
            current_table_name
        );
    END LOOP;
END;
$$;

CALL setup_audit_triggers(
    'countries',
    'states',
    'cities',
    'locations',
    'campuses',
    'faculties',
    'schools',
    'roles',
    'users',
    'students',
    'institutions',
    'projects',
    'documents',
    'invitations'
);
