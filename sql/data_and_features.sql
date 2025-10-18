-- data_and_features.sql
-- This script assumes the RIMS schema already exists (run 00_all.sql first).
-- It inserts seed data, defines simple procedures, demonstrates usage,
-- provides complex queries, recreates views, and creates indexes as requested.

BEGIN;
SET search_path TO public;

-- 1) INSERTS: at least 4 rows each; ≥20 articles; rich associations

-- Wydawca (4+)
INSERT INTO Wydawca (nazwa, kraj, srednia_retrakcji, czy_otwarty_dostep) VALUES
 ('SciPress', 'Polska', 0.015, TRUE),
 ('GlobalPub', 'USA', 0.030, FALSE),
 ('EuroScience', 'Niemcy', 0.025, TRUE),
 ('AsiaAcad', 'Japonia', 0.020, TRUE),
 ('LatAm Research', 'Brazylia', 0.018, FALSE)
ON CONFLICT (nazwa) DO NOTHING;

-- Afiliacja (4+)
INSERT INTO Afiliacja (nazwa, kraj, miasto) VALUES
 ('Uniwersytet Warszawski', 'Polska', 'Warszawa'),
 ('Politechnika Gdańska', 'Polska', 'Gdańsk'),
 ('MIT', 'USA', 'Cambridge'),
 ('TU Berlin', 'Niemcy', 'Berlin'),
 ('Uni. Sao Paulo', 'Brazylia', 'Sao Paulo')
ON CONFLICT (nazwa) DO NOTHING;

-- Dyscypliny (4+)
INSERT INTO Dyscypliny (nazwa) VALUES
 ('Informatyka'),
 ('Fizyka'),
 ('Biologia'),
 ('Chemia'),
 ('Matematyka')
ON CONFLICT (nazwa) DO NOTHING;

-- Czasopisma (4+)
-- We will reference existing Wydawca and Dyscypliny by SELECT
INSERT INTO Czasopisma (tytul, impact_factor, id_wydawcy, id_dyscypliny)
SELECT x.tytul, x.if, w.id_wydawcy, d.id_dyscypliny FROM (
  VALUES
    ('Journal of Computing', 0.950::DECIMAL(5,3), 'SciPress', 'Informatyka'),
    ('Physics Letters East', 1.200, 'EuroScience', 'Fizyka'),
    ('BioFrontiers', 0.650, 'GlobalPub', 'Biologia'),
    ('Chemistry Today', 0.850, 'AsiaAcad', 'Chemia'),
    ('Mathematical Insights', 0.400, 'SciPress', 'Matematyka')
) AS x(tytul, if, wyd, dys)
JOIN Wydawca w ON w.nazwa = x.wyd
JOIN Dyscypliny d ON d.nazwa = x.dys
ON CONFLICT (tytul) DO NOTHING;

-- Autor (4+)
INSERT INTO Autor (imie, nazwisko, orcid, id_afiliacji)
SELECT x.imie, x.nazw, x.orcid, a.id_afiliacji FROM (
  VALUES
    ('Anna', 'Kowalska', '0000-0001-1111-1111', 'Uniwersytet Warszawski'),
    ('Piotr', 'Nowak', '0000-0002-2222-2222', 'Politechnika Gdańska'),
    ('John', 'Smith', '0000-0003-3333-3333', 'MIT'),
    ('Claudia', 'Schmidt', '0000-0004-4444-4444', 'TU Berlin'),
    ('Marcos', 'Silva', '0000-0005-5555-5555', 'Uni. Sao Paulo')
) AS x(imie, nazw, orcid, af)
JOIN Afiliacja a ON a.nazwa = x.af
ON CONFLICT (orcid) DO NOTHING;

-- ZrodloFinansowania (4+)
INSERT INTO ZrodloFinansowania (nazwa, typ, kraj) VALUES
 ('NCN', 'Grant publiczny', 'Polska'),
 ('NSF', 'Grant publiczny', 'USA'),
 ('HorizonEU', 'Grant UE', 'Belgia'),
 ('PrivateTechFund', 'Prywatny', 'USA'),
 ('BioMedTrust', 'Prywatny', 'Niemcy')
ON CONFLICT DO NOTHING;

-- Artykul (20+)
-- Use existing Czasopisma titles; mixture of WR and years
WITH cz AS (
  SELECT id_czasopisma, tytul FROM Czasopisma
)
INSERT INTO Artykul (tytul, doi, rok_publikacji, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma)
VALUES
 -- Journal of Computing
 ('Algorytmy rozproszone A', '10.1000/jc.0001', 2021, 100, 0.920, '2024-01-10', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Analiza złożoności B', '10.1000/jc.0002', 2022, 80, 0.150, '2024-02-20', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Systemy czasu rzeczywistego C', '10.1000/jc.0003', 2020, 70, 0.300, '2023-12-05', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Uczenie maszynowe D', '10.1000/jc.0004', 2019, 120, 0.250, '2024-01-15', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 -- Physics Letters East
 ('Cząstki elementarne E', '10.2000/ple.0001', 2018, 90, 0.700, '2024-03-01', (SELECT id_czasopisma FROM cz WHERE tytul='Physics Letters East')),
 ('Fale grawitacyjne F', '10.2000/ple.0002', 2022, 85, 0.280, '2024-04-04', (SELECT id_czasopisma FROM cz WHERE tytul='Physics Letters East')),
 ('Nadprzewodniki G', '10.2000/ple.0003', 2023, 95, 0.150, '2024-05-06', (SELECT id_czasopisma FROM cz WHERE tytul='Physics Letters East')),
 -- BioFrontiers
 ('Sekwencjonowanie genomu H', '10.3000/bf.0001', 2021, 110, 0.350, '2024-01-25', (SELECT id_czasopisma FROM cz WHERE tytul='BioFrontiers')),
 ('CRISPR i etyka I', '10.3000/bf.0002', 2019, 75, 0.220, '2024-02-12', (SELECT id_czasopisma FROM cz WHERE tytul='BioFrontiers')),
 ('Metabolomika J', '10.3000/bf.0003', 2020, 65, 0.180, '2024-03-08', (SELECT id_czasopisma FROM cz WHERE tytul='BioFrontiers')),
 -- Chemistry Today
 ('Kataliza węglowodorów K', '10.4000/ct.0001', 2017, 60, 0.410, '2024-04-18', (SELECT id_czasopisma FROM cz WHERE tytul='Chemistry Today')),
 ('Nowe polimery L', '10.4000/ct.0002', 2018, 70, 0.270, '2024-05-20', (SELECT id_czasopisma FROM cz WHERE tytul='Chemistry Today')),
 ('Baterie litowe M', '10.4000/ct.0003', 2023, 90, 0.140, '2024-05-22', (SELECT id_czasopisma FROM cz WHERE tytul='Chemistry Today')),
 -- Mathematical Insights
 ('Topologia N', '10.5000/mi.0001', 2015, 50, 0.800, '2024-01-01', (SELECT id_czasopisma FROM cz WHERE tytul='Mathematical Insights')),
 ('Analiza funkcjonalna O', '10.5000/mi.0002', 2016, 55, 0.600, '2024-01-02', (SELECT id_czasopisma FROM cz WHERE tytul='Mathematical Insights')),
 ('Teoria liczb P', '10.5000/mi.0003', 2018, 65, 0.200, '2024-01-03', (SELECT id_czasopisma FROM cz WHERE tytul='Mathematical Insights')),
 -- extras to reach 20+
 ('Systemy rozproszone Q', '10.1000/jc.0005', 2021, 85, 0.330, '2024-02-01', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Algorytmy grafowe R', '10.1000/jc.0006', 2022, 95, 0.290, '2024-03-01', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Uczenie głębokie S', '10.1000/jc.0007', 2023, 105, 0.180, '2024-03-15', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Teoria informacji T', '10.1000/jc.0008', 2024, 75, 0.260, '2024-04-01', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing')),
 ('Analiza danych U', '10.1000/jc.0009', 2020, 70, 0.120, '2024-04-10', (SELECT id_czasopisma FROM cz WHERE tytul='Journal of Computing'))
ON CONFLICT (doi) DO NOTHING;

-- Artykul_Autor (many links, ensure broad coverage)
-- Map by ORCID and DOI for clarity
WITH a AS (
  SELECT id_autora, orcid FROM Autor
), art AS (
  SELECT id_artykulu, doi FROM Artykul
)
INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT art.id_artykulu,
       CASE WHEN substr(art.doi,1,7)='10.1000' THEN (SELECT id_autora FROM Autor WHERE orcid='0000-0001-1111-1111')
            WHEN substr(art.doi,1,7)='10.2000' THEN (SELECT id_autora FROM Autor WHERE orcid='0000-0003-3333-3333')
            WHEN substr(art.doi,1,7)='10.3000' THEN (SELECT id_autora FROM Autor WHERE orcid='0000-0002-2222-2222')
            ELSE (SELECT id_autora FROM Autor WHERE orcid='0000-0004-4444-4444') END AS id_autora,
       1
FROM art
ON CONFLICT DO NOTHING;

-- Add second authors for variety
INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT art.id_artykulu,
       (SELECT id_autora FROM Autor WHERE orcid='0000-0005-5555-5555') AS id_autora,
       2
FROM Artykul art
WHERE (art.wspolczynnik_rzetelnosci < 0.3 OR art.rok_publikacji >= 2022)
ON CONFLICT DO NOTHING;

-- Artykul_ZrodloFinansowania (join many)
INSERT INTO Artykul_ZrodloFinansowania (id_artykulu, id_zrodla)
SELECT art.id_artykulu, zf.id_zrodla
FROM Artykul art
JOIN ZrodloFinansowania zf ON (
  (zf.nazwa IN ('NCN','NSF') AND art.rok_publikacji >= 2021) OR
  (zf.nazwa='HorizonEU' AND art.rok_publikacji BETWEEN 2018 AND 2020) OR
  (zf.nazwa='PrivateTechFund' AND art.wspolczynnik_rzetelnosci < 0.25) OR
  (zf.nazwa='BioMedTrust' AND art.wspolczynnik_rzetelnosci < 0.20)
)
ON CONFLICT DO NOTHING;

-- ZarzutNierzetelnosci (link some as withdrawn)
INSERT INTO ZarzutNierzetelnosci (typ_nierzetelnosci, status, data_zgloszenia, czy_wycofany, id_artykulu)
SELECT x.typ, x.status, x.data_zgl, x.czy, a.id_artykulu FROM (
  VALUES
    ('plagiat','zakończony', DATE '2024-02-01', TRUE, '10.1000/jc.0002'),
    ('dane fałszywe','w toku', DATE '2024-03-12', FALSE, '10.2000/ple.0002'),
    ('manipulacja recenzją','zakończony', DATE '2024-04-10', TRUE, '10.3000/bf.0003'),
    ('błąd metodologiczny','zakończony', DATE '2024-05-05', TRUE, '10.4000/ct.0003'),
    ('inne','w toku', DATE '2024-05-20', FALSE, '10.1000/jc.0007')
) AS x(typ, status, data_zgl, czy, doi)
JOIN Artykul a ON a.doi = x.doi
ON CONFLICT DO NOTHING;

-- Cytowanie (some relations)
INSERT INTO Cytowanie (id_cytujacego, id_cytowanego, data_zdarzenia)
SELECT a1.id_artykulu, a2.id_artykulu, x.dt FROM (
  VALUES
    ('10.1000/jc.0001','10.1000/jc.0002', DATE '2024-06-01'),
    ('10.1000/jc.0004','10.2000/ple.0003', DATE '2024-06-02'),
    ('10.3000/bf.0001','10.3000/bf.0003', DATE '2024-06-03'),
    ('10.5000/mi.0001','10.1000/jc.0009', DATE '2024-06-04'),
    ('10.4000/ct.0002','10.4000/ct.0001', DATE '2024-06-05')
) AS x(doi1, doi2, dt)
JOIN Artykul a1 ON a1.doi = x.doi1
JOIN Artykul a2 ON a2.doi = x.doi2
ON CONFLICT DO NOTHING;

-- [ADDITION] Politechnika Warszawska: afiliacja, autorzy, czasopismo, artykuły i powiązania

-- Afiliacja: Politechnika Warszawska
INSERT INTO Afiliacja (nazwa, kraj, miasto)
VALUES ('Politechnika Warszawska', 'Polska', 'Warszawa')
ON CONFLICT (nazwa) DO NOTHING;

-- Autorzy PW (trzech, z unikalnymi ORCID)
INSERT INTO Autor (imie, nazwisko, orcid, id_afiliacji)
SELECT x.imie, x.nazw, x.orcid, a.id_afiliacji
FROM (
  VALUES
    ('Jan', 'Zieliński', '0000-0006-6666-6666'),
    ('Magdalena', 'Wiśniewska', '0000-0007-7777-7777'),
    ('Tomasz', 'Kaczmarek', '0000-0008-8888-8888')
) AS x(imie, nazw, orcid)
JOIN Afiliacja a ON a.nazwa = 'Politechnika Warszawska'
ON CONFLICT (orcid) DO NOTHING;

-- Dodatkowe czasopismo: Warsaw Tech Reports (u wydawcy SciPress, dyscyplina Informatyka)
INSERT INTO Czasopisma (tytul, impact_factor, id_wydawcy, id_dyscypliny)
SELECT 'Warsaw Tech Reports', 0.300::DECIMAL(5,3), w.id_wydawcy, d.id_dyscypliny
FROM Wydawca w
JOIN Dyscypliny d ON d.nazwa = 'Informatyka'
WHERE w.nazwa = 'SciPress'
ON CONFLICT (tytul) DO NOTHING;

-- Artykuły PW (3 szt.) w Warsaw Tech Reports
INSERT INTO Artykul (
  tytul, doi, rok_publikacji, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma
) VALUES
  ('Inżynieria oprogramowania na PW', '10.6000/wtr.0001', 2024, 80, 0.450, DATE '2025-10-18', (SELECT id_czasopisma FROM Czasopisma WHERE tytul='Warsaw Tech Reports')),
  ('Systemy wbudowane na PW',       '10.6000/wtr.0002', 2023, 70, 0.620, DATE '2025-10-18', (SELECT id_czasopisma FROM Czasopisma WHERE tytul='Warsaw Tech Reports')),
  ('Sieci 5G w kampusie PW',        '10.6000/wtr.0003', 2022, 85, 0.300, DATE '2025-10-18', (SELECT id_czasopisma FROM Czasopisma WHERE tytul='Warsaw Tech Reports'))
ON CONFLICT (doi) DO NOTHING;

-- Powiązania artykuł–autor (kolejność autorów)
-- 10.6000/wtr.0001 → Jan Zieliński (1), Magdalena Wiśniewska (2)
INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT a.id_artykulu, au.id_autora, 1
FROM Artykul a JOIN Autor au ON a.doi='10.6000/wtr.0001' AND au.orcid='0000-0006-6666-6666'
ON CONFLICT DO NOTHING;

INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT a.id_artykulu, au.id_autora, 2
FROM Artykul a JOIN Autor au ON a.doi='10.6000/wtr.0001' AND au.orcid='0000-0007-7777-7777'
ON CONFLICT DO NOTHING;

-- 10.6000/wtr.0002 → Magdalena Wiśniewska (1), Tomasz Kaczmarek (2)
INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT a.id_artykulu, au.id_autora, 1
FROM Artykul a JOIN Autor au ON a.doi='10.6000/wtr.0002' AND au.orcid='0000-0007-7777-7777'
ON CONFLICT DO NOTHING;

INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT a.id_artykulu, au.id_autora, 2
FROM Artykul a JOIN Autor au ON a.doi='10.6000/wtr.0002' AND au.orcid='0000-0008-8888-8888'
ON CONFLICT DO NOTHING;

-- 10.6000/wtr.0003 → Tomasz Kaczmarek (1)
INSERT INTO Artykul_Autor (id_artykulu, id_autora, kolejnosc_autora)
SELECT a.id_artykulu, au.id_autora, 1
FROM Artykul a JOIN Autor au ON a.doi='10.6000/wtr.0003' AND au.orcid='0000-0008-8888-8888'
ON CONFLICT DO NOTHING;

-- Finansowanie NCN dla artykułów PW
INSERT INTO Artykul_ZrodloFinansowania (id_artykulu, id_zrodla)
SELECT a.id_artykulu, z.id_zrodla
FROM Artykul a
JOIN ZrodloFinansowania z ON z.nazwa = 'NCN'
WHERE a.doi IN ('10.6000/wtr.0001','10.6000/wtr.0002','10.6000/wtr.0003')
ON CONFLICT DO NOTHING;

-- Cytowanie: artykuł PW cytuje wcześniejszy z Journal of Computing
INSERT INTO Cytowanie (id_cytujacego, id_cytowanego, data_zdarzenia)
SELECT a1.id_artykulu, a2.id_artykulu, DATE '2025-10-18'
FROM Artykul a1, Artykul a2
WHERE a1.doi = '10.6000/wtr.0001' AND a2.doi = '10.1000/jc.0001'
ON CONFLICT DO NOTHING;

COMMIT;

-- 2) PROCEDURES (simplified) using plpgsql

-- Procedure: InsertNewArticle(tytul_in, doi_in, rok_in, id_czasopisma_in, ...)
CREATE OR REPLACE PROCEDURE InsertNewArticle(
  tytul_in VARCHAR,
  doi_in VARCHAR,
  rok_in INT,
  id_czasopisma_in INT,
  punkty_mein_in INT DEFAULT NULL,
  wr_in DECIMAL(4,3) DEFAULT NULL,
  data_akt_in DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO Artykul (tytul, doi, rok_publikacji, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma)
  VALUES (tytul_in, doi_in, rok_in, punkty_mein_in, wr_in, data_akt_in, id_czasopisma_in);
END;
$$;

-- Procedure: UpdateWR(article_id_in, new_wr_in)
CREATE OR REPLACE PROCEDURE UpdateWR(
  article_id_in INT,
  new_wr_in DECIMAL(4,3),
  id_uzytkownika_in INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
  old_wr DECIMAL(4,3);
BEGIN
  SELECT wspolczynnik_rzetelnosci INTO old_wr FROM Artykul WHERE id_artykulu = article_id_in;
  UPDATE Artykul
    SET wspolczynnik_rzetelnosci = new_wr_in,
        data_ostatniej_aktualizacji = CURRENT_DATE
  WHERE id_artykulu = article_id_in;

  INSERT INTO LogOceny (id_artykulu, data_obliczenia, stary_wspolczynnik, nowy_wspolczynnik, id_uzytkownika)
  VALUES (article_id_in, CURRENT_DATE, old_wr, new_wr_in, id_uzytkownika_in);
END;
$$;

-- 3) USAGE EXAMPLES
-- Call InsertNewArticle 3 times
DO $$
DECLARE cid INT;
BEGIN
  SELECT id_czasopisma INTO cid FROM Czasopisma WHERE tytul='Journal of Computing' LIMIT 1;
  CALL InsertNewArticle('Nowe podejście do indeksów', '10.1000/jc.0100', 2024, cid, 95, 0.310, CURRENT_DATE);
  CALL InsertNewArticle('Analiza rozproszona w praktyce', '10.1000/jc.0101', 2023, cid, 88, 0.280, CURRENT_DATE);
  CALL InsertNewArticle('Techniki optymalizacji zapytań', '10.1000/jc.0102', 2022, cid, 92, 0.450, CURRENT_DATE);
END $$;

-- Call UpdateWR at least 2 times
DO $$
DECLARE aid1 INT; aid2 INT;
BEGIN
  SELECT id_artykulu INTO aid1 FROM Artykul WHERE doi='10.1000/jc.0002';
  SELECT id_artykulu INTO aid2 FROM Artykul WHERE doi='10.3000/bf.0002';
  CALL UpdateWR(aid1, 0.180, 101);
  CALL UpdateWR(aid2, 0.260, 102);
END $$;

-- 4) COMPLEX QUERIES

-- Query 1: Authors who published low-WR (<0.3) articles in journals with IF < 1.0 (use subquery for IF)
-- Result columns: autor, artykul, wr, czasopismo, if
WITH low_if_journals AS (
  SELECT id_czasopisma FROM Czasopisma WHERE impact_factor < 1.0
)
SELECT au.imie || ' ' || au.nazwisko AS autor,
       ar.tytul AS artykul,
       ar.wspolczynnik_rzetelnosci AS wr,
       cz.tytul AS czasopismo,
       cz.impact_factor AS if
FROM Autor au
JOIN Artykul_Autor aa ON aa.id_autora = au.id_autora
JOIN Artykul ar ON ar.id_artykulu = aa.id_artykulu
JOIN Czasopisma cz ON cz.id_czasopisma = ar.id_czasopisma
WHERE ar.wspolczynnik_rzetelnosci < 0.3
  AND cz.id_czasopisma IN (SELECT id_czasopisma FROM low_if_journals)
ORDER BY autor, wr ASC;

-- Query 2: How many authors from Afiliacja X published works with a misconduct allegation (czy_wycofany = TRUE)
-- Parameterize by name; here use 'Politechnika Gdańska' as X
SELECT af.nazwa AS afiliacja,
       COUNT(DISTINCT au.id_autora) AS autorzy_z_wycofanymi
FROM Afiliacja af
JOIN Autor au ON au.id_afiliacji = af.id_afiliacji
JOIN Artykul_Autor aa ON aa.id_autora = au.id_autora
JOIN Artykul ar ON ar.id_artykulu = aa.id_artykulu
JOIN ZarzutNierzetelnosci zn ON zn.id_artykulu = ar.id_artykulu AND zn.czy_wycofany = TRUE
WHERE af.nazwa = 'Politechnika Gdańska'
GROUP BY af.nazwa;

-- 5) VIEWS (recreate to ensure presence)
CREATE OR REPLACE VIEW "Widok_Wycofane_Artykuły_Wydawcy" AS
WITH artykuly_wydawcy AS (
  SELECT w.id_wydawcy,
         w.nazwa AS wydawca,
         COUNT(a.id_artykulu) AS liczba_artykulow
  FROM Wydawca w
  JOIN Czasopisma c ON c.id_wydawcy = w.id_wydawcy
  JOIN Artykul a ON a.id_czasopisma = c.id_czasopisma
  GROUP BY w.id_wydawcy, w.nazwa
), wycofane_wydawcy AS (
  SELECT w.id_wydawcy,
         COUNT(DISTINCT zn.id_artykulu) AS liczba_wycofanych
  FROM Wydawca w
  JOIN Czasopisma c ON c.id_wydawcy = w.id_wydawcy
  JOIN Artykul a ON a.id_czasopisma = c.id_czasopisma
  JOIN ZarzutNierzetelnosci zn ON zn.id_artykulu = a.id_artykulu AND zn.czy_wycofany = TRUE
  GROUP BY w.id_wydawcy
)
SELECT aw.id_wydawcy,
       aw.wydawca,
       COALESCE(ww.liczba_wycofanych, 0) AS liczba_wycofanych,
       aw.liczba_artykulow,
       CASE WHEN aw.liczba_artykulow > 0
            THEN ROUND( (COALESCE(ww.liczba_wycofanych,0)::numeric / aw.liczba_artykulow::numeric) * 100, 2)
            ELSE 0 END AS procent_wycofanych
FROM artykuly_wydawcy aw
LEFT JOIN wycofane_wydawcy ww ON ww.id_wydawcy = aw.id_wydawcy;

CREATE OR REPLACE VIEW Widok_Ryzykowne_Finansowanie AS
SELECT zf.id_zrodla,
       zf.nazwa,
       zf.typ,
       zf.kraj,
       COUNT(DISTINCT a.id_artykulu) AS liczba_artykulow,
       AVG(a.wspolczynnik_rzetelnosci) AS sr_wspolczynnik,
       SUM(CASE WHEN a.wspolczynnik_rzetelnosci IS NOT NULL AND a.wspolczynnik_rzetelnosci < 0.200 THEN 1 ELSE 0 END) AS n_niskich,
       ROUND(
         CASE WHEN COUNT(DISTINCT a.id_artykulu) > 0
              THEN (SUM(CASE WHEN a.wspolczynnik_rzetelnosci IS NOT NULL AND a.wspolczynnik_rzetelnosci < 0.200 THEN 1 ELSE 0 END)::numeric
                    / COUNT(DISTINCT a.id_artykulu)::numeric) * 100
              ELSE 0 END
         , 2) AS procent_niskich
FROM ZrodloFinansowania zf
LEFT JOIN Artykul_ZrodloFinansowania azf ON azf.id_zrodla = zf.id_zrodla
LEFT JOIN Artykul a ON a.id_artykulu = azf.id_artykulu
GROUP BY zf.id_zrodla, zf.nazwa, zf.typ, zf.kraj
HAVING COUNT(DISTINCT a.id_artykulu) > 0;

-- 6) INDEXES
-- Simple index on data_publikacji requested; schema uses rok_publikacji and data_ostatniej_aktualizacji
-- Provide both as practical stand-ins
CREATE INDEX IF NOT EXISTS idx_artykul_rok_publikacji ON Artykul(rok_publikacji);
CREATE INDEX IF NOT EXISTS idx_artykul_data_ostatniej_aktualizacji ON Artykul(data_ostatniej_aktualizacji);

-- Composite across tables is not possible; provide effective per-table indexes
CREATE INDEX IF NOT EXISTS idx_artykul_wspolczynnik_rzetelnosci ON Artykul(wspolczynnik_rzetelnosci);
CREATE INDEX IF NOT EXISTS idx_afiliacja_kraj ON Afiliacja(kraj);
-- Join helpers
CREATE INDEX IF NOT EXISTS idx_aa_id_autora ON Artykul_Autor(id_autora);
CREATE INDEX IF NOT EXISTS idx_aa_id_artykulu ON Artykul_Autor(id_artykulu);
