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

  const { data: bCity } = await supabase.from("cities").select("id").eq("city_name", "Barcelona").single();
  const bCityId = bCity?.id;

  let { data: locationOriente } = await supabase
    .from("locations")
    .select("id")
    .eq("address", "Sede Oriente, Barcelona, Estado Anzoátegui.")
    .maybeSingle();

  if (!locationOriente) {
    const { data: newLoc, error: locErr } = await supabase
      .from("locations")
      .insert({
        city_id: bCityId,
        address: "Sede Oriente, Barcelona, Estado Anzoátegui.",
        created_by: SEED_WORKER_ID,
        updated_by: SEED_WORKER_ID
      })
      .select("id")
      .single();
    if (locErr) throw locErr;
    locationOriente = newLoc;
  }

  let { data: campusData } = await supabase
    .from("campuses")
    .select("id")
    .eq("campus_name", "Universidad Santa Maria - La Florencia")
    .single();
  const campusId = campusData?.id;

  let { data: campusOriente } = await supabase
    .from("campuses")
    .select("id")
    .eq("campus_name", "Sede Oriente")
    .maybeSingle();

  if (!campusOriente) {
    const { data: newCmp, error: cmpErr } = await supabase
      .from("campuses")
      .insert({
        campus_name: "Sede Oriente",
        location_id: locationOriente.id,
        created_by: SEED_WORKER_ID,
        updated_by: SEED_WORKER_ID
      })
      .select("id")
      .single();
    if (cmpErr) throw cmpErr;
    campusOriente = newCmp;
  }

  const { data: allFacData } = await supabase
    .from("faculties")
    .select("id, faculty_name");

  const facultiesMap = Object.fromEntries(allFacData.map((f) => [f.faculty_name, f.id]));

  const orienteFacultiesData = [
    { name: "Facultad de Ingenieria - Sede Oriente", reports: 3, min: 2, max: 5 },
    { name: "Facultad de Derecho - Sede Oriente", reports: 1, min: 1, max: 2 },
    { name: "Facultad de Farmacia - Sede Oriente", reports: 3, min: 1, max: 3 },
    { name: "Facultad de Ciencias Economicas y Sociales - Sede Oriente", reports: 0, min: 1, max: 5 }
  ];

  for (const fac of orienteFacultiesData) {
    let { data: facRow } = await supabase
      .from("faculties")
      .select("id")
      .eq("faculty_name", fac.name)
      .maybeSingle();

    if (!facRow) {
      const { data: newFac, error: facErr } = await supabase
        .from("faculties")
        .insert({
          faculty_name: fac.name,
          campus_id: campusOriente.id,
          reports_required_count: fac.reports,
          min_members: fac.min,
          max_members: fac.max,
          created_by: SEED_WORKER_ID,
          updated_by: SEED_WORKER_ID
        })
        .select("id")
        .single();
      if (facErr) throw facErr;
      facRow = newFac;
    }
    facultiesMap[fac.name] = facRow.id;
  }

  const degreesList = [
    "Ingenieria de Sistemas",
    "Ingenieria Civil",
    "Ingenieria Industrial",
    "Derecho",
    "Farmacia",
    "Comunicacion Social",
    "Administracion",
    "Contaduria Publica",
    "Arquitectura",
    "Ingenieria en Telecomunicaciones",
    "Estudios Internacionales",
    "Economia",
    "Odontologia"
  ];

  const degreeIds = {};
  for (const dName of degreesList) {
    const { data: degRow } = await supabase
      .from("degrees")
      .select("id")
      .eq("degree_name", dName)
      .single();
    degreeIds[dName] = degRow.id;
  }

  const orienteSchoolsData = [
    { degree: "Ingenieria de Sistemas", faculty: "Facultad de Ingenieria - Sede Oriente" },
    { degree: "Ingenieria Civil", faculty: "Facultad de Ingenieria - Sede Oriente" },
    { degree: "Ingenieria Industrial", faculty: "Facultad de Ingenieria - Sede Oriente" },
    { degree: "Derecho", faculty: "Facultad de Derecho - Sede Oriente" },
    { degree: "Farmacia", faculty: "Facultad de Farmacia - Sede Oriente" },
    { degree: "Comunicacion Social", faculty: "Facultad de Ciencias Economicas y Sociales - Sede Oriente" },
    { degree: "Administracion", faculty: "Facultad de Ciencias Economicas y Sociales - Sede Oriente" },
    { degree: "Contaduria Publica", faculty: "Facultad de Ciencias Economicas y Sociales - Sede Oriente" }
  ];

  const schoolsMap = {};
  for (const sch of orienteSchoolsData) {
    const degId = degreeIds[sch.degree];
    const facId = facultiesMap[sch.faculty];

    let { data: schRow } = await supabase
      .from("schools")
      .select("id")
      .eq("degree_id", degId)
      .eq("faculty_id", facId)
      .maybeSingle();

    if (!schRow) {
      const { data: newSch, error: schErr } = await supabase
        .from("schools")
        .insert({
          degree_id: degId,
          faculty_id: facId,
          created_by: SEED_WORKER_ID,
          updated_by: SEED_WORKER_ID
        })
        .select("id")
        .single();
      if (schErr) throw schErr;
      schRow = newSch;
    }
    schoolsMap[sch.degree + "@" + sch.faculty] = schRow.id;
  }

  const { data: mainSchools } = await supabase
    .from("schools")
    .select("id, degree_id, faculty_id, degrees(degree_name), faculties(faculty_name)");

  for (const ms of mainSchools) {
    if (ms.degrees?.degree_name && ms.faculties?.faculty_name) {
      schoolsMap[ms.degrees.degree_name + "@" + ms.faculties.faculty_name] = ms.id;
    }
  }

  await supabase
    .from("campuses")
    .update({
      rector_profile_id: null,
      vicerector_administrativo_profile_id: null,
      vicerector_academico_profile_id: null,
      updated_by: SEED_WORKER_ID
    })
    .in("id", [campusId, campusOriente.id]);

  await supabase
    .from("faculties")
    .update({
      dean_profile_id: null,
      coordinator_profile_id: null,
      updated_by: SEED_WORKER_ID
    })
    .in("campus_id", [campusId, campusOriente.id]);

  await supabase
    .from("schools")
    .update({
      subcoordinator_profile_id: null,
      updated_by: SEED_WORKER_ID
    })
    .in("faculty_id", Object.values(facultiesMap));

  const testAccounts = [
    {
      email: "rector1@usm.com",
      password: "123",
      role: "rector",
      user_names: "Rector",
      user_last_names: "Universidad",
      national_id: "V-20000017",
      primary_contact: "04121111127",
      secondary_contact: "0412222238",
      targetCampus: "Universidad Santa Maria - La Florencia"
    },
    {
      email: "vicerector_academico1@usm.com",
      password: "123",
      role: "vicerector_academico",
      user_names: "Academico",
      user_last_names: "Vicerector",
      national_id: "V-20000007",
      primary_contact: "04121111117",
      secondary_contact: "04122222228",
      targetCampus: "Universidad Santa Maria - La Florencia"
    },
    {
      email: "vicerector_admin1@usm.com",
      password: "123",
      role: "vicerector_administrativo",
      user_names: "Administrativo",
      user_last_names: "Vicerector",
      national_id: "V-20000008",
      primary_contact: "04121111118",
      secondary_contact: "04122222229",
      targetCampus: "Universidad Santa Maria - La Florencia"
    },
    {
      email: "administrativo@usm.com",
      password: "123",
      role: "administrative",
      user_names: "Admin",
      user_last_names: "Empleado",
      national_id: "V-20000009",
      primary_contact: "04121111119",
      secondary_contact: "04122222230"
    },
    {
      email: "director_general@usm.com",
      password: "123",
      role: "director_general",
      user_names: "Juan Carlos",
      user_last_names: "González Fidalgo",
      national_id: "V-20000013",
      primary_contact: "04121111123",
      secondary_contact: "0412222234"
    },
    {
      email: "sysadmin@usm.com",
      password: "123",
      role: "sysadmin",
      user_names: "Sys",
      user_last_names: "Admin",
      national_id: "V-20000015",
      primary_contact: "04121111125",
      secondary_contact: "0412222236"
    },
    {
      email: "planning@usm.com",
      password: "123",
      role: "planning_admissions",
      user_names: "Planeamiento",
      user_last_names: "Admision",
      national_id: "V-20000016",
      primary_contact: "04121111126",
      secondary_contact: "0412222237"
    },
    {
      email: "dean1@usm.com",
      password: "123",
      role: "dean",
      user_names: "Susana",
      user_last_names: "Mileo",
      national_id: "V-20000014",
      primary_contact: "04121111124",
      secondary_contact: "0412222235",
      targetFaculty: "Facultad de Ingenieria"
    },
    {
      email: "coordinator_eng@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Luisa",
      user_last_names: "Mendez",
      national_id: "V-20000010",
      primary_contact: "04121111120",
      secondary_contact: "0412222231",
      targetFaculty: "Facultad de Ingenieria",
      targetSchools: ["Ingenieria de Sistemas", "Ingenieria Civil", "Ingenieria Industrial", "Ingenieria en Telecomunicaciones", "Arquitectura"]
    },
    {
      email: "subcoord_eng1@usm.com",
      password: "123",
      role: "subcoordinator",
      user_names: "Gabriel",
      user_last_names: "Martinez",
      national_id: "V-20000012",
      primary_contact: "04121111122",
      secondary_contact: "0412222233",
      targetFaculty: "Facultad de Ingenieria",
      targetSchools: ["Ingenieria de Sistemas", "Ingenieria en Telecomunicaciones"]
    },
    {
      email: "subcoord_civil@usm.com",
      password: "123",
      role: "subcoordinator",
      user_names: "Civil",
      user_last_names: "Subcoordinador",
      national_id: "V-20000030",
      primary_contact: "04121111129",
      secondary_contact: "0412222240",
      targetFaculty: "Facultad de Ingenieria",
      targetSchools: ["Ingenieria Civil"]
    },
    {
      email: "subcoord_ind@usm.com",
      password: "123",
      role: "subcoordinator",
      user_names: "Industrial",
      user_last_names: "Subcoordinador",
      national_id: "V-20000031",
      primary_contact: "04121111130",
      secondary_contact: "0412222241",
      targetFaculty: "Facultad de Ingenieria",
      targetSchools: ["Ingenieria Industrial"]
    },
    {
      email: "subcoord_arq@usm.com",
      password: "123",
      role: "subcoordinator",
      user_names: "Arquitectura",
      user_last_names: "Subcoordinador",
      national_id: "V-20000032",
      primary_contact: "04121111131",
      secondary_contact: "0412222242",
      targetFaculty: "Facultad de Ingenieria",
      targetSchools: ["Arquitectura"]
    },
    {
      email: "tomas@usm.com",
      password: "123",
      role: "student",
      user_names: "Tomas",
      user_last_names: "Santana",
      national_id: "V-29098809",
      primary_contact: "04121111111",
      secondary_contact: "04122222222",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "luis@usm.com",
      password: "123",
      role: "student",
      user_names: "Luis",
      user_last_names: "Kirk",
      national_id: "V-21065700",
      primary_contact: "04121111112",
      secondary_contact: "04122222223",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_civil1@usm.com",
      password: "123",
      role: "student",
      user_names: "Javier",
      user_last_names: "Rivas",
      national_id: "V-31065711",
      primary_contact: "04121111113",
      secondary_contact: "04122222224",
      extra_metadata: {
        degree_name: "Ingenieria Civil",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_ind1@usm.com",
      password: "123",
      role: "student",
      user_names: "Industrial Student",
      user_last_names: "La Florencia",
      national_id: "V-31065712",
      primary_contact: "04121111132",
      secondary_contact: "0412222243",
      extra_metadata: {
        degree_name: "Ingenieria Industrial",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_telecom1@usm.com",
      password: "123",
      role: "student",
      user_names: "Telecom Student",
      user_last_names: "La Florencia",
      national_id: "V-31065713",
      primary_contact: "04121111133",
      secondary_contact: "0412222244",
      extra_metadata: {
        degree_name: "Ingenieria en Telecomunicaciones",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_arq1@usm.com",
      password: "123",
      role: "student",
      user_names: "Arch Student",
      user_last_names: "La Florencia",
      national_id: "V-31065714",
      primary_contact: "04121111134",
      secondary_contact: "0412222245",
      extra_metadata: {
        degree_name: "Arquitectura",
        faculty_name: "Facultad de Ingenieria",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_law@usm.com",
      password: "123",
      role: "dean",
      user_names: "Derecho",
      user_last_names: "Decano",
      national_id: "V-20000033",
      primary_contact: "04121111135",
      secondary_contact: "0412222246",
      targetFaculty: "Facultad de Derecho"
    },
    {
      email: "coordinator_law@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Derecho",
      user_last_names: "Coordinador",
      national_id: "V-20000011",
      primary_contact: "04121111121",
      secondary_contact: "0412222232",
      targetFaculty: "Facultad de Derecho",
      targetSchools: ["Derecho", "Estudios Internacionales"]
    },
    {
      email: "student_law1@usm.com",
      password: "123",
      role: "student",
      user_names: "Diego",
      user_last_names: "Guerrero",
      national_id: "V-31065715",
      primary_contact: "04121111115",
      secondary_contact: "04122222226",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_law2@usm.com",
      password: "123",
      role: "student",
      user_names: "Hernandez",
      user_last_names: "Cristian",
      national_id: "V-31065716",
      primary_contact: "04121111116",
      secondary_contact: "04122222227",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "B"
      }
    },
    {
      email: "student_law3@usm.com",
      password: "123",
      role: "student",
      user_names: "Law Student",
      user_last_names: "Three",
      national_id: "V-31065717",
      primary_contact: "04121111136",
      secondary_contact: "0412222247",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "C"
      }
    },
    {
      email: "student_intl1@usm.com",
      password: "123",
      role: "student",
      user_names: "Intl Student",
      user_last_names: "La Florencia",
      national_id: "V-31065718",
      primary_contact: "04121111137",
      secondary_contact: "0412222248",
      extra_metadata: {
        degree_name: "Estudios Internacionales",
        faculty_name: "Facultad de Derecho",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_faces@usm.com",
      password: "123",
      role: "dean",
      user_names: "FACES",
      user_last_names: "Decano",
      national_id: "V-20000034",
      primary_contact: "04121111138",
      secondary_contact: "0412222249",
      targetFaculty: "Facultad de Ciencias Economicas y Sociales"
    },
    {
      email: "coordinator_faces@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "FACES",
      user_last_names: "Coordinador",
      national_id: "V-20000037",
      primary_contact: "04121111139",
      secondary_contact: "0412222250",
      targetFaculty: "Facultad de Ciencias Economicas y Sociales",
      targetSchools: ["Comunicacion Social", "Administracion", "Economia", "Contaduria Publica"]
    },
    {
      email: "student_cs1@usm.com",
      password: "123",
      role: "student",
      user_names: "Comms Student",
      user_last_names: "La Florencia",
      national_id: "V-31065719",
      primary_contact: "04121111140",
      secondary_contact: "0412222251",
      extra_metadata: {
        degree_name: "Comunicacion Social",
        faculty_name: "Facultad de Ciencias Economicas y Sociales",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_admin1@usm.com",
      password: "123",
      role: "student",
      user_names: "Admin Student",
      user_last_names: "La Florencia",
      national_id: "V-31065720",
      primary_contact: "04121111141",
      secondary_contact: "0412222252",
      extra_metadata: {
        degree_name: "Administracion",
        faculty_name: "Facultad de Ciencias Economicas y Sociales",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_econ1@usm.com",
      password: "123",
      role: "student",
      user_names: "Econ Student",
      user_last_names: "La Florencia",
      national_id: "V-31065721",
      primary_contact: "04121111142",
      secondary_contact: "0412222253",
      extra_metadata: {
        degree_name: "Economia",
        faculty_name: "Facultad de Ciencias Economicas y Sociales",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_cont1@usm.com",
      password: "123",
      role: "student",
      user_names: "Accounting Student",
      user_last_names: "La Florencia",
      national_id: "V-31065722",
      primary_contact: "04121111143",
      secondary_contact: "0412222254",
      extra_metadata: {
        degree_name: "Contaduria Publica",
        faculty_name: "Facultad de Ciencias Economicas y Sociales",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_odonto@usm.com",
      password: "123",
      role: "dean",
      user_names: "Odontologia",
      user_last_names: "Decano",
      national_id: "V-20000035",
      primary_contact: "04121111144",
      secondary_contact: "0412222255",
      targetFaculty: "Facultad de Odontologia"
    },
    {
      email: "coordinator_odonto@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Odontologia",
      user_last_names: "Coordinador",
      national_id: "V-20000038",
      primary_contact: "04121111145",
      secondary_contact: "0412222256",
      targetFaculty: "Facultad de Odontologia",
      targetSchools: ["Odontologia"]
    },
    {
      email: "student_odonto1@usm.com",
      password: "123",
      role: "student",
      user_names: "Odonto Student",
      user_last_names: "La Florencia",
      national_id: "V-31065723",
      primary_contact: "04121111146",
      secondary_contact: "0412222257",
      extra_metadata: {
        degree_name: "Odontologia",
        faculty_name: "Facultad de Odontologia",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_pharmacy@usm.com",
      password: "123",
      role: "dean",
      user_names: "Farmacia",
      user_last_names: "Decano",
      national_id: "V-20000036",
      primary_contact: "04121111147",
      secondary_contact: "0412222258",
      targetFaculty: "Facultad de Farmacia"
    },
    {
      email: "coordinator_pharmacy@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Farmacia",
      user_last_names: "Coordinador",
      national_id: "V-20000039",
      primary_contact: "04121111148",
      secondary_contact: "0412222259",
      targetFaculty: "Facultad de Farmacia",
      targetSchools: ["Farmacia"]
    },
    {
      email: "student_pharmacy1@usm.com",
      password: "123",
      role: "student",
      user_names: "Pharmacy Student",
      user_last_names: "La Florencia",
      national_id: "V-31065724",
      primary_contact: "04121111149",
      secondary_contact: "0412222260",
      extra_metadata: {
        degree_name: "Farmacia",
        faculty_name: "Facultad de Farmacia",
        campus_name: "Universidad Santa Maria - La Florencia",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "rector2@usm.com",
      password: "123",
      role: "rector",
      user_names: "Rector Oriente",
      user_last_names: "Universidad",
      national_id: "V-40000001",
      primary_contact: "04121111150",
      secondary_contact: "0412222261",
      targetCampus: "Sede Oriente"
    },
    {
      email: "vicerector_academico2@usm.com",
      password: "123",
      role: "vicerector_academico",
      user_names: "Academico Oriente",
      user_last_names: "Vicerector",
      national_id: "V-40000002",
      primary_contact: "04121111151",
      secondary_contact: "0412222262",
      targetCampus: "Sede Oriente"
    },
    {
      email: "vicerector_admin2@usm.com",
      password: "123",
      role: "vicerector_administrativo",
      user_names: "Administrativo Oriente",
      user_last_names: "Vicerector",
      national_id: "V-40000003",
      primary_contact: "04121111152",
      secondary_contact: "0412222263",
      targetCampus: "Sede Oriente"
    },
    {
      email: "dean_eng2@usm.com",
      password: "123",
      role: "dean",
      user_names: "Ingenieria",
      user_last_names: "Decano Oriente",
      national_id: "V-40000004",
      primary_contact: "04121111153",
      secondary_contact: "0412222264",
      targetFaculty: "Facultad de Ingenieria - Sede Oriente"
    },
    {
      email: "coordinator_eng2@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Ingenieria",
      user_last_names: "Coordinador Oriente",
      national_id: "V-40000008",
      primary_contact: "04121111157",
      secondary_contact: "0412222268",
      targetFaculty: "Facultad de Ingenieria - Sede Oriente",
      targetSchools: ["Ingenieria de Sistemas", "Ingenieria Civil", "Ingenieria Industrial"]
    },
    {
      email: "student_sys_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Sistemas Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000001",
      primary_contact: "04121111162",
      secondary_contact: "0412222273",
      extra_metadata: {
        degree_name: "Ingenieria de Sistemas",
        faculty_name: "Facultad de Ingenieria - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_civil_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Civil Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000002",
      primary_contact: "04121111163",
      secondary_contact: "0412222274",
      extra_metadata: {
        degree_name: "Ingenieria Civil",
        faculty_name: "Facultad de Ingenieria - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_ind_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Industrial Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000003",
      primary_contact: "04121111164",
      secondary_contact: "0412222275",
      extra_metadata: {
        degree_name: "Ingenieria Industrial",
        faculty_name: "Facultad de Ingenieria - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_law_oriente@usm.com",
      password: "123",
      role: "dean",
      user_names: "Derecho",
      user_last_names: "Decano Oriente",
      national_id: "V-40000005",
      primary_contact: "04121111154",
      secondary_contact: "0412222265",
      targetFaculty: "Facultad de Derecho - Sede Oriente"
    },
    {
      email: "coordinator_law_oriente@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Derecho",
      user_last_names: "Coordinador Oriente",
      national_id: "V-40000009",
      primary_contact: "04121111158",
      secondary_contact: "0412222269",
      targetFaculty: "Facultad de Derecho - Sede Oriente",
      targetSchools: ["Derecho"]
    },
    {
      email: "student_law_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Derecho Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000004",
      primary_contact: "04121111165",
      secondary_contact: "0412222276",
      extra_metadata: {
        degree_name: "Derecho",
        faculty_name: "Facultad de Derecho - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_pharmacy_oriente@usm.com",
      password: "123",
      role: "dean",
      user_names: "Farmacia",
      user_last_names: "Decano Oriente",
      national_id: "V-40000006",
      primary_contact: "04121111155",
      secondary_contact: "0412222266",
      targetFaculty: "Facultad de Farmacia - Sede Oriente"
    },
    {
      email: "coordinator_pharmacy_oriente@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "Farmacia",
      user_last_names: "Coordinador Oriente",
      national_id: "V-40000010",
      primary_contact: "04121111159",
      secondary_contact: "0412222270",
      targetFaculty: "Facultad de Farmacia - Sede Oriente",
      targetSchools: ["Farmacia"]
    },
    {
      email: "student_pharmacy_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Farmacia Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000005",
      primary_contact: "04121111166",
      secondary_contact: "0412222277",
      extra_metadata: {
        degree_name: "Farmacia",
        faculty_name: "Facultad de Farmacia - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "dean_faces_oriente@usm.com",
      password: "123",
      role: "dean",
      user_names: "FACES",
      user_last_names: "Decano Oriente",
      national_id: "V-40000007",
      primary_contact: "04121111156",
      secondary_contact: "0412222267",
      targetFaculty: "Facultad de Ciencias Economicas y Sociales - Sede Oriente"
    },
    {
      email: "coordinator_faces_oriente@usm.com",
      password: "123",
      role: "coordinator",
      user_names: "FACES",
      user_last_names: "Coordinador Oriente",
      national_id: "V-40000011",
      primary_contact: "04121111160",
      secondary_contact: "0412222271",
      targetFaculty: "Facultad de Ciencias Economicas y Sociales - Sede Oriente",
      targetSchools: ["Comunicacion Social", "Administracion", "Contaduria Publica"]
    },
    {
      email: "student_cs_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Comms Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000006",
      primary_contact: "04121111167",
      secondary_contact: "0412222278",
      extra_metadata: {
        degree_name: "Comunicacion Social",
        faculty_name: "Facultad de Ciencias Economicas y Sociales - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_admin_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Admin Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000007",
      primary_contact: "04121111168",
      secondary_contact: "0412222279",
      extra_metadata: {
        degree_name: "Administracion",
        faculty_name: "Facultad de Ciencias Economicas y Sociales - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    },
    {
      email: "student_cont_oriente@usm.com",
      password: "123",
      role: "student",
      user_names: "Accounting Student",
      user_last_names: "Sede Oriente",
      national_id: "V-41000008",
      primary_contact: "04121111169",
      secondary_contact: "0412222280",
      extra_metadata: {
        degree_name: "Contaduria Publica",
        faculty_name: "Facultad de Ciencias Economicas y Sociales - Sede Oriente",
        campus_name: "Sede Oriente",
        semester: "8",
        shift: "MORNING",
        section: "A"
      }
    }
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
        updated_by: SEED_WORKER_ID
      };

      if (account.role === "coordinator" && account.targetFaculty) {
        const facId = facultiesMap[account.targetFaculty];
        const schIds = (account.targetSchools || []).map((s) => schoolsMap[s + "@" + account.targetFaculty]).filter(Boolean);
        invitationPayload.faculties_to_be_coordinator = [facId];
        invitationPayload.schools_to_be_coordinator = schIds;
      } else if (account.role === "subcoordinator" && account.targetFaculty) {
        const schIds = (account.targetSchools || []).map((s) => schoolsMap[s + "@" + account.targetFaculty]).filter(Boolean);
        invitationPayload.schools_to_be_subcoordinator = schIds;
      } else if (account.role === "rector" && account.targetCampus) {
        invitationPayload.campus_to_be_rector = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
      } else if (account.role === "vicerector_administrativo" && account.targetCampus) {
        invitationPayload.campus_to_be_vicerector_administrativo = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
      } else if (account.role === "vicerector_academico" && account.targetCampus) {
        invitationPayload.campus_to_be_vicerector_academico = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
      } else if (account.role === "dean" && account.targetFaculty) {
        invitationPayload.faculty_to_be_dean = facultiesMap[account.targetFaculty];
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
          token: INVITATION_TOKEN
        }
      );

      await supabase
        .from("invitations")
        .update({ hashed_token: hashedToken, updated_by: SEED_WORKER_ID })
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
        invitation_token: INVITATION_TOKEN
      }
    );
  }

  for (const account of testAccounts) {
    if (["rector", "vicerector_administrativo", "vicerector_academico", "dean", "coordinator", "subcoordinator"].includes(account.role)) {
      const { data: prof } = await supabase
        .from("profiles")
        .select("id")
        .eq("national_id", account.national_id)
        .single();
      
      if (prof?.id) {
        if (account.role === "rector" && account.targetCampus) {
          const cId = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
          await supabase.from("campuses").update({ rector_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", cId);
        } else if (account.role === "vicerector_administrativo" && account.targetCampus) {
          const cId = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
          await supabase.from("campuses").update({ vicerector_administrativo_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", cId);
        } else if (account.role === "vicerector_academico" && account.targetCampus) {
          const cId = account.targetCampus === "Sede Oriente" ? campusOriente.id : campusId;
          await supabase.from("campuses").update({ vicerector_academico_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", cId);
        } else if (account.role === "dean" && account.targetFaculty) {
          const fId = facultiesMap[account.targetFaculty];
          await supabase.from("faculties").update({ dean_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", fId);
        } else if (account.role === "coordinator" && account.targetFaculty) {
          const fId = facultiesMap[account.targetFaculty];
          await supabase.from("faculties").update({ coordinator_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", fId);
        } else if (account.role === "subcoordinator" && account.targetFaculty) {
          const schIds = (account.targetSchools || []).map((s) => schoolsMap[s + "@" + account.targetFaculty]).filter(Boolean);
          for (const sId of schIds) {
            await supabase.from("schools").update({ subcoordinator_profile_id: prof.id, updated_by: SEED_WORKER_ID }).eq("id", sId);
          }
        }
      }
    }
  }
}

main();
