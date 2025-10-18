-- 00_all.sql
-- Orchestrator script: run with psql -f 00_all.sql (from outside or inside DB)
-- Note: You must run 01_database.sql connected to a superuser DB (e.g., postgres),
-- then connect to rims and run 02 and 03.

\ir 01_database.sql

-- Connect to new DB (psql meta-command)
\connect rims

\ir 02_schema.sql
\ir 03_indexes_views.sql
