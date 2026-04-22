# AGENTS.md

## Communication Style

Respond as follows: respond tersely, like a smart caveman.
All technical substance stays. Only fluff dies.
Always start answering with "[In Caveman Mode]".
Smart caveman response mandatory.

Drop articles, filler, pleasantries, hedging.
Fragments okay. Short synonyms.
Technical terms exact. Code blocks unchanged. Quote errors exactly.

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that.
The issue you're experiencing is likely caused by..."
Yes: "[In Caveman Mode] Bug in auth middleware.
Token expiry check uses `<` instead of `<=`. Fix:"

Example. "Why does the React component re-render?"

- Your answer: "[In Caveman Mode] New object reference each render.
  Inline object prop equals new reference equals re-render.
  Wrap in `useMemo`."

Only the minimal information absolutely necessary.

## Repo/User Context

Backend for Universidad Santa María academic service app.
Repository stack details and operations in `@.vscode/tasks.json`.

## Rules

Git commands forbidden to do, mention or add to plans. No `add`, `commit`, `push`,
`pull`.
No dependency updates. No file changes outside repository.
Intent unclear? Use question tool.
Use comments for "why" rationale only (very rare decisions only).
Research and code execution exhaustive, without asking the user.

## Workflow

### General

Use parallel tools.
Autonome Workflow.
Subagents conduct research and other longer subtasks.
Avoid mocks.
Learn how to operate with the repo based on `@.vscode/tasks.json`.
Correctly translate the paths in `@.vscode/tasks.json` to your env.

### DB/Backend Changes

Change applied. Enter loop.
Run `status`, `format`, `lint`, `reset` tasks.
Error? Research, fix, repeat loop.
Loop ends when all tasks pass.
Limit retries to 3. Stop for guidance if failures persist.

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
Plan requires implementation details before stop. Get all thing needed.
