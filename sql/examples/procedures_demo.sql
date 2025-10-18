-- procedures_demo.sql
-- Demonstrates calling InsertNewArticle and UpdateWR on the RIMS database.

DO $$
DECLARE cid INT;
BEGIN
  SELECT id_czasopisma INTO cid FROM Czasopisma WHERE tytul='Warsaw Tech Reports' LIMIT 1;
  IF cid IS NULL THEN
    RAISE NOTICE 'Brak czasopisma Warsaw Tech Reports';
  ELSE
    CALL InsertNewArticle('PW: Architektura mikroserwisów', '10.6000/wtr.demo01', 2025, cid, 90, 0.420, CURRENT_DATE);
    CALL InsertNewArticle('PW: Analiza ruchu sieciowego', '10.6000/wtr.demo02', 2025, cid, 85, 0.310, CURRENT_DATE);
  END IF;
END $$;

DO $$
DECLARE a_id INT;
BEGIN
  SELECT id_artykulu INTO a_id FROM Artykul WHERE doi='10.6000/wtr.demo02';
  IF a_id IS NOT NULL THEN
    CALL UpdateWR(a_id, 0.280, 999);
  END IF;
END $$;

-- Inspect effect
SELECT tytul, doi, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji
FROM Artykul
WHERE doi IN ('10.6000/wtr.demo01','10.6000/wtr.demo02')
ORDER BY doi;

SELECT * FROM LogOceny
WHERE id_artykulu IN (SELECT id_artykulu FROM Artykul WHERE doi='10.6000/wtr.demo02')
ORDER BY id_logu DESC LIMIT 3;
