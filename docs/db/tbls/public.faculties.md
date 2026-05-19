# public.faculties

## Description

## Columns

| Name | Type | Default | Nullable | Children | Parents | Comment |
| ---- | ---- | ------- | -------- | -------- | ------- | ------- |
| created_at | timestamp with time zone | now() | false |  |  |  |
| created_by | uuid | auth.uid() | false |  |  |  |
| updated_at | timestamp with time zone | now() | false |  |  |  |
| updated_by | uuid | auth.uid() | true |  |  |  |
| id | bigint |  | false | [public.schools](public.schools.md) [public.invitations](public.invitations.md) |  |  |
| campus_id | bigint |  | false |  | [public.campuses](public.campuses.md) |  |
| faculty_name | text |  | false |  |  |  |
| reports_required_count | smallint | 3 | false |  |  |  |
| min_members | smallint | 1 | false |  |  |  |
| max_members | smallint | 1 | false |  |  |  |
| dean_profile_id | uuid |  | true |  | [public.profiles](public.profiles.md) |  |
| coordinator_profile_id | uuid |  | true |  | [public.profiles](public.profiles.md) |  |

## Constraints

| Name | Type | Definition |
| ---- | ---- | ---------- |
| faculties_check | CHECK | CHECK ((min_members <= max_members)) |
| faculties_max_members_check | CHECK | CHECK (((max_members >= 1) AND (max_members <= 20))) |
| faculties_min_members_check | CHECK | CHECK (((min_members >= 1) AND (min_members <= 20))) |
| faculties_reports_required_count_check | CHECK | CHECK (((reports_required_count >= 0) AND (reports_required_count <= 10))) |
| faculties_coordinator_profile_id_fkey | FOREIGN KEY | FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id) |
| faculties_dean_profile_id_fkey | FOREIGN KEY | FOREIGN KEY (dean_profile_id) REFERENCES profiles(id) |
| faculties_campus_id_fkey | FOREIGN KEY | FOREIGN KEY (campus_id) REFERENCES campuses(id) |
| faculties_pkey | PRIMARY KEY | PRIMARY KEY (id) |
| faculties_faculty_name_key | UNIQUE | UNIQUE (faculty_name) |

## Indexes

| Name | Definition |
| ---- | ---------- |
| faculties_pkey | CREATE UNIQUE INDEX faculties_pkey ON public.faculties USING btree (id) |
| faculties_faculty_name_key | CREATE UNIQUE INDEX faculties_faculty_name_key ON public.faculties USING btree (faculty_name) |

## Triggers

| Name | Definition |
| ---- | ---------- |
| audit_faculties_changes | CREATE TRIGGER audit_faculties_changes AFTER INSERT OR DELETE OR UPDATE ON public.faculties FOR EACH ROW EXECUTE FUNCTION log_changes() |
| trg_audit_update_faculties | CREATE TRIGGER trg_audit_update_faculties BEFORE UPDATE ON public.faculties FOR EACH ROW EXECUTE FUNCTION handle_audit_update() |

## Relations

```mermaid
erDiagram

"public.schools" }o--|| "public.faculties" : "FOREIGN KEY (faculty_id) REFERENCES faculties(id)"
"public.invitations" }o--o| "public.faculties" : "FOREIGN KEY (faculty_to_be_dean) REFERENCES faculties(id)"
"public.faculties" }o--|| "public.campuses" : "FOREIGN KEY (campus_id) REFERENCES campuses(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (dean_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"

"public.faculties" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint campus_id FK ""
  text faculty_name ""
  smallint reports_required_count ""
  smallint min_members ""
  smallint max_members ""
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
  uuid subcoordinator_profile_id FK ""
}
"public.invitations" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  uuid invited_by_profile_id FK ""
  bigint__ faculties_to_be_coordinator ""
  bigint__ schools_to_be_subcoordinator ""
  bigint campus_to_be_rector FK ""
  bigint campus_to_be_vicerector_administrativo FK ""
  bigint campus_to_be_vicerector_academico FK ""
  bigint faculty_to_be_dean FK ""
  bigint role_to_have_id FK ""
  text email ""
  text hashed_token ""
  integer failed_attemps ""
  timestamp_with_time_zone token_expires_at ""
  timestamp_with_time_zone reclaimed_at ""
}
"public.campuses" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint location_id FK ""
  text campus_name ""
  uuid rector_profile_id FK ""
  uuid vicerector_administrativo_profile_id FK ""
  uuid vicerector_academico_profile_id FK ""
}
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
```

---

> Generated by [tbls](https://github.com/k1LoW/tbls)
