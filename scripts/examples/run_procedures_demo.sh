#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

SQL_FILE="$ROOT_DIR/sql/examples/procedures_demo.sql"
if [[ ! -f "$SQL_FILE" ]]; then
  echo "Not found: $SQL_FILE" >&2
  exit 1
fi

echo "[demo] Running procedures demo on rims..."
sudo -u postgres psql -d rims -f "$SQL_FILE"
echo "[demo] Done."
