# public.profiles

## Description

## Columns

| Name | Type | Default | Nullable | Children | Parents | Comment |
| ---- | ---- | ------- | -------- | -------- | ------- | ------- |
| created_at | timestamp with time zone | now() | false |  |  |  |
| created_by | uuid | auth.uid() | false |  |  |  |
| updated_at | timestamp with time zone | now() | false |  |  |  |
| updated_by | uuid | auth.uid() | true |  |  |  |
| id | uuid |  | false | [public.campuses](public.campuses.md) [public.faculties](public.faculties.md) [public.schools](public.schools.md) [public.students](public.students.md) [public.institutions](public.institutions.md) [public.documents](public.documents.md) [public.projects](public.projects.md) [public.invitations](public.invitations.md) |  |  |
| first_name | text |  | false |  |  |  |
| last_name | text |  | false |  |  |  |
| national_id | text |  | false |  |  |  |
| email | text |  | false |  |  |  |
| primary_contact | text |  | false |  |  |  |
| secondary_contact | text |  | true |  |  |  |
| role_id | bigint |  | true |  | [public.roles](public.roles.md) |  |

## Constraints

| Name | Type | Definition |
| ---- | ---- | ---------- |
| profiles_id_fkey | FOREIGN KEY | FOREIGN KEY (id) REFERENCES auth.users(id) |
| profiles_role_id_fkey | FOREIGN KEY | FOREIGN KEY (role_id) REFERENCES roles(id) |
| profiles_pkey | PRIMARY KEY | PRIMARY KEY (id) |
| profiles_national_id_key | UNIQUE | UNIQUE (national_id) |
| profiles_email_key | UNIQUE | UNIQUE (email) |

## Indexes

| Name | Definition |
| ---- | ---------- |
| profiles_pkey | CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id) |
| profiles_national_id_key | CREATE UNIQUE INDEX profiles_national_id_key ON public.profiles USING btree (national_id) |
| profiles_email_key | CREATE UNIQUE INDEX profiles_email_key ON public.profiles USING btree (email) |

## Triggers

| Name | Definition |
| ---- | ---------- |
| trg_audit_update_profiles | CREATE TRIGGER trg_audit_update_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION handle_audit_update() |
| audit_profiles_changes | CREATE TRIGGER audit_profiles_changes AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION log_changes() |

## Relations

```mermaid
erDiagram

"public.campuses" }o--|| "public.profiles" : "FOREIGN KEY (president_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--|| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--|| "public.profiles" : "FOREIGN KEY (dean_profile_id) REFERENCES profiles(id)"
"public.schools" }o--|| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.students" }o--|| "public.profiles" : "FOREIGN KEY (profile_id) REFERENCES profiles(id)"
"public.institutions" }o--o| "public.profiles" : "FOREIGN KEY (contact_person_profile_id) REFERENCES profiles(id)"
"public.documents" }o--|| "public.profiles" : "FOREIGN KEY (uploaded_by_profile_id) REFERENCES profiles(id) ON DELETE CASCADE"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (student_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.invitations" }o--o| "public.profiles" : "FOREIGN KEY (invited_by_profile_id) REFERENCES profiles(id)"
"public.profiles" }o--o| "public.roles" : "FOREIGN KEY (role_id) REFERENCES roles(id)"

"public.profiles" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id FK ""
  text first_name ""
  text last_name ""
  text national_id ""
  text email ""
  text primary_contact ""
  text secondary_contact ""
  bigint role_id FK ""
}
"public.campuses" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint location_id FK ""
  text campus_name ""
  uuid president_profile_id FK ""
}
"public.faculties" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint campus_id FK ""
  text faculty_name ""
  uuid dean_profile_id FK ""
  uuid coordinator_profile_id FK ""
}
"public.schools" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint faculty_id FK ""
  text school_name ""
  uuid tutor_profile_id FK ""
}
"public.students" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid profile_id FK ""
  bigint faculty_id FK ""
  bigint school_id FK ""
  semester_enum semester ""
  shift_enum shift ""
  section_enum section ""
}
"public.institutions" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint location_id FK ""
  uuid contact_person_profile_id FK ""
  text institution_name ""
}
"public.documents" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  text bucket_id FK ""
  text storage_path ""
  uuid uploaded_by_profile_id FK ""
}
"public.projects" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid tutor_profile_id FK ""
  uuid coordinator_profile_id FK ""
  uuid student_profile_id FK ""
  bigint institution_id FK ""
  text title ""
  text abstract ""
  bigint pre_project_document_id FK ""
  text pre_project_observations ""
  timestamp_with_time_zone pre_project_approved_at ""
  bigint project_document_id FK ""
  text project_observations ""
  timestamp_with_time_zone project_received_at ""
  timestamp_with_time_zone final_project_approved_at ""
}
"public.invitations" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid invited_by_profile_id FK ""
  text email ""
  bigint role_id FK ""
  text token ""
  boolean is_active ""
}
"public.roles" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  text role_name ""
  integer permission_level ""
}
```

---

> Generated by [tbls](https://github.com/k1LoW/tbls)
