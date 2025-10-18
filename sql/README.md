# RIMS PostgreSQL Schema

This folder contains SQL scripts to create the RIMS database, schema, indexes, and views according to the provided ERD and normalization guidelines.

## Files
- `00_all.sql` – orchestrates all steps: creates DB, connects, creates schema, indexes, and views.
- `01_database.sql` – drops and creates the `rims` database (kills existing connections first).
- `02_schema.sql` – defines all tables with PKs/FKs and constraints (3NF: Wydawca, Afiliacja, Dyscypliny, Czasopisma, Autor, Artykul, ZrodloFinansowania, Artykul_Autor, Artykul_ZrodloFinansowania, LogOceny, Cytowanie, ZarzutNierzetelnosci).
- `03_indexes_views.sql` – creates indexes and views: `Widok_Wycofane_Artykuły_Wydawcy`, `Widok_Ryzykowne_Finansowanie`.

## Requirements
- PostgreSQL server and `psql` client installed.
- A superuser or a user with privileges to create databases.

## How to run

From this `sql` directory:

```bash
# Using default superuser 'postgres' and local socket
psql -U postgres -f 00_all.sql
```

If your PostgreSQL runs on a different host/port or with a different user:

```bash
PGHOST=localhost PGPORT=5432 PGUSER=your_user psql -f 00_all.sql
```

You can also run step-by-step:

```bash
psql -U postgres -f 01_database.sql
psql -U postgres -d rims -f 02_schema.sql
psql -U postgres -d rims -f 03_indexes_views.sql
```

## Notes
- The spec asked for an index on `data_publikacji` in `Artykul`. The schema uses `rok_publikacji` and `data_ostatniej_aktualizacji`; both are indexed as practical alternatives.
- Cross-table composite indexes are not supported; instead, separate indexes are provided on `Artykul(wspolczynnik_rzetelnosci)` and `Afiliacja(kraj)`, plus join helper indexes on `Artykul_Autor`.
- Foreign keys use `ON UPDATE CASCADE`. Deletion policies are conservative (`RESTRICT` or `CASCADE` where association/log tables). Adjust as needed for your data lifecycle.
