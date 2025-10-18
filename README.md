# Sprawozdanie – System RIMS (PostgreSQL)

## Wstęp i źródła

To sprawozdanie dokumentuje przygotowanie i uruchomienie bazy danych RIMS w PostgreSQL, wraz z danymi testowymi, procedurami, widokami oraz skryptami pomocniczymi.

- Pliki `polecenie.md` (w `sql/`) oraz `pomoc.md` powstały przy użyciu narzędzia Gemini.
- Do Gemini załączyłem plik `MojeERD.csv`, który został wyeksportowany z narzędzia Lucidchart na podstawie stworzonego tam schematu bazy danych.

## Struktura repozytorium

Najważniejsze pliki: `MojeERD.csv` (eksport ERD z Lucidchart), `pomoc.md` (wytyczne 3NF), folder `sql/` (skrypty tworzące bazę, schemat, widoki i dane: m.in. `00_all.sql`, `02_schema.sql`, `03_indexes_views.sql`, `data_and_features.sql`), folder `scripts/` (automaty: `setup_db.sh`, `show_results.sh`), oraz `pełna_konwersacja.md` (zapis prac).

## Model danych i normalizacja (3NF)

Na bazie `pomoc.md` i ERD: dodano słowniki (`Dyscypliny`) oraz `Czasopisma`; znormalizowano łańcuch Wydawca→Czasopismo→Artykuł; zastosowano `SERIAL` dla PK typu INT; dla kluczowych kolumn ustawiono `NOT NULL`; relacje N:M zrealizowano przez `Artykul_Autor` i `Artykul_ZrodloFinansowania` (klucze złożone).

## Tabele (skrót)

- `Wydawca(id_wydawcy PK, nazwa UNIQUE NOT NULL, kraj, srednia_retrakcji, czy_otwarty_dostep)`
- `Afiliacja(id_afiliacji PK, nazwa UNIQUE NOT NULL, kraj, miasto)`
- `Dyscypliny(id_dyscypliny PK, nazwa UNIQUE NOT NULL)`
- `Czasopisma(id_czasopisma PK, tytul UNIQUE NOT NULL, impact_factor, id_wydawcy FK, id_dyscypliny FK)`
- `Autor(id_autora PK, imie, nazwisko NOT NULL, orcid UNIQUE, id_afiliacji FK)`
- `ZrodloFinansowania(id_zrodla PK, nazwa NOT NULL, typ, kraj)`
- `Artykul(id_artykulu PK, tytul NOT NULL, doi UNIQUE NOT NULL, rok_publikacji NOT NULL, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma FK)`
- `Artykul_Autor(id_artykulu PK/FK, id_autora PK/FK, kolejnosc_autora)`
- `Artykul_ZrodloFinansowania(id_artykulu PK/FK, id_zrodla PK/FK)`
- `LogOceny(id_logu PK, id_artykulu FK, data_obliczenia NOT NULL, stary_wspolczynnik, nowy_wspolczynnik NOT NULL, id_uzytkownika)`
- `Cytowanie(id_cytowania PK, id_cytujacego FK, id_cytowanego FK, data_zdarzenia)`
- `ZarzutNierzetelnosci(id_zarzutu PK, typ_nierzetelnosci NOT NULL, status, data_zgloszenia, czy_wycofany, id_artykulu FK)`

## Relacje

- Wydawca 1—N Czasopisma —N Artykul
- Autor N—M Artykul (przez `Artykul_Autor`)
- ZrodloFinansowania N—M Artykul (przez `Artykul_ZrodloFinansowania`)
- Afiliacja 1—N Autor
- Artykul cytuje Artykul (self-FK w `Cytowanie`)
- Artykul 1—N ZarzutNierzetelnosci
- Artykul 1—N LogOceny

## Indeksy

Zaimplementowano indeksy na kolumnach filtrujących i łączących: `Artykul(rok_publikacji)`, `Artykul(data_ostatniej_aktualizacji)`, `Artykul(wspolczynnik_rzetelnosci)`, `Afiliacja(kraj)` oraz pomocnicze `Artykul_Autor(id_autora)` i `(id_artykulu)`. Wzmiankowane w specyfikacji `data_publikacji` zastąpiono praktycznie dostępnymi polami (rok/data_aktualizacji). Indeks „przez dwie tabele” nie jest wspierany – użyto alternatywy per tabela.

## Widoki

- "`Widok_Wycofane_Artykuły_Wydawcy`" – agregacja % wycofanych artykułów na wydawcę (łączenia: Wydawca, Czasopisma, Artykul, ZarzutNierzetelnosci). Nazwa widoku cytowana (polskie znaki).
- `Widok_Ryzykowne_Finansowanie` – łączy źródła finansowania i artykuły, liczy udział niskiego WR (< 0.2) oraz średni WR.

## Procedury

- `InsertNewArticle(tytul_in, doi_in, rok_in, id_czasopisma_in, punkty_mein_in DEFAULT NULL, wr_in DEFAULT NULL, data_akt_in DEFAULT NULL)` – dodaje nowy rekord do `Artykul`.
- `UpdateWR(article_id_in, new_wr_in, id_uzytkownika_in DEFAULT NULL)` – aktualizuje WR w `Artykul` i dopisuje wpis do `LogOceny` z poprzednią i nową wartością.

## Dane testowe (z `data_and_features.sql`)

- Minimum 4 rekordy w każdej tabeli głównej/słownikowej; ≥20 rekordów w `Artykul`.
- Szerokie pokrycie asocjacji (N:M), cytowania, zarzuty (z `czy_wycofany = TRUE`).

Przykładowe wyniki po załadowaniu:
- `SELECT COUNT(*) FROM Artykul;` → 24
- „Wycofane artykuły wydawcy” – SciPress (1/15, 6.67%), GlobalPub (1/3, 33.33%), AsiaAcad (1/3, 33.33%), EuroScience (0/3, 0%).
- „Ryzykowne finansowanie” – m.in. NCN, NSF, HorizonEU, PrivateTechFund, BioMedTrust z odpowiednimi wskaźnikami.
- `LogOceny` – wpisy powstałe w wyniku wywołań `UpdateWR`.

## Skrypty bash

`scripts/setup_db.sh` uruchamia SQL przez stdin (bezproblemowe uprawnienia dla `postgres`), a `scripts/show_results.sh` wypisuje 4 zapytania (widok „Ryzykowne” w trybie `-XAtqc`).

## Jak uruchomić

Ręcznie w `sql/`:
```bash
psql -U postgres -f 00_all.sql
psql -U postgres -d rims -f data_and_features.sql
```
Albo skryptami (lokalny Postgres, sudo):
```bash
chmod +x scripts/*.sh
./scripts/setup_db.sh
./scripts/show_results.sh
```

### Podgląd danych w przeglądarce (GitHub Pages)

- Strona: po włączeniu Pages (Settings → Pages → Deploy from a branch → main /docs) będzie dostępna pod adresem:
	https://radekszewczyk01.github.io/RIMS_Database/
- Aktualizacja zawartości `docs/` (index.html + CSV):
	```bash
	# jednorazowo
	chmod +x scripts/*.sh
  
	# eksport + publikacja + commit/push
	./scripts/export_and_publish.sh "docs: refresh GitHub Pages preview"
	```
	Skrypt wywołuje `export_rims.sh` (tworzy schema.sql, CSV i index.html), następnie `publish_docs.sh` (kopiuje do `docs/`).

## Uwierzytelnianie i środowisko

Lokalnie działa autoryzacja peer dla roli `postgres` (stąd `sudo -u postgres`). Alternatywnie użyj `PGHOST/PGPORT/PGUSER/PGPASSWORD` i odpowiednio zmień skrypty.

## Gdzie są przechowywane dane

W repozytorium dane do zasilenia (INSERT) znajdują się w pliku `sql/data_and_features.sql`.

Fizyczne pliki bazy są w katalogu danych PostgreSQL. Na tej maszynie:

- `SHOW data_directory;` → `/var/lib/postgresql/16/main`
- przykładowa tabela `public.artykul`: `SELECT pg_relation_filepath('public.artykul');` → `base/24576/24645`, czyli pełna ścieżka to `/var/lib/postgresql/16/main/base/24576/24645` (mogą istnieć segmenty `.1`, itp.).

Tych plików nie modyfikuje się ręcznie — do pracy z danymi używamy SQL (psql), dumpów/restore itp.

## Podsumowanie

Baza RIMS została przygotowana zgodnie z wymaganiami 3NF, wypełniona sensownymi danymi testowymi, wyposażona w procedury i widoki. Dostarczono komplet skryptów SQL i bash do łatwego uruchomienia i weryfikacji.
