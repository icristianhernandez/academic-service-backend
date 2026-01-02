-- 04_audit_and_immutability.sql
-- Audit log and triggers preventing deletions

-- Central audit log for inserts and updates
CREATE TABLE IF NOT EXISTS public.audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE')),
  old_data JSONB,
  new_data JSONB,
  acted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acted_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- updated_at maintenance for audit log
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_audit_log'
  ) THEN
    CREATE TRIGGER set_updated_at_audit_log
    BEFORE UPDATE ON public.audit_log
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END;
$$;

-- Prevent deletions on critical tables
CREATE OR REPLACE FUNCTION public.prevent_delete()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Deletes are not allowed on %', TG_TABLE_NAME;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_delete_students') THEN
    CREATE TRIGGER prevent_delete_students
    BEFORE DELETE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.prevent_delete();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_delete_projects') THEN
    CREATE TRIGGER prevent_delete_projects
    BEFORE DELETE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.prevent_delete();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_delete_audit_log') THEN
    CREATE TRIGGER prevent_delete_audit_log
    BEFORE DELETE ON public.audit_log
    FOR EACH ROW EXECUTE FUNCTION public.prevent_delete();
  END IF;
END;
$$;

-- Helper to retrieve acting user id consistently
CREATE OR REPLACE FUNCTION public.current_actor_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_claim TEXT;
BEGIN
  v_claim := current_setting('request.jwt.claim.sub', TRUE);
  IF v_claim IS NULL OR v_claim = '' THEN
    RETURN auth.uid();
  END IF;

  RETURN COALESCE(auth.uid(), v_claim::UUID);
EXCEPTION
  WHEN invalid_text_representation THEN
    RETURN auth.uid();
END;
$$;

-- Audit logging for inserts and updates
CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_actor UUID;
  v_record_id TEXT;
BEGIN
  v_actor := public.current_actor_id();

  IF TG_OP = 'INSERT' THEN
    v_record_id := COALESCE(NEW.id::TEXT, '');
    INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data, acted_by)
    VALUES (TG_TABLE_NAME, v_record_id, 'INSERT', NULL, TO_JSONB(NEW), v_actor);
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    v_record_id := COALESCE(NEW.id::TEXT, OLD.id::TEXT, '');
    INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data, acted_by)
    VALUES (TG_TABLE_NAME, v_record_id, 'UPDATE', TO_JSONB(OLD), TO_JSONB(NEW), v_actor);
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'log_audit_students') THEN
    CREATE TRIGGER log_audit_students
    AFTER INSERT OR UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'log_audit_projects') THEN
    CREATE TRIGGER log_audit_projects
    AFTER INSERT OR UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.log_audit();
  END IF;
END;
$$;
