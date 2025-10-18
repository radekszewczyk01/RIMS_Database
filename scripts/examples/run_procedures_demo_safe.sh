#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQL_FILE="$ROOT_DIR/sql/examples/procedures_demo.sql"
LOGDIR="$ROOT_DIR/exports/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/procedures_demo_$(date +%Y%m%d_%H%M%S).log"

if [[ ! -f "$SQL_FILE" ]]; then
  echo "[safe-run] SQL file not found: $SQL_FILE" >&2
  exit 1
fi

echo "[safe-run] Log: $LOGFILE"

# If sudo -n succeeds, we can run without prompting; otherwise, instruct the user to run with sudo manually.
if sudo -n true 2>/dev/null; then
  echo "[safe-run] running demo as postgres (no password prompt) ..."
  # Run psql and capture output to log
  sudo -u postgres psql -d rims -f "$SQL_FILE" > "$LOGFILE" 2>&1 || true
  echo "[safe-run] finished. Log saved to: $LOGFILE"
  echo "[safe-run] Showing last 80 lines of log:"
  tail -n 80 "$LOGFILE" || true
else
  echo "[safe-run] sudo requires a password in this session; to avoid blocking prompts, run one of the following:" >&2
  echo "  1) Run the script with sudo so the terminal handles the prompt safely:" >&2
  echo "       sudo $0" >&2
  echo "  2) Or run psql as a configured DB user (no sudo). Example:" >&2
  echo "       export PGUSER=your_pg_user; ./scripts/examples/run_procedures_demo_safe.sh" >&2
  echo "  3) Or use the original runner interactively: ./scripts/examples/run_procedures_demo.sh" >&2
  exit 2
fi
