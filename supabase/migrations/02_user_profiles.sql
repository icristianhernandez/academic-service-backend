-- 02_user_profiles.sql
-- Student and administrative profile tables linked to auth.users

-- Students capture academic and contact details
CREATE TABLE IF NOT EXISTS public.students (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  ci TEXT NOT NULL,
  surnames TEXT NOT NULL,
  names TEXT NOT NULL,
  email CITEXT NOT NULL,
  contact_number1 TEXT,
  contact_number2 TEXT,
  faculty_id BIGINT NOT NULL REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  school_id BIGINT NOT NULL REFERENCES public.schools(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  semester TEXT NOT NULL,
  turn TEXT NOT NULL,
  section TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ci ~ '^[0-9]{5,20}$'),
  UNIQUE (user_id),
  UNIQUE (ci)
);

-- Administrative/staff profiles tied to auth.users with optional faculty/school scope
CREATE TABLE IF NOT EXISTS public.admin_profiles (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  display_name TEXT,
  role_hint TEXT,
  faculty_id BIGINT REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  school_id BIGINT REFERENCES public.schools(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_students_ci ON public.students(ci);
CREATE INDEX IF NOT EXISTS idx_students_user_id ON public.students(user_id);
CREATE INDEX IF NOT EXISTS idx_students_faculty_id ON public.students(faculty_id);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON public.students(school_id);

CREATE INDEX IF NOT EXISTS idx_admin_profiles_user_id ON public.admin_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_profiles_faculty_id ON public.admin_profiles(faculty_id);
CREATE INDEX IF NOT EXISTS idx_admin_profiles_school_id ON public.admin_profiles(school_id);

-- Attach updated_at triggers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_students'
  ) THEN
    CREATE TRIGGER set_updated_at_students
    BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_admin_profiles'
  ) THEN
    CREATE TRIGGER set_updated_at_admin_profiles
    BEFORE UPDATE ON public.admin_profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END;
$$;
