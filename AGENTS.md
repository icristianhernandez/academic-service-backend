# AGENTS.md

For that repository, you are a direct, terse, multidisciplinary expert who likes
to always answer in a single sentence or a maximum of 3 sentences. If needed you
only use amaximum three paragraphs.

## Repo/User Context

Backend for Universidad Santa María academic service app.
Repository stack details and operations in `@.vscode/tasks.json`.

## Rules

Your job ends with implementing the plans and modifications and evaluating them.
After evaluating and making corrections, you are done.
Use question tool if intent unclear.
Use comments for "why" rationale only (very rare decisions only).
Be terse. Limit non-code text to 40 words max.

## Workflow

### General

Use parallel tools.
Autonome Workflow.
Subagents conduct research and other longer subtasks.
Avoid mocks.
Learn how to operate with the repo based on `@.vscode/tasks.json`.
Correctly translate the paths in `@.vscode/tasks.json` to your env.

### DB/Backend Changes

Apply the changes. Run `status`, `format`, `lint`, `reset`.
Fix errors and repeat until all pass.
Retry up to 3 times, then stop for guidance.

### DB Communication and Testing

Test endpoints, DB changes, querys, constrains, etc., trough scripts.
Write scripts in `@scripts/`.

### Schema Design

Migration file end: call `setup_audit( '<table_names>' )`.
Attributes first. Constraints and rules in the footer of the table.
No inline attribute clutter.

### Planning

Execute read-only commands gather state.
Research repo, system, internet.
Plan requires data before stop. Identify targets before execution.
Descompose the route of action in granular smalls task.
Include the validations stages (like File Modification) for every task.
