# Backup Module

Creates logical PostgreSQL backups of the Supabase production database via `pg_dump`. Designed to run on an external server (VPS).

## Dependencies

```bash
# Debian/Ubuntu
sudo apt install postgresql-client

# macOS (already ships with pg_dump on recent versions, or via Postgres.app)
```

## Setup

```bash
cp .env.example .env
# Edit .env with your Supabase project connection string
vim .env
```

Get the connection URI from Supabase Dashboard → **Settings → Database → Connection string URI**. Use the **direct connection** (port 5432), not the pooler (port 6543).

## Usage

```bash
# Create a daily backup (for cron)
./backup.sh --daily

# Create a manual backup (timestamped, no auto-cleanup)
./backup.sh --manual

# Apply retention rules only
./backup.sh --cleanup
```

## Cron Installation

```bash
# Copy the cron entry
cat cron.conf

# Edit crontab
crontab -e
# Paste the line, adjust the path to backup.sh
```

## Restore

```bash
psql "$SUPABASE_DB_URL" < /path/to/backup.sql
```

For large databases, use `pg_restore` if the dump was created with `--format=custom`, or pipe the SQL file directly.

## File Layout

```
$BACKUP_DIR/
├── daily/       ← kept: $RETENTION_DAILY newest
├── weekly/      ← kept: $RETENTION_WEEKLY newest, promoted each Sunday
└── manual/      ← never auto-deleted
```

## Retention

Configured via `.env`:
| Variable          | Default | Description                     |
|-------------------|---------|---------------------------------|
| `RETENTION_DAILY` | 3       | Number of daily backups to keep |
| `RETENTION_WEEKLY`| 4       | Number of weekly backups to keep|
| `WEEKLY_DAY`      | 0       | Day of week for promotion (Sun) |
