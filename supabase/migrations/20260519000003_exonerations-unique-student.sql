alter table public.exonerations
add constraint exonerations_student_profile_id_unique
unique (student_profile_id);
