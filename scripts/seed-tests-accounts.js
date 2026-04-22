const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

const INVITATION_TOKEN = "123456";
const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";

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
    if (
      error.message.includes("already exists") ||
      error.message.includes("already been registered")
    ) {
      console.log(`User ${email} already exists.`);
      return null;
    }
    console.error(`Error creating user ${email}:`, error);
    return null;
  }

  console.log(`User ${email} created successfully.`);
  return data;
}

async function main() {
  // 1. Fetch roles
  const { data: roles, error: rolesError } = await supabase
    .from("roles")
    .select("id, role_name");
  if (rolesError) {
    console.error("Error fetching roles:", rolesError);
    return;
  }
  const roleMap = Object.fromEntries(roles.map((r) => [r.role_name, r.id]));

  // 2. Fetch Engineering faculty and Systems school
  const { data: facultyData } = await supabase
    .from("faculties")
    .select("id")
    .eq("faculty_name", "Facultad de Ingenieria")
    .single();
  const engineeringFacultyId = facultyData?.id;

  const { data: schoolData } = await supabase
    .from("schools")
    .select("id, degrees!inner(degree_name)")
    .eq("degrees.degree_name", "Ingenieria de Sistemas")
    .single();
  const systemsSchoolId = schoolData?.id;

  // 3. Ensure a default institution exists
  const { data: existingInstitution } = await supabase
    .from("institutions")
    .select("id")
    .limit(1)
    .single();

  if (!existingInstitution) {
    const { data: locationData } = await supabase
      .from("locations")
      .select("id")
      .limit(1)
      .single();

    if (locationData) {
      const { error: instError } = await supabase
        .from("institutions")
        .insert({
          location_id: locationData.id,
          institution_name: "Universidad Santa Maria - Test Institution",
          created_by: SEED_WORKER_ID,
          updated_by: SEED_WORKER_ID,
        });
      if (instError) {
        console.error("Error creating test institution:", instError);
      } else {
        console.log("Test institution created.");
      }
    }
  }

  const testAccounts = [
    {
      email: "student@test.local",
      password: "123",
      role: "student",
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
      role: "administrative",
      user_names: "test test",
      user_last_names: "administrative 1",
      national_id: "V-10000002",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "tutor@test.local",
      password: "123",
      role: "tutor",
      user_names: "test test",
      user_last_names: "tutor 1",
      national_id: "V-10000003",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "coordinator@test.local",
      password: "123",
      role: "coordinator",
      user_names: "test test",
      user_last_names: "coordinator 1",
      national_id: "V-10000004",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "dean@test.local",
      password: "123",
      role: "dean",
      user_names: "test test",
      user_last_names: "dean 1",
      national_id: "V-10000005",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
    {
      email: "sysadmin@test.local",
      password: "123",
      role: "sysadmin",
      user_names: "test test",
      user_last_names: "sysadmin 1",
      national_id: "V-10000006",
      primary_contact: "04241111111",
      secondary_contact: "04241111111",
    },
  ];

  for (const account of testAccounts) {
    const roleId = roleMap[account.role];

    // 3. Ensure invitation exists
    const { data: existingInvitation } = await supabase
      .from("invitations")
      .select("id")
      .eq("email", account.email)
      .single();

    if (!existingInvitation) {
      const invitationPayload = {
        email: account.email,
        role_to_have_id: roleId,
        created_by: SEED_WORKER_ID,
        updated_by: SEED_WORKER_ID,
      };

      if (account.role === "coordinator") {
        invitationPayload.faculty_to_be_coordinator = engineeringFacultyId;
      } else if (account.role === "tutor") {
        invitationPayload.school_to_be_tutor = systemsSchoolId;
      }

      const { error: invError } = await supabase
        .from("invitations")
        .insert(invitationPayload);

      if (invError) {
        console.error(
          `Error creating invitation for ${account.email}:`,
          invError,
        );
        continue;
      }

      // SECURITY CONCERN
      const { data: hashedToken } = await supabase.rpc(
        "hash_invitation_token",
        {
          token: INVITATION_TOKEN,
        },
      );

      await supabase
        .from("invitations")
        .update({ hashed_token: hashedToken })
        .eq("email", account.email);

      console.log(`Invitation for ${account.email} created.`);
    }

    // 4. Create user
    await seedTestUsers(
      account.email,
      account.password,
      account.user_names,
      account.user_last_names,
      account.national_id,
      account.primary_contact,
      account.secondary_contact,
      {
        ...account.extra_metadata,
        invitation_token: INVITATION_TOKEN,
      },
    );
  }
}

main();
