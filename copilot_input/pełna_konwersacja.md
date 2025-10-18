# Pełna konwersacja – RIMS (PostgreSQL)

Poniżej znajduje się chronologiczny zapis naszej współpracy wraz z kluczowymi wynikami z terminala.

---

## 1) Start i kontekst

- System: Linux (bash)
- Struktura na starcie: `MojeERD.csv`, `pomoc.md`
- Prośba: na podstawie ERD i wskazówek w `pomoc.md` przygotować kompletny skrypt SQL dla PostgreSQL (RIMS) i utworzyć bazę.

---

## 2) Utworzenie struktury SQL i skryptów bazy

Asystent: Utworzyłem folder `sql/` i dodałem skrypty:
- `00_all.sql` – orchestrator (uruchamia 01, przełącza na RIMS, uruchamia 02 i 03)
- `01_database.sql` – DROP/CREATE database `rims` (zamyka połączenia)
- `02_schema.sql` – tabele zgodnie z 3NF i wymaganiami
- `03_indexes_views.sql` – indeksy oraz widoki
- `README.md` – instrukcje uruchomienia

---

## 3) Wymagania z `polecenie.md` – dane + procedury + przykłady + złożone zapytania

Asystent: Dodałem `sql/data_and_features.sql` zawierający:
- INSERTy dla wszystkich tabel (≥4 szt. w każdej, ≥20 w `Artykul`), asocjacje N:M
- Procedury: `InsertNewArticle(...)` i `UpdateWR(...)`
- Przykładowe wywołania (3x insert, 2x update)
- Dwa złożone zapytania (WR<0.3 w IF<1.0, oraz autorzy z afiliacji X z wycofaniami)
- Odświeżenie widoków i indeksów

W trakcie testów poprawiłem:
- Rzutowania dat (`DATE 'YYYY-MM-DD'`)
- Tworzenie procedur (bez DO-wrappów, prawidłowa kolejność parametrów w `InsertNewArticle`)

---

## 4) Uruchomienie w terminalu – tworzenie bazy i schematu

Polecenie:
```
psql -U postgres -d postgres -f sql/00_all.sql
```
Wynik (fragment – błąd uwierzytelnienia peer):
```
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Ponowna próba z użytkownikiem systemowym `postgres`:
```
sudo -u postgres psql -f sql/00_all.sql
```
Wynik (fragment):
```
DO
DROP DATABASE
CREATE DATABASE
You are now connected to database "rims" as user "postgres".
...
CREATE TABLE
...
CREATE VIEW
CREATE VIEW
COMMIT
```

---

## 5) Uruchomienie `data_and_features.sql` – pierwsze podejście i poprawki

Polecenie:
```
sudo -u postgres psql -d rims -f sql/data_and_features.sql
```
Wynik (fragment – błędy do poprawy):
```
ERROR:  column "data_zgloszenia" is of type date but expression is of type text
...
ERROR:  syntax error at or near "BEGIN"
...
ERROR:  procedure insertnewarticle(...) does not exist
...
(0 rows) – przy próbie zapytań, bo procedury się nie utworzyły
```
Asystent: Naprawiłem rzutowania dat, przebudowałem definicje procedur (bez DO, poprawny porządek parametrów).

---

## 6) Uruchomienie `data_and_features.sql` – sukces

Polecenie:
```
sudo -u postgres psql -d rims -f sql/data_and_features.sql
```
Wynik (fragment):
```
INSERT 0 ...
COMMIT
CREATE PROCEDURE
CREATE PROCEDURE
DO
DO
 afiliacja | autorzy_z_wycofanymi 
-----------+----------------------
 Politechnika Gdańska | 1
(1 row)

CREATE VIEW
CREATE VIEW
...
CREATE INDEX
...
```

Weryfikacje (pojedyncze komendy):
```
sudo -u postgres psql -d rims -c "SELECT COUNT(*) FROM Artykul;"
```
Wynik:
```
 count 
-------
    24
(1 row)
```
```
sudo -u postgres psql -d rims -c "SELECT * FROM \"Widok_Wycofane_Artykuły_Wydawcy\" LIMIT 10;"
```
Wynik (przykład):
```
 id_wydawcy |   wydawca   | liczba_wycofanych | liczba_artykulow | procent_wycofanych 
------------+-------------+-------------------+------------------+--------------------
         11 | SciPress    |                 1 |               15 |               6.67
         12 | GlobalPub   |                 1 |                3 |              33.33
         14 | AsiaAcad    |                 1 |                3 |              33.33
         13 | EuroScience |                 0 |                3 |               0.00
(4 rows)
```
```
sudo -u postgres psql -d rims -XAtqc "SELECT * FROM Widok_Ryzykowne_Finansowanie LIMIT 10;"
```
Wynik (przykład):
```
11|NCN|Grant publiczny|Polska|10|0.30800000000000000000|4|40.00
12|NSF|Grant publiczny|USA|10|0.30800000000000000000|4|40.00
13|HorizonEU|Grant UE|Belgia|8|0.28500000000000000000|2|25.00
14|PrivateTechFund|Prywatny|USA|8|0.17625000000000000000|6|75.00
15|BioMedTrust|Prywatny|Niemcy|6|0.15833333333333333333|6|100.00
```
```
sudo -u postgres psql -d rims -c "SELECT * FROM LogOceny ORDER BY id_logu DESC LIMIT 5;"
```
Wynik (przykład):
```
 id_logu | id_artykulu | data_obliczenia | stary_wspolczynnik | nowy_wspolczynnik | id_uzytkownika 
---------+-------------+-----------------+--------------------+-------------------+----------------
       4 |          51 | 2025-10-18      |              0.220 |             0.260 |            102
       3 |          44 | 2025-10-18      |              0.150 |             0.180 |            101
       2 |             | 2025-10-18      |                    |             0.260 |            102
       1 |             | 2025-10-18      |                    |             0.180 |            101
(4 rows)
```

---

## 7) Folder `scripts/` – skrypty bash i testy

Asystent: Na prośbę utworzyłem folder `scripts` równolegle do `sql`:
- `scripts/setup_db.sh` – uruchamia `sql/00_all.sql` i `sql/data_and_features.sql` (przez `sudo -u postgres`, z przekierowaniem stdin)
- `scripts/show_results.sh` – pokazuje 4 zapytania; dla widoku „Ryzykowne” dodałem tryb `-XAtqc` (zwarty, bez pagera)
- `scripts/README.md` – opis uruchomienia

Nadanie uprawnień i uruchomienia:
```
chmod +x scripts/*.sh
./scripts/setup_db.sh
```
Pierwsza próba (fragment):
```
psql: error: /home/radek/Documents/BazyDanych/sql/00_all.sql: Permission denied
```
Poprawka skryptu (stdin) i ponowne uruchomienie – OK (przy wielokrotnym uruchomieniu pojawia się spodziewany błąd duplikacji DOI w demonstracyjnych CALL-ach).

Uruchomienie wyników:
```
./scripts/show_results.sh
```
Wynik (fragmenty):
```
[query] SELECT COUNT(*) FROM Artykul;
 count 
-------
    24
(1 row)

[query] SELECT * FROM "Widok_Wycofane_Artykuły_Wydawcy" LIMIT 10;
...
(4 rows)

[query] SELECT * FROM Widok_Ryzykowne_Finansowanie LIMIT 10; (compact output)
11|NCN|Grant publiczny|Polska|13|0.31692307692307692308|4|30.77
12|NSF|Grant publiczny|USA|13|0.31692307692307692308|4|30.77
13|HorizonEU|Grant UE|Belgia|8|0.28500000000000000000|2|25.00
14|PrivateTechFund|Prywatny|USA|8|0.176250000000000000000|6|75.00
15|BioMedTrust|Prywatny|Niemcy|6|0.15833333333333333333|6|100.00
...

[query] SELECT * FROM LogOceny ORDER BY id_logu DESC LIMIT 5;
 id_logu | id_artykulu | data_obliczenia | stary_wspolczynnik | nowy_wspolczynnik | id_uzytkownika 
---------+-------------+-----------------+--------------------+-------------------+----------------
       6 |          51 | 2025-10-18      |              0.260 |             0.260 |            102
       5 |          44 | 2025-10-18      |              0.180 |             0.180 |            101
       4 |          51 | 2025-10-18      |              0.220 |             0.260 |            102
       3 |          44 | 2025-10-18      |              0.150 |             0.180 |            101
       2 |             | 2025-10-18      |                    |             0.260 |            102
(5 rows)
```

---

## 8) Stan końcowy

- Baza `rims` z pełnym schematem (3NF), danymi, procedurami, widokami i indeksami jest gotowa.
- Skrypty SQL: `sql/*` oraz skrypty bash: `scripts/*` są dostępne i przetestowane.
- Zapytania demonstracyjne zwracają oczekiwane wyniki.

---

Jeśli chcesz, mogę rozszerzyć log o dokładne, pełne treści wszystkich komunikatów (bez ucinania fragmentów) lub wyeksportować wynik widoków do CSV.

---

## 9) Skrypty bash i dodatkowe testy

- Utworzyłem `scripts/setup_db.sh` (uruchamianie 00_all.sql i data_and_features.sql przez stdin z sudo) i `scripts/show_results.sh` (wyniki, w tym widok w trybie `-XAtqc`).
- Wystąpił początkowo błąd uprawnień (psql nie mógł czytać pliku z katalogu domowego użytkownika `radek`), skrypt poprawiono poprzez przekierowanie stdin.
- Uruchomienie `./scripts/setup_db.sh` zakończyło się poprawnie (przy wielokrotnym odpalaniu spodziewany komunikat o duplikacji DOI w przykładowych CALL).
- `./scripts/show_results.sh` wyświetla: COUNT artykułów, widok „Wycofane artykuły wydawcy”, widok „Ryzykowne finansowanie” (kompaktowy format), ostatnie wpisy `LogOceny`.

## 10) Sprawozdanie LaTeX

- W folderze `sprawozdanie/` powstał projekt LaTeX: `sprawozdanie.tex`, konfiguracja `.latexmkrc` i skrypt `build.sh`.
- PDF został wygenerowany (`sprawozdanie/sprawozdanie.pdf`), z typowymi ostrzeżeniami o łamaniu wierszy (nie wpływają na poprawność).
- Następnie zredukowano liczbę punktorów, dodano sekcję „Gdzie są przechowywane dane” i pominięto plany na przyszłość; PDF przebudowano.

## 11) Gdzie są przechowywane dane

- W repozytorium rekordy do zasilenia znajdują się w `sql/data_and_features.sql`.
- Fizyczne pliki bazy: `SHOW data_directory;` → `/var/lib/postgresql/16/main`; przykładowo `public.artykul` → `base/24576/24645`, czyli `/var/lib/postgresql/16/main/base/24576/24645`.

## 12) Gitignore i czyszczenie cache

- Dodano `.gitignore` w katalogu głównym oraz w repozytorium `sprawozdanie/` (repo lokalne ma osobny katalog `.git`), aby ignorować artefakty LaTeX (PDF, aux, log itd.) oraz zachować tylko pliki źródłowe (`.tex`) i dokumentację (`.md`).
- Wykonano „czyszczenie cache” (`git rm -r --cached .`/ponowne dodanie) w repozytorium `sprawozdanie/`, aby reguły `.gitignore` zaczęły obowiązywać dla już śledzonych plików.
