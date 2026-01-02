-- 05_rbac_and_rls.sql
-- Role definitions and Row Level Security policies

-- Role catalog
CREATE TABLE IF NOT EXISTS public.roles (
  name TEXT PRIMARY KEY,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.roles (name, description) VALUES
  ('rectorate', 'Global access role'),
  ('vicerectorate', 'Global access role'),
  ('planning', 'Global access role'),
  ('dean', 'Faculty-scoped role'),
  ('director_school', 'School-scoped role'),
  ('coordinator', 'School-scoped coordinator'),
  ('student', 'Student role')
ON CONFLICT (name) DO NOTHING;

-- Role assignments with optional scope
CREATE TABLE IF NOT EXISTS public.role_assignments (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_name TEXT NOT NULL REFERENCES public.roles(name) ON UPDATE CASCADE ON DELETE RESTRICT,
  faculty_id BIGINT REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  school_id BIGINT REFERENCES public.schools(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_role_assignments_user_id ON public.role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_role_assignments_role_name ON public.role_assignments(role_name);
CREATE INDEX IF NOT EXISTS idx_role_assignments_faculty_id ON public.role_assignments(faculty_id);
CREATE INDEX IF NOT EXISTS idx_role_assignments_school_id ON public.role_assignments(school_id);

-- Maintain updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_roles'
  ) THEN
    CREATE TRIGGER set_updated_at_roles
    BEFORE UPDATE ON public.roles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_role_assignments'
  ) THEN
    CREATE TRIGGER set_updated_at_role_assignments
    BEFORE UPDATE ON public.role_assignments
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END;
$$;

-- Helper functions for permission checks
CREATE OR REPLACE FUNCTION public.has_global_access(p_uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.role_assignments ra
    WHERE ra.user_id = p_uid
      AND ra.role_name IN ('rectorate', 'vicerectorate', 'planning')
  );
$$;

CREATE OR REPLACE FUNCTION public.has_faculty_access(p_uid UUID, p_faculty_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.role_assignments ra
    WHERE ra.user_id = p_uid
      AND ra.role_name = 'dean'
      AND ra.faculty_id = p_faculty_id
  );
$$;

CREATE OR REPLACE FUNCTION public.has_school_access(p_uid UUID, p_school_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.role_assignments ra
    WHERE ra.user_id = p_uid
      AND ra.role_name IN ('director_school', 'coordinator')
      AND ra.school_id = p_school_id
  );
$$;

-- Helper to determine administrative access to a project via its student
CREATE OR REPLACE FUNCTION public.can_manage_project(p_uid UUID, p_student_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN p_uid IS NULL THEN FALSE
    ELSE
      public.has_global_access(p_uid)
      OR EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = p_student_id
          AND public.has_faculty_access(p_uid, s.faculty_id)
      )
      OR EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = p_student_id
          AND public.has_school_access(p_uid, s.school_id)
      )
  END;
$$;

-- Enable RLS
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Students policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_global_select'
  ) THEN
    CREATE POLICY students_global_select ON public.students
    FOR SELECT USING (public.has_global_access(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_faculty_select'
  ) THEN
    CREATE POLICY students_faculty_select ON public.students
    FOR SELECT USING (public.has_faculty_access(auth.uid(), faculty_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_faculty_update'
  ) THEN
    CREATE POLICY students_faculty_update ON public.students
    FOR UPDATE USING (public.has_faculty_access(auth.uid(), faculty_id))
    WITH CHECK (public.has_faculty_access(auth.uid(), faculty_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_school_select'
  ) THEN
    CREATE POLICY students_school_select ON public.students
    FOR SELECT USING (public.has_school_access(auth.uid(), school_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_school_update'
  ) THEN
    CREATE POLICY students_school_update ON public.students
    FOR UPDATE USING (public.has_school_access(auth.uid(), school_id))
    WITH CHECK (public.has_school_access(auth.uid(), school_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_self_select'
  ) THEN
    CREATE POLICY students_self_select ON public.students
    FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'students' AND policyname = 'students_insert_scoped'
  ) THEN
    CREATE POLICY students_insert_scoped ON public.students
    FOR INSERT WITH CHECK (
      public.has_global_access(auth.uid())
      OR public.has_faculty_access(auth.uid(), faculty_id)
      OR public.has_school_access(auth.uid(), school_id)
      OR auth.uid() = user_id
    );
  END IF;
END;
$$;

-- Projects policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'projects' AND policyname = 'projects_select_scoped'
  ) THEN
    CREATE POLICY projects_select_scoped ON public.projects
    FOR SELECT USING (
      public.can_manage_project(auth.uid(), public.projects.student_id)
      OR EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = public.projects.student_id
          AND s.user_id = auth.uid()
      )
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'projects' AND policyname = 'projects_update_scoped'
  ) THEN
    -- Only scoped administrative roles can update projects; students are read-only
    CREATE POLICY projects_update_using ON public.projects
    FOR UPDATE USING (
      public.can_manage_project(auth.uid(), public.projects.student_id)
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'projects' AND policyname = 'projects_update_check'
  ) THEN
    CREATE POLICY projects_update_check ON public.projects
    FOR UPDATE WITH CHECK (
      public.can_manage_project(auth.uid(), public.projects.student_id)
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'projects' AND policyname = 'projects_insert_scoped'
  ) THEN
    CREATE POLICY projects_insert_scoped ON public.projects
    FOR INSERT WITH CHECK (
      public.can_manage_project(auth.uid(), public.projects.student_id)
      OR EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = public.projects.student_id
          AND s.user_id = auth.uid()
      )
    );
  END IF;
END;
$$;

-- Audit log policies: allow inserts (for triggers) and restrict reads to global roles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'audit_log' AND policyname = 'audit_log_insert_all'
  ) THEN
    CREATE POLICY audit_log_insert_all ON public.audit_log
    FOR INSERT WITH CHECK (TRUE);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'audit_log' AND policyname = 'audit_log_global_select'
  ) THEN
    CREATE POLICY audit_log_global_select ON public.audit_log
    FOR SELECT USING (public.has_global_access(auth.uid()));
  END IF;
END;
$$;
