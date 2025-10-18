-- 02_schema.sql
-- Create all tables for RIMS with 3NF normalization per wymagania

BEGIN;

-- Schema namespace (optional)
CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public;

-- 1. Wydawca
CREATE TABLE IF NOT EXISTS Wydawca (
  id_wydawcy SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  kraj VARCHAR(100),
  srednia_retrakcji DECIMAL(4,3),
  czy_otwarty_dostep BOOLEAN
);

-- 2. Afiliacja
CREATE TABLE IF NOT EXISTS Afiliacja (
  id_afiliacji SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) UNIQUE NOT NULL,
  kraj VARCHAR(100),
  miasto VARCHAR(100)
);

-- 3. Dyscypliny (dictionary)
CREATE TABLE IF NOT EXISTS Dyscypliny (
  id_dyscypliny SERIAL PRIMARY KEY,
  nazwa VARCHAR(100) UNIQUE NOT NULL
);

-- 4. Czasopisma (normalized: links to Wydawca and Dyscypliny)
CREATE TABLE IF NOT EXISTS Czasopisma (
  id_czasopisma SERIAL PRIMARY KEY,
  tytul VARCHAR(255) UNIQUE NOT NULL,
  impact_factor DECIMAL(5,3),
  id_wydawcy INT REFERENCES Wydawca(id_wydawcy) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_dyscypliny INT REFERENCES Dyscypliny(id_dyscypliny) ON UPDATE CASCADE ON DELETE SET NULL
);

-- 5. Autor (FK to Afiliacja)
CREATE TABLE IF NOT EXISTS Autor (
  id_autora SERIAL PRIMARY KEY,
  imie VARCHAR(100),
  nazwisko VARCHAR(150) NOT NULL,
  orcid VARCHAR(50) UNIQUE,
  id_afiliacji INT REFERENCES Afiliacja(id_afiliacji) ON UPDATE CASCADE ON DELETE SET NULL
);

-- 6. ZrodloFinansowania
CREATE TABLE IF NOT EXISTS ZrodloFinansowania (
  id_zrodla SERIAL PRIMARY KEY,
  nazwa VARCHAR(255) NOT NULL,
  typ VARCHAR(100),
  kraj VARCHAR(100)
);

-- 7. Artykul (FK to Czasopisma)
CREATE TABLE IF NOT EXISTS Artykul (
  id_artykulu SERIAL PRIMARY KEY,
  tytul VARCHAR(500) NOT NULL,
  doi VARCHAR(100) UNIQUE NOT NULL,
  rok_publikacji INT NOT NULL,
  punkty_mein INT,
  wspolczynnik_rzetelnosci DECIMAL(4,3),
  data_ostatniej_aktualizacji DATE,
  id_czasopisma INT REFERENCES Czasopisma(id_czasopisma) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 8. Artykul_Autor (N:M) composite PK
CREATE TABLE IF NOT EXISTS Artykul_Autor (
  id_artykulu INT NOT NULL,
  id_autora INT NOT NULL,
  kolejnosc_autora INT,
  PRIMARY KEY (id_artykulu, id_autora),
  FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (id_autora) REFERENCES Autor(id_autora) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 9. Artykul_ZrodloFinansowania (N:M) composite PK
CREATE TABLE IF NOT EXISTS Artykul_ZrodloFinansowania (
  id_artykulu INT NOT NULL,
  id_zrodla INT NOT NULL,
  PRIMARY KEY (id_artykulu, id_zrodla),
  FOREIGN KEY (id_artykulu) REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (id_zrodla) REFERENCES ZrodloFinansowania(id_zrodla) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 10. LogOceny
CREATE TABLE IF NOT EXISTS LogOceny (
  id_logu SERIAL PRIMARY KEY,
  id_artykulu INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  data_obliczenia DATE NOT NULL,
  stary_wspolczynnik DECIMAL(4,3),
  nowy_wspolczynnik DECIMAL(4,3) NOT NULL,
  id_uzytkownika INT
);

-- 11. Cytowanie (self-referencing to Artykul)
CREATE TABLE IF NOT EXISTS Cytowanie (
  id_cytowania SERIAL PRIMARY KEY,
  id_cytujacego INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  id_cytowanego INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE,
  data_zdarzenia DATE
);

-- 12. ZarzutNierzetelnosci (link to artykul; flag instead of decision date per spec)
CREATE TABLE IF NOT EXISTS ZarzutNierzetelnosci (
  id_zarzutu SERIAL PRIMARY KEY,
  typ_nierzetelnosci VARCHAR(50) NOT NULL,
  status VARCHAR(50),
  data_zgloszenia DATE,
  czy_wycofany BOOLEAN,
  id_artykulu INT REFERENCES Artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE
);

COMMIT;
