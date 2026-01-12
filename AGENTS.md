# AGENTS

## Scope & Restrictions

- **Scope**: Entire repo (no nested agent files).
- **Git Operations**: Agents must never perform commits, PRs, pulls, or pushes, nor should they suggest performing these actions or include commit messages or anything related to these operations.
- **External Rules**: No Cursor or Copilot rules present; follow this file.

## Workflow & Quality Control

1. **Analyze**: Review the repo to detect side changes required by the primary task.
2. **Side Effects**: Any changes to the DB must be reflected in the data dictionary at `docs/schema-data-dictionary.md`.
3. **Linting & Formatting**:
   - Tooling: Node 18+ with npm; Supabase CLI via `npx`.
   - Lint: `sqlfluff lint supabase/migrations/*.sql` (config in `.sqlfluff`).
   - Format: `sqlfluff fix supabase/migrations/*.sql` .
4. **Completion Rule**: Agents must run format, lint, and fix commands until no new errors are reported before finishing the assigned task.

## Database Development Standards

### Naming & Style

- **SQL Keywords**: Use lowercase.
- **Identifiers**: Use snake_case.
- **Tables**: Use plural names (e.g., `users`, `projects`).
- **Columns**: Use snake_case (e.g., `first_name`, `national_id`).
- **Enums**:
  - Naming: `<name>_enum`.
  - Values: Lowercase or uppercase tokens matching existing types; preserve values from the schema dictionary.
- **Comments**: Use `--` for concise rationale near non-obvious DDL only. Avoid unnecessary commenting, keep them as minimum or don't add them if things are clear.
- **General Naming**: always use descriptive and complete names for variables, etc.

### Schema Design

- **Types**: Use explicit types; avoid implicit casts.
- **Dates**: Prefer `timestamptz`.
- **Primary Keys**:
  - Always use `gen_random_uuid()` unless linking to Supabase Auth `users.id`.
  - Declare PKs before data changes.
- **Constraints**:
  - Declare FK/Unique constraints before data changes.
  - Include `ON DELETE` rules explicitly.
- **Audit Implementation**:
  - Tables must include `LIKE audit_meta INCLUDING ALL`.
  - Mandatory audit columns must be enabled via `enable_audit_tracking` function.
  - Enable `handle_audit_update` for all new tables, to add the `audit_meta` support.

### Migrations & SQL

- **Imports**: Keep `CREATE EXTENSION`/`SET` statements stable. Imports are generally not applicable for the current SQL-only backend.
- **DDL Operations**:
  - Avoid redundant `DROP` unless intentional.
  - Avoid `IF NOT EXISTS` unless reruns are expected (prefer deterministic migrations).
- **Error Handling**:
  - Prefer deterministic migrations.
  - In PL/pgSQL, use `RAISE EXCEPTION` with descriptive messages.
