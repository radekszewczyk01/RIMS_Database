# Bash Scripts

Helper scripts to set up the RIMS database and show example results.

- `setup_db.sh` – runs `sql/00_all.sql` and `sql/data_and_features.sql` using the OS `postgres` user via sudo.
- `show_results.sh` – prints the results for key verification queries.

Usage:

```bash
# Make executable once
chmod +x scripts/*.sh

# Create DB + schema + data + features
./scripts/setup_db.sh

# Show selected results
./scripts/show_results.sh
```

Notes:
- These scripts assume local Postgres with peer authentication for the OS user `postgres`.
- If sudo prompts for your password, enter your Linux account password.
- To adapt for non-sudo environments, replace `sudo -u postgres psql ...` with your connection params (PGHOST/PGPORT/PGUSER/PGPASSWORD) and drop sudo.
