
> **"Na podstawie istniejącego schematu RIMS w PostgreSQL (z uwzględnieniem normalizacji do 3NF) wygeneruj następujące skrypty SQL. Wynikiem końcowym powinien być jeden plik o nazwie `data_and_features.sql`, który zawiera poniższe elementy w tej kolejności:**
>
> ### 1. Wypełnienie Danych (Minimalna Wymagalność)
>
> **Wygeneruj polecenia `INSERT` dla wszystkich tabel, zapewniając sensowny kontekst danych dla systemu RIMS.**
>
> [cite_start]* **Ilość rekordów:** W każdej tabeli (głównej i słownikowej) musi znajdować się **co najmniej 4 rekordy**[cite: 9].
> * **Priorytet:** Największą liczbę rekordów (np. co najmniej 20) umieść w tabeli **`Artykuł`** oraz w tabelach asocjacyjnych (`Artykul_Autor`), aby zapewnić wystarczającą ilość danych do testowania zapytań i indeksów.
>
> ### 2. Elementy Programowalne (Uproszczone dla Etapu 1)
>
> **Stwórz "sprytne" procedury do zarządzania danymi (choć są to elementy Etapu 2, pozwalają na testowanie danych):**
>
> * **Procedura `InsertNewArticle(tytul_in, doi_in, ...)`:** Procedura na poziomie **Etapu 2**, która przyjmuje parametry dla nowego artykułu, a następnie dodaje rekord do tabeli **`Artykuł`**.
> * **Procedura `UpdateWR(article_id_in, new_wr_in)`:** Procedura, która **aktualizuje** pole `wspolczynnik_rzetelnosci` dla danego artykułu i jednocześnie tworzy nowy rekord w tabeli **`LogOceny`** (demonstrując użycie dwóch tabel).
>
> ### 3. Przykłady Użycia Procedur i Zmiany Danych
>
> **Pokaż, jak używać procedur i jak zmieniać dane:**
>
> * Wywołaj **trzykrotnie** procedurę `InsertNewArticle(...)`, aby dodać 3 nowe rekordy (w sumie ponad minimum).
> * Wywołaj procedurę `UpdateWR(...)` co najmniej **dwa razy**, aby zaktualizować wskaźnik rzetelności dla dwóch różnych artykułów.
>
> ### 4. Złożone Zapytania (Wymagane)
>
> **Wygeneruj dwa złożone zapytania SQL, które udokumentują funkcjonalności RIMS:**
>
> * **Zapytanie 1 (Złożone z Podzapytaniem):** Wybierz autorów, którzy opublikowali **artykuły o niskim WR (np. WR < 0.3)** w **czasopismach o IF < 1.0** (użyj podzapytania do weryfikacji IF).
> * **Zapytanie 2 (Złożone z Agregacją):** Oblicz, ilu autorów związanych z **Afiliacją X** opublikowało prace, które mają **Zarzut Nierzetelności** (`czy_wycofany = TRUE`).
>
> ### 5. Perspektywy (Views) (Wymagane)
>
> [cite_start]**Użyj poleceń `CREATE VIEW` dla wcześniej zdefiniowanych perspektyw (minimum 2 nietrywialne [cite: 10]):**
>
> * **`Widok_Wycofane_Artykuły_Wydawcy`** (łączy co najmniej 3 tabele i używa agregacji).
> * **`Widok_Ryzykowne_Finansowanie`** (łączy co najmniej 3 tabele, filtruje i zawiera wskaźniki).
>
> ### 6. Indeksy (Wymagane)
>
> [cite_start]**Użyj poleceń `CREATE INDEX` dla optymalizacji[cite: 10]:**
>
> * **Indeks Prosty:** Na kolumnie **`data_publikacji`** w tabeli `Artykul`.
> * **Indeks Kompozytowy:** Na kolumnach **`wspolczynnik_rzetelnosci`** (z `Artykul`) i **`kraj`** (z `Afiliacja`), pamiętając o konieczności `JOIN` (działanie jest tu poprawne).
>
> **Zacznij generowanie kodu od razu.**"