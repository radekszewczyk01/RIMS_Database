# Bash Scripts

Helper scripts to set up the RIMS database, show example results, and export data for sharing.

Folder structure:
- `db/` – database lifecycle helpers (e.g., `setup_db.sh`).
- `export/` – export/publish helpers (kept top-level for backwards compatibility wrappers).
- `examples/` – runnable examples (e.g., procedure demo).

- `setup_db.sh` – runs `sql/00_all.sql` and `sql/data_and_features.sql` using the OS `postgres` user via sudo.
- `show_results.sh` – prints the results for key verification queries.
- `export_rims.sh` – exports schema.sql, CSV per table, and generates index.html preview; outputs a tar.gz ready to upload (e.g., OneDrive).

Usage:

```bash
# Make executable once
chmod +x scripts/*.sh

# Create DB + schema + data + features
./scripts/setup_db.sh

# Show selected results
./scripts/show_results.sh

# Export schema + CSV + index.html to exports/<timestamp> and create tar.gz archive
./scripts/export_rims.sh

# Customize (examples):
# Use a specific DB user (no sudo), host and database
./scripts/export_rims.sh --user myuser --host localhost --db rims

# Skip HTML preview or change number of rows in preview
./scripts/export_rims.sh --no-html
./scripts/export_rims.sh --preview-rows 100

# Run procedure usage demo (InsertNewArticle, UpdateWR)
./scripts/examples/run_procedures_demo.sh
```

## GitHub Pages (podgląd danych w przeglądarce)

Włączenie:
1. Na GitHub: Settings → Pages.
2. Build and deployment: Deploy from a branch.
3. Branch: `main`, Folder: `/docs`.

Odświeżanie zawartości `docs/`:
```bash
# Jednym krokiem (eksport → publikacja → commit/push)
./scripts/refresh_pages.sh "docs: refresh GitHub Pages preview"

# Albo manualnie krok po kroku
./scripts/export_rims.sh --as-postgres --preview-rows 50
./scripts/publish_docs.sh
git add docs
git commit -m "docs: refresh GitHub Pages preview"
git push origin HEAD:main
```

Notes:
- These scripts assume local Postgres with peer authentication for the OS user `postgres`.
- If sudo prompts for your password, enter your Linux account password.
- To adapt for non-sudo environments, replace `sudo -u postgres psql ...` with your connection params (PGHOST/PGPORT/PGUSER/PGPASSWORD) and drop sudo.
 - For OneDrive upload automation consider `rclone` (onedrive remote): `rclone copy exports/*.tar.gz onedrive:YourFolder -P`
