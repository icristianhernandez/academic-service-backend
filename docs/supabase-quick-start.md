# Supabase Quick Start

## Sources / Docs

- https://supabase.com/docs/guides/local-development
- https://supabase.com/docs/guides/local-development/cli/getting-started
- https://supabase.com/docs/guides/local-development/overview

## Add / Update supabase to the repo

Install supabase as a development dependency:

```bash
npm install supabase --save-dev
```

If updating, clean supabase first to allow a clean update:

```bash
npx supabase db diff -f my_schema
npx supabase db dump --local --data-only > supabase/seed.sql
npx supabase stop --no-backup
```

To create the supabase DB in the repo (first time command):

```bash
npx supabase init
```

## Start supabase instance

```bash
npx supabase start
```

## Stop supabase instance

```bash
npx supabase stop
```

## Migrations (for adding or altering DB objects locally — rules and tables, not rows)

- Diff local changes made through Local Studio (localhost:54323).
- You can view per-table SQL definitions through the dashboard and use these for migration files.

Create a diff-based migration:

```bash
npx supabase db diff --use-pg-schema -f <feature-name>
```

This creates:

```
supabase/migrations/<timestamp>_<feature-name>.sql
```

Review the generated SQL file and make any necessary adjustments.

Create a new migration and write SQL directly:

```bash
npx supabase migration new <feature-name>
```

This creates:

```
supabase/migrations/<timestamp>_<feature-name>.sql
```

Add the SQL to the above file.

Reset the DB to the current migrations (applied):

```bash
npx supabase db reset
```

## Seed / Sample data (persisted across restarts for debugging)

- Seed file location: `supabase/seed.sql`
- Write initial/persistent data in SQL.
- You can dump the current session's seeded data:

```bash
npx supabase db dump --local --data-only > supabase/seed.sql
```

## Deploy changes

Login and link your project:

```bash
npx supabase login
npx supabase link --project-ref <project-id>
```

You can get `<project-id>` from your project's dashboard URL: https://supabase.com/dashboard/project/<project-id>

Apply migrations/changes from the remote instance:

```bash
npx supabase db pull
npx supabase migration up
npx supabase db reset
```

Push DB changes:

```bash
npx supabase db push
```

Deploy Edge Functions (if used):

```bash
npx supabase functions deploy <function_name>
```
