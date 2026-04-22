const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

const STUDENT_EMAIL = "student@test.local";
const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";

async function lookupPhasesAndStates() {
  const [{ data: phaseData }, { data: stateData }] = await Promise.all([
    supabase
      .from("project_phases")
      .select("id, project_phase_name")
      .order("project_phase_order"),
    supabase
      .from("project_states")
      .select("id, project_state_name"),
  ]);

  return {
    preproyectoId: phaseData.find((p) => p.project_phase_name === "Preproyecto")?.id,
    phases: phaseData,
    states: stateData,
    enRevisionId: stateData.find((s) => s.project_state_name === "En Revisión")?.id,
  };
}

async function lookupStudentProfile() {
  const { data: profile } = await supabase
    .from("profiles")
    .select("id, user_names, user_last_names")
    .eq("email", STUDENT_EMAIL)
    .single();

  return profile;
}

async function lookupStudentRecord(studentProfileId) {
  const { data: student } = await supabase
    .from("students")
    .select("id")
    .eq("profile_id", studentProfileId)
    .single();

  return student;
}

async function lookupInstitution() {
  const { data: institution } = await supabase
    .from("institutions")
    .select("id")
    .limit(1)
    .single();

  return institution;
}

async function createDocument(uploadedByProfileId) {
  const { data, error } = await supabase
    .from("documents")
    .insert({
      bucket_id: "project",
      storage_path: `test/${Date.now()}-submission.pdf`,
      uploaded_by_profile_id: uploadedByProfileId,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Error creating document:", error);
    throw new Error(`Document creation failed: ${error.message}`);
  }

  return data.id;
}

async function createProject(studentProfileId, institutionId, title) {
  const { data, error } = await supabase
    .from("projects")
    .insert({
      student_profile_id: studentProfileId,
      institution_id: institutionId,
      title,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id, tutor_profile_id, coordinator_profile_id")
    .single();

  if (error) {
    console.error("Error creating project:", error);
    throw new Error(`Project creation failed: ${error.message}`);
  }

  return data;
}

async function insertProjectProgress(
  projectId,
  phaseId,
  stateId,
  authorProfileId,
  documentId,
) {
  const { data, error } = await supabase
    .from("project_progress")
    .insert({
      project_id: projectId,
      project_phase_id: phaseId,
      project_state_id: stateId,
      author_profile_id: authorProfileId,
      document_id: documentId,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Error inserting project_progress:", error);
    throw new Error(`project_progress insert failed: ${error.message}`);
  }

  return data.id;
}

async function callWorker() {
  const { data, error } = await supabase.rpc(
    "process_notification_events_queue",
    { p_batch_size: 100 },
  );

  if (error) {
    console.error("Error calling worker:", error);
    throw new Error(`Worker RPC failed: ${error.message}`);
  }

  return data;
}

async function getNotificationTypeKey(typeId) {
  const { data } = await supabase
    .from("notification_types")
    .select("type_key")
    .eq("id", typeId)
    .single();

  return data?.type_key;
}

async function verifyNotificationEvent(progressId, projectStaff) {
  const { data: event } = await supabase
    .from("notifications_events")
    .select("id, notification_type_id, payload, actor_id")
    .eq("source_record_id", progressId.toString())
    .single();

  if (!event) {
    throw new Error("No notifications_events found for this project_progress");
  }

  const typeKey = await getNotificationTypeKey(event.notification_type_id);

  console.log("\n=== NOTIFICATION EVENT ===");
  console.log(`ID: ${event.id}`);
  console.log(`Type: ${typeKey} (notification_type_id: ${event.notification_type_id})`);
  console.log(`Payload: ${JSON.stringify(event.payload)}`);
  console.log(`Actor: ${event.actor_id}`);

  return { event, typeKey };
}

async function verifyRecipients(eventId, projectStaff) {
  const { data: recipients } = await supabase
    .from("notification_recipients")
    .select("id, recipient_id")
    .eq("notification_id", eventId);

  console.log("\n=== NOTIFICATION RECIPIENTS ===");
  console.log(`Count: ${recipients?.length ?? 0}`);

  if (recipients && recipients.length > 0) {
    for (const recipient of recipients) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("email, user_names, user_last_names")
        .eq("id", recipient.recipient_id)
        .single();

      const profileDesc = profile
        ? `${profile.user_names} ${profile.user_last_names} <${profile.email}>`
        : recipient.recipient_id;

      console.log(`  - ${recipient.id}: ${profileDesc}`);
    }
  }

  return recipients ?? [];
}

async function main() {
  console.log("=== PROJECT PROGRESS NOTIFICATION TEST ===\n");

  const [studentProfile, institution, phasesAndStates] = await Promise.all([
    lookupStudentProfile(),
    lookupInstitution(),
    lookupPhasesAndStates(),
  ]);

  if (!studentProfile) {
    console.error("Student profile not found for:", STUDENT_EMAIL);
    process.exit(1);
  }

  if (!institution) {
    console.error("No institution found in database");
    process.exit(1);
  }

  if (!phasesAndStates.preproyectoId) {
    console.error("Preproyecto phase not found");
    process.exit(1);
  }

  if (!phasesAndStates.enRevisionId) {
    console.error("En Revision state not found");
    process.exit(1);
  }

  console.log(`Student: ${studentProfile.user_names} ${studentProfile.user_last_names}`);
  console.log(`Student Profile ID: ${studentProfile.id}`);
  console.log(`Preproyecto Phase ID: ${phasesAndStates.preproyectoId}`);
  console.log(`En Revision State ID: ${phasesAndStates.enRevisionId}`);

  const studentRecord = await lookupStudentRecord(studentProfile.id);
  if (!studentRecord) {
    console.error("Student record not found in students table");
    process.exit(1);
  }

  console.log("\n--- Creating project ---");
  const project = await createProject(
    studentProfile.id,
    institution.id,
    "Test Project for Notification Flow",
  );
  console.log(`Project created: ID=${project.id}`);
  console.log(`  Tutor: ${project.tutor_profile_id}`);
  console.log(`  Coordinator: ${project.coordinator_profile_id}`);

  console.log("\n--- Creating document ---");
  const documentId = await createDocument(studentProfile.id);
  console.log(`Document created: ID=${documentId}`);

  console.log("\n--- Inserting project_progress (Preproyecto + En Revision) ---");
  const progressId = await insertProjectProgress(
    project.id,
    phasesAndStates.preproyectoId,
    phasesAndStates.enRevisionId,
    studentProfile.id,
    documentId,
  );
  console.log(`project_progress inserted: ID=${progressId}`);

  console.log("\n--- Calling worker to process queue ---");
  const processedCount = await callWorker();
  console.log(`Worker processed: ${processedCount} event(s)`);

  console.log("\n--- Verifying notification event ---");
  let eventData;
  try {
    eventData = await verifyNotificationEvent(progressId, project);
  } catch (err) {
    console.error(`\nFAIL: ${err.message}`);
    process.exit(1);
  }

  const expectedTypeKey = "project-phase-advanced-to-review";
  if (eventData.typeKey !== expectedTypeKey) {
    console.error(
      `\nFAIL: Expected notification type '${expectedTypeKey}', got '${eventData.typeKey}'`,
    );
    process.exit(1);
  }
  console.log(`\nPASS: Notification type is '${expectedTypeKey}'`);

  console.log("\n--- Verifying notification recipients ---");
  const recipients = await verifyRecipients(eventData.event.id, project);

  const expectedRecipients = [
    project.tutor_profile_id,
    project.coordinator_profile_id,
    studentProfile.id,
  ];

  let allRecipientsFound = true;
  for (const expectedId of expectedRecipients) {
    const found = recipients.some((r) => r.recipient_id === expectedId);
    if (!found) {
      console.error(`\nFAIL: Expected recipient ${expectedId} not found`);
      allRecipientsFound = false;
    }
  }

  if (!allRecipientsFound) {
    process.exit(1);
  }

  console.log(`\nPASS: All ${recipients.length} expected recipients found`);
  console.log("\n=== ALL TESTS PASSED ===\n");
}

main().catch((err) => {
  console.error("\nUnhandled error:", err);
  process.exit(1);
});
