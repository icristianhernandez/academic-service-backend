const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

async function seedTestUsers(
  email,
  password,
  first_name,
  second_name,
  last_name,
  second_last_name,
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
      first_name,
      second_name,
      last_name,
      second_last_name,
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
      first_name: "student",
      second_name: "student2",
      last_name: "test",
      second_last_name: "student2",
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
      first_name: "administrative",
      second_name: "administrative2",
      last_name: "test",
      second_last_name: "administrative2",
      national_id: "V-10000002",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "tutor@test.local",
      password: "123",
      first_name: "tutor",
      second_name: "tutor2",
      last_name: "test",
      second_last_name: "tutor2",
      national_id: "V-10000003",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "coordinator@test.local",
      password: "123",
      first_name: "coordinator",
      second_name: null,
      last_name: "test",
      second_last_name: "coordinator2",
      national_id: "V-10000004",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "dean@test.local",
      password: "123",
      first_name: "dean",
      second_name: "",
      last_name: "test",
      second_last_name: "dean2",
      national_id: "V-10000005",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "sysadmin@test.local",
      password: "123",
      first_name: "sysadmin",
      second_name: "sysadmin2",
      last_name: "test",
      second_last_name: "sysadmin2",
      national_id: "V-10000006",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
  ];

  for (const account of testAccounts) {
    await seedTestUsers(
      account.email,
      account.password,
      account.first_name,
      account.second_name,
      account.last_name,
      account.second_last_name,
      account.national_id,
      account.primary_contact,
      account.secondary_contact,
      account.extra_metadata,
    );
  }
}

main();
