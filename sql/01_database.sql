-- 01_database.sql
-- Drops and creates the RIMS database (safe for repeated runs).

-- Terminate connections to RIMS if it exists
DO $$
BEGIN
   IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'rims') THEN
      PERFORM pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE datname = 'rims' AND pid <> pg_backend_pid();
   END IF;
END$$;

-- Drop and create database
DROP DATABASE IF EXISTS rims;
CREATE DATABASE rims;
