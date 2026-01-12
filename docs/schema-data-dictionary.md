# Data Type Dictionary

## Custom Types

| Type          | Values                                            | Dev Notes                  |
| :------------ | :------------------------------------------------ | :------------------------- |
| semester_enum | '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' | Academic semester number   |
| section_enum  | 'A', 'B', 'C', 'D', 'E', 'F'                      | Cohort/section designation |
| shift_enum    | 'MORNING', 'EVENING'                              | Student shift              |

---

## Audit Base & Triggers

- `audit_meta` base columns: `created_at timestamptz NOT NULL DEFAULT now()`, `created_by uuid NOT NULL DEFAULT auth.uid()`, `updated_at timestamptz NOT NULL DEFAULT now()`, `updated_by uuid DEFAULT auth.uid()`.
- Tables created with `LIKE audit_meta INCLUDING ALL` inherit these columns and defaults.
- Trigger function `handle_audit_update` sets `updated_at` and `updated_by` on updates.
- `enable_audit_tracking(...)` is enabled for: countries, states, cities, locations, campuses, faculties, schools, roles, students, users, institutions, projects, documents, invitations, audit_logs. If you add/remove tracked tables, update the migration accordingly.

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

| Attribute    | Data Type   | Nullable | Default           | Constraints | Dev Notes             |
| :----------- | :---------- | :------- | :---------------- | :---------- | :-------------------- |
| id           | uuid        | No       | gen_random_uuid() | PK          |                       |
| country_name | text        | No       |                   | UNIQUE      |                       |
| created_at   | timestamptz | No       | now()             |             | Inherits audit fields |
| updated_at   | timestamptz | No       | now()             |             | Inherits audit fields |
| created_by   | uuid        | No       | auth.uid()        |             | Inherits audit fields |
| updated_by   | uuid        | Yes      | auth.uid()        |             | Inherits audit fields |

---

## Table: states

| Attribute  | Data Type   | Nullable | Default           | Constraints        | Dev Notes             |
| :--------- | :---------- | :------- | :---------------- | :----------------- | :-------------------- |
| id         | uuid        | No       | gen_random_uuid() | PK                 |                       |
| country_id | uuid        | No       |                   | FK -> countries.id |                       |
| state_name | text        | No       |                   | UNIQUE             |                       |
| created_at | timestamptz | No       | now()             |                    | Inherits audit fields |
| updated_at | timestamptz | No       | now()             |                    | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()        |                    | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()        |                    | Inherits audit fields |

---

## Table: cities

| Attribute  | Data Type   | Nullable | Default           | Constraints     | Dev Notes             |
| :--------- | :---------- | :------- | :---------------- | :-------------- | :-------------------- |
| id         | uuid        | No       | gen_random_uuid() | PK              |                       |
| state_id   | uuid        | No       |                   | FK -> states.id |                       |
| city_name  | text        | No       |                   | UNIQUE          |                       |
| created_at | timestamptz | No       | now()             |                 | Inherits audit fields |
| updated_at | timestamptz | No       | now()             |                 | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()        |                 | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()        |                 | Inherits audit fields |

---

## Table: locations

| Attribute  | Data Type   | Nullable | Default           | Constraints     | Dev Notes             |
| :--------- | :---------- | :------- | :---------------- | :-------------- | :-------------------- |
| id         | uuid        | No       | gen_random_uuid() | PK              |                       |
| city_id    | uuid        | No       |                   | FK -> cities.id |                       |
| address    | text        | No       |                   |                 |                       |
| created_at | timestamptz | No       | now()             |                 | Inherits audit fields |
| updated_at | timestamptz | No       | now()             |                 | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()        |                 | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()        |                 | Inherits audit fields |

---

## Table: roles

| Attribute        | Data Type   | Nullable | Default           | Constraints | Dev Notes             |
| :--------------- | :---------- | :------- | :---------------- | :---------- | :-------------------- |
| id               | uuid        | No       | gen_random_uuid() | PK          |                       |
| role_name        | text        | No       |                   | UNIQUE      |                       |
| permission_level | integer     | No       |                   |             |                       |
| created_at       | timestamptz | No       | now()             |             | Inherits audit fields |
| updated_at       | timestamptz | No       | now()             |             | Inherits audit fields |
| created_by       | uuid        | No       | auth.uid()        |             | Inherits audit fields |
| updated_by       | uuid        | Yes      | auth.uid()        |             | Inherits audit fields |

---

## Table: users

| Attribute         | Data Type   | Nullable | Default    | Constraints    | Dev Notes             |
| :---------------- | :---------- | :------- | :--------- | :------------- | :-------------------- |
| id                | uuid        | No       |            | PK             | Supabase auth user id |
| first_name        | varchar(20) | No       |            |                |                       |
| last_name         | varchar(20) | No       |            |                |                       |
| national_id       | varchar(12) | No       |            | UNIQUE         |                       |
| email             | varchar(50) | No       |            | UNIQUE         |                       |
| primary_contact   | text        | No       |            |                |                       |
| secondary_contact | text        | Yes      |            |                |                       |
| role_id           | uuid        | Yes      |            | FK -> roles.id |                       |
| created_at        | timestamptz | No       | now()      |                | Inherits audit fields |
| updated_at        | timestamptz | No       | now()      |                | Inherits audit fields |
| created_by        | uuid        | No       | auth.uid() |                | Inherits audit fields |
| updated_by        | uuid        | Yes      | auth.uid() |                | Inherits audit fields |

---

## Table: campuses

| Attribute    | Data Type   | Nullable | Default           | Constraints        | Dev Notes             |
| :----------- | :---------- | :------- | :---------------- | :----------------- | :-------------------- |
| id           | uuid        | No       | gen_random_uuid() | PK                 |                       |
| location_id  | uuid        | Yes      |                   | FK -> locations.id |                       |
| campus_name  | text        | No       |                   | UNIQUE             |                       |
| president_id | uuid        | Yes      |                   | FK -> users.id     |                       |
| created_at   | timestamptz | No       | now()             |                    | Inherits audit fields |
| updated_at   | timestamptz | No       | now()             |                    | Inherits audit fields |
| created_by   | uuid        | No       | auth.uid()        |                    | Inherits audit fields |
| updated_by   | uuid        | Yes      | auth.uid()        |                    | Inherits audit fields |

---

## Table: faculties

| Attribute      | Data Type   | Nullable | Default           | Constraints       | Dev Notes             |
| :------------- | :---------- | :------- | :---------------- | :---------------- | :-------------------- |
| id             | uuid        | No       | gen_random_uuid() | PK                |                       |
| campus_id      | uuid        | No       |                   | FK -> campuses.id |                       |
| faculty_name   | text        | No       |                   | UNIQUE            |                       |
| dean_id        | uuid        | Yes      |                   | FK -> users.id    |                       |
| coordinator_id | uuid        | Yes      |                   | FK -> users.id    |                       |
| created_at     | timestamptz | No       | now()             |                   | Inherits audit fields |
| updated_at     | timestamptz | No       | now()             |                   | Inherits audit fields |
| created_by     | uuid        | No       | auth.uid()        |                   | Inherits audit fields |
| updated_by     | uuid        | Yes      | auth.uid()        |                   | Inherits audit fields |

---

## Table: schools

| Attribute   | Data Type   | Nullable | Default           | Constraints        | Dev Notes             |
| :---------- | :---------- | :------- | :---------------- | :----------------- | :-------------------- |
| id          | uuid        | No       | gen_random_uuid() | PK                 |                       |
| faculty_id  | uuid        | No       |                   | FK -> faculties.id |                       |
| school_name | text        | No       |                   | UNIQUE             |                       |
| tutor_id    | uuid        | Yes      |                   | FK -> users.id     |                       |
| created_at  | timestamptz | No       | now()             |                    | Inherits audit fields |
| updated_at  | timestamptz | No       | now()             |                    | Inherits audit fields |
| created_by  | uuid        | No       | auth.uid()        |                    | Inherits audit fields |
| updated_by  | uuid        | Yes      | auth.uid()        |                    | Inherits audit fields |

---

## Table: students

| Attribute  | Data Type     | Nullable | Default    | Constraints                          | Dev Notes             |
| :--------- | :------------ | :------- | :--------- | :----------------------------------- | :-------------------- |
| user_id    | uuid          | No       |            | PK, FK -> users.id ON DELETE CASCADE |                       |
| faculty_id | uuid          | Yes      |            | FK -> faculties.id                   |                       |
| school_id  | uuid          | Yes      |            | FK -> schools.id                     |                       |
| semester   | semester_enum | Yes      |            |                                      |                       |
| shift      | shift_enum    | Yes      |            |                                      |                       |
| section    | section_enum  | Yes      |            |                                      |                       |
| created_at | timestamptz   | No       | now()      |                                      | Inherits audit fields |
| updated_at | timestamptz   | No       | now()      |                                      | Inherits audit fields |
| created_by | uuid          | No       | auth.uid() |                                      | Inherits audit fields |
| updated_by | uuid          | Yes      | auth.uid() |                                      | Inherits audit fields |

---

## Table: institutions

| Attribute         | Data Type   | Nullable | Default           | Constraints        | Dev Notes             |
| :---------------- | :---------- | :------- | :---------------- | :----------------- | :-------------------- |
| id                | uuid        | No       | gen_random_uuid() | PK                 |                       |
| location_id       | uuid        | Yes      |                   | FK -> locations.id |                       |
| contact_person_id | uuid        | Yes      |                   | FK -> users.id     |                       |
| institution_name  | text        | No       |                   | UNIQUE             |                       |
| created_at        | timestamptz | No       | now()             |                    | Inherits audit fields |
| updated_at        | timestamptz | No       | now()             |                    | Inherits audit fields |
| created_by        | uuid        | No       | auth.uid()        |                    | Inherits audit fields |
| updated_by        | uuid        | Yes      | auth.uid()        |                    | Inherits audit fields |

---

## Table: documents

| Attribute    | Data Type   | Nullable | Default           | Constraints                      | Dev Notes                                       |
| :----------- | :---------- | :------- | :---------------- | :------------------------------- | :---------------------------------------------- |
| id           | uuid        | No       | gen_random_uuid() | PK                               | Can store display/name/size/type metadata later |
| storage_path | text        | No       |                   | UNIQUE                           |                                                 |
| uploaded_by  | uuid        | No       |                   | FK -> users.id ON DELETE CASCADE |                                                 |
| created_at   | timestamptz | No       | now()             |                                  | Inherits audit fields                           |
| updated_at   | timestamptz | No       | now()             |                                  | Inherits audit fields                           |
| created_by   | uuid        | No       | auth.uid()        |                                  | Inherits audit fields                           |
| updated_by   | uuid        | Yes      | auth.uid()        |                                  | Inherits audit fields                           |

---

## Table: projects

| Attribute                 | Data Type   | Nullable | Default           | Constraints           | Dev Notes             |
| :------------------------ | :---------- | :------- | :---------------- | :-------------------- | :-------------------- |
| id                        | uuid        | No       | gen_random_uuid() | PK                    |                       |
| tutor_id                  | uuid        | Yes      |                   | FK -> users.id        |                       |
| coordinator_id            | uuid        | Yes      |                   | FK -> users.id        |                       |
| student_id                | uuid        | Yes      |                   | FK -> users.id        |                       |
| institution_id            | uuid        | Yes      |                   | FK -> institutions.id |                       |
| title                     | text        | No       |                   |                       |                       |
| abstract                  | text        | Yes      |                   |                       |                       |
| pre_project_document_id   | uuid        | Yes      |                   | FK -> documents.id    |                       |
| pre_project_observations  | text        | Yes      |                   |                       |                       |
| pre_project_approved_at   | timestamptz | Yes      | NULL              |                       |                       |
| project_document_id       | uuid        | Yes      |                   | FK -> documents.id    |                       |
| project_observations      | text        | Yes      |                   |                       |                       |
| project_received_at       | timestamptz | Yes      | NULL              |                       |                       |
| final_project_approved_at | timestamptz | Yes      |                   |                       |                       |
| created_at                | timestamptz | No       | now()             |                       | Inherits audit fields |
| updated_at                | timestamptz | No       | now()             |                       | Inherits audit fields |
| created_by                | uuid        | No       | auth.uid()        |                       | Inherits audit fields |
| updated_by                | uuid        | Yes      | auth.uid()        |                       | Inherits audit fields |

---

## Table: invitations

| Attribute  | Data Type   | Nullable | Default           | Constraints    | Dev Notes             |
| :--------- | :---------- | :------- | :---------------- | :------------- | :-------------------- |
| id         | uuid        | No       | gen_random_uuid() | PK             |                       |
| invited_by | uuid        | Yes      |                   | FK -> users.id |                       |
| email      | text        | No       |                   | UNIQUE         |                       |
| role_id    | uuid        | Yes      |                   | FK -> roles.id |                       |
| token      | text        | No       |                   |                |                       |
| is_active  | boolean     | Yes      | true              |                |                       |
| created_at | timestamptz | No       | now()             |                | Inherits audit fields |
| updated_at | timestamptz | No       | now()             |                | Inherits audit fields |
| created_by | uuid        | No       | auth.uid()        |                | Inherits audit fields |
| updated_by | uuid        | Yes      | auth.uid()        |                | Inherits audit fields |

---

## Table: audit_logs

| Attribute      | Data Type   | Nullable | Default           | Constraints | Dev Notes             |
| :------------- | :---------- | :------- | :---------------- | :---------- | :-------------------- |
| id             | uuid        | No       | gen_random_uuid() | PK          |                       |
| table_name     | text        | No       |                   |             |                       |
| operation_type | text        | No       |                   |             |                       |
| record_id      | uuid        | Yes      |                   |             |                       |
| old_values     | jsonb       | Yes      |                   |             |                       |
| new_values     | jsonb       | Yes      |                   |             |                       |
| created_at     | timestamptz | No       | now()             |             | Inherits audit fields |
| updated_at     | timestamptz | No       | now()             |             | Inherits audit fields |
| created_by     | uuid        | No       | auth.uid()        |             | Inherits audit fields |
| updated_by     | uuid        | Yes      | auth.uid()        |             | Inherits audit fields |

---

## Removed / Deprecated (for reference)

- Previous documentation sections for `stages`, `project_stages`, and `project_stage_history` are removed here because the current migration does not create these tables. If they should exist, add them back to migrations and to `enable_audit_tracking`.
