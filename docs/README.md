# RIMS export

Zawartość paczki:
- schema.sql – definicja schematu bazy (tabele, klucze, widoki, bez danych)
- csv/*.csv – dane z każdej tabeli schematu public w formacie CSV (nagłówki kolumn)
- index.html – podgląd pierwszych 50 wierszy każdej tabeli (jeśli włączone)

Jak odtworzyć:
- Import CSV: w dowolnym narzędziu (psql, DBeaver, Excel) wczytaj pliki z folderu csv.
- Odtworzenie schematu: psql -f schema.sql (na pustej bazie) – następnie załaduj CSV zgodnie z kolejnością zależności.

Uwaga: Paczka przeznaczona jest tylko do odczytu i inspekcji danych.
