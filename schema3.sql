--
-- PostgreSQL database dump
--

\restrict 2igqnHwOIIGcEMGmzs1WrNB1YWLfu8iS7fspbL0793WucKz4VYje8WY7k6eI5IO

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: section_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.section_enum AS ENUM (
    'A',
    'B',
    'C',
    'D',
    'E',
    'F'
);


--
-- Name: semester_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.semester_enum AS ENUM (
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
);


--
-- Name: shift_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.shift_enum AS ENUM (
    'MORNING',
    'EVENING'
);


--
-- Name: attach_audit_triggers(text[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.attach_audit_triggers(VARIADIC table_names text[])
    LANGUAGE plpgsql
    AS $$
declare
    table_name text;
    trigger_name text;
begin
    foreach table_name in array table_names
    loop
        trigger_name := format('audit_%s_changes', table_name);

        execute format(
            'create trigger %I
             after insert or update or delete on %I
             for each row execute function log_changes();',
            trigger_name,
            table_name
        );
    end loop;
end;
$$;


--
-- Name: enable_audit_tracking(text[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.enable_audit_tracking(VARIADIC target_table_names text[])
    LANGUAGE plpgsql
    AS $$
declare
    current_table_name text;
    dynamic_trigger_name text;
begin
    foreach current_table_name in array target_table_names
    loop
        dynamic_trigger_name := format('trg_audit_update_%s', current_table_name);

        execute format(
            'create trigger %I
             before update on %I
             for each row
             execute function handle_audit_update()',
            dynamic_trigger_name,
            current_table_name
        );
    end loop;
end;
$$;


--
-- Name: handle_audit_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_audit_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    new := jsonb_populate_record(
        new,
        jsonb_build_object(
            'updated_at', now(),
            'updated_by', auth.uid()
        )
    );
    return new;
end;
$$;


--
-- Name: log_changes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_changes() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'extensions'
    AS $$
declare
    change_payload jsonb;
begin
    if tg_op = 'DELETE' then
        change_payload := jsonb_build_object('old_record', to_jsonb(old));
    elsif tg_op = 'UPDATE' then
        change_payload := jsonb_build_object(
            'old_record', to_jsonb(old),
            'new_record', to_jsonb(new)
        );
    elsif tg_op = 'INSERT' then
        change_payload := jsonb_build_object('new_record', to_jsonb(new));
    end if;

    insert into public.audit_logs (
        schema_name,
        table_name,
        operation_name,
        auth_uid,
        payload
    ) values (
        tg_table_schema,
        tg_table_name,
        tg_op,
        auth.uid(),
        change_payload
    );

    return null;
end;
$$;


--
-- Name: setup_audit(text[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.setup_audit(VARIADIC table_names text[])
    LANGUAGE plpgsql
    AS $$
begin
    call enable_audit_tracking(variadic table_names);
    call attach_audit_triggers(variadic table_names);
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    operation_name text NOT NULL,
    auth_uid uuid DEFAULT auth.uid(),
    payload jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_meta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_meta (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid()
);


--
-- Name: campuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campuses (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    location_id bigint NOT NULL,
    campus_name text NOT NULL,
    president_profile_id uuid NOT NULL
);


--
-- Name: campuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.campuses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.campuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cities (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    state_id bigint NOT NULL,
    city_name text NOT NULL
);


--
-- Name: cities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    country_name text NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.countries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    bucket_id text DEFAULT 'project'::text NOT NULL,
    storage_path text NOT NULL,
    uploaded_by_profile_id uuid NOT NULL
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: faculties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faculties (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    campus_id bigint NOT NULL,
    faculty_name text NOT NULL,
    dean_profile_id uuid NOT NULL,
    coordinator_profile_id uuid NOT NULL
);


--
-- Name: faculties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.faculties ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.faculties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: institutions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.institutions (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    location_id bigint,
    contact_person_profile_id uuid,
    institution_name text NOT NULL
);


--
-- Name: institutions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.institutions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.institutions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    invited_by_profile_id uuid,
    email text NOT NULL,
    role_id bigint,
    token text NOT NULL,
    is_active boolean DEFAULT true
);


--
-- Name: invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.invitations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    city_id bigint NOT NULL,
    address text NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.locations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id uuid NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    national_id text NOT NULL,
    email text NOT NULL,
    primary_contact text NOT NULL,
    secondary_contact text,
    role_id bigint
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    tutor_profile_id uuid NOT NULL,
    coordinator_profile_id uuid NOT NULL,
    student_profile_id uuid NOT NULL,
    institution_id bigint NOT NULL,
    title text NOT NULL,
    abstract text,
    pre_project_document_id bigint NOT NULL,
    pre_project_observations text,
    pre_project_approved_at timestamp with time zone,
    project_document_id bigint,
    project_observations text,
    project_received_at timestamp with time zone,
    final_project_approved_at timestamp with time zone
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.projects ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    role_name text NOT NULL,
    permission_level integer NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: schools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schools (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    faculty_id bigint NOT NULL,
    school_name text NOT NULL,
    tutor_profile_id uuid NOT NULL
);


--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.schools ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.states (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    country_id bigint NOT NULL,
    state_name text NOT NULL
);


--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.states ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.students (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT auth.uid() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT auth.uid(),
    id bigint NOT NULL,
    profile_id uuid NOT NULL,
    faculty_id bigint NOT NULL,
    school_id bigint NOT NULL,
    semester public.semester_enum,
    shift public.shift_enum,
    section public.section_enum
);


--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.students ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: campuses campuses_campus_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT campuses_campus_name_key UNIQUE (campus_name);


--
-- Name: campuses campuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT campuses_pkey PRIMARY KEY (id);


--
-- Name: cities cities_city_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_city_name_key UNIQUE (city_name);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);


--
-- Name: countries countries_country_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_country_name_key UNIQUE (country_name);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: documents documents_bucket_id_storage_path_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_bucket_id_storage_path_key UNIQUE (bucket_id, storage_path);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: faculties faculties_faculty_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_faculty_name_key UNIQUE (faculty_name);


--
-- Name: faculties faculties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_pkey PRIMARY KEY (id);


--
-- Name: institutions institutions_institution_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_institution_name_key UNIQUE (institution_name);


--
-- Name: institutions institutions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_email_key UNIQUE (email);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_email_key UNIQUE (email);


--
-- Name: profiles profiles_national_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_national_id_key UNIQUE (national_id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: schools schools_school_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_school_name_key UNIQUE (school_name);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: states states_state_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_state_name_key UNIQUE (state_name);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_table; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_table ON public.audit_logs USING btree (table_name);


--
-- Name: campuses audit_campuses_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_campuses_changes AFTER INSERT OR DELETE OR UPDATE ON public.campuses FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: cities audit_cities_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cities_changes AFTER INSERT OR DELETE OR UPDATE ON public.cities FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: countries audit_countries_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_countries_changes AFTER INSERT OR DELETE OR UPDATE ON public.countries FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: documents audit_documents_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_documents_changes AFTER INSERT OR DELETE OR UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: faculties audit_faculties_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_faculties_changes AFTER INSERT OR DELETE OR UPDATE ON public.faculties FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: institutions audit_institutions_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_institutions_changes AFTER INSERT OR DELETE OR UPDATE ON public.institutions FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: invitations audit_invitations_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_invitations_changes AFTER INSERT OR DELETE OR UPDATE ON public.invitations FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: locations audit_locations_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_locations_changes AFTER INSERT OR DELETE OR UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: profiles audit_profiles_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_profiles_changes AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: projects audit_projects_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_projects_changes AFTER INSERT OR DELETE OR UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: roles audit_roles_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_roles_changes AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: schools audit_schools_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_schools_changes AFTER INSERT OR DELETE OR UPDATE ON public.schools FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: states audit_states_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_states_changes AFTER INSERT OR DELETE OR UPDATE ON public.states FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: students audit_students_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_students_changes AFTER INSERT OR DELETE OR UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- Name: campuses trg_audit_update_campuses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_campuses BEFORE UPDATE ON public.campuses FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: cities trg_audit_update_cities; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_cities BEFORE UPDATE ON public.cities FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: countries trg_audit_update_countries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_countries BEFORE UPDATE ON public.countries FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: documents trg_audit_update_documents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_documents BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: faculties trg_audit_update_faculties; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_faculties BEFORE UPDATE ON public.faculties FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: institutions trg_audit_update_institutions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_institutions BEFORE UPDATE ON public.institutions FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: invitations trg_audit_update_invitations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_invitations BEFORE UPDATE ON public.invitations FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: locations trg_audit_update_locations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_locations BEFORE UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: profiles trg_audit_update_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: projects trg_audit_update_projects; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_projects BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: roles trg_audit_update_roles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_roles BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: schools trg_audit_update_schools; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_schools BEFORE UPDATE ON public.schools FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: states trg_audit_update_states; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_states BEFORE UPDATE ON public.states FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: students trg_audit_update_students; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_update_students BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.handle_audit_update();


--
-- Name: campuses campuses_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT campuses_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: campuses campuses_president_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT campuses_president_profile_id_fkey FOREIGN KEY (president_profile_id) REFERENCES public.profiles(id);


--
-- Name: cities cities_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: documents documents_bucket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: documents documents_uploaded_by_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_uploaded_by_profile_id_fkey FOREIGN KEY (uploaded_by_profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: faculties faculties_campus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_campus_id_fkey FOREIGN KEY (campus_id) REFERENCES public.campuses(id);


--
-- Name: faculties faculties_coordinator_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_coordinator_profile_id_fkey FOREIGN KEY (coordinator_profile_id) REFERENCES public.profiles(id);


--
-- Name: faculties faculties_dean_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faculties_dean_profile_id_fkey FOREIGN KEY (dean_profile_id) REFERENCES public.profiles(id);


--
-- Name: institutions institutions_contact_person_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_contact_person_profile_id_fkey FOREIGN KEY (contact_person_profile_id) REFERENCES public.profiles(id);


--
-- Name: institutions institutions_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: invitations invitations_invited_by_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_invited_by_profile_id_fkey FOREIGN KEY (invited_by_profile_id) REFERENCES public.profiles(id);


--
-- Name: invitations invitations_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: locations locations_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- Name: profiles profiles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: projects projects_coordinator_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_coordinator_profile_id_fkey FOREIGN KEY (coordinator_profile_id) REFERENCES public.profiles(id);


--
-- Name: projects projects_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id);


--
-- Name: projects projects_pre_project_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pre_project_document_id_fkey FOREIGN KEY (pre_project_document_id) REFERENCES public.documents(id);


--
-- Name: projects projects_project_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_project_document_id_fkey FOREIGN KEY (project_document_id) REFERENCES public.documents(id);


--
-- Name: projects projects_student_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_student_profile_id_fkey FOREIGN KEY (student_profile_id) REFERENCES public.profiles(id);


--
-- Name: projects projects_tutor_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tutor_profile_id_fkey FOREIGN KEY (tutor_profile_id) REFERENCES public.profiles(id);


--
-- Name: schools schools_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id);


--
-- Name: schools schools_tutor_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_tutor_profile_id_fkey FOREIGN KEY (tutor_profile_id) REFERENCES public.profiles(id);


--
-- Name: states states_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: students students_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id);


--
-- Name: students students_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: students students_school_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_school_id_fkey FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs read_only_audit_logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_only_audit_logs ON public.audit_logs FOR SELECT TO authenticated USING (true);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: PROCEDURE attach_audit_triggers(VARIADIC table_names text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON PROCEDURE public.attach_audit_triggers(VARIADIC table_names text[]) TO anon;
GRANT ALL ON PROCEDURE public.attach_audit_triggers(VARIADIC table_names text[]) TO authenticated;
GRANT ALL ON PROCEDURE public.attach_audit_triggers(VARIADIC table_names text[]) TO service_role;


--
-- Name: PROCEDURE enable_audit_tracking(VARIADIC target_table_names text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON PROCEDURE public.enable_audit_tracking(VARIADIC target_table_names text[]) TO anon;
GRANT ALL ON PROCEDURE public.enable_audit_tracking(VARIADIC target_table_names text[]) TO authenticated;
GRANT ALL ON PROCEDURE public.enable_audit_tracking(VARIADIC target_table_names text[]) TO service_role;


--
-- Name: FUNCTION handle_audit_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_audit_update() TO anon;
GRANT ALL ON FUNCTION public.handle_audit_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_audit_update() TO service_role;


--
-- Name: FUNCTION log_changes(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.log_changes() TO anon;
GRANT ALL ON FUNCTION public.log_changes() TO authenticated;
GRANT ALL ON FUNCTION public.log_changes() TO service_role;


--
-- Name: PROCEDURE setup_audit(VARIADIC table_names text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON PROCEDURE public.setup_audit(VARIADIC table_names text[]) TO anon;
GRANT ALL ON PROCEDURE public.setup_audit(VARIADIC table_names text[]) TO authenticated;
GRANT ALL ON PROCEDURE public.setup_audit(VARIADIC table_names text[]) TO service_role;


--
-- Name: TABLE audit_logs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.audit_logs TO anon;
GRANT ALL ON TABLE public.audit_logs TO authenticated;
GRANT ALL ON TABLE public.audit_logs TO service_role;


--
-- Name: SEQUENCE audit_logs_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.audit_logs_id_seq TO anon;
GRANT ALL ON SEQUENCE public.audit_logs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.audit_logs_id_seq TO service_role;


--
-- Name: TABLE audit_meta; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.audit_meta TO anon;
GRANT ALL ON TABLE public.audit_meta TO authenticated;
GRANT ALL ON TABLE public.audit_meta TO service_role;


--
-- Name: TABLE campuses; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.campuses TO anon;
GRANT ALL ON TABLE public.campuses TO authenticated;
GRANT ALL ON TABLE public.campuses TO service_role;


--
-- Name: SEQUENCE campuses_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.campuses_id_seq TO anon;
GRANT ALL ON SEQUENCE public.campuses_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.campuses_id_seq TO service_role;


--
-- Name: TABLE cities; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.cities TO anon;
GRANT ALL ON TABLE public.cities TO authenticated;
GRANT ALL ON TABLE public.cities TO service_role;


--
-- Name: SEQUENCE cities_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.cities_id_seq TO anon;
GRANT ALL ON SEQUENCE public.cities_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.cities_id_seq TO service_role;


--
-- Name: TABLE countries; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.countries TO anon;
GRANT ALL ON TABLE public.countries TO authenticated;
GRANT ALL ON TABLE public.countries TO service_role;


--
-- Name: SEQUENCE countries_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.countries_id_seq TO anon;
GRANT ALL ON SEQUENCE public.countries_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.countries_id_seq TO service_role;


--
-- Name: TABLE documents; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.documents TO anon;
GRANT ALL ON TABLE public.documents TO authenticated;
GRANT ALL ON TABLE public.documents TO service_role;


--
-- Name: SEQUENCE documents_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.documents_id_seq TO anon;
GRANT ALL ON SEQUENCE public.documents_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.documents_id_seq TO service_role;


--
-- Name: TABLE faculties; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.faculties TO anon;
GRANT ALL ON TABLE public.faculties TO authenticated;
GRANT ALL ON TABLE public.faculties TO service_role;


--
-- Name: SEQUENCE faculties_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.faculties_id_seq TO anon;
GRANT ALL ON SEQUENCE public.faculties_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.faculties_id_seq TO service_role;


--
-- Name: TABLE institutions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.institutions TO anon;
GRANT ALL ON TABLE public.institutions TO authenticated;
GRANT ALL ON TABLE public.institutions TO service_role;


--
-- Name: SEQUENCE institutions_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.institutions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.institutions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.institutions_id_seq TO service_role;


--
-- Name: TABLE invitations; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.invitations TO anon;
GRANT ALL ON TABLE public.invitations TO authenticated;
GRANT ALL ON TABLE public.invitations TO service_role;


--
-- Name: SEQUENCE invitations_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.invitations_id_seq TO anon;
GRANT ALL ON SEQUENCE public.invitations_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.invitations_id_seq TO service_role;


--
-- Name: TABLE locations; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.locations TO anon;
GRANT ALL ON TABLE public.locations TO authenticated;
GRANT ALL ON TABLE public.locations TO service_role;


--
-- Name: SEQUENCE locations_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.locations_id_seq TO anon;
GRANT ALL ON SEQUENCE public.locations_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.locations_id_seq TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.projects TO anon;
GRANT ALL ON TABLE public.projects TO authenticated;
GRANT ALL ON TABLE public.projects TO service_role;


--
-- Name: SEQUENCE projects_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.projects_id_seq TO anon;
GRANT ALL ON SEQUENCE public.projects_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.projects_id_seq TO service_role;


--
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.roles TO anon;
GRANT ALL ON TABLE public.roles TO authenticated;
GRANT ALL ON TABLE public.roles TO service_role;


--
-- Name: SEQUENCE roles_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.roles_id_seq TO anon;
GRANT ALL ON SEQUENCE public.roles_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.roles_id_seq TO service_role;


--
-- Name: TABLE schools; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.schools TO anon;
GRANT ALL ON TABLE public.schools TO authenticated;
GRANT ALL ON TABLE public.schools TO service_role;


--
-- Name: SEQUENCE schools_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.schools_id_seq TO anon;
GRANT ALL ON SEQUENCE public.schools_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.schools_id_seq TO service_role;


--
-- Name: TABLE states; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.states TO anon;
GRANT ALL ON TABLE public.states TO authenticated;
GRANT ALL ON TABLE public.states TO service_role;


--
-- Name: SEQUENCE states_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.states_id_seq TO anon;
GRANT ALL ON SEQUENCE public.states_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.states_id_seq TO service_role;


--
-- Name: TABLE students; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.students TO anon;
GRANT ALL ON TABLE public.students TO authenticated;
GRANT ALL ON TABLE public.students TO service_role;


--
-- Name: SEQUENCE students_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON SEQUENCE public.students_id_seq TO anon;
GRANT ALL ON SEQUENCE public.students_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.students_id_seq TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict 2igqnHwOIIGcEMGmzs1WrNB1YWLfu8iS7fspbL0793WucKz4VYje8WY7k6eI5IO

