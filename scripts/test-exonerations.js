const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";

async function lookupProfile(email) {
  const { data } = await supabase
    .from("profiles")
    .select("id, email")
    .eq("email", email)
    .single();
  return data;
}

async function createDoc(uploaderId, path) {
  const { data, error } = await supabase
    .from("documents")
    .insert({
      bucket_id: "exonerations",
      storage_path: path,
      uploaded_by_profile_id: uploaderId,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id")
    .single();

  if (error) throw new Error(`Doc creation failed: ${error.message}`);
  return data.id;
}

async function getState(name) {
  const { data } = await supabase
    .from("exoneration_states")
    .select("id")
    .eq("exoneration_state_name", name)
    .single();
  return data.id;
}

async function main() {
  const results = { pass: 0, fail: 0 };

  const student = await lookupProfile("student@test.local");
  const coordinator = await lookupProfile("coordinator@test.local");
  const planning = await lookupProfile("administrative@test.local");

  if (!student || !coordinator || !planning) {
    console.error("Missing profiles:", { student: !!student,
      coordinator: !!coordinator, planning: !!planning });
    process.exit(1);
  }

  const certDocId = await createDoc(student.id,
    `test/cert-${Date.now()}.pdf`);

  // ── TEST 1: Create exoneration (auto-assigns coordinator) ──
  const { data: exoneration, error: vErr } = await supabase
    .from("exonerations")
    .insert({
      student_profile_id: student.id,
      certificate_document_id: certDocId,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("*")
    .single();

  if (vErr) {
    console.error("FAIL 1  Create exoneration:", vErr.message);
    results.fail++;
  } else {
    console.log("PASS 1  Exoneration created, coordinator auto-set:",
      exoneration.coordinator_profile_id === coordinator.id);
    results.pass++;
  }

  const reviewId = await getState("En revisión");
  const validatedId = await getState("Validado por Coordinador");
  const consignedId = await getState("Consignado a Planeamiento y Admisión");
  const approvedId = await getState("Aprobado por Planeamiento y Admisión");
  const rejectedId = await getState("Rechazado para corrección");

  // ── TEST 2: First progress (En revision) ──
  const { error: p1Err } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id,
      exoneration_state_id: reviewId,
      author_profile_id: student.id,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    });

  if (p1Err) { console.error("FAIL 2  En revision:", p1Err.message); results.fail++; }
  else { console.log("PASS 2  En revision"); results.pass++; }

  // ── TEST 3: Rejection flow (En revision -> Rechazado -> En revision) ──
  const { error: rejErr } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id, exoneration_state_id: rejectedId,
      author_profile_id: coordinator.id, created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
    });

  if (rejErr) { console.error("FAIL 3a Reject:", rejErr.message); results.fail++; }
  else {
    console.log("PASS 3a Rechazado para corrección"); results.pass++;

    const { error: reopenErr } = await supabase
      .from("exoneration_progress")
      .insert({
        exoneration_id: exoneration.id, exoneration_state_id: reviewId,
        author_profile_id: student.id, created_by: SEED_WORKER_ID, updated_by: SEED_WORKER_ID,
      });

    if (reopenErr) { console.error("FAIL 3b Reopen:", reopenErr.message); results.fail++; }
    else { console.log("PASS 3b Rechazado -> En revision"); results.pass++; }
  }

  // ── TEST 4: Coordinador valida (after reopen) ──
  const { error: p2Err } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id,
      exoneration_state_id: validatedId,
      author_profile_id: coordinator.id,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    });

  if (p2Err) { console.error("FAIL 4  Validado por Coordinador:", p2Err.message); results.fail++; }
  else { console.log("PASS 4  Validado por Coordinador"); results.pass++; }

  // ── TEST 5: Coordinador consigna ──
  const { error: p3Err } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id,
      exoneration_state_id: consignedId,
      author_profile_id: coordinator.id,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    });

  if (p3Err) { console.error("FAIL 5  Consignado:", p3Err.message); results.fail++; }
  else { console.log("PASS 5  Consignado a Planeamiento"); results.pass++; }

  // ── TEST 6: Planning approves ──
  const { error: p4Err } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id,
      exoneration_state_id: approvedId,
      author_profile_id: planning.id,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    });

  if (p4Err) { console.error("FAIL 6  Aprobado:", p4Err.message); results.fail++; }
  else { console.log("PASS 6  Aprobado por Planeamiento"); results.pass++; }

  // ── TEST 7: Invalid transition (Aprobado -> Validado is invalid) ──
  const { error: invalidErr } = await supabase
    .from("exoneration_progress")
    .insert({
      exoneration_id: exoneration.id,
      exoneration_state_id: validatedId,
      author_profile_id: coordinator.id,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    });

  if (invalidErr) { console.log("PASS 7  Invalid transition rejected:", invalidErr.message); results.pass++; }
  else { console.error("FAIL 7  Invalid transition not rejected"); results.fail++; }

  // ── TEST 8: Mutual exclusivity (project after exoneration) ──
  const { data: inst } = await supabase.from("institutions").select("id").limit(1).single();
  const { error: projErr } = await supabase.from("projects").insert({
    student_profile_id: student.id,
    institution_id: inst.id,
    title: "Should fail — student has exoneration",
    created_by: SEED_WORKER_ID,
    updated_by: SEED_WORKER_ID,
  });

  if (projErr) { console.log("PASS 8  Project blocked (mutual exclusivity):", projErr.message); results.pass++; }
  else { console.error("FAIL 8  Mutual exclusivity failed"); results.fail++; }

  // ── TEST 9: Unique student constraint ──
  const { error: dupErr } = await supabase.from("exonerations").insert({
    student_profile_id: student.id,
    certificate_document_id: certDocId,
    created_by: SEED_WORKER_ID,
    updated_by: SEED_WORKER_ID,
  });

  if (dupErr) { console.log("PASS 9  Unique student enforced:", dupErr.message); results.pass++; }
  else { console.error("FAIL 9  Unique constraint failed"); results.fail++; }

  // ── TEST 10: Notifications generated ──
  const { data: events } = await supabase
    .from("notifications_events")
    .select("id")
    .eq("source_kind", "exoneration_progress");

  console.log("       Notifications events:", events.length);
  if (events.length >= 5) { console.log("PASS 10 Notification events generated"); results.pass++; }
  else { console.error("FAIL 10 Expected >=5 events, got", events.length); results.fail++; }

  // ── TEST 11: Storage bucket exists ──
  const { data: buckets } = await supabase.storage.listBuckets();
  const found = buckets.some(b => b.name === "exonerations");
  if (found) { console.log("PASS 11 Storage bucket exists"); results.pass++; }
  else { console.error("FAIL 11 Storage bucket missing"); results.fail++; }

  console.log(`\n=== RESULTS: ${results.pass} passed, ${results.fail} failed ===`);
  process.exit(results.fail > 0 ? 1 : 0);
}

main().catch(err => { console.error("Script error:", err); process.exit(1); });
