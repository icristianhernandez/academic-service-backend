# postgres

## Tables

| Name | Columns | Comment | Type |
| ---- | ------- | ------- | ---- |
| [public.audit_meta](public.audit_meta.md) | 4 |  | BASE TABLE |
| [public.audit_logs](public.audit_logs.md) | 9 |  | BASE TABLE |
| [public.roles](public.roles.md) | 7 |  | BASE TABLE |
| [public.profiles](public.profiles.md) | 12 |  | BASE TABLE |
| [public.countries](public.countries.md) | 6 |  | BASE TABLE |
| [public.states](public.states.md) | 7 |  | BASE TABLE |
| [public.cities](public.cities.md) | 7 |  | BASE TABLE |
| [public.locations](public.locations.md) | 7 |  | BASE TABLE |
| [public.campuses](public.campuses.md) | 8 |  | BASE TABLE |
| [public.faculties](public.faculties.md) | 9 |  | BASE TABLE |
| [public.degrees](public.degrees.md) | 6 |  | BASE TABLE |
| [public.schools](public.schools.md) | 8 |  | BASE TABLE |
| [public.invitations](public.invitations.md) | 12 |  | BASE TABLE |
| [public.students](public.students.md) | 10 |  | BASE TABLE |
| [public.institutions](public.institutions.md) | 8 |  | BASE TABLE |
| [public.documents](public.documents.md) | 8 |  | BASE TABLE |
| [public.projects_states](public.projects_states.md) | 7 |  | BASE TABLE |
| [public.projects_states_flow](public.projects_states_flow.md) | 7 |  | BASE TABLE |
| [public.projects](public.projects.md) | 15 |  | BASE TABLE |
| [public.notification_preferences](public.notification_preferences.md) | 9 |  | BASE TABLE |
| [public.notification_events](public.notification_events.md) | 12 |  | BASE TABLE |
| [public.notification_deliveries](public.notification_deliveries.md) | 12 |  | BASE TABLE |
| [public.notifications](public.notifications.md) | 10 |  | BASE TABLE |

## Stored procedures and functions

| Name | ReturnType | Arguments | Type |
| ---- | ------- | ------- | ---- |
| public.plpgsql_check_function_tb | record | funcoid regprocedure, relid regclass DEFAULT 0, fatal_errors boolean DEFAULT true, other_warnings boolean DEFAULT true, performance_warnings boolean DEFAULT false, extra_warnings boolean DEFAULT true, security_warnings boolean DEFAULT false, compatibility_warnings boolean DEFAULT false, oldtable name DEFAULT NULL::name, newtable name DEFAULT NULL::name, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype, without_warnings boolean DEFAULT false, all_warnings boolean DEFAULT false, use_incomment_options boolean DEFAULT true, incomment_options_usage_warning boolean DEFAULT false, constant_tracing boolean DEFAULT true | FUNCTION |
| public.plpgsql_check_function | text | funcoid regprocedure, relid regclass DEFAULT 0, format text DEFAULT 'text'::text, fatal_errors boolean DEFAULT true, other_warnings boolean DEFAULT true, performance_warnings boolean DEFAULT false, extra_warnings boolean DEFAULT true, security_warnings boolean DEFAULT false, compatibility_warnings boolean DEFAULT false, oldtable name DEFAULT NULL::name, newtable name DEFAULT NULL::name, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype, without_warnings boolean DEFAULT false, all_warnings boolean DEFAULT false, use_incomment_options boolean DEFAULT true, incomment_options_usage_warning boolean DEFAULT false, constant_tracing boolean DEFAULT true | FUNCTION |
| public.plpgsql_check_function_tb | record | name text, relid regclass DEFAULT 0, fatal_errors boolean DEFAULT true, other_warnings boolean DEFAULT true, performance_warnings boolean DEFAULT false, extra_warnings boolean DEFAULT true, security_warnings boolean DEFAULT false, compatibility_warnings boolean DEFAULT false, oldtable name DEFAULT NULL::name, newtable name DEFAULT NULL::name, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype, without_warnings boolean DEFAULT false, all_warnings boolean DEFAULT false, use_incomment_options boolean DEFAULT true, incomment_options_usage_warning boolean DEFAULT false, constant_tracing boolean DEFAULT true | FUNCTION |
| public.plpgsql_check_function | text | name text, relid regclass DEFAULT 0, format text DEFAULT 'text'::text, fatal_errors boolean DEFAULT true, other_warnings boolean DEFAULT true, performance_warnings boolean DEFAULT false, extra_warnings boolean DEFAULT true, security_warnings boolean DEFAULT false, compatibility_warnings boolean DEFAULT false, oldtable name DEFAULT NULL::name, newtable name DEFAULT NULL::name, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype, without_warnings boolean DEFAULT false, all_warnings boolean DEFAULT false, use_incomment_options boolean DEFAULT true, incomment_options_usage_warning boolean DEFAULT false, constant_tracing boolean DEFAULT true | FUNCTION |
| public.__plpgsql_show_dependency_tb | record | funcoid regprocedure, relid regclass DEFAULT 0, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype | FUNCTION |
| public.__plpgsql_show_dependency_tb | record | name text, relid regclass DEFAULT 0, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype | FUNCTION |
| public.plpgsql_show_dependency_tb | record | funcoid regprocedure, relid regclass DEFAULT 0, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype | FUNCTION |
| public.plpgsql_show_dependency_tb | record | fnname text, relid regclass DEFAULT 0, anyelememttype regtype DEFAULT 'integer'::regtype, anyenumtype regtype DEFAULT '-'::regtype, anyrangetype regtype DEFAULT 'int4range'::regtype, anycompatibletype regtype DEFAULT 'integer'::regtype, anycompatiblerangetype regtype DEFAULT 'int4range'::regtype | FUNCTION |
| public.plpgsql_profiler_function_tb | record | funcoid regprocedure | FUNCTION |
| public.plpgsql_profiler_function_tb | record | name text | FUNCTION |
| public.plpgsql_profiler_function_statements_tb | record | funcoid regprocedure | FUNCTION |
| public.plpgsql_profiler_function_statements_tb | record | name text | FUNCTION |
| public.plpgsql_profiler_install_fake_queryid_hook | void |  | FUNCTION |
| public.plpgsql_profiler_remove_fake_queryid_hook | void |  | FUNCTION |
| public.plpgsql_profiler_reset_all | void |  | FUNCTION |
| public.plpgsql_profiler_reset | void | funcoid regprocedure | FUNCTION |
| public.plpgsql_coverage_statements | float8 | funcoid regprocedure | FUNCTION |
| public.plpgsql_coverage_statements | float8 | name text | FUNCTION |
| public.plpgsql_coverage_branches | float8 | funcoid regprocedure | FUNCTION |
| public.plpgsql_coverage_branches | float8 | name text | FUNCTION |
| public.plpgsql_check_pragma | int4 | VARIADIC name text[] | FUNCTION |
| public.plpgsql_profiler_functions_all | record |  | FUNCTION |
| public.plpgsql_check_profiler | bool | enable boolean DEFAULT NULL::boolean | FUNCTION |
| public.plpgsql_check_tracer | bool | enable boolean DEFAULT NULL::boolean, verbosity text DEFAULT NULL::text | FUNCTION |
| public.handle_audit_update | trigger |  | FUNCTION |
| public.enable_audit_tracking | void | VARIADIC target_table_names text[] | PROCEDURE |
| public.log_changes | trigger |  | FUNCTION |
| public.attach_audit_triggers | void | VARIADIC table_names text[] | PROCEDURE |
| public.setup_audit | void | VARIADIC table_names text[] | PROCEDURE |
| public.validate_invitation_on_signup | trigger |  | FUNCTION |
| public.handle_new_profile | trigger |  | FUNCTION |
| public.handle_new_student_profile | trigger |  | FUNCTION |
| public.assign_faculty_to_coordinator_on_signup | trigger |  | FUNCTION |
| public.assign_school_to_teacher_on_signup | trigger |  | FUNCTION |
| public.deactivate_invitation_on_signup | trigger |  | FUNCTION |
| public.get_invitation_rol | text | p_email text, p_token text | FUNCTION |
| public.set_invited_by_profile_id | trigger |  | FUNCTION |
| public.set_project_staff_on_insert | trigger |  | FUNCTION |

## Enums

| Name | Values |
| ---- | ------- |
| auth.aal_level | aal1, aal2, aal3 |
| auth.code_challenge_method | plain, s256 |
| auth.factor_status | unverified, verified |
| auth.factor_type | phone, totp, webauthn |
| auth.oauth_authorization_status | approved, denied, expired, pending |
| auth.oauth_client_type | confidential, public |
| auth.oauth_registration_type | dynamic, manual |
| auth.oauth_response_type | code |
| auth.one_time_token_type | confirmation_token, email_change_token_current, email_change_token_new, phone_change_token, reauthentication_token, recovery_token |
| net.request_status | ERROR, PENDING, SUCCESS |
| public.notification_channel_enum | email, in_app |
| public.notification_delivery_status_enum | failed, pending, processing, sent, skipped |
| public.section_enum | A, B, C, D, E, F |
| public.semester_enum | 1, 10, 2, 3, 4, 5, 6, 7, 8, 9 |
| public.shift_enum | EVENING, MORNING |
| realtime.action | DELETE, ERROR, INSERT, TRUNCATE, UPDATE |
| realtime.equality_op | eq, gt, gte, in, lt, lte, neq |
| storage.buckettype | ANALYTICS, STANDARD, VECTOR |

## Relations

```mermaid
erDiagram

"public.profiles" }o--o| "public.roles" : "FOREIGN KEY (role_id) REFERENCES roles(id)"
"public.states" }o--|| "public.countries" : "FOREIGN KEY (country_id) REFERENCES countries(id)"
"public.cities" }o--|| "public.states" : "FOREIGN KEY (state_id) REFERENCES states(id)"
"public.locations" }o--|| "public.cities" : "FOREIGN KEY (city_id) REFERENCES cities(id)"
"public.campuses" }o--o| "public.profiles" : "FOREIGN KEY (president_profile_id) REFERENCES profiles(id)"
"public.campuses" }o--|| "public.locations" : "FOREIGN KEY (location_id) REFERENCES locations(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--o| "public.profiles" : "FOREIGN KEY (dean_profile_id) REFERENCES profiles(id)"
"public.faculties" }o--|| "public.campuses" : "FOREIGN KEY (campus_id) REFERENCES campuses(id)"
"public.schools" }o--o| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.schools" }o--|| "public.faculties" : "FOREIGN KEY (faculty_id) REFERENCES faculties(id)"
"public.schools" }o--|| "public.degrees" : "FOREIGN KEY (degree_id) REFERENCES degrees(id)"
"public.invitations" }o--o| "public.roles" : "FOREIGN KEY (role_to_have_id) REFERENCES roles(id)"
"public.invitations" }o--o| "public.profiles" : "FOREIGN KEY (invited_by_profile_id) REFERENCES profiles(id)"
"public.invitations" }o--o| "public.faculties" : "FOREIGN KEY (faculty_to_be_coordinator) REFERENCES faculties(id)"
"public.invitations" }o--o| "public.schools" : "FOREIGN KEY (school_to_be_tutor) REFERENCES schools(id)"
"public.students" }o--|| "public.profiles" : "FOREIGN KEY (profile_id) REFERENCES profiles(id)"
"public.students" }o--|| "public.schools" : "FOREIGN KEY (school_id) REFERENCES schools(id)"
"public.institutions" }o--o| "public.profiles" : "FOREIGN KEY (contact_person_profile_id) REFERENCES profiles(id)"
"public.institutions" }o--o| "public.locations" : "FOREIGN KEY (location_id) REFERENCES locations(id)"
"public.documents" }o--|| "public.profiles" : "FOREIGN KEY (uploaded_by_profile_id) REFERENCES profiles(id) ON DELETE CASCADE"
"public.projects_states_flow" }o--|| "public.projects_states" : "FOREIGN KEY (from_state) REFERENCES projects_states(id)"
"public.projects_states_flow" }o--|| "public.projects_states" : "FOREIGN KEY (to_state) REFERENCES projects_states(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (coordinator_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (student_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.profiles" : "FOREIGN KEY (tutor_profile_id) REFERENCES profiles(id)"
"public.projects" }o--|| "public.institutions" : "FOREIGN KEY (institution_id) REFERENCES institutions(id)"
"public.projects" }o--|| "public.documents" : "FOREIGN KEY (state_doc_id) REFERENCES documents(id)"
"public.projects" }o--|| "public.projects_states" : "FOREIGN KEY (current_state_id) REFERENCES projects_states(id)"
"public.projects" }o--|| "public.projects_states" : "FOREIGN KEY (last_normal_state_id) REFERENCES projects_states(id)"
"public.notification_preferences" }o--|| "public.profiles" : "FOREIGN KEY (profile_id) REFERENCES profiles(id)"
"public.notification_events" }o--o| "public.profiles" : "FOREIGN KEY (actor_profile_id) REFERENCES profiles(id)"
"public.notification_events" }o--|| "public.profiles" : "FOREIGN KEY (recipient_profile_id) REFERENCES profiles(id)"
"public.notification_deliveries" }o--|| "public.notification_events" : "FOREIGN KEY (event_id) REFERENCES notification_events(id) ON DELETE CASCADE"
"public.notifications" }o--|| "public.profiles" : "FOREIGN KEY (profile_id) REFERENCES profiles(id)"
"public.notifications" }o--o| "public.notification_events" : "FOREIGN KEY (event_id) REFERENCES notification_events(id)"

"public.audit_meta" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
}
"public.audit_logs" {
  bigint id ""
  text schema_name ""
  text table_name ""
  text record_id ""
  text operation_name ""
  uuid auth_uid ""
  jsonb old_data ""
  jsonb new_data ""
  timestamp_with_time_zone created_at ""
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
}
"public.countries" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  text country_name ""
}
"public.states" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint country_id FK ""
  text state_name ""
}
"public.cities" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint state_id FK ""
  text city_name ""
}
"public.locations" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint city_id FK ""
  text address ""
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
"public.degrees" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  text degree_name ""
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
  text token ""
  boolean is_active ""
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
"public.projects_states" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  text project_state_name ""
  boolean normal_flow_state ""
}
"public.projects_states_flow" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  bigint id ""
  bigint from_state FK ""
  bigint to_state FK ""
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
  bigint last_normal_state_id FK ""
  bigint current_state_id FK ""
  bigint state_doc_id FK ""
  text state_metadata ""
}
"public.notification_preferences" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id ""
  uuid profile_id FK ""
  text event_type ""
  notification_channel_enum channel ""
  boolean enabled ""
}
"public.notification_events" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id ""
  text event_type ""
  uuid recipient_profile_id FK ""
  uuid actor_profile_id FK ""
  jsonb payload ""
  text dedupe_key ""
  timestamp_with_time_zone available_at ""
  timestamp_with_time_zone processed_at ""
}
"public.notification_deliveries" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id ""
  uuid event_id FK ""
  notification_channel_enum channel ""
  notification_delivery_status_enum status ""
  integer attempt_count ""
  timestamp_with_time_zone last_attempt_at ""
  timestamp_with_time_zone sent_at ""
  text error_message ""
}
"public.notifications" {
  timestamp_with_time_zone created_at ""
  uuid created_by ""
  timestamp_with_time_zone updated_at ""
  uuid updated_by ""
  uuid id ""
  uuid profile_id FK ""
  uuid event_id FK ""
  text notification_type ""
  jsonb payload ""
  timestamp_with_time_zone read_at ""
}
```

---

> Generated by [tbls](https://github.com/k1LoW/tbls)
