-- 03_projects_and_tracking.sql
-- Projects table and approval tracking state machine

CREATE TABLE IF NOT EXISTS public.projects (
  id BIGSERIAL PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES public.students(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  institution_id BIGINT NOT NULL REFERENCES public.institutions(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  project_name TEXT NOT NULL,
  general_objective TEXT NOT NULL,
  specific_objective_1 TEXT,
  specific_objective_2 TEXT,
  specific_objective_3 TEXT,
  specific_objective_4 TEXT,
  justification TEXT NOT NULL,
  introduction TEXT NOT NULL,
  summary TEXT NOT NULL,
  coordinator TEXT,
  tutor TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CHECK (end_date >= start_date),
  approved_ante_project BOOLEAN NOT NULL DEFAULT FALSE,
  approved_ante_project_at TIMESTAMPTZ,
  project_received BOOLEAN NOT NULL DEFAULT FALSE,
  project_received_at TIMESTAMPTZ,
  approved_final_project BOOLEAN NOT NULL DEFAULT FALSE,
  approved_final_project_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for relationships
CREATE INDEX IF NOT EXISTS idx_projects_student_id ON public.projects(student_id);
CREATE INDEX IF NOT EXISTS idx_projects_institution_id ON public.projects(institution_id);

-- Trigger to keep updated_at current
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_projects'
  ) THEN
    CREATE TRIGGER set_updated_at_projects
    BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END;
$$;

-- State machine timestamps: set approval timestamps when toggled to TRUE
CREATE OR REPLACE FUNCTION public.set_project_state_timestamps()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.approved_ante_project AND (OLD IS NULL OR NOT OLD.approved_ante_project) AND NEW.approved_ante_project_at IS NULL THEN
    NEW.approved_ante_project_at := NOW();
  END IF;

  IF NEW.project_received AND (OLD IS NULL OR NOT OLD.project_received) AND NEW.project_received_at IS NULL THEN
    NEW.project_received_at := NOW();
  END IF;

  IF NEW.approved_final_project AND (OLD IS NULL OR NOT OLD.approved_final_project) AND NEW.approved_final_project_at IS NULL THEN
    NEW.approved_final_project_at := NOW();
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_project_state_timestamps'
  ) THEN
    CREATE TRIGGER set_project_state_timestamps
    BEFORE INSERT OR UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.set_project_state_timestamps();
  END IF;
END;
$$;
