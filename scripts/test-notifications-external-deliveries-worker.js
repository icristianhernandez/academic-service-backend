const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "http://127.0.0.1:54321";
const SERVICE_ROLE_KEY = "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz";
const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";
const STUDENT_EMAIL = "student@test.local";

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function lookupPhasesAndStates() {
  const [{ data: phaseData }, { data: stateData }] = await Promise.all([
    supabase.from("project_phases").select("id, project_phase_name").order("project_phase_order"),
    supabase.from("project_states").select("id, project_state_name"),
  ]);

  return {
    preproyectoId: phaseData.find((p) => p.project_phase_name === "Preproyecto")?.id,
    enRevisionId: stateData.find((s) => s.project_state_name === "En Revisión")?.id,
  };
}

async function lookupStudentProfile() {
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("id, user_names, user_last_names")
    .eq("email", STUDENT_EMAIL)
    .single();

  if (error) {
    throw new Error(`Student profile lookup failed: ${error.message}`);
  }

  return profile;
}

async function lookupInstitution() {
  const { data: institution, error } = await supabase
    .from("institutions")
    .select("id")
    .limit(1)
    .single();

  if (error) {
    throw new Error(`Institution lookup failed: ${error.message}`);
  }

  return institution;
}

async function createDocument(uploadedByProfileId) {
  const { data, error } = await supabase
    .from("documents")
    .insert({
      bucket_id: "project",
      storage_path: `test/${Date.now()}-external-delivery.pdf`,
      uploaded_by_profile_id: uploadedByProfileId,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id")
    .single();

  if (error) {
    throw new Error(`Document creation failed: ${error.message}`);
  }

  return data.id;
}

async function createProject(studentProfileId, institutionId) {
  const { data, error } = await supabase
    .from("projects")
    .insert({
      student_profile_id: studentProfileId,
      institution_id: institutionId,
      title: `External delivery test ${Date.now()}`,
      created_by: SEED_WORKER_ID,
      updated_by: SEED_WORKER_ID,
    })
    .select("id")
    .single();

  if (error) {
    throw new Error(`Project creation failed: ${error.message}`);
  }

  return data.id;
}

async function insertProjectProgress(projectId, phaseId, stateId, authorProfileId, documentId) {
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
    throw new Error(`project_progress insert failed: ${error.message}`);
  }

  return data.id;
}

async function processEventsQueue() {
  const { data, error } = await supabase.rpc("process_notification_events_queue", {
    p_batch_size: 100,
  });

  if (error) {
    throw new Error(`process_notification_events_queue failed: ${error.message}`);
  }

  return data;
}

async function findEventByProgressId(progressId) {
  const { data: event, error } = await supabase
    .from("notifications_events")
    .select("id")
    .eq("source_record_id", String(progressId))
    .order("id", { ascending: false })
    .limit(1)
    .single();

  if (error) {
    throw new Error(`Notification event lookup failed: ${error.message}`);
  }

  return event;
}

async function fetchRecipients(eventId) {
  const { data: recipients, error } = await supabase
    .from("notification_recipients")
    .select("id, recipient_id")
    .eq("notification_id", eventId);

  if (error) {
    throw new Error(`Recipients lookup failed: ${error.message}`);
  }

  return recipients ?? [];
}

async function fetchDeliveries(recipientNotificationIds) {
  const { data: deliveries, error } = await supabase
    .from("notifications_external_deliveries")
    .select("id, notification_recipient_id, to_channel, delivery_status, retry_count, error_message")
    .in("notification_recipient_id", recipientNotificationIds)
    .eq("to_channel", "email")
    .order("id", { ascending: true });

  if (error) {
    throw new Error(`Deliveries lookup failed: ${error.message}`);
  }

  return deliveries ?? [];
}

async function invokeExternalDeliveriesWorker() {
  const { data, error } = await supabase.rpc(
    "invoke_notifications_external_deliveries_worker",
    {
      p_batch_size: 100,
    },
  );

  if (error) {
    throw new Error(`invoke_notifications_external_deliveries_worker failed: ${error.message}`);
  }

  return data;
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  console.log("=== NOTIFICATIONS EXTERNAL DELIVERIES TEST ===");

  const [studentProfile, institution, phasesAndStates] = await Promise.all([
    lookupStudentProfile(),
    lookupInstitution(),
    lookupPhasesAndStates(),
  ]);

  if (!phasesAndStates.preproyectoId || !phasesAndStates.enRevisionId) {
    throw new Error("Required phase/state IDs not found");
  }

  const projectId = await createProject(studentProfile.id, institution.id);
  const documentId = await createDocument(studentProfile.id);
  const progressId = await insertProjectProgress(
    projectId,
    phasesAndStates.preproyectoId,
    phasesAndStates.enRevisionId,
    studentProfile.id,
    documentId,
  );

  const processedEventsCount = await processEventsQueue();
  console.log(`Events worker processed: ${processedEventsCount}`);

  const event = await findEventByProgressId(progressId);
  const { data: eventWithActor, error: eventWithActorError } = await supabase
    .from("notifications_events")
    .select("id, actor_id")
    .eq("id", event.id)
    .single();

  if (eventWithActorError) {
    throw new Error(`Notification event actor lookup failed: ${eventWithActorError.message}`);
  }

  const recipients = await fetchRecipients(event.id);

  if (recipients.length === 0) {
    throw new Error("No recipients produced by events worker");
  }

  const actorWasNotified = recipients.some(
    (recipient) => recipient.recipient_id === eventWithActor.actor_id,
  );
  if (actorWasNotified) {
    throw new Error("Action author should not be in notification_recipients");
  }

  const recipientNotificationIds = recipients.map((recipient) => recipient.id);

  const deliveriesBefore = await fetchDeliveries(recipientNotificationIds);
  if (deliveriesBefore.length === 0) {
    throw new Error("No notifications_external_deliveries rows created");
  }

  const hasNonPendingBefore = deliveriesBefore.some(
    (delivery) => delivery.delivery_status !== "pending",
  );
  if (hasNonPendingBefore) {
    throw new Error("Expected pending deliveries before edge worker processing");
  }

  const requestId = await invokeExternalDeliveriesWorker();
  console.log(`Worker invoked by pg_net request id: ${requestId}`);

  let deliveriesAfter = [];
  let pendingAfterCount = deliveriesBefore.length;
  for (let attempt = 0; attempt < 15; attempt += 1) {
    await sleep(1000);
    deliveriesAfter = await fetchDeliveries(recipientNotificationIds);
    pendingAfterCount = deliveriesAfter.filter(
      (delivery) => delivery.delivery_status === "pending",
    ).length;
    if (pendingAfterCount === 0) {
      break;
    }
  }

  if (pendingAfterCount > 0) {
    throw new Error(
      `Expected zero pending deliveries after webhook invocation. Pending: ${pendingAfterCount}`,
    );
  }

  const sentAfterCount = deliveriesAfter.filter((delivery) => delivery.delivery_status === "sent").length;
  if (sentAfterCount === 0) {
    throw new Error("Expected at least one sent external delivery");
  }

  if (sentAfterCount !== recipients.length) {
    throw new Error(
      `Expected sent deliveries to match recipients. sent=${sentAfterCount} recipients=${recipients.length}`,
    );
  }

  console.log(`Recipients: ${recipients.length}`);
  console.log(`Deliveries before: ${deliveriesBefore.length}`);
  console.log(`Sent after processing: ${sentAfterCount}`);
  console.log("=== TEST PASSED ===");
}

main().catch((error) => {
  console.error("TEST FAILED:", error.message);
  process.exit(1);
});
