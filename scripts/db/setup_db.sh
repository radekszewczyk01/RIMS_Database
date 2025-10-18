#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
sudo -u postgres psql < "$ROOT_DIR/sql/00_all.sql"
sudo -u postgres psql -d rims < "$ROOT_DIR/sql/data_and_features.sql"
echo "[setup_db] Done."
