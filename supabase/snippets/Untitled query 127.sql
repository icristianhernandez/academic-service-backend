SELECT 
    p.id as proyecto_id,
    p.title as nombre_proyecto,
    prof.user_names || ' ' || prof.user_last_names as estudiante
FROM projects p
JOIN profiles prof ON p.student_profile_id = prof.id

WHERE EXISTS (
    SELECT 1 FROM project_progress pp
    JOIN project_phases ph ON pp.project_phase_id = ph.id
    JOIN project_states ps ON pp.project_state_id = ps.id
    WHERE pp.project_id = p.id
      AND ph.project_phase_name = 'Preproyecto'
      AND ps.project_state_name = 'Aprobado'
)
AND NOT EXISTS (
    SELECT 1 FROM project_progress pp
    JOIN project_phases ph ON pp.project_phase_id = ph.id
    WHERE pp.project_id = p.id
      AND ph.project_phase_name = 'Reporte 1'
);
