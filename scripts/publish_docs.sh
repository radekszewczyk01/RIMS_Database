#!/usr/bin/env bash
set -euo pipefail

# Copy the latest export (schema + csv + index.html) into docs/ so that GitHub Pages can host it.
# If no export exists yet, it will generate a fresh one into a temp dir and then copy.

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
EXPORTS_DIR="$ROOT_DIR/exports"
DOCS_DIR="$ROOT_DIR/docs"

mkdir -p "$EXPORTS_DIR" "$DOCS_DIR"

# Find latest export folder (unpacked). If only tar.gz exists, unpack it.
latest_folder=""

if compgen -G "$EXPORTS_DIR/rims_export_*" > /dev/null; then
  # Prefer unpacked folder over tar.gz
  latest_folder=$(ls -1dt "$EXPORTS_DIR"/rims_export_* 2>/dev/null | head -n1 || true)
fi

if [[ -z "$latest_folder" || ! -d "$latest_folder" ]]; then
  # Try unpacking the latest tar.gz
  latest_archive=$(ls -1t "$EXPORTS_DIR"/rims_export_*.tar.gz 2>/dev/null | head -n1 || true)
  if [[ -n "$latest_archive" ]]; then
    echo "Unpacking $latest_archive"
    tar -xzf "$latest_archive" -C "$EXPORTS_DIR"
    latest_folder="${latest_archive%.tar.gz}"
  fi
fi

if [[ -z "$latest_folder" || ! -d "$latest_folder" ]]; then
  echo "No export found. Generating a new one..."
  "$ROOT_DIR/scripts/export_rims.sh" --as-postgres --preview-rows 50
  latest_archive=$(ls -1t "$EXPORTS_DIR"/rims_export_*.tar.gz | head -n1)
  tar -xzf "$latest_archive" -C "$EXPORTS_DIR"
  latest_folder="${latest_archive%.tar.gz}"
fi

echo "Publishing $latest_folder to docs/"
mkdir -p "$DOCS_DIR/csv"
cp -f "$latest_folder/schema.sql" "$DOCS_DIR/schema.sql"
cp -f "$latest_folder/index.html" "$DOCS_DIR/index.html"
cp -f "$latest_folder/README.md" "$DOCS_DIR/README.md" || true
cp -f "$latest_folder"/csv/*.csv "$DOCS_DIR/csv/"

echo "Docs prepared in $DOCS_DIR. Commit and push them to main to publish via GitHub Pages."
