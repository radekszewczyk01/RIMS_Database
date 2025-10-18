#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

run() {
  local q="$1"
  echo -e "\n[query] $q"
  sudo -u postgres psql -d rims -c "$q"
}

run "SELECT COUNT(*) FROM Artykul;"
run "SELECT * FROM \"Widok_Wycofane_Artykuły_Wydawcy\" LIMIT 10;"
# Print the next view in compact, pager-safe format
echo -e "\n[query] SELECT * FROM Widok_Ryzykowne_Finansowanie LIMIT 10; (compact output)"
sudo -u postgres psql -d rims -XAtqc "SELECT * FROM Widok_Ryzykowne_Finansowanie LIMIT 10;"
run "SELECT * FROM LogOceny ORDER BY id_logu DESC LIMIT 5;"

echo -e "\n[show_results] Done."