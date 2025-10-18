#!/usr/bin/env bash
set -euo pipefail

# One-shot: export schema+CSV+HTML, publish to docs/, and push to GitHub Pages (main/docs)

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# 1) Export (local socket, sudo -u postgres) with preview rows
./scripts/export_rims.sh --as-postgres --preview-rows 50

# 2) Publish to docs/
./scripts/publish_docs.sh

# 3) Commit and push to main (Pages uses /docs)
git add docs
COMMIT_MSG=${1:-"docs: refresh GitHub Pages preview"}
git commit -m "$COMMIT_MSG" || echo "No changes to commit."
git push origin HEAD:main || true

echo "Done. If not yet enabled, configure GitHub Pages: Settings → Pages → Deploy from a branch → main /docs"
