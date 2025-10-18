# Bash Scripts

Helper scripts to set up the RIMS database, show example results, and export data for sharing.

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
```

Notes:
- These scripts assume local Postgres with peer authentication for the OS user `postgres`.
- If sudo prompts for your password, enter your Linux account password.
- To adapt for non-sudo environments, replace `sudo -u postgres psql ...` with your connection params (PGHOST/PGPORT/PGUSER/PGPASSWORD) and drop sudo.
 - For OneDrive upload automation consider `rclone` (onedrive remote): `rclone copy exports/*.tar.gz onedrive:YourFolder -P`
