# AGENTS.md

The guidelines written here must be followed in all scenarios exactly as they
are written.

## Repo/User Context

This is the backend for an academic service app for Universidad Santa María,
Venezuela. You can view the (tasks) and get an idea of the repository stack
in: @.vscode/tasks.json

## Rules

Never perform, suggest, or include plans to execute a git add, git commit,
git push/pull, dependency installation or update, or the removal or
modification of files outside the current repository.

Do not make assumptions about the user request; if something is unstated or
ambiguous, ask the user for clarification using the question tool. After
completing the user request, provide the user with a short, direct response.

Answer shortly to a user request, preferably in one paragraph of no more than
two lines. If more space is needed to avoid cutting details, it is allowed.
This constraint does not apply to research, running subcommands, code, and so on.
For all tasks required to answer or fulfill a user request, perform them exhaustively.

## Workflow

### When performing DB/Backend changes

After making changes, read the repository tasks.json and enter an iterative
loop to:

- Check if Supabase is active (status task).
- Apply the (format task).
- Apply the (lint task).
- Run the DB (reset task).
- If any of these (tasks) return an error, analyze the cause, research
  solutions, apply them, and repeat the loop until all tasks pass.
- You have permission to run these tasks and their associated commands.

### When communicating directly with the DB

To test endpoints and behaviors, write scripts in @scripts/ and run them to
check connections, queries, constraints, etc.

## Schema design conventions

You must do a " call setup_audit( {comma separated string of table names} )"
when adding new tables in a migration; this should be placed at the end of
the file once all tables have been added and contain all tables in the call.

Additionally, define all constraints, validations, and business rules for
table attributes in the table creation after defining the attributes (at the
'footer' of the table creation) to avoid cluttering inline attribute
definitions.
