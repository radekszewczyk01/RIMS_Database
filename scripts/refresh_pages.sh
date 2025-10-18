#!/usr/bin/env bash
set -euo pipefail

# Refresh GitHub Pages (docs/) after DB changes:
# 1) export schema+CSV+index.html
# 2) publish to docs/
# 3) commit & push to main

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

MSG=${1:-"docs: refresh GitHub Pages preview"}

./scripts/export_and_publish.sh "$MSG"

echo "Pages refreshed. If Pages not enabled: Settings → Pages → Deploy from a branch → main /docs"
