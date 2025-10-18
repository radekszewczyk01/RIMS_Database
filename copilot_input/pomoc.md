### 1. Polecenie Wstępne: Kontekst

Poleć agentowi, aby stworzył skrypt SQL, który odzwierciedla system RIMS.

> "Stwórz kompletny skrypt SQL dla PostgreSQL. Skrypt ma usunąć i utworzyć bazę danych o nazwie **RIMS**. Ma zawierać polecenia `CREATE TABLE` dla **wszystkich** tabel, w tym pomocniczych, z uwzględnieniem następujących poprawek normalizacyjnych 3NF:
> 1.  Dodaj nową główną tabelę **`Czasopisma`** i tabelę słownikową **`Dyscypliny`**.
> 2.  Znormalizuj relację Wydawca-Czasopismo-Artykuł.
> 3.  Użyj **`SERIAL`** dla wszystkich kluczy głównych (PK) typu INT.
> 4.  Dodaj **`NOT NULL`** do kluczowych kolumn."

---

## 2. Instrukcje dla Tabel Głównych (8+ Encji)

Poniżej są szczegółowe tabele. Agent powinien stworzyć je w odpowiedniej kolejności (najpierw encje bez kluczy obcych, potem te z FK).

### Tabela 1: Wydawca (Publisher)
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_wydawcy` | `SERIAL INT` | **PK** |
| `nazwa` | `VARCHAR(255)` | **UNIQUE, NOT NULL** |
| `kraj` | `VARCHAR(100)` | |
| `srednia_retrakcji` | `DECIMAL(4,3)` | |
| `czy_otwarty_dostep` | `BOOLEAN` | |

### Tabela 2: Afiliacja (Instytucje)
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_afiliacji` | `SERIAL INT` | **PK** |
| `nazwa` | `VARCHAR(255)` | **UNIQUE, NOT NULL** |
| `kraj` | `VARCHAR(100)` | |
| `miasto` | `VARCHAR(100)` | |

### Tabela 3: Autor
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_autora` | `SERIAL INT` | **PK** |
| `imie` | `VARCHAR(100)` | |
| `nazwisko` | `VARCHAR(150)` | **NOT NULL** |
| `orcid` | `VARCHAR(50)` | **UNIQUE** |
| `id_afiliacji` | `INT` | **FK** do `Afiliacja` |

### Tabela 4: ŹródłoFinansowania (Granty)
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_zrodla` | `SERIAL INT` | **PK** |
| `nazwa` | `VARCHAR(255)` | **NOT NULL** |
| `typ` | `VARCHAR(100)` | |
| `kraj` | `VARCHAR(100)` | |

### Tabela 5: ZarzutNierzetelnosci
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_zarzutu` | `SERIAL INT` | **PK** |
| `typ_nierzetelnosci` | `VARCHAR(50)` | **NOT NULL** |
| `status` | `VARCHAR(50)` | |
| `data_zgloszenia` | `DATE` | |
| `czy_wycofany` | `BOOLEAN` | |

### Tabela 6 (Nowa): Dyscypliny (Tabela Słownikowa)
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_dyscypliny` | `SERIAL INT` | **PK** |
| `nazwa` | `VARCHAR(100)` | **UNIQUE, NOT NULL** |

### Tabela 7 (Nowa): Czasopisma
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_czasopisma` | `SERIAL INT` | **PK** |
| `tytul` | `VARCHAR(255)` | **UNIQUE, NOT NULL** |
| `impact_factor` | `DECIMAL(5,3)` | |
| `id_wydawcy` | `INT` | **FK** do `Wydawca` |
| `id_dyscypliny` | `INT` | **FK** do `Dyscypliny` |

### Tabela 8: Artykuł
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_artykulu` | `SERIAL INT` | **PK** |
| `tytul` | `VARCHAR(500)` | **NOT NULL** |
| `doi` | `VARCHAR(100)` | **UNIQUE, NOT NULL** |
| `rok_publikacji` | `INT` | **NOT NULL** |
| `punkty_mein` | `INT` | |
| `wspolczynnik_rzetelnosci` | `DECIMAL(4,3)` | |
| `data_ostatniej_aktualizacji` | `DATE` | |
| `id_czasopisma` | `INT` | **FK** do `Czasopisma` |

---

## 3. Instrukcje dla Tabel Asocjacyjnych i Logów (Klucze Kompozytowe)

### Tabela 9: Artykul\_Autor (Relacja N:M)
> Agent musi zastosować **klucz kompozytowy** (PK) na obu kolumnach `id_artykulu` i `id_autora`.

| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_artykulu` | `INT` | **PK, FK** do `Artykul` |
| `id_autora` | `INT` | **PK, FK** do `Autor` |
| `kolejnosc_autora` | `INT` | |

### Tabela 10: Artykul\_ZrodloFinansowania (Relacja N:M)
> Agent musi zastosować **klucz kompozytowy** (PK) na obu kolumnach `id_artykulu` i `id_zrodla`.

| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_artykulu` | `INT` | **PK, FK** do `Artykul` |
| `id_zrodla` | `INT` | **PK, FK** do `ZrodloFinansowania` |

### Tabela 11: LogOceny (Log)
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_logu` | `SERIAL INT` | **PK** |
| `id_artykulu` | `INT` | **FK** do `Artykul` |
| `data_obliczenia` | `DATE` | **NOT NULL** |
| `stary_wspolczynnik` | `DECIMAL(4,3)` | |
| `nowy_wspolczynnik` | `DECIMAL(4,3)` | **NOT NULL** |
| `id_uzytkownika` | `INT` | |

### Tabela 12: Cytowanie
| Atrybut | Typ | Klucze |
| :--- | :--- | :--- |
| `id_cytowania` | `SERIAL INT` | **PK** |
| `id_cytujacego` | `INT` | **FK** do `Artykul` |
| `id_cytowanego` | `INT` | **FK** do `Artykul` |
| `data_zdarzenia` | `DATE` | |

---

## 4. Ostatnie Instrukcje (Perspektywy i Indeksy)

> "Po stworzeniu wszystkich tabel, dodaj do skryptu:
> 1.  Polecenie **`CREATE INDEX`** na kolumnie **`data_publikacji`** w tabeli **`Artykul`**.
> 2.  Polecenie **`CREATE INDEX`** (kompozytowy) na kolumnach **`wspolczynnik_rzetelnosci`** (z `Artykul`) i **`kraj`** (z `Afiliacja`), pamiętając o konieczności **JOIN**."
> 3.  Polecenia **`CREATE VIEW`** dla perspektyw: **`Widok_Wycofane_Artykuły_Wydawcy`** oraz **`Widok_Ryzykowne_Finansowanie`**.

Po wykonaniu tych poleceń przez agenta, otrzymasz gotowy do uruchomienia skrypt SQL, który w pełni spełnia wymagania Etapu 1.