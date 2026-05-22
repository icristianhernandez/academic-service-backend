const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz"
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
  extra_metadata = {}
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
      console.log("User " + email + " already exists.");
      return null;
    }
    console.error("Error creating user " + email + ":", error);
    return null;
  }

  console.log("User " + email + " created successfully.");
  return data;
}

async function main() {
  const { data: roles, error: rolesError } = await supabase
    .from("roles")
    .select("id, role_name");
  if (rolesError) {
    console.error("Error fetching roles:", rolesError);
    return;
  }
  const roleMap = Object.fromEntries(roles.map((r) => [r.role_name, r.id]));

  const { data: engFacultyData } = await supabase
    .from("faculties")
    .select("id")
    .eq("faculty_name", "Facultad de Ingenieria")
    .single();
  const engFacultyId = engFacultyData?.id;

  const { data: lawFacultyData } = await supabase
    .from("faculties")
    .select("id")
    .eq("faculty_name", "Facultad de Derecho")
    .single();
  const lawFacultyId = lawFacultyData?.id;

  const { data: systemsSchoolData } = await supabase
    .from("schools")
    .select("id, degrees!inner(degree_name)")
    .eq("degrees.degree_name", "Ingenieria de Sistemas")
    .single();
  const systemsSchoolId = systemsSchoolData?.id;

  const { data: civilSchoolData } = await supabase
    .from("schools")
    .select("id, degrees!inner(degree_name)")
    .eq("degrees.degree_name", "Ingenieria Civil")
    .single();
  const civilSchoolId = civilSchoolData?.id;

  const { data: lawSchoolData } = await supabase
    .from("schools")
    .select("id, degrees!inner(degree_name)")
    .eq("degrees.degree_name", "Derecho")
    .single();
  const lawSchoolId = lawSchoolData?.id;

  const { data: campusData } = await supabase
    .from("campuses")
    .select("id")
    .eq("campus_name", "Universidad Santa Maria - La Florencia")
    .single();
  const campusId = campusData?.id;

  await supabase
    .from("campuses")
    .update({
      rector_profile_id: null,
      vicerector_administrativo_profile_id: null,
      vicerector_academico_profile_id: null
    })
    .eq("id", campusId);

  await supabase
    .from("faculties")
    .update({
      dean_profile_id: null,
      coordinator_profile_id: null
    })
    .in("id", [engFacultyId, lawFacultyId]);

  await supabase
    .from("schools")
    .update({
      subcoordinator_profile_id: null
    })
    .in("id", [systemsSchoolId, civilSchoolId, lawSchoolId]);

  const testAccounts = [
    {
      email: "student_sys1@custom.local",
      password: "123",
      role: "student",
      user_names: "Orozco Aristigueta",
      user_last_names: "Miguel Adrian",
      national_id: "V-31065709",
      primary_contact: "04121111111",
      secondary_contact: "04122222222",
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
      email: "student_sys2@custom.local",
      password: "123",
      role: "student",
      user_names: "Santana Kirk",
      user_last_names: "Tomas Eloy",
      national_id: "V-20000002",
      primary_contact: "04121111112",
      secondary_contact: "04122222223",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "2",
        shift: "MORNING",
        section: "B",
      },
    },
    {
      email: "student_sys3@custom.local",
      password: "123",
      role: "student",
      user_names: "Andrade Kirk",
      user_last_names: "Luis Angel",
      national_id: "V-20000003",
      primary_contact: "04121111113",
      secondary_contact: "04122222224",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "3",
        shift: "MORNING",
        section: "C",
      },
    },
    {
      email: "student_civil1@custom.local",
      password: "123",
      role: "student",
      user_names: "Rivas",
      user_last_names: "Javier",
      national_id: "V-20000004",
      primary_contact: "04121111114",
      secondary_contact: "04122222225",
      extra_metadata: {
        degree_name: "Ingenieria Civil",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "1",
        shift: "MORNING",
        section: "A",
      },
    },
    {
      email: "student_law1@custom.local",
      password: "123",
      role: "student",
      user_names: "Guerrero Leon",
      user_last_names: "Diego Alejandro",
      national_id: "V-20000005",
      primary_contact: "04121111115",
      secondary_contact: "04122222226",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "1",
        shift: "MORNING",
        section: "A",
      },
    },
    {
      email: "student_law2@custom.local",
      password: "123",
      role: "student",
      user_names: "Hernandez",
      user_last_names: "Cristian",
      national_id: "V-20000006",
      primary_contact: "04121111116",
      secondary_contact: "04122222227",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "2",
        shift: "MORNING",
        section: "B",
      },
    },
    {
      email: "vicerector_academico@custom.local",
      password: "123",
      role: "vicerector_academico",
      user_names: "Academico",
      user_last_names: "Vicerector",
      national_id: "V-20000007",
      primary_contact: "04121111117",
      secondary_contact: "04122222228",
    },
    {
      email: "vicerector_administrativo@custom.local",
      password: "123",
      role: "vicerector_administrativo",
      user_names: "Administrativo",
      user_last_names: "Vicerector",
      national_id: "V-20000008",
      primary_contact: "04121111118",
      secondary_contact: "04122222229",
    },
    {
      email: "administrative@custom.local",
      password: "123",
      role: "administrative",
      user_names: "Admin",
      user_last_names: "Empleado",
      national_id: "V-20000009",
      primary_contact: "04121111119",
      secondary_contact: "04122222230",
    },
    {
      email: "coordinator_eng@custom.local",
      password: "123",
      role: "coordinator",
      user_names: "Ingenieria",
      user_last_names: "Coordinador",
      national_id: "V-20000010",
      primary_contact: "04121111120",
      secondary_contact: "0412222231",
    },
    {
      email: "coordinator_law@custom.local",
      password: "123",
      role: "coordinator",
      user_names: "Derecho",
      user_last_names: "Coordinador",
      national_id: "V-20000011",
      primary_contact: "04121111121",
      secondary_contact: "0412222232",
    },
    {
      email: "subcoordinator@custom.local",
      password: "123",
      role: "subcoordinator",
      user_names: "Sistemas y Civil",
      user_last_names: "Subcoordinador",
      national_id: "V-20000012",
      primary_contact: "04121111122",
      secondary_contact: "0412222233",
    },
    {
      email: "director_general@custom.local",
      password: "123",
      role: "director_general",
      user_names: "Director",
      user_last_names: "General",
      national_id: "V-20000013",
      primary_contact: "04121111123",
      secondary_contact: "0412222234",
    },
    {
      email: "dean@custom.local",
      password: "123",
      role: "dean",
      user_names: "Ingenieria",
      user_last_names: "Decano",
      national_id: "V-20000014",
      primary_contact: "04121111124",
      secondary_contact: "0412222235",
    },
    {
      email: "sysadmin@custom.local",
      password: "123",
      role: "sysadmin",
      user_names: "Sys",
      user_last_names: "Admin",
      national_id: "V-20000015",
      primary_contact: "04121111125",
      secondary_contact: "0412222236",
    },
    {
      email: "planning_admissions@custom.local",
      password: "123",
      role: "planning_admissions",
      user_names: "Planeamiento",
      user_last_names: "Admision",
      national_id: "V-20000016",
      primary_contact: "04121111126",
      secondary_contact: "0412222237",
    },
    {
      email: "rector@custom.local",
      password: "123",
      role: "rector",
      user_names: "Rector",
      user_last_names: "Universidad",
      national_id: "V-20000017",
      primary_contact: "04121111127",
      secondary_contact: "0412222238",
    },
  ];

  for (const account of testAccounts) {
    const roleId = roleMap[account.role];

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
        if (account.email.includes("eng")) {
          invitationPayload.faculties_to_be_coordinator = [engFacultyId];
        } else {
          invitationPayload.faculties_to_be_coordinator = [lawFacultyId];
        }
      } else if (account.role === "subcoordinator") {
        invitationPayload.schools_to_be_subcoordinator = [systemsSchoolId, civilSchoolId];
      } else if (account.role === "rector") {
        invitationPayload.campus_to_be_rector = campusId;
      } else if (account.role === "vicerector_administrativo") {
        invitationPayload.campus_to_be_vicerector_administrativo = campusId;
      } else if (account.role === "vicerector_academico") {
        invitationPayload.campus_to_be_vicerector_academico = campusId;
      } else if (account.role === "dean") {
        invitationPayload.faculty_to_be_dean = engFacultyId;
      }

      const { error: invError } = await supabase
        .from("invitations")
        .insert(invitationPayload);

      if (invError) {
        console.error(
          "Error creating invitation for " + account.email + ":",
          invError
        );
        continue;
      }

      const { data: hashedToken } = await supabase.rpc(
        "hash_invitation_token",
        {
          token: INVITATION_TOKEN,
        }
      );

      await supabase
        .from("invitations")
        .update({ hashed_token: hashedToken })
        .eq("email", account.email);

      console.log("Invitation for " + account.email + " created.");
    }

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
      }
    );
  }
}

main();
