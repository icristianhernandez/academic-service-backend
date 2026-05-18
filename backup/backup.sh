#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

BACKUP_DIR="${BACKUP_DIR:-/var/backups/academic-service}"
RETENTION_DAILY="${RETENTION_DAILY:-3}"
RETENTION_WEEKLY="${RETENTION_WEEKLY:-4}"
WEEKLY_DAY="${WEEKLY_DAY:-0}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { log "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage: backup.sh --daily | --manual | --cleanup

  --daily    Create a daily backup, promote to weekly on Sunday, then run retention
  --manual   Create a manual backup (timestamped, no auto-cleanup)
  --cleanup  Apply retention rules (keep last \$RETENTION_DAILY daily + \$RETENTION_WEEKLY weekly)
EOF
  exit 0
}

check_pg_dump() {
  command -v pg_dump >/dev/null 2>&1 || error "pg_dump not found. Install postgresql-client."
}

ensure_dirs() {
  mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/weekly" "$BACKUP_DIR/manual"
}

require_db_url() {
  : "${SUPABASE_DB_URL:?SUPABASE_DB_URL not set}"
}

dump() {
  require_db_url
  local output="$1"
  log "Running pg_dump → $output"
  pg_dump "$SUPABASE_DB_URL" \
    --no-owner \
    --no-acl \
    --exclude-schema=auth \
    --exclude-schema=storage \
    --exclude-schema=extensions \
    --exclude-schema=supabase_migrations \
    -f "$output"
  log "Done ($(du -h "$output" | cut -f1))"
}

cleanup_globs() {
  local dir="$1" max="$2" pattern="$3"
  find "$dir" -maxdepth 1 -name "$pattern" -printf '%f\n' 2>/dev/null |
    sort -r |
    tail -n +$((max + 1)) |
    while read -r f; do
      rm -f "$dir/$f"
      log "Removed old backup: $f"
    done || true
}

do_cleanup() {
  log "Running retention: keep $RETENTION_DAILY daily, $RETENTION_WEEKLY weekly"
  cleanup_globs "$BACKUP_DIR/daily" "$RETENTION_DAILY" "*.sql"
  cleanup_globs "$BACKUP_DIR/weekly" "$RETENTION_WEEKLY" "*.sql"
  log "Cleanup done"
}

do_daily() {
  check_pg_dump
  ensure_dirs

  local date_str week_str dow
  date_str=$(date '+%Y-%m-%d')
  week_str=$(date '+%Y-W%V')
  dow=$(date '+%w')
  local output="$BACKUP_DIR/daily/$date_str.sql"

  dump "$output"

  if [ "$dow" = "$WEEKLY_DAY" ]; then
    cp "$output" "$BACKUP_DIR/weekly/$week_str.sql"
    log "Promoted to weekly: $week_str.sql"
  fi

  do_cleanup
}

do_manual() {
  check_pg_dump
  ensure_dirs

  local ts output
  ts=$(date '+%Y-%m-%d_%H%M%S')
  output="$BACKUP_DIR/manual/$ts.sql"

  dump "$output"
  log "Manual backup: $output"
}

case "${1:-}" in
  --daily|daily) do_daily ;;
  --manual|manual) do_manual ;;
  --cleanup|cleanup) do_cleanup ;;
  *) usage ;;
esac
