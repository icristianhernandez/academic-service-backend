const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

const SEED_WORKER_ID = "00000000-0000-0000-0000-000000000001";
const STUDENT_EMAIL = "student@test.local";

async function lookupContext() {
  const [{ data: studentProfile, error: studentProfileError }, { data: institution, error: institutionError }, { data: stateData, error: stateError }, { data: phaseData, error: phaseError }] = await Promise.all([
    supabase
      .from("profiles")
      .select("id, user_names, user_last_names")
      .eq("email", STUDENT_EMAIL)
      .single(),
    supabase
      .from("institutions")
      .select("id")
      .limit(1)
      .single(),
    supabase
      .from("project_states")
      .select("id, project_state_name"),
    supabase
      .from("project_phases")
      .select("id, project_phase_name, phase_kind, report_number, project_phase_order")
      .order("project_phase_order", { ascending: true }),
  ]);

  if (studentProfileError) {
    throw new Error(`Student profile lookup failed: ${studentProfileError.message}`);
  }

  if (institutionError) {
    throw new Error(`Institution lookup failed: ${institutionError.message}`);
  }

  if (stateError) {
    throw new Error(`Project states lookup failed: ${stateError.message}`);
  }

  if (phaseError) {
    throw new Error(`Project phases lookup failed: ${phaseError.message}`);
  }

  const waitingStateId = stateData.find((state) => state.project_state_name === "En Espera")?.id;
  if (!waitingStateId) {
    throw new Error("En Espera state not found");
  }

  const preprojectPhase = phaseData.find((phase) => phase.phase_kind === "preproject");
  const finalReportPhase = phaseData.find((phase) => phase.phase_kind === "final_report");
  const approvedPhase = phaseData.find((phase) => phase.phase_kind === "approved");

  if (!preprojectPhase || !finalReportPhase || !approvedPhase) {
    throw new Error("Required fixed phases not found");
  }

  const reportPhasesByNumber = new Map();
  for (const phase of phaseData) {
    if (phase.phase_kind === "report") {
      reportPhasesByNumber.set(phase.report_number, phase);
    }
  }

  for (let reportNumber = 1; reportNumber <= 10; reportNumber += 1) {
    if (!reportPhasesByNumber.get(reportNumber)) {
      throw new Error(`Missing report phase for report_number ${reportNumber}`);
    }
  }

  const { data: studentRecord, error: studentRecordError } = await supabase
    .from("students")
    .select("id, school_id, schools!inner(faculty_id)")
    .eq("profile_id", studentProfile.id)
    .single();

  if (studentRecordError) {
    throw new Error(`Student record lookup failed: ${studentRecordError.message}`);
  }

  const facultyId = studentRecord?.schools?.faculty_id;
  if (!facultyId) {
    throw new Error("Student faculty not found");
  }

  return {
    studentProfile,
    institution,
    waitingStateId,
    preprojectPhase,
    finalReportPhase,
    approvedPhase,
    reportPhasesByNumber,
    facultyId,
  };
}

async function updateFacultyReportsCount(facultyId, reportsRequiredCount) {
  const { error } = await supabase
    .from("faculties")
    .update({ reports_required_count: reportsRequiredCount })
    .eq("id", facultyId);

  if (error) {
    throw new Error(`Faculty update failed: ${error.message}`);
  }
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
    .select("id")
    .single();

  if (error) {
    throw new Error(`Project creation failed: ${error.message}`);
  }

  return data.id;
}

async function createDocument(profileId, keySuffix) {
  const { data, error } = await supabase
    .from("documents")
    .insert({
      bucket_id: "project",
      storage_path: `test/${Date.now()}-${keySuffix}.pdf`,
      uploaded_by_profile_id: profileId,
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

  return { data, error };
}

async function expectProgressSuccess(label, payload) {
  const { data, error } = await insertProjectProgress(
    payload.projectId,
    payload.phaseId,
    payload.stateId,
    payload.authorProfileId,
    payload.documentId,
  );

  if (error) {
    throw new Error(`${label}: expected success, got error '${error.message}'`);
  }

  console.log(`PASS: ${label} (progress_id=${data.id})`);
}

async function expectProgressFailure(label, payload, expectedSnippet) {
  const { error } = await insertProjectProgress(
    payload.projectId,
    payload.phaseId,
    payload.stateId,
    payload.authorProfileId,
    payload.documentId,
  );

  if (!error) {
    throw new Error(`${label}: expected failure, insert succeeded`);
  }

  if (!error.message.includes(expectedSnippet)) {
    throw new Error(
      `${label}: expected error containing '${expectedSnippet}', got '${error.message}'`,
    );
  }

  console.log(`PASS: ${label} (error='${error.message}')`);
}

async function runZeroReportsScenario(context) {
  console.log("\n=== Scenario: 0 reports ===");
  await updateFacultyReportsCount(context.facultyId, 0);

  const projectId = await createProject(
    context.studentProfile.id,
    context.institution.id,
    `Phase flow test - 0 reports - ${Date.now()}`,
  );
  const documentId = await createDocument(context.studentProfile.id, "faculty-0");

  const basePayload = {
    projectId,
    stateId: context.waitingStateId,
    authorProfileId: context.studentProfile.id,
    documentId,
  };

  await expectProgressSuccess("0 reports: Preproyecto", {
    ...basePayload,
    phaseId: context.preprojectPhase.id,
  });

  await expectProgressFailure(
    "0 reports: Reporte 1 blocked",
    {
      ...basePayload,
      phaseId: context.reportPhasesByNumber.get(1).id,
    },
    "Faculty supports 0 reports",
  );

  await expectProgressSuccess("0 reports: Reporte Final", {
    ...basePayload,
    phaseId: context.finalReportPhase.id,
  });

  await expectProgressSuccess("0 reports: Aprobado", {
    ...basePayload,
    phaseId: context.approvedPhase.id,
  });
}

async function runTwoReportsScenario(context) {
  console.log("\n=== Scenario: 2 reports ===");
  await updateFacultyReportsCount(context.facultyId, 2);

  const projectId = await createProject(
    context.studentProfile.id,
    context.institution.id,
    `Phase flow test - 2 reports - ${Date.now()}`,
  );
  const documentId = await createDocument(context.studentProfile.id, "faculty-2");

  const basePayload = {
    projectId,
    stateId: context.waitingStateId,
    authorProfileId: context.studentProfile.id,
    documentId,
  };

  await expectProgressSuccess("2 reports: Preproyecto", {
    ...basePayload,
    phaseId: context.preprojectPhase.id,
  });

  await expectProgressSuccess("2 reports: Reporte 1", {
    ...basePayload,
    phaseId: context.reportPhasesByNumber.get(1).id,
  });

  await expectProgressSuccess("2 reports: Reporte 2", {
    ...basePayload,
    phaseId: context.reportPhasesByNumber.get(2).id,
  });

  await expectProgressFailure(
    "2 reports: Reporte 3 blocked",
    {
      ...basePayload,
      phaseId: context.reportPhasesByNumber.get(3).id,
    },
    "Faculty supports 2 reports",
  );

  await expectProgressSuccess("2 reports: Reporte Final", {
    ...basePayload,
    phaseId: context.finalReportPhase.id,
  });

  await expectProgressSuccess("2 reports: Aprobado", {
    ...basePayload,
    phaseId: context.approvedPhase.id,
  });
}

async function runTenReportsScenario(context) {
  console.log("\n=== Scenario: 10 reports ===");
  await updateFacultyReportsCount(context.facultyId, 10);

  const projectId = await createProject(
    context.studentProfile.id,
    context.institution.id,
    `Phase flow test - 10 reports - ${Date.now()}`,
  );
  const documentId = await createDocument(context.studentProfile.id, "faculty-10");

  const basePayload = {
    projectId,
    stateId: context.waitingStateId,
    authorProfileId: context.studentProfile.id,
    documentId,
  };

  await expectProgressSuccess("10 reports: Preproyecto", {
    ...basePayload,
    phaseId: context.preprojectPhase.id,
  });

  await expectProgressFailure(
    "10 reports: cannot skip to Reporte 3",
    {
      ...basePayload,
      phaseId: context.reportPhasesByNumber.get(3).id,
    },
    "Invalid transition",
  );

  for (let reportNumber = 1; reportNumber <= 10; reportNumber += 1) {
    await expectProgressSuccess(`10 reports: Reporte ${reportNumber}`, {
      ...basePayload,
      phaseId: context.reportPhasesByNumber.get(reportNumber).id,
    });
  }

  await expectProgressSuccess("10 reports: Reporte Final", {
    ...basePayload,
    phaseId: context.finalReportPhase.id,
  });

  await expectProgressSuccess("10 reports: Aprobado", {
    ...basePayload,
    phaseId: context.approvedPhase.id,
  });
}

async function main() {
  console.log("=== PROJECT PHASE FLOW BY FACULTY TEST ===");

  const context = await lookupContext();
  let originalReportsRequiredCount = null;

  try {
    const { data: facultyRow, error: facultyError } = await supabase
      .from("faculties")
      .select("reports_required_count")
      .eq("id", context.facultyId)
      .single();

    if (facultyError) {
      throw new Error(`Faculty baseline lookup failed: ${facultyError.message}`);
    }

    originalReportsRequiredCount = facultyRow.reports_required_count;

    await runZeroReportsScenario(context);
    await runTwoReportsScenario(context);
    await runTenReportsScenario(context);

    console.log("\n=== ALL FACULTY REPORT SCENARIOS PASSED ===");
  } finally {
    if (originalReportsRequiredCount !== null) {
      await updateFacultyReportsCount(context.facultyId, originalReportsRequiredCount);
      console.log(
        `\nRestored faculty reports_required_count=${originalReportsRequiredCount}`,
      );
    }
  }
}

main().catch((error) => {
  console.error("TEST FAILED:", error.message);
  process.exit(1);
});
