# public.profiles

## Description

## Columns

| Name | Type | Default | Nullable | Children | Parents | Comment |
| ---- | ---- | ------- | -------- | -------- | ------- | ------- |
| created_at | timestamp with time zone | now() | false |  |  |  |
| created_by | uuid | auth.uid() | false |  |  |  |
| updated_at | timestamp with time zone | now() | false |  |  |  |
| updated_by | uuid | auth.uid() | true |  |  |  |
| id | uuid |  | false | [public.campuses](public.campuses.md) [public.faculties](public.faculties.md) [public.schools](public.schools.md) [public.invitations](public.invitations.md) [public.students](public.students.md) [public.documents](public.documents.md) [public.institutions](public.institutions.md) [public.projects](public.projects.md) [public.project_progress](public.project_progress.md) [public.notifications_events](public.notifications_events.md) [public.notification_recipients](public.notification_recipients.md) |  |  |
| user_names | text |  | false |  |  |  |
| user_last_names | text |  | false |  |  |  |
| national_id | text |  | false |  |  |  |
| primary_contact | text |  | false |  |  |  |
| secondary_contact | text |  | true |  |  |  |
| email | text |  | false |  |  |  |
| role_id | bigint |  | true |  | [public.roles](public.roles.md) |  |
| profile_photo_path | text |  | true |  |  |  |
| email_notifications_enabled | boolean | true | true |  |  |  |
| inbox_notifications_enabled | boolean | true | true |  |  |  |
| disabled_at | timestamp with time zone |  | true |  |  |  |

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
| audit_profiles_changes | CREATE TRIGGER audit_profiles_changes AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION log_changes() |
| trg_audit_update_profiles | CREATE TRIGGER trg_audit_update_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION handle_audit_update() |

## Relations

```mermaid
erDiagram

"public.campuses" }o--o| "public.profiles" : "FOREIGN KEY (president_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (dean_profile_id) REFERENCES profiles(id)"
"public.schools" }o--o| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.invitations" }o--o| "public.profiles" : "FOREIGN KEY (invited_by_profile_id) REFERENCES profiles(id)"
"public.students" }o--|| "public.profiles" : "FOREIGN KEY (profile_id) REFERENCES profiles(id)"
"public.documents" }o--|| "public.profiles" : "FOREIGN KEY (uploaded_by_profile_id) REFERENCES profiles(id) ON DELETE CASCADE"
"public.institutions" }o--o| "public.profiles" : "FOREIGN KEY (contact_person_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (student_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.project_progress" }o--|| "public.profiles" : "FOREIGN KEY (author_profile_id) REFERENCES profiles(id)"
"public.notifications_events" }o--o| "public.profiles" : "FOREIGN KEY (actor_id) REFERENCES profiles(id)"
"public.notification_recipients" }o--|| "public.profiles" : "FOREIGN KEY (recipient_id) REFERENCES profiles(id)"
"public.profiles" }o--o| "public.roles" : "FOREIGN KEY (role_id) REFERENCES roles(id)"

"public.profiles" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id FK ""
  text user_names ""
  text user_last_names ""
  text national_id ""
  text primary_contact ""
  text secondary_contact ""
  text email ""
  bigint role_id FK ""
  text profile_photo_path ""
  boolean email_notifications_enabled ""
  boolean inbox_notifications_enabled ""
  timestamp_with_time_zone disabled_at ""
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
  smallint reports_required_count ""
  uuid dean_profile_id FK ""
  uuid coordinator_profile_id FK ""
}
"public.schools" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint degree_id FK ""
  bigint faculty_id FK ""
  uuid tutor_profile_id FK ""
}
"public.invitations" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid invited_by_profile_id FK ""
  bigint faculty_to_be_coordinator FK ""
  bigint school_to_be_tutor FK ""
  bigint role_to_have_id FK ""
  text email ""
  text hashed_token ""
  integer failed_attemps ""
  timestamp_with_time_zone token_expires_at ""
  timestamp_with_time_zone reclaimed_at ""
}
"public.students" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid profile_id FK ""
  bigint school_id FK ""
  semester_enum semester ""
  shift_enum shift ""
  section_enum section ""
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
}
"public.project_progress" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint project_id FK ""
  bigint project_phase_id FK ""
  bigint project_state_id FK ""
  uuid author_profile_id FK ""
  bigint document_id FK ""
  text observations ""
}
"public.notifications_events" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint notification_type_id FK ""
  text source_kind ""
  text operation_kind ""
  text source_record_id ""
  jsonb payload ""
  uuid actor_id FK ""
  notification_event_status_enum processed_status ""
  integer retry_count ""
  timestamp_with_time_zone processed_at ""
  text error_message ""
  timestamp_with_time_zone last_attempt ""
}
"public.notification_recipients" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint notification_id FK ""
  uuid recipient_id FK ""
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
