#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/docs/generated"
CORE_DOC="$OUTPUT_DIR/schema-core.md"
ADVANCED_DOC="$OUTPUT_DIR/schema-advanced.md"
ERD_DOC="$OUTPUT_DIR/erd.mmd"

mkdir -p "$OUTPUT_DIR"

if ! STATUS_ENV="$(cd "$REPO_ROOT" && npx supabase status -o env 2>/dev/null)"; then
  echo "Supabase local is not running. Start it first with: npx supabase start" >&2
  exit 1
fi

DB_URL="$(printf '%s\n' "$STATUS_ENV" | sed -n 's/^DB_URL=//p' | tail -n 1)"
if [[ -z "$DB_URL" ]]; then
  echo "Could not read DB_URL from 'npx supabase status -o env'." >&2
  exit 1
fi

psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off >"$CORE_DOC" <<'SQL'
\pset format wrapped
\pset border 2
\pset linestyle unicode
\pset title 'Schema Core (tables, columns, types, constraints, defaults, nullable)'
\echo '# Schema Core'
\echo ''
\echo 'Generated from Supabase local metadata.'
\echo ''
with table_list as (
  select
    table_schema,
    table_name
  from information_schema.tables
  where table_type = 'BASE TABLE'
    and table_schema not in ('pg_catalog', 'information_schema')
    and table_schema not like 'pg_toast%'
),
column_constraints as (
  select
    kcu.table_schema,
    kcu.table_name,
    kcu.column_name,
    string_agg(
      case
        when tc.constraint_type = 'FOREIGN KEY' then
          tc.constraint_type || ' -> ' || ccu.table_schema || '.' || ccu.table_name || '(' || ccu.column_name || ')'
        else tc.constraint_type
      end,
      ', '
      order by tc.constraint_type
    ) as constraints
  from information_schema.table_constraints tc
  join information_schema.key_column_usage kcu
    on tc.constraint_name = kcu.constraint_name
   and tc.table_schema = kcu.table_schema
   and tc.table_name = kcu.table_name
  left join information_schema.constraint_column_usage ccu
    on ccu.constraint_name = tc.constraint_name
   and ccu.constraint_schema = tc.table_schema
  where tc.table_schema not in ('pg_catalog', 'information_schema')
  group by
    kcu.table_schema,
    kcu.table_name,
    kcu.column_name
)
select
  c.table_schema as schema,
  c.table_name as table_name,
  c.ordinal_position as position,
  c.column_name,
  case
    when c.data_type in ('character varying', 'character')
      and c.character_maximum_length is not null then c.data_type || '(' || c.character_maximum_length || ')'
    when c.data_type in ('numeric', 'decimal')
      and c.numeric_precision is not null then c.data_type || '(' || c.numeric_precision || ',' || coalesce(c.numeric_scale, 0) || ')'
    else c.data_type
  end as data_type,
  coalesce(cc.constraints, '') as constraints,
  c.column_default as default_value,
  c.is_nullable
from information_schema.columns c
join table_list t
  on t.table_schema = c.table_schema
 and t.table_name = c.table_name
left join column_constraints cc
  on cc.table_schema = c.table_schema
 and cc.table_name = c.table_name
 and cc.column_name = c.column_name
order by
  c.table_schema,
  c.table_name,
  c.ordinal_position;
SQL

{
  cat <<'MD'
# Advanced Schema Objects

Generated from Supabase local metadata.

## Views

MD
  psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off -P format=wrapped -P border=2 -P linestyle=unicode -c "
    select table_schema as schema_name, table_name as view_name
    from information_schema.views
    where table_schema not in ('pg_catalog', 'information_schema')
    order by table_schema, table_name;
  "

  cat <<'MD'

## Functions

MD
  psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off -P format=wrapped -P border=2 -P linestyle=unicode -c "
    select n.nspname as schema_name,
           p.proname as function_name,
           pg_get_function_identity_arguments(p.oid) as arguments,
           pg_get_function_result(p.oid) as returns
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname not in ('pg_catalog', 'information_schema')
    order by n.nspname, p.proname;
  "

  cat <<'MD'

## Triggers

MD
  psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off -P format=wrapped -P border=2 -P linestyle=unicode -c "
    select trigger_schema as schema_name,
           event_object_table as table_name,
           trigger_name,
           string_agg(event_manipulation, ', ' order by event_manipulation) as events,
           action_timing as timing
    from information_schema.triggers
    where trigger_schema not in ('pg_catalog', 'information_schema')
    group by trigger_schema, event_object_table, trigger_name, action_timing
    order by trigger_schema, event_object_table, trigger_name;
  "

  cat <<'MD'

## RLS (row-level security)

### Tables with RLS enabled

MD
  psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off -P format=wrapped -P border=2 -P linestyle=unicode -c "
    select schemaname as schema_name,
           tablename as table_name,
           rowsecurity as rls_enabled,
           forcerowsecurity as force_rls
    from pg_tables
    where schemaname not in ('pg_catalog', 'information_schema')
    order by schemaname, tablename;
  "

  cat <<'MD'

### Policies

MD
  psql "$DB_URL" -v ON_ERROR_STOP=1 -P pager=off -P format=wrapped -P border=2 -P linestyle=unicode -c "
    select schemaname as schema_name,
           tablename as table_name,
           policyname as policy_name,
           cmd as command,
           roles,
           permissive,
           qual,
           with_check
    from pg_policies
    order by schemaname, tablename, policyname;
  "
} >"$ADVANCED_DOC"

{
  echo "erDiagram"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -At -F $'\t' -P pager=off -c "
    with primary_keys as (
      select
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
      from information_schema.table_constraints tc
      join information_schema.key_column_usage kcu
        on tc.constraint_name = kcu.constraint_name
       and tc.table_schema = kcu.table_schema
       and tc.table_name = kcu.table_name
      where tc.constraint_type = 'PRIMARY KEY'
    ),
    foreign_keys as (
      select
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
      from information_schema.table_constraints tc
      join information_schema.key_column_usage kcu
        on tc.constraint_name = kcu.constraint_name
       and tc.table_schema = kcu.table_schema
       and tc.table_name = kcu.table_name
      where tc.constraint_type = 'FOREIGN KEY'
    )
    select
      c.table_schema,
      c.table_name,
      c.column_name,
      c.data_type,
      (pk.column_name is not null)::int as is_primary_key,
      (fk.column_name is not null)::int as is_foreign_key
    from information_schema.columns c
    left join primary_keys pk
      on pk.table_schema = c.table_schema
     and pk.table_name = c.table_name
     and pk.column_name = c.column_name
    left join foreign_keys fk
      on fk.table_schema = c.table_schema
     and fk.table_name = c.table_name
     and fk.column_name = c.column_name
    where c.table_schema not in ('pg_catalog', 'information_schema')
      and c.table_schema not like 'pg_toast%'
    order by c.table_schema, c.table_name, c.ordinal_position;
  " | awk -F '\t' '
    {
      schema = $1
      table = $2
      column = $3
      data_type = $4
      is_pk = $5
      is_fk = $6
      table_key = schema "." table
      if (current_table != table_key) {
        if (current_table != "") {
          print "  }"
        }
        print "  " schema "_" table " {"
        current_table = table_key
      }
      flags = ""
      if (is_pk == 1) flags = flags " PK"
      if (is_fk == 1) flags = flags " FK"
      print "    " data_type " " column flags
    }
    END {
      if (current_table != "") {
        print "  }"
      }
    }
  '

  psql "$DB_URL" -v ON_ERROR_STOP=1 -At -F $'\t' -P pager=off -c "
    select
      tc.table_schema as source_schema,
      tc.table_name as source_table,
      kcu.column_name as source_column,
      ccu.table_schema as target_schema,
      ccu.table_name as target_table,
      ccu.column_name as target_column
    from information_schema.table_constraints tc
    join information_schema.key_column_usage kcu
      on tc.constraint_name = kcu.constraint_name
     and tc.table_schema = kcu.table_schema
    join information_schema.constraint_column_usage ccu
      on ccu.constraint_name = tc.constraint_name
     and ccu.constraint_schema = tc.table_schema
    where tc.constraint_type = 'FOREIGN KEY'
      and tc.table_schema not in ('pg_catalog', 'information_schema')
    order by source_schema, source_table, source_column;
  " | awk -F '\t' '{
    print "  " $4 "_" $5 " ||--o{ " $1 "_" $2 " : \"" $6 " -> " $3 "\""
  }'
} >"$ERD_DOC"

echo "Generated:"
echo "  - $CORE_DOC"
echo "  - $ADVANCED_DOC"
echo "  - $ERD_DOC"
