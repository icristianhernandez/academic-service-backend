# postgres

## Tables

| Name | Columns | Comment | Type |
| ---- | ------- | ------- | ---- |
| [public.audit_meta](public.audit_meta.md) | 4 |  | BASE TABLE |
| [public.audit_logs](public.audit_logs.md) | 9 |  | BASE TABLE |
| [public.roles](public.roles.md) | 7 |  | BASE TABLE |
| [public.profiles](public.profiles.md) | 16 |  | BASE TABLE |
| [public.countries](public.countries.md) | 6 |  | BASE TABLE |
| [public.states](public.states.md) | 7 |  | BASE TABLE |
| [public.cities](public.cities.md) | 7 |  | BASE TABLE |
| [public.locations](public.locations.md) | 7 |  | BASE TABLE |
| [public.campuses](public.campuses.md) | 8 |  | BASE TABLE |
| [public.faculties](public.faculties.md) | 10 |  | BASE TABLE |
| [public.degrees](public.degrees.md) | 6 |  | BASE TABLE |
| [public.schools](public.schools.md) | 8 |  | BASE TABLE |
| [public.invitations](public.invitations.md) | 14 |  | BASE TABLE |
| [public.students](public.students.md) | 10 |  | BASE TABLE |
| [public.documents](public.documents.md) | 8 |  | BASE TABLE |
| [public.institutions](public.institutions.md) | 8 |  | BASE TABLE |
| [public.project_phases](public.project_phases.md) | 9 |  | BASE TABLE |
| [public.project_states](public.project_states.md) | 6 |  | BASE TABLE |
| [public.projects](public.projects.md) | 11 |  | BASE TABLE |
| [public.project_progress](public.project_progress.md) | 11 |  | BASE TABLE |
| [public.notification_types](public.notification_types.md) | 6 |  | BASE TABLE |
| [public.notification_recipients_rules](public.notification_recipients_rules.md) | 8 |  | BASE TABLE |
| [public.notification_type_resolution_rules](public.notification_type_resolution_rules.md) | 11 |  | BASE TABLE |
| [public.notification_type_defaults](public.notification_type_defaults.md) | 8 |  | BASE TABLE |
| [public.notifications_events](public.notifications_events.md) | 16 |  | BASE TABLE |
| [public.notification_recipients](public.notification_recipients.md) | 7 |  | BASE TABLE |
| [public.user_inbox](public.user_inbox.md) | 7 |  | BASE TABLE |
| [public.notifications_external_deliveries](public.notifications_external_deliveries.md) | 12 |  | BASE TABLE |

## Functions

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
| public.generate_invitation_token | text |  | FUNCTION |
| public.hash_invitation_token | text | token text | FUNCTION |
| public.assign_invitation_token | trigger |  | FUNCTION |
| public.validate_project_progress_phase_transition | trigger |  | FUNCTION |
| public.set_project_staff_on_insert | trigger |  | FUNCTION |
| public.resolve_notification_type_id | int8 | p_source_kind text, p_operation_kind text, p_context jsonb | FUNCTION |
| public.enqueue_project_progress_notification_event | trigger |  | FUNCTION |
| public.process_notification_events_queue | int4 | p_batch_size integer DEFAULT 100 | FUNCTION |
| public.claim_notifications_external_deliveries_queue | record | p_batch_size integer DEFAULT 100 | FUNCTION |
| public.invoke_notifications_external_deliveries_worker | int8 | p_batch_size integer DEFAULT 100 | FUNCTION |
| public.mark_notifications_external_delivery_sent | bool | p_delivery_id bigint | FUNCTION |
| public.mark_notifications_external_delivery_failed | bool | p_delivery_id bigint, p_error_message text | FUNCTION |

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
| public.notification_channel_enum | email |
| public.notification_delivery_status_enum | failed, pending, processing, sent, skipped |
| public.notification_event_status_enum | failed, pending, processed, processing |
| public.notification_rule_target_kind_enum | actor, event_schema, explicit_profile, payload, permission_level, role |
| public.section_enum | A, B, C, D, E, F |
| public.semester_enum | 1, 10, 2, 3, 4, 5, 6, 7, 8, 9 |
| public.shift_enum | EVENING, MORNING |
| realtime.action | DELETE, ERROR, INSERT, TRUNCATE, UPDATE |
| realtime.equality_op | eq, gt, gte, in, lt, lte, neq |
| storage.buckettype | ANALYTICS, STANDARD, VECTOR |

---

> Generated by [tbls](https://github.com/k1LoW/tbls)
