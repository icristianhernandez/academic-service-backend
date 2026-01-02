-- 01_initial_schema.sql
-- Extensions and base lookup tables for faculties, schools, and institutions

-- Enable citext for case-insensitive email handling
CREATE EXTENSION IF NOT EXISTS "citext";

-- Generic trigger function to maintain updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Faculties lookup table
CREATE TABLE IF NOT EXISTS public.faculties (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Schools belong to faculties
CREATE TABLE IF NOT EXISTS public.schools (
  id BIGSERIAL PRIMARY KEY,
  faculty_id BIGINT NOT NULL REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (faculty_id, name)
);

-- Institutions where service will be provided
CREATE TABLE IF NOT EXISTS public.institutions (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  address TEXT,
  contact_email CITEXT,
  contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for foreign keys
CREATE INDEX IF NOT EXISTS idx_schools_faculty_id ON public.schools(faculty_id);

-- Attach updated_at triggers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_faculties'
  ) THEN
    CREATE TRIGGER set_updated_at_faculties
    BEFORE UPDATE ON public.faculties
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_schools'
  ) THEN
    CREATE TRIGGER set_updated_at_schools
    BEFORE UPDATE ON public.schools
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_institutions'
  ) THEN
    CREATE TRIGGER set_updated_at_institutions
    BEFORE UPDATE ON public.institutions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END;
$$;
