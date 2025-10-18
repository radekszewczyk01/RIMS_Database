#!/usr/bin/env bash
set -euo pipefail

# Export PostgreSQL database (schema + CSV per table + index.html preview) into exports/ folder
# Defaults assume local Postgres and DB name 'rims'.
# By default commands execute as postgres OS user (sudo -u postgres) to avoid auth issues.

DB_NAME="rims"
DB_HOST=""
DB_PORT="${PGPORT:-5432}"
DB_USER="${PGUSER:-}"
OUTDIR=""
AS_POSTGRES=1
PREVIEW_ROWS=50
GEN_HTML=1

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --db NAME           Database name (default: rims)
  --host HOST         Host (default: local UNIX socket)
  --port PORT         Port (default: 5432 or PGPORT)
  --user USER         Database user (disables --as-postgres)
  --outdir PATH       Output directory (default: exports/rims_export_YYYYMMDD_HHMMSS)
  --no-html           Skip index.html generation
  --preview-rows N    Rows per table in HTML preview (default: 50)
  --as-postgres       Run pg_dump/psql as OS user 'postgres' via sudo (default)
  -h, --help          Show this help

Environment:
  PGUSER, PGHOST, PGPORT can override defaults if --user/--host/--port are not provided.
USAGE
}

while [[ ${1:-} =~ ^- ]]; do
  case "$1" in
    --db) DB_NAME="$2"; shift 2 ;;
    --host) DB_HOST="$2"; shift 2 ;;
    --port) DB_PORT="$2"; shift 2 ;;
    --user) DB_USER="$2"; AS_POSTGRES=0; shift 2 ;;
    --outdir) OUTDIR="$2"; shift 2 ;;
    --no-html) GEN_HTML=0; shift 1 ;;
    --preview-rows) PREVIEW_ROWS="$2"; shift 2 ;;
    --as-postgres) AS_POSTGRES=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

timestamp() { date +%Y%m%d_%H%M%S; }

if [[ -z "$OUTDIR" ]]; then
  OUTDIR="exports/rims_export_$(timestamp)"
fi

mkdir -p "$OUTDIR/csv"

run_psql() {
  local q="$1"
  if [[ $AS_POSTGRES -eq 1 ]]; then
    if [[ -n "$DB_HOST" ]]; then
      sudo -u postgres psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -XAtqc "$q"
    else
      sudo -u postgres psql -d "$DB_NAME" -XAtqc "$q"
    fi
  else
    if [[ -n "$DB_HOST" ]]; then
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -XAtqc "$q"
    else
      psql -U "$DB_USER" -d "$DB_NAME" -XAtqc "$q"
    fi
  fi
}

run_psql_file() {
  if [[ $AS_POSTGRES -eq 1 ]]; then
    if [[ -n "$DB_HOST" ]]; then
      sudo -u postgres psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -X "$@"
    else
      sudo -u postgres psql -d "$DB_NAME" -X "$@"
    fi
  else
    if [[ -n "$DB_HOST" ]]; then
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -X "$@"
    else
      psql -U "$DB_USER" -d "$DB_NAME" -X "$@"
    fi
  fi
}

run_pg_dump_schema() {
  if [[ $AS_POSTGRES -eq 1 ]]; then
    if [[ -n "$DB_HOST" ]]; then
      sudo -u postgres pg_dump -h "$DB_HOST" -p "$DB_PORT" -s -d "$DB_NAME"
    else
      sudo -u postgres pg_dump -s -d "$DB_NAME"
    fi
  else
    if [[ -n "$DB_HOST" ]]; then
      pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -s -d "$DB_NAME"
    else
      pg_dump -U "$DB_USER" -s -d "$DB_NAME"
    fi
  fi
}

run_copy_to_csv() {
  local tbl="$1" out="$2"
  local sql="COPY (SELECT * FROM \"$tbl\") TO STDOUT WITH CSV HEADER"
  if [[ $AS_POSTGRES -eq 1 ]]; then
    if [[ -n "$DB_HOST" ]]; then
      sudo -u postgres psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -c "$sql" > "$out"
    else
      sudo -u postgres psql -d "$DB_NAME" -c "$sql" > "$out"
    fi
  else
    if [[ -n "$DB_HOST" ]]; then
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" > "$out"
    else
      psql -U "$DB_USER" -d "$DB_NAME" -c "$sql" > "$out"
    fi
  fi
}

echo "Export: schema.sql"
run_pg_dump_schema > "$OUTDIR/schema.sql"

echo "Pobieram listę tabel..."
tables=$(run_psql "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;")

if [[ -z "$tables" ]]; then
  echo "Brak tabel w schemacie public lub brak uprawnień." >&2
fi

while IFS= read -r tbl; do
  [[ -z "$tbl" ]] && continue
  echo "Eksportuję tabelę: $tbl"
  run_copy_to_csv "$tbl" "$OUTDIR/csv/${tbl}.csv"
done <<< "$tables"

# README
cat > "$OUTDIR/README.md" <<EOM
# RIMS export

Zawartość paczki:
- schema.sql – definicja schematu bazy (tabele, klucze, widoki, bez danych)
- csv/*.csv – dane z każdej tabeli schematu public w formacie CSV (nagłówki kolumn)
- index.html – podgląd pierwszych $PREVIEW_ROWS wierszy każdej tabeli (jeśli włączone)

Jak odtworzyć:
- Import CSV: w dowolnym narzędziu (psql, DBeaver, Excel) wczytaj pliki z folderu csv.
- Odtworzenie schematu: psql -f schema.sql (na pustej bazie) – następnie załaduj CSV zgodnie z kolejnością zależności.

Uwaga: Paczka przeznaczona jest tylko do odczytu i inspekcji danych.
EOM

if [[ $GEN_HTML -eq 1 ]]; then
  echo "Generuję index.html (podgląd CSV)..."
  python3 "$(dirname "$0")/make_index_html.py" "$OUTDIR/csv" "$OUTDIR/index.html" "$PREVIEW_ROWS"
fi

# Spakuj
ARCHIVE="${OUTDIR}.tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")"
echo "Gotowe: $ARCHIVE"

echo "\nWrzucenie na OneDrive: możesz użyć przeglądarki lub rclone (jeśli skonfigurowany):"
echo "rclone copy '$ARCHIVE' onedrive:FolderNaOneDrive -P"
