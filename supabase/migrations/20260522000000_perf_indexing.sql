create index if not exists idx_profiles_national_id on public.profiles (national_id);
create index if not exists idx_profiles_email on public.profiles (email);
create index if not exists idx_profiles_role_id on public.profiles (role_id);
create index if not exists idx_profiles_names_last_names on public.profiles (user_names, user_last_names);

create index if not exists idx_students_profile_id on public.students (profile_id);
create index if not exists idx_students_school_id on public.students (school_id);

create index if not exists idx_project_progress_project_id on public.project_progress (project_id);
create index if not exists idx_project_progress_phase_id on public.project_progress (project_phase_id);
create index if not exists idx_project_progress_state_id on public.project_progress (project_state_id);

create index if not exists idx_exoneration_progress_exoneration_id on public.exoneration_progress (exoneration_id);
create index if not exists idx_exoneration_progress_state_id on public.exoneration_progress (exoneration_state_id);

create index if not exists idx_audit_logs_table_name_created_at on public.audit_logs (table_name, created_at desc);
create index if not exists idx_audit_logs_record_id on public.audit_logs (record_id);
