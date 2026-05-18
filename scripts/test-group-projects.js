const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

const INVITATION_TOKEN = "123456";
const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";

let passCount = 0;
let failCount = 0;

function pass(msg) { console.log(`  PASS: ${msg}`); passCount++; }
function fail(msg) { console.error(`  FAIL: ${msg}`); failCount++; }

async function expectOk(promise, label) {
  const { error } = await promise;
  if (error) fail(`${label}: ${error.message}`);
  else pass(label);
}

async function expectErr(promise, hint, label) {
  const { error } = await promise;
  if (!error) fail(`${label} — expected error, got success`);
  else if (!error.message.includes(hint))
    fail(`${label} — expected hint "${hint}", got "${error.message}"`);
  else pass(label);
}

async function ensureStudent(email, names, lastNames, nationalId, extra = {}) {
  const { data: existing } = await supabase.from("profiles").select("id").eq("email", email).single();
  if (existing) return existing.id;

  const { data: roleData } = await supabase.from("roles").select("id").eq("role_name", "student").single();
  const { data: existingInv } = await supabase.from("invitations").select("id").eq("email", email).single();
  if (!existingInv) {
    await supabase.from("invitations").insert({
      email, role_to_have_id: roleData.id,
      created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
    });
    const { data: hashed } = await supabase.rpc("hash_invitation_token", { token: INVITATION_TOKEN });
    await supabase.from("invitations").update({ hashed_token: hashed }).eq("email", email);
  }

  const { data, error } = await supabase.auth.admin.createUser({
    email, password: "123", email_confirm: true,
    user_metadata: {
      user_names: names, user_last_names: lastNames, national_id: nationalId,
      primary_contact: "04240000000", secondary_contact: "04240000000",
      invitation_token: INVITATION_TOKEN, ...extra,
    },
  });
  if (error) {
    if (error.message.includes("already exists") || error.message.includes("already been registered")) {
      const { data: p } = await supabase.from("profiles").select("id").eq("email", email).single();
      return p?.id;
    }
    throw error;
  }
  return data.user.id;
}

async function main() {
  console.log("=== GROUP PROJECTS TEST ===\n");

  const [{ data: roles }, { data: schools }, { data: faculties }, { data: phases }, { data: states }] =
    await Promise.all([
      supabase.from("roles").select("id, role_name"),
      supabase.from("schools").select("id, degrees!inner(degree_name)"),
      supabase.from("faculties").select("id, faculty_name, min_members, max_members"),
      supabase.from("project_phases").select("id, project_phase_name").order("project_phase_order"),
      supabase.from("project_states").select("id, project_state_name"),
    ]);

  const ingFac = faculties.find(f => f.faculty_name === "Facultad de Ingenieria");
  const prePhase = phases.find(p => p.project_phase_name === "Preproyecto");
  const revState = states.find(s => s.project_state_name === "En revisión");

  pass(`Ingenieria min_members=${ingFac.min_members} max_members=${ingFac.max_members}`);

  // Ensure all needed students
  // A,B,C,E,F,G,H from Ingenieria de Sistemas, D from Derecho
  const optsIS = (n) => ({ degree_name: "Ingenieria de Sistemas", faculty_name: "Facultad de Ingenieria",
    campus_name: "Universidad Santa Maria - La Florencia", semester: "1", shift: "MORNING", section: n });
  const A = await ensureStudent("student@test.local", "test", "A", "V-10000001", optsIS("A"));
  const B = await ensureStudent("test-m1@test.local", "test", "B", "V-20000001", optsIS("B"));
  const C = await ensureStudent("test-m2@test.local", "test", "C", "V-20000002", optsIS("B"));
  const D = await ensureStudent("test-law@test.local", "test", "D", "V-20000003",
    { degree_name: "Derecho", faculty_name: "Facultad de Derecho",
      campus_name: "Universidad Santa Maria - La Florencia", semester: "1", shift: "MORNING", section: "A" });
  const E = await ensureStudent("test-m3@test.local", "test", "E", "V-20000004", optsIS("B"));
  const F = await ensureStudent("test-m4@test.local", "test", "F", "V-20000005", optsIS("B"));
  const G = await ensureStudent("test-m5@test.local", "test", "G", "V-20000006", optsIS("B"));
  const H = await ensureStudent("test-m6@test.local", "test", "H", "V-20000007", optsIS("B"));

  // Default institution
  const { data: loc } = await supabase.from("locations").select("id").limit(1).single();
  if (!await supabase.from("institutions").select("id").limit(1).single().then(r => r.data)) {
    await supabase.from("institutions").insert({
      location_id: loc.id, institution_name: "Test Inst",
      created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
    });
  }
  const institution = await supabase.from("institutions").select("id").limit(1).single().then(r => r.data);

  // ============ PROJECT 1 ============
  const { data: pj1 } = await supabase.from("projects").insert({
    student_profile_id: A, institution_id: institution.id,
    title: "Group Project 1", created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
  }).select("id").single();
  if (!pj1) { console.error("Failed creating project 1"); process.exit(1); }
  console.log(`\nProject 1: id=${pj1.id}`);

  const pm = () => supabase.from("project_members");

  // --- 1 leader per project ---
  console.log("\n--- 1 leader per project ---");
  await expectOk(pm().insert({ project_id: pj1.id, profile_id: A, is_leader: true,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add leader A");
  await expectErr(pm().insert({ project_id: pj1.id, profile_id: B, is_leader: true,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "idx_project_members_one_leader", "Reject second leader B");

  // --- Same school ---
  console.log("\n--- Same school ---");
  await expectErr(pm().insert({ project_id: pj1.id, profile_id: D, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "same school", "Reject D from Derecho");

  // --- Add B and C as members ---
  console.log("\n--- Add members ---");
  await expectOk(pm().insert({ project_id: pj1.id, profile_id: B, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add B (2/5)");
  await expectOk(pm().insert({ project_id: pj1.id, profile_id: C, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add C (3/5)");

  // ============ PROJECT 2 (unique profile constraint) ============
  console.log("\n--- Unique profile across projects ---");
  const { data: pj2, error: pj2e } = await supabase.from("projects").insert({
    student_profile_id: G, institution_id: institution.id,
    title: "Group Project 2", created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
  }).select("id").single();
  if (pj2e || !pj2) { console.error(`Project 2 error: ${pj2e?.message}`); process.exit(1); }
  console.log(`Project 2: id=${pj2.id}`);

  await expectOk(pm().insert({ project_id: pj2.id, profile_id: G, is_leader: true,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add leader G to project 2");
  // B already in project 1, cannot join project 2
  await expectErr(pm().insert({ project_id: pj2.id, profile_id: B, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "unique", "Reject B (already in project 1) from project 2");
  // G already leader of project 2, cannot join project 1
  await expectErr(pm().insert({ project_id: pj1.id, profile_id: G, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "unique", "Reject G (already leader of project 2) from project 1");

  // ============ MAX MEMBERS ============
  console.log("\n--- Max members (5) ---");
  await expectOk(pm().insert({ project_id: pj1.id, profile_id: E, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add E (4/5)");
  await expectOk(pm().insert({ project_id: pj1.id, profile_id: F, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }), "Add F (5/5)");
  await expectErr(pm().insert({ project_id: pj1.id, profile_id: H, is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "exceeds maximum", "Reject 6th member H");

  // ============ NO CHANGES AFTER PROJECT BEGINS ============
  console.log("\n--- No changes after project begins ---");
  const docResult = await supabase.from("documents").insert({
    bucket_id: "project", storage_path: `test/${Date.now()}.pdf`,
    uploaded_by_profile_id: A, created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
  }).select("id").single();
  if (docResult.error || !docResult.data) {
    console.error(`Document insert error: ${docResult.error?.message}`);
    process.exit(1);
  }
  const { error: ppErr } = await supabase.from("project_progress").insert({
    project_id: pj1.id, project_phase_id: prePhase.id, project_state_id: revState.id,
    author_profile_id: A, document_id: docResult.data.id,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
  }).select("id").single();
  if (ppErr) { console.error(`project_progress: ${ppErr.message}`); process.exit(1); }
  console.log("Preproyecto submitted");

  // Attempt insert after progress exists
  await expectErr(pm().insert({ project_id: pj1.id, profile_id: (await ensureStudent("test-m7@test.local", "test", "I", "V-20000008", optsIS("B"))), is_leader: false,
    created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID }),
    "Cannot modify members after project has begun", "Reject insert after progress");
  // Attempt delete after progress exists
  await expectErr(pm().delete().eq("project_id", pj1.id).eq("profile_id", F),
    "Cannot modify members after project has begun", "Reject delete after progress");

  console.log(`\n=== SUMMARY: ${passCount} passed, ${failCount} failed ===\n`);
  if (failCount > 0) process.exit(1);
  console.log("=== ALL TESTS PASSED ===\n");
}

main().catch(err => { console.error("Unhandled:", err); process.exit(1); });
