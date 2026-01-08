# Data Type Dictionary

### Table: audit_meta

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: countries

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| country_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: states

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| country_id | uuid | No |  | FK -> countries.id |  |
| state_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: cities

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| state_id | uuid | No |  | FK -> states.id |  |
| city_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: locations

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| city_id | uuid | No |  | FK -> cities.id |  |
| address | text | No |  |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: campuses

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| location_id | uuid | Yes |  | FK -> locations.id |  |
| campus_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: faculties

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| campus_id | uuid | No |  | FK -> campuses.id |  |
| faculty_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: schools

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| faculty_id | uuid | No |  | FK -> faculties.id |  |
| school_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: roles

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| role_name | text | No |  | UNIQUE |  |
| permission_level | integer | No |  |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: semesters

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| semester_name | varchar(12) | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: shifts

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| shift_name | varchar(12) | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: sections

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| section_name | varchar(12) | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: users

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No |  | PK |  |
| first_name | varchar(20) | No |  |  |  |
| last_name | varchar(20) | No |  |  |  |
| national_id | varchar(12) | No |  | UNIQUE |  |
| email | varchar(50) | No |  | UNIQUE |  |
| primary_contact | text | No |  |  |  |
| secondary_contact | text | Yes |  |  |  |
| role_id | uuid | Yes |  | FK -> roles.id |  |
| school_id | uuid | Yes |  | FK -> schools.id |  |
| semester_id | uuid | Yes |  | FK -> semesters.id |  |
| shift_id | uuid | Yes |  | FK -> shifts.id |  |
| section_id | uuid | Yes |  | FK -> sections.id |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: institutions

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| location_id | uuid | Yes |  | FK -> locations.id |  |
| contact_person_id | uuid | Yes |  | FK -> users.id |  |
| institution_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: projects

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| tutor_id | uuid | Yes |  | FK -> users.id |  |
| coordinator_id | uuid | Yes |  | FK -> users.id |  |
| student_id | uuid | Yes |  | FK -> users.id |  |
| institution_id | uuid | Yes |  | FK -> institutions.id |  |
| title | text | No |  |  |  |
| general_objective | text | No |  |  |  |
| specific_objective_1 | text | Yes |  |  |  |
| specific_objective_2 | text | Yes |  |  |  |
| specific_objective_3 | text | Yes |  |  |  |
| specific_objective_4 | text | Yes |  |  |  |
| justification | text | Yes |  |  |  |
| introduction | text | Yes |  |  |  |
| abstract | text | Yes |  |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: documents

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK | Table note: can have display name, size, type metadata (unsure) |
| storage_path | text | No |  | UNIQUE |  |
| uploaded_by | uuid | No |  | FK -> users.id ON DELETE CASCADE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: stages

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK | Table note: rethink workflow/names |
| stage_name | text | No |  | UNIQUE |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: project_stages

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| project_id | uuid | No |  | FK -> projects.id ON DELETE CASCADE |  |
| stage_id | uuid | No |  | FK -> stages.id |  |
| document_id | uuid | Yes |  | FK -> documents.id |  |
| observations | text | Yes |  |  |  |
| reached_at | timestamptz | No | now() |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: invitations

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| invited_by | uuid | Yes |  | FK -> users.id |  |
| email | text | No |  | UNIQUE |  |
| role_id | uuid | Yes |  | FK -> roles.id |  |
| token | text | No |  |  |  |
| is_active | boolean | Yes | true |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Table: audit_logs

| Attribute   | Data Type | Nullable | Default | Constraints | Dev Notes |
| :---------- | :-------- | :------- | :------ | :---------- | :-------- |
| id | uuid | No | gen_random_uuid() | PK |  |
| table_name | text | No |  |  |  |
| operation_type | text | No |  |  |  |
| record_id | uuid | Yes |  |  |  |
| old_values | jsonb | Yes |  |  |  |
| new_values | jsonb | Yes |  |  |  |
| created_at | timestamptz | No | now() |  |  |
| updated_at | timestamptz | No | now() |  |  |
| created_by | uuid | Yes |  |  |  |
| updated_by | uuid | Yes |  |  |  |

---

### Custom Types

None defined in this migration.
