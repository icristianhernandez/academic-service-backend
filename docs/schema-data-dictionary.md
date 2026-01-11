# Data Type Dictionary

### Table: audit_meta

| Attribute  | Data Type   | Nullable | Default     | Constraints | Dev Notes |
| :--------- | :---------- | :------- | :---------- | :---------- | :-------- |
| created_at | timestamptz | No       | now()       |             |           |
| created_by | uuid        | No       | auth.uid()  |             | NOT NULL, defaults to auth.uid() |
| updated_at | timestamptz | No       | now()       |             |           |
| updated_by | uuid        | Yes      | auth.uid()  |             | defaults to auth.uid() |

---

### Table: countries

| Attribute    | Data Type   | Nullable | Default           | Constraints | Dev Notes |
| :----------- | :---------- | :------- | :---------------- | :---------- | :-------- |
| id           | uuid        | No       | gen_random_uuid() | PK          |           |
| country_name | text        | No       |                   | UNIQUE      |           |
| created_at   | timestamptz | No       | now()             |             |           |
| updated_at   | timestamptz | No       | now()             |             |           |
| created_by   | uuid        | No       | auth.uid()       |             | Inherits from audit_meta (NOT NULL, defaults to auth.uid()) |
| updated_by   | uuid        | Yes      |                   |             |           |

---

### Table: states

| Attribute  | Data Type   | Nullable | Default           | Constraints        | Dev Notes |
| :--------- | :---------- | :------- | :---------------- | :----------------- | :-------- |
| id         | uuid        | No       | gen_random_uuid() | PK                 |           |
| country_id | uuid        | No       |                   | FK -> countries.id |           |
| state_name | text        | No       |                   | UNIQUE             |           |
| created_at | timestamptz | No       | now()             |                    |           |
| updated_at | timestamptz | No       | now()             |                    |           |
| created_by | uuid        | Yes      |                   |                    |           |
| updated_by | uuid        | Yes      |                   |                    |           |

---

### Table: cities

| Attribute  | Data Type   | Nullable | Default           | Constraints     | Dev Notes |
| :--------- | :---------- | :------- | :---------------- | :-------------- | :-------- |
| id         | uuid        | No       | gen_random_uuid() | PK              |           |
| state_id   | uuid        | No       |                   | FK -> states.id |           |
| city_name  | text        | No       |                   | UNIQUE          |           |
| created_at | timestamptz | No       | now()             |                 |           |
| updated_at | timestamptz | No       | now()             |                 |           |
| created_by | uuid        | Yes      |                   |                 |           |
| updated_by | uuid        | Yes      |                   |                 |           |

---

### Table: locations

| Attribute  | Data Type   | Nullable | Default           | Constraints     | Dev Notes |
| :--------- | :---------- | :------- | :---------------- | :-------------- | :-------- |
| id         | uuid        | No       | gen_random_uuid() | PK              |           |
| city_id    | uuid        | No       |                   | FK -> cities.id |           |
| address    | text        | No       |                   |                 |           |
| created_at | timestamptz | No       | now()             |                 |           |
| updated_at | timestamptz | No       | now()             |                 |           |
| created_by | uuid        | Yes      |                   |                 |           |
| updated_by | uuid        | Yes      |                   |                 |           |

---

### Table: campuses

| Attribute   | Data Type   | Nullable | Default           | Constraints        | Dev Notes |
| :---------- | :---------- | :------- | :---------------- | :----------------- | :-------- |
| id          | uuid        | No       | gen_random_uuid() | PK                 |           |
| location_id | uuid        | Yes      |                   | FK -> locations.id |           |
| campus_name | text        | No       |                   | UNIQUE             |           |
| president_id| uuid        | Yes      |                   | FK -> users.id     |           |
| created_at  | timestamptz | No       | now()             |                    |           |
| updated_at  | timestamptz | No       | now()             |                    |           |
| created_by  | uuid        | Yes      |                   |                    |           |
| updated_by  | uuid        | Yes      |                   |                    |           |

---

### Table: faculties

| Attribute    | Data Type   | Nullable | Default           | Constraints       | Dev Notes |
| :----------- | :---------- | :------- | :---------------- | :---------------- | :-------- |
| id           | uuid        | No       | gen_random_uuid() | PK                |           |
| campus_id    | uuid        | No       |                   | FK -> campuses.id |           |
| faculty_name | text        | No       |                   | UNIQUE            |           |
| dean_id      | uuid        | Yes      |                   | FK -> users.id    |           |
| coordinator_id | uuid      | Yes      |                   | FK -> users.id    |           |
| created_at   | timestamptz | No       | now()             |                   |           |
| updated_at   | timestamptz | No       | now()             |                   |           |
| created_by   | uuid        | Yes      |                   |                   |           |
| updated_by   | uuid        | Yes      |                   |                   |           |

---

### Table: schools

| Attribute   | Data Type   | Nullable | Default           | Constraints        | Dev Notes |
| :---------- | :---------- | :------- | :---------------- | :----------------- | :-------- |
| id          | uuid        | No       | gen_random_uuid() | PK                 |           |
| faculty_id  | uuid        | No       |                   | FK -> faculties.id |           |
| school_name | text        | No       |                   | UNIQUE             |           |
| tutor_id    | uuid        | Yes      |                   | FK -> users.id     |           |
| created_at  | timestamptz | No       | now()             |                    |           |
| updated_at  | timestamptz | No       | now()             |                    |           |
| created_by  | uuid        | Yes      |                   |                    |           |
| updated_by  | uuid        | Yes      |                   |                    |           |

---

### Table: roles

| Attribute        | Data Type   | Nullable | Default           | Constraints | Dev Notes |
| :--------------- | :---------- | :------- | :---------------- | :---------- | :-------- |
| id               | uuid        | No       | gen_random_uuid() | PK          |           |
| role_name        | text        | No       |                   | UNIQUE      |           |
| permission_level | integer     | No       |                   |             |           |
| created_at       | timestamptz | No       | now()             |             |           |
| updated_at       | timestamptz | No       | now()             |             |           |
| created_by       | uuid        | Yes      |                   |             |           |
| updated_by       | uuid        | Yes      |                   |             |           |

---

### Custom Types

| Type          | Values                                   | Dev Notes                |
| :------------ | :--------------------------------------- | :----------------------- |
| semester_enum | '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' | Replaces semesters table |
| section_enum  | 'A', 'B', 'C', 'D', 'E', 'F'              | Replaces sections table  |
| shift_enum    | 'MORNING', 'EVENING'                      | Replaces shifts table    |

---

### Audit & triggers

The database uses handle_audit_update trigger and enable_audit_tracking(...) to maintain updated_at and updated_by fields on writes (see supabase/migrations/20260103031448_initial-schema.sql:61-106 and 172-206). The current migration enables audit tracking for the following tables:

- countries
- states
- cities
- locations
- campuses
- faculties
- schools
- roles
- students
- users
- institutions
- projects
- documents
- projects_stages  (note: referenced name — mismatch with documented project_stages section)
- project_stage_history (note: referenced but not present in docs)
- invitations
- audit_logs

If you add/remove tables with audit tracked fields, ensure enable_audit_tracking(...) is updated accordingly.

---

### Table: users

| Attribute         | Data Type     | Nullable | Default | Constraints      | Dev Notes                        |
| :---------------- | :------------ | :------- | :------ | :--------------- | :------------------------------- |
| id                | uuid          | No       |         | PK               |                                  |
| first_name        | varchar(20)   | No       |         |                  |                                  |
| last_name         | varchar(20)   | No       |         |                  |                                  |
| national_id       | varchar(12)   | No       |         | UNIQUE           |                                  |
| email             | varchar(50)   | No       |         | UNIQUE           |                                  |
| primary_contact   | text          | No       |         |                  |                                  |
| secondary_contact | text          | Yes      |         |                  |                                  |
| role_id           | uuid          | Yes      |         | FK -> roles.id   |                                  |

---

### Table: students

| Attribute   | Data Type     | Nullable | Default | Constraints           | Dev Notes |
| :---------- | :------------ | :------- | :------ | :-------------------- | :-------- |
| user_id     | uuid          | No       |         | PK -> users.id        |          |
| faculty_id  | uuid          | Yes      |         | FK -> faculties.id    |          |
| school_id   | uuid          | Yes      |         | FK -> schools.id      |          |
| semester    | semester_enum | Yes      |         |                       |          |
| shift       | shift_enum    | Yes      |         |                       |          |
| section     | section_enum  | Yes      |         |                       |          |
| created_at  | timestamptz   | No       | now()   |                       |          |
| updated_at  | timestamptz   | No       | now()   |                       |          |
| created_by  | uuid          | Yes      |         |                       |          |
| updated_by  | uuid          | Yes      |         |                       |          |
| Dev Notes:   | Students table: audit tracked. Note: indexes on faculty_id and school_id were referenced in docs but are not present in migration; consider adding them if needed. | |  |  |  |

---

### Table: institutions

| Attribute         | Data Type   | Nullable | Default           | Constraints        | Dev Notes |
| :---------------- | :---------- | :------- | :---------------- | :----------------- | :-------- |
| id                | uuid        | No       | gen_random_uuid() | PK                 |           |
| location_id       | uuid        | Yes      |                   | FK -> locations.id |           |
| contact_person_id | uuid        | Yes      |                   | FK -> users.id     |           |
| institution_name  | text        | No       |                   | UNIQUE             |           |
| created_at        | timestamptz | No       | now()             |                    |           |
| updated_at        | timestamptz | No       | now()             |                    |           |
| created_by        | uuid        | Yes      |                   |                    |           |
| updated_by        | uuid        | Yes      |                   |                    |           |

---

### Table: projects

| Attribute                | Data Type   | Nullable | Default           | Constraints           | Dev Notes |
| :----------------------- | :---------- | :------- | :---------------- | :-------------------- | :-------- |
| id                       | uuid        | No       | gen_random_uuid() | PK                    |           |
| tutor_id                 | uuid        | Yes      |                   | FK -> users.id        |           |
| coordinator_id           | uuid        | Yes      |                   | FK -> users.id        |           |
| student_id               | uuid        | Yes      |                   | FK -> users.id        |           |
| institution_id           | uuid        | Yes      |                   | FK -> institutions.id |           |
| title                    | text        | No       |                   |                       |           |
| abstract                 | text        | Yes      |                   |                       |           |
| pre_project_document_id  | uuid        | Yes      |                   | FK -> documents.id    |           |
| pre_project_observations | text        | Yes      |                   |                       |           |
| pre_project_approved_at  | timestamptz | Yes      | NULL              |                       |           |
| project_document_id      | uuid        | Yes      |                   | FK -> documents.id    |           |
| project_observations     | text        | Yes      |                   |                       |           |
| project_received_at      | timestamptz | Yes      | NULL              |                       |           |
| final_project_approved_at| timestamptz | Yes      |                   |                       |           |
| created_at               | timestamptz | No       | now()             |                       |           |
| updated_at               | timestamptz | No       | now()             |                       |           |
| created_by               | uuid        | Yes      |                   |                       |           |
| updated_by               | uuid        | Yes      |                   |                       |           |

---

### Table: documents

| Attribute    | Data Type   | Nullable | Default           | Constraints                      | Dev Notes                                                       |
| :----------- | :---------- | :------- | :---------------- | :------------------------------- | :-------------------------------------------------------------- |
| id           | uuid        | No       | gen_random_uuid() | PK                               | Table note: can have display name, size, type metadata (unsure) |
| storage_path | text        | No       |                   | UNIQUE                           |                                                                 |
| uploaded_by  | uuid        | No       |                   | FK -> users.id ON DELETE CASCADE |                                                                 |
| created_at   | timestamptz | No       | now()             |                                  |                                                                 |
| updated_at   | timestamptz | No       | now()             |                                  |                                                                 |
| created_by   | uuid        | Yes      |                   |                                  |                                                                 |
| updated_by   | uuid        | Yes      |                   |                                  |                                                                 |

---

### Table: stages

| Attribute  | Data Type   | Nullable | Default           | Constraints | Dev Notes                          |
| :--------- | :---------- | :------- | :---------------- | :---------- | :--------------------------------- |
| id         | uuid        | No       | gen_random_uuid() | PK          | Table note: rethink workflow/names |
| stage_name | text        | No       |                   | UNIQUE      |                                    |
| created_at | timestamptz | No       | now()             |             |                                    |
| updated_at | timestamptz | No       | now()             |             |                                    |
| created_by | uuid        | Yes      |                   |             |                                    |
| updated_by | uuid        | Yes      |                   |             |                                    |

---

### Table: project_stages

**Note:** The project_stages table was previously part of the schema but is not created in the current migration. The migration's enable_audit_tracking call references 'projects_stages' and 'project_stage_history' (supabase/migrations/20260103031448_initial-schema.sql:208-226), indicating a naming mismatch: the audit list references pluralized/alternate table names. Action required: decide whether to restore/rename the tables in the migration to match this documented schema or to remove these entries from enable_audit_tracking. For now, this section remains documented for reference.

| Attribute    | Data Type   | Nullable | Default           | Constraints                         | Dev Notes |
| :----------- | :---------- | :------- | :---------------- | :---------------------------------- | :-------- |
| id           | uuid        | No       | gen_random_uuid() | PK                                  |           |
| project_id   | uuid        | No       |                   | FK -> projects.id ON DELETE CASCADE |           |
| stage_id     | uuid        | No       |                   | FK -> stages.id                     |           |
| document_id  | uuid        | Yes      |                   | FK -> documents.id                  |           |
| observations | text        | Yes      |                   |                                     |           |
| reached_at   | timestamptz | No       | now()             |                                     |           |
| created_at   | timestamptz | No       | now()             |                                     |           |
| updated_at   | timestamptz | No       | now()             |                                     |           |
| created_by   | uuid        | Yes      |                   |                                     |           |
| updated_by   | uuid        | Yes      |                   |                                     |           |

---

### Table: invitations

| Attribute  | Data Type   | Nullable | Default           | Constraints    | Dev Notes |
| :--------- | :---------- | :------- | :---------------- | :------------- | :-------- |
| id         | uuid        | No       | gen_random_uuid() | PK             |           |
| invited_by | uuid        | Yes      |                   | FK -> users.id |           |
| email      | text        | No       |                   | UNIQUE         |           |
| role_id    | uuid        | Yes      |                   | FK -> roles.id |           |
| token      | text        | No       |                   |                |           |
| is_active  | boolean     | Yes      | true              |                |           |
| created_at | timestamptz | No       | now()             |                |           |
| updated_at | timestamptz | No       | now()             |                |           |
| created_by | uuid        | Yes      |                   |                |           |
| updated_by | uuid        | Yes      |                   |                |           |

---

### Table: audit_logs

| Attribute      | Data Type   | Nullable | Default           | Constraints | Dev Notes |
| :------------- | :---------- | :------- | :---------------- | :---------- | :-------- |
| id             | uuid        | No       | gen_random_uuid() | PK          |           |
| table_name     | text        | No       |                   |             |           |
| operation_type | text        | No       |                   |             |           |
| record_id      | uuid        | Yes      |                   |             |           |
| old_values     | jsonb       | Yes      |                   |             |           |
| new_values     | jsonb       | Yes      |                   |             |           |
| created_at     | timestamptz | No       | now()             |             |           |
| updated_at     | timestamptz | No       | now()             |             |           |
| created_by     | uuid        | Yes      |                   |             |           |
| updated_by     | uuid        | Yes      |                   |             |           |

---

