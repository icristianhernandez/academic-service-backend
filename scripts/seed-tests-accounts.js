const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

async function seedTestUsers(
  email,
  password,
  user_names,
  user_last_names,
  national_id,
  primary_contact,
  secondary_contact,
  extra_metadata = {},
) {
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      user_names,
      user_last_names,
      national_id,
      primary_contact,
      secondary_contact,
      ...extra_metadata,
    },
  });
  if (error) {
    console.error(`Error creating user ${email}:`, error);
    return null;
  }

  console.log(`User ${email} created successfully.`);
  return data;
}

async function main() {
  const testAccounts = [
    {
      email: "student@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "student 1",
      national_id: "V-10000001",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "1",
        shift: "MORNING",
        section: "A",
      },
    },
    {
      email: "administrative@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "administrative 1",
      national_id: "V-10000002",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "tutor@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "tutor 1",
      national_id: "V-10000003",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "coordinator@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "coordinator 1",
      national_id: "V-10000004",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "dean@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "dean 1",
      national_id: "V-10000005",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "sysadmin@test.local",
      password: "123",
      user_names: "test test",
      user_last_names: "sysadmin 1",
      national_id: "V-10000006",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
  ];

  for (const account of testAccounts) {
    await seedTestUsers(
      account.email,
      account.password,
      account.user_names,
      account.user_last_names,
      account.national_id,
      account.primary_contact,
      account.secondary_contact,
      account.extra_metadata,
    );
  }
}

main();
