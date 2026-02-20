# Data Type Dictionary

<!--toc:start-->

- [Data Type Dictionary](#data-type-dictionary)
  - [Custom Types](#custom-types)
  - [Audit Base & Triggers](#audit-base-triggers)
  - [Table: audit_meta](#table-auditmeta)
  - [Table: countries](#table-countries)
  - [Table: states](#table-states)
  - [Table: cities](#table-cities)
  - [Table: locations](#table-locations)
  - [Table: roles](#table-roles)
  - [Table: profiles](#table-profiles)
  - [Table: campuses](#table-campuses)
  - [Table: faculties](#table-faculties)
  - [Table: schools](#table-schools)
  - [Table: students](#table-students)
  - [Table: institutions](#table-institutions)
  - [Table: documents](#table-documents)
  - [Table: projects](#table-projects)
  - [Table: invitations](#table-invitations)
  - [Table: audit_logs](#table-auditlogs)
  <!--toc:end-->

## Custom Types

| Type          | Values                                            | Dev Notes                  |
| :------------ | :------------------------------------------------ | :------------------------- |
| semester_enum | '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' | Academic semester number   |
| section_enum  | 'A', 'B', 'C', 'D', 'E', 'F'                      | Cohort/section designation |
| shift_enum    | 'MORNING', 'EVENING'                              | Student shift              |

Primary keys use `bigint generated always as identity` for application tables. The auth boundary remains `profiles.id uuid` to stay compatible with `auth.users.id`.

Extensions: `plpgsql_check` (loaded for validation).

---

## Audit Base & Triggers

- `audit_meta` base columns: `created_at timestamptz NOT NULL DEFAULT now()`, `created_by uuid NOT NULL DEFAULT auth.uid()`, `updated_at timestamptz NOT NULL DEFAULT now()`, `updated_by uuid DEFAULT auth.uid()`.
- Tables created with `LIKE audit_meta INCLUDING ALL` inherit these columns and defaults.
- Trigger function `handle_audit_update` sets `updated_at` and `updated_by` on updates.
- `setup_audit(...)` creates both update audit triggers (`enable_audit_tracking`) and update/add/delete audit triggers (`attach_audit_triggers`) for: countries, states, cities, locations, campuses, faculties, schools, roles, students, profiles, institutions, projects, documents, invitations.
- `enable_audit_tracking` on a table creates a trigger that updates the `updated_at` and `updated_by` fields on every update to the row.
- `attach_audit_triggers` on a table creates triggers that log `INSERT`, `UPDATE`, and `DELETE` operations to the `audit_logs` table, capturing the schema name, table name, operation type, user ID, and a JSON payload of the row data.

---

## Table: audit_meta

| Attribute  | Data Type   | Nullable | Default    | Constraints | Dev Notes         |
| :--------- | :---------- | :------- | :--------- | :---------- | :---------------- |
| created_at | timestamptz | No       | now()      |             | Base audit column |
| created_by | uuid        | No       | auth.uid() |             | Base audit column |
| updated_at | timestamptz | No       | now()      |             | Base audit column |
| updated_by | uuid        | Yes      | auth.uid() |             | Base audit column |

---

## Table: countries

| Attribute    | Data Type   | Nullable | Default                      | Constraints | Dev Notes             |
| :----------- | :---------- | :------- | :--------------------------- | :---------- | :-------------------- |
| id           | bigint      | No       | generated always as identity | PK          |                       |
| country_name | text        | No       |                              | UNIQUE      |                       |
| created_at   | timestamptz | No       | now()                        |             | Inherits audit fields |
| updated_at   | timestamptz | No       | now()                        |             | Inherits audit fields |
| created_by   | uuid        | No       | auth.uid()                   |             | Inherits audit fields |
| updated_by   | uuid        | Yes      | auth.uid()                   |             | Inherits audit fields |

---

## Table: states

| Attribute  | Data Type   | Nullable | Default                      | Constraints        | Dev Notes             |
| :--------- | :---------- | :------- | :--------------------------- | :----------------- | :-------------------- |
| id         | bigint      | No       | generated always as identity | PK                 |                       |
| country_id | bigint      | No       |                              | FK -> countries.id |                       |
| state_name | text        | No       |                              | UNIQUE             |                       |
| created_at | timestamptz | No       | now()                        |                    | Inherits audit fields |
| updated_at | timestamptz | No       | now()                        |                    | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()                   |                    | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()                   |                    | Inherits audit fields |

---

## Table: cities

| Attribute  | Data Type   | Nullable | Default                      | Constraints     | Dev Notes             |
| :--------- | :---------- | :------- | :--------------------------- | :-------------- | :-------------------- |
| id         | bigint      | No       | generated always as identity | PK              |                       |
| state_id   | bigint      | No       |                              | FK -> states.id |                       |
| city_name  | text        | No       |                              | UNIQUE          |                       |
| created_at | timestamptz | No       | now()                        |                 | Inherits audit fields |
| updated_at | timestamptz | No       | now()                        |                 | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()                   |                 | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()                   |                 | Inherits audit fields |

---

## Table: locations

| Attribute  | Data Type   | Nullable | Default                      | Constraints     | Dev Notes             |
| :--------- | :---------- | :------- | :--------------------------- | :-------------- | :-------------------- |
| id         | bigint      | No       | generated always as identity | PK              |                       |
| city_id    | bigint      | No       |                              | FK -> cities.id |                       |
| address    | text        | No       |                              |                 |                       |
| created_at | timestamptz | No       | now()                        |                 | Inherits audit fields |
| updated_at | timestamptz | No       | now()                        |                 | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()                   |                 | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()                   |                 | Inherits audit fields |

---

## Table: roles

| Attribute        | Data Type   | Nullable | Default                      | Constraints | Dev Notes             |
| :--------------- | :---------- | :------- | :--------------------------- | :---------- | :-------------------- |
| id               | bigint      | No       | generated always as identity | PK          |                       |
| role_name        | text        | No       |                              | UNIQUE      |                       |
| permission_level | integer     | No       |                              |             |                       |
| created_at       | timestamptz | No       | now()                        |             | Inherits audit fields |
| updated_at       | timestamptz | No       | now()                        |             | Inherits audit fields |
| created_by       | uuid        | No       | auth.uid()                   |             | Inherits audit fields |
| updated_by       | uuid        | Yes      | auth.uid()                   |             | Inherits audit fields |

---

## Table: profiles

| Attribute         | Data Type   | Nullable | Default    | Constraints    | Dev Notes             |
| :---------------- | :---------- | :------- | :--------- | :------------- | :-------------------- |
| id                | uuid        | No       |            | PK             | Supabase auth user id |
| first_name        | text        | No       |            |                |                       |
| last_name         | text        | No       |            |                |                       |
| national_id       | text        | No       |            | UNIQUE         |                       |
| email             | text        | No       |            | UNIQUE         |                       |
| primary_contact   | text        | No       |            |                |                       |
| secondary_contact | text        | Yes      |            |                |                       |
| role_id           | bigint      | Yes      |            | FK -> roles.id |                       |
| created_at        | timestamptz | No       | now()      |                | Inherits audit fields |
| updated_at        | timestamptz | No       | now()      |                | Inherits audit fields |
| created_by        | uuid        | No       | auth.uid() |                | Inherits audit fields |
| updated_by        | uuid        | Yes      | auth.uid() |                | Inherits audit fields |

---

## Table: campuses

| Attribute    | Data Type   | Nullable | Default                      | Constraints        | Dev Notes             |
| :----------- | :---------- | :------- | :--------------------------- | :----------------- | :-------------------- |
| id           | bigint      | No       | generated always as identity | PK                 |                       |
| location_id  | bigint      | No       |                              | FK -> locations.id |                       |
| campus_name  | text        | No       |                              | UNIQUE             |                       |
| president_profile_id | uuid        | No       |                              | FK -> profiles.id     |                       |
| created_at   | timestamptz | No       | now()                        |                    | Inherits audit fields |
| updated_at   | timestamptz | No       | now()                        |                    | Inherits audit fields |
| created_by   | uuid        | No       | auth.uid()                   |                    | Inherits audit fields |
| updated_by   | uuid        | Yes      | auth.uid()                   |                    | Inherits audit fields |

---

## Table: faculties

| Attribute      | Data Type   | Nullable | Default                      | Constraints       | Dev Notes             |
| :------------- | :---------- | :------- | :--------------------------- | :---------------- | :-------------------- |
| id             | bigint      | No       | generated always as identity | PK                |                       |
| campus_id      | bigint      | No       |                              | FK -> campuses.id |                       |
| faculty_name   | text        | No       |                              | UNIQUE            |                       |
| dean_profile_id        | uuid        | No       |                              | FK -> profiles.id    |                       |
| coordinator_profile_id | uuid        | No       |                              | FK -> profiles.id    |                       |
| created_at     | timestamptz | No       | now()                        |                   | Inherits audit fields |
| updated_at     | timestamptz | No       | now()                        |                   | Inherits audit fields |
| created_by     | uuid        | No       | auth.uid()                   |                   | Inherits audit fields |
| updated_by     | uuid        | Yes      | auth.uid()                   |                   | Inherits audit fields |

---

## Table: schools

| Attribute   | Data Type   | Nullable | Default                      | Constraints        | Dev Notes             |
| :---------- | :---------- | :------- | :--------------------------- | :----------------- | :-------------------- |
| id          | bigint      | No       | generated always as identity | PK                 |                       |
| faculty_id  | bigint      | No       |                              | FK -> faculties.id |                       |
| school_name | text        | No       |                              | UNIQUE             |                       |
| tutor_profile_id    | uuid        | No       |                              | FK -> profiles.id     |                       |
| created_at  | timestamptz | No       | now()                        |                    | Inherits audit fields |
| updated_at  | timestamptz | No       | now()                        |                    | Inherits audit fields |
| created_by  | uuid        | No       | auth.uid()                   |                    | Inherits audit fields |
| updated_by  | uuid        | Yes      | auth.uid()                   |                    | Inherits audit fields |

---

## Table: students

| Attribute  | Data Type     | Nullable | Default                      | Constraints        | Dev Notes             |
| :--------- | :------------ | :------- | :--------------------------- | :----------------- | :-------------------- |
| id         | bigint        | No       | generated always as identity | PK                 |                       |
| profile_id    | uuid          | No       |                              | FK -> profiles.id     |                       |
| faculty_id | bigint        | No       |                              | FK -> faculties.id |                       |
| school_id  | bigint        | No       |                              | FK -> schools.id   |                       |
| semester   | semester_enum | Yes      |                              |                    |                       |
| shift      | shift_enum    | Yes      |                              |                    |                       |
| section    | section_enum  | Yes      |                              |                    |                       |
| created_at | timestamptz   | No       | now()                        |                    | Inherits audit fields |
| updated_at | timestamptz   | No       | now()                        |                    | Inherits audit fields |
| created_by | uuid          | No       | auth.uid()                   |                    | Inherits audit fields |
| updated_by | uuid          | Yes      | auth.uid()                   |                    | Inherits audit fields |

---

## Table: institutions

| Attribute         | Data Type   | Nullable | Default                      | Constraints        | Dev Notes             |
| :---------------- | :---------- | :------- | :--------------------------- | :----------------- | :-------------------- |
| id                | bigint      | No       | generated always as identity | PK                 |                       |
| location_id       | bigint      | Yes      |                              | FK -> locations.id |                       |
| contact_person_profile_id | uuid        | Yes      |                              | FK -> profiles.id     |                       |
| institution_name  | text        | No       |                              | UNIQUE             |                       |
| created_at        | timestamptz | No       | now()                        |                    | Inherits audit fields |
| updated_at        | timestamptz | No       | now()                        |                    | Inherits audit fields |
| created_by        | uuid        | No       | auth.uid()                   |                    | Inherits audit fields |
| updated_by        | uuid        | Yes      | auth.uid()                   |                    | Inherits audit fields |

---

## Table: documents

| Attribute    | Data Type   | Nullable | Default                      | Constraints                      | Dev Notes                                       |
| :----------- | :---------- | :------- | :--------------------------- | :------------------------------- | :---------------------------------------------- |
| id           | bigint      | No       | generated always as identity | PK                               | Can store display/name/size/type metadata later |
| bucket_id    | text        | No       | project                      | FK -> storage.buckets.id         | Uses shared project bucket (public)             |
| storage_path | text        | No       |                              | UNIQUE (bucket_id, storage_path) |                                                 |
| uploaded_by_profile_id  | uuid        | No       |                              | FK -> profiles.id ON DELETE CASCADE |                                                 |
| created_at   | timestamptz | No       | now()                        |                                  | Inherits audit fields                           |
| updated_at   | timestamptz | No       | now()                        |                                  | Inherits audit fields                           |
| created_by   | uuid        | No       | auth.uid()                   |                                  | Inherits audit fields                           |
| updated_by   | uuid        | Yes      | auth.uid()                   |                                  | Inherits audit fields                           |

Bucket: `project`

- Inserted in migration with `public = TRUE`.
- RLS policies allow all actions (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) for the `authenticated` role when `bucket_id = 'project'`.
- This bucket is shared for both pre-project and project documents.

---

## Table: projects

| Attribute                 | Data Type   | Nullable | Default                      | Constraints           | Dev Notes             |
| :------------------------ | :---------- | :------- | :--------------------------- | :-------------------- | :-------------------- |
| id                        | bigint      | No       | generated always as identity | PK                    |                       |
| tutor_profile_id                  | uuid        | No       |                              | FK -> profiles.id        |                       |
| coordinator_profile_id            | uuid        | No       |                              | FK -> profiles.id        |                       |
| student_profile_id                | uuid        | No       |                              | FK -> profiles.id        |                       |
| institution_id            | bigint      | No       |                              | FK -> institutions.id |                       |
| title                     | text        | No       |                              |                       |                       |
| abstract                  | text        | Yes      |                              |                       |                       |
| pre_project_document_id   | bigint      | No       |                              | FK -> documents.id    |                       |
| pre_project_observations  | text        | Yes      |                              |                       |                       |
| pre_project_approved_at   | timestamptz | Yes      |                              |                       |                       |
| project_document_id       | bigint      | Yes      |                              | FK -> documents.id    |                       |
| project_observations      | text        | Yes      |                              |                       |                       |
| project_received_at       | timestamptz | Yes      |                              |                       |                       |
| final_project_approved_at | timestamptz | Yes      |                              |                       |                       |
| created_at                | timestamptz | No       | now()                        |                       | Inherits audit fields |
| updated_at                | timestamptz | No       | now()                        |                       | Inherits audit fields |
| created_by                | uuid        | No       | auth.uid()                   |                       | Inherits audit fields |
| updated_by                | uuid        | Yes      | auth.uid()                   |                       | Inherits audit fields |

---

## Table: invitations

| Attribute  | Data Type   | Nullable | Default                      | Constraints    | Dev Notes             |
| :--------- | :---------- | :------- | :--------------------------- | :------------- | :-------------------- |
| id         | bigint      | No       | generated always as identity | PK             |                       |
| invited_by_profile_id | uuid        | Yes      |                              | FK -> profiles.id |                       |
| email      | text        | No       |                              | UNIQUE         |                       |
| role_id    | bigint      | Yes      |                              | FK -> roles.id |                       |
| token      | text        | No       |                              |                |                       |
| is_active  | boolean     | Yes      | true                         |                |                       |
| created_at | timestamptz | No       | now()                        |                | Inherits audit fields |
| updated_at | timestamptz | No       | now()                        |                | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()                   |                | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()                   |                | Inherits audit fields |

---

## Table: audit_logs

| Attribute      | Data Type   | Nullable | Default                      | Constraints | Dev Notes                        |
| :------------- | :---------- | :------- | :--------------------------- | :---------- | :------------------------------- |
| id             | bigint      | No       | generated always as identity | PK          |                                  |
| schema_name    | text        | No       |                              |             |                                  |
| table_name     | text        | No       |                              |             | Indexed (idx_audit_logs_table)   |
| operation_name | text        | No       |                              |             |                                  |
| auth_uid       | uuid        | Yes      | auth.uid()                   |             |                                  |
| payload        | jsonb       | Yes      |                              |             |                                  |
| created_at     | timestamptz | No       | now()                        |             | Indexed (idx_audit_logs_created) |

- Row Level Security: enabled with `read_only_audit_logs` policy for `authenticated` role.
