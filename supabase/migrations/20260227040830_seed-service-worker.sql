do $$
declare
	seed_user_id constant uuid := '00000000-0000-0000-0000-000000000001';
begin
	insert into auth.users (
		id,
		aud,
		role,
		email,
		encrypted_password,
		email_confirmed_at,
		raw_app_meta_data,
		raw_user_meta_data,
		created_at,
		updated_at
	)
	values (
		seed_user_id,
		'authenticated',
		'authenticated',
		'seed-worker@usm.local',
		crypt(gen_random_uuid()::text, gen_salt('bf')),
		now(),
		'{"provider":"email","providers":["email"]}'::jsonb,
		'{"display_name":"Seed Service Worker"}'::jsonb,
		now(),
		now()
	)
	on conflict (id) do update
	set
		email = excluded.email,
		raw_app_meta_data = excluded.raw_app_meta_data,
		raw_user_meta_data = excluded.raw_user_meta_data,
		updated_at = now();
end;
$$;
