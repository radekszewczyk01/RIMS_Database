-- 03_indexes_views.sql
-- Indexes and Views for RIMS

BEGIN;
SET search_path TO public;

-- 1. Create index on publication date
-- NOTE: The spec mentions data_publikacji, while the schema has rok_publikacji and data_ostatniej_aktualizacji.
-- We'll index rok_publikacji (common filter) and data_ostatniej_aktualizacji if desired.
CREATE INDEX IF NOT EXISTS idx_artykul_rok_publikacji ON Artykul(rok_publikacji);
CREATE INDEX IF NOT EXISTS idx_artykul_data_ostatniej_aktualizacji ON Artykul(data_ostatniej_aktualizacji);

-- 2. Composite index across join columns is not possible directly across tables.
-- Effective alternative: index columns used in join/filter separately.
-- For query patterns filtering by wspolczynnik_rzetelnosci and afiliacja.kraj, create indexes:
CREATE INDEX IF NOT EXISTS idx_artykul_wspolczynnik_rzetelnosci ON Artykul(wspolczynnik_rzetelnosci);
CREATE INDEX IF NOT EXISTS idx_afiliacja_kraj ON Afiliacja(kraj);
-- Additionally, helpful join indexes on association table:
CREATE INDEX IF NOT EXISTS idx_art_aut_id_artykulu ON Artykul_Autor(id_artykulu);
CREATE INDEX IF NOT EXISTS idx_art_aut_id_autora ON Artykul_Autor(id_autora);

-- 3. Views
-- Note: quoted due to non-ASCII characters in identifier
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

-- View: Widok_Ryzykowne_Finansowanie
-- "Źródła finansowania, których artykuły mają bardzo niski współczynnik wiarygodności"
-- Parametr graniczny przyjmijmy na 0.200 (20%).
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
HAVING COUNT(DISTINCT a.id_artykulu) > 0; -- tylko te, które finansowały jakiekolwiek artykuły

COMMIT;
