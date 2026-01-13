# Database migration plan (Supabase)

## Objectives
- Model the academic service workflow with strongly normalized tables (5NF-oriented) to avoid redundancy and update anomalies.
- Capture personal data, project metadata, approvals, and responsible parties with clear foreign keys and enumerated domains.
- Enforce immutability of deletion operations and maintain an auditable log of inserts/updates.
- Prepare role mapping to grant access for rectoría, vicerrectorado académico, dirección de planeamiento y admisión, Dirección, Decanos, Directores de Escuela y Coordinadores.

## High-level entities
1. **Person**: stores apellido(s), nombre(s), C.I., email. Independent from enrollment data.
2. **Contact numbers**: up to two phone slots per person (ordered 1..2). Separate table to keep atomic phone numbers.
3. **Faculties / Schools**: dimension tables; school references faculty.
4. **Academic placement**: semester, turno, sección as reference tables to keep consistent lookup values.
5. **Service enrollment**: links a person to faculty, school, semester, turno, sección (one fact per row).
6. **Institution**: where the service is performed.
7. **Project**: name, objetivo general, justificación, introducción, resumen, institution + dates.
8. **Specific objectives**: up to four rows per project with a sequence number.
9. **Supervisors**: coordinator and tutor linked to the project with a role field.
10. **Project milestones**: anteproyecto aprobado (sí/no + fecha), proyecto recibido (sí/no + fecha), proyecto final aprobado (sí/no + fecha) stored as typed milestone rows.
11. **Access control lookup**: list of allowed roles and mapping to auth.users (for future RLS policies).
12. **Audit log**: append-only record of INSERT/UPDATE events for critical tables; deletion operations blocked.

## Normalization approach (5NF principles)
- Each table represents a single fact; multi-valued attributes (phones, specific objectives, milestones, supervisors) are isolated in dependent tables with minimal candidate keys.
- Reference/lookup tables (semester, turno, sección, faculties, schools, milestone types, supervisor roles) ensure domains are enforced via FK + unique constraints.
- All relationships use surrogate integer primary keys (or UUIDs for auth.users mapping) with NOT NULL and unique natural keys where appropriate (e.g., CI, email).
- Association tables (user_roles, project_specific_objectives, project_milestones, project_supervisors) split independent relationships to avoid redundancy and allow future expansion without schema churn.

## Constraints and business rules
- C.I. and email unique per person.
- Contact numbers: CHECK(contact_order IN (1,2)) and UNIQUE(person_id, contact_order) to cap at two entries.
- Specific objectives: CHECK(seq BETWEEN 1 AND 4) and UNIQUE(project_id, seq).
- Milestones: constrained by enumerated milestone_type (anteproyecto_aprobado, proyecto_recibido, proyecto_final_aprobado). One row per project per type enforced by UNIQUE(project_id, milestone_type_id).
- Deletions are blocked on core tables (people, contacts, enrollments, projects, objectives, supervisors, milestones, institutions) via BEFORE DELETE triggers that raise exceptions.
- Timestamps: created_at/updated_at on transactional tables; audit log records table name, action, record PK, old/new JSON snapshots, and user identifier when available (auth.uid()).

## Access model scaffold
- `access_roles` table seeds allowed organizational roles (rectoria, vicerrectorado_academico, planeamiento_admision — Dirección de planeamiento y admisión, direccion_general, decano, director_escuela, coordinador) using the same role_key values as the migration seeds.
- `user_roles` maps auth.users (user_id UUID) to one or more access_roles. Future RLS policies can use these tables; current migration only seeds structure.

## Migration steps
1. **Create lookup/reference tables**: faculties, schools, semesters, turns, sections, milestone_types, supervisor_roles, access_roles.
2. **Create core tables**: people, person_contacts, service_enrollments, institutions.
3. **Create project tables**: projects, project_specific_objectives, project_supervisors, project_milestones.
4. **Auditing & immutability**:
   - Create `audit_log` table.
   - Create trigger function to log INSERT/UPDATE for target tables.
   - Create trigger function to block DELETE on protected tables.
   - Attach triggers accordingly.
5. **Access scaffolding**: create `user_roles` table and seed access_roles values.
6. **Seed reference data**: milestone types, supervisor roles, sample academic placement values (turns, sections) as needed for consistent domains.

## Testing / verification plan
- Validate schema with `supabase db lint` or `supabase db diff` (if available) and ensure migrations apply cleanly.
- Manually insert sample rows into people, projects, objectives to confirm FK chains and audit triggers capture activity; verify DELETE raises an exception.
- Confirm uniqueness constraints enforce max counts (contacts <=2, objectives <=4, milestones 1 per type).
