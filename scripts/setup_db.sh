#!/usr/bin/env bash
set -euo pipefail

# Resolve project root as parent of this script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "[setup_db] Running 00_all.sql (requires sudo for postgres OS user)..."
# Use stdin redirection so radek reads the file and postgres just reads stdin
sudo -u postgres psql < "$ROOT_DIR/sql/00_all.sql"

echo "[setup_db] Loading data_and_features.sql into rims (requires sudo)..."
sudo -u postgres psql -d rims < "$ROOT_DIR/sql/data_and_features.sql"

echo "[setup_db] Done."