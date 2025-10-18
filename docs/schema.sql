--
-- PostgreSQL database dump
--

\restrict V0YyBUKekw618JhzUYdDAUcYfu91ZGVkmE0phUpkOf3k4WWGF29G6a3GCLcgWgK

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: insertnewarticle(character varying, character varying, integer, integer, integer, numeric, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.insertnewarticle(IN tytul_in character varying, IN doi_in character varying, IN rok_in integer, IN id_czasopisma_in integer, IN punkty_mein_in integer DEFAULT NULL::integer, IN wr_in numeric DEFAULT NULL::numeric, IN data_akt_in date DEFAULT NULL::date)
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO Artykul (tytul, doi, rok_publikacji, punkty_mein, wspolczynnik_rzetelnosci, data_ostatniej_aktualizacji, id_czasopisma)
  VALUES (tytul_in, doi_in, rok_in, punkty_mein_in, wr_in, data_akt_in, id_czasopisma_in);
END;
$$;


ALTER PROCEDURE public.insertnewarticle(IN tytul_in character varying, IN doi_in character varying, IN rok_in integer, IN id_czasopisma_in integer, IN punkty_mein_in integer, IN wr_in numeric, IN data_akt_in date) OWNER TO postgres;

--
-- Name: updatewr(integer, numeric, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.updatewr(IN article_id_in integer, IN new_wr_in numeric, IN id_uzytkownika_in integer DEFAULT NULL::integer)
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


ALTER PROCEDURE public.updatewr(IN article_id_in integer, IN new_wr_in numeric, IN id_uzytkownika_in integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: artykul; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.artykul (
    id_artykulu integer NOT NULL,
    tytul character varying(500) NOT NULL,
    doi character varying(100) NOT NULL,
    rok_publikacji integer NOT NULL,
    punkty_mein integer,
    wspolczynnik_rzetelnosci numeric(4,3),
    data_ostatniej_aktualizacji date,
    id_czasopisma integer
);


ALTER TABLE public.artykul OWNER TO postgres;

--
-- Name: czasopisma; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.czasopisma (
    id_czasopisma integer NOT NULL,
    tytul character varying(255) NOT NULL,
    impact_factor numeric(5,3),
    id_wydawcy integer,
    id_dyscypliny integer
);


ALTER TABLE public.czasopisma OWNER TO postgres;

--
-- Name: wydawca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wydawca (
    id_wydawcy integer NOT NULL,
    nazwa character varying(255) NOT NULL,
    kraj character varying(100),
    srednia_retrakcji numeric(4,3),
    czy_otwarty_dostep boolean
);


ALTER TABLE public.wydawca OWNER TO postgres;

--
-- Name: zarzutnierzetelnosci; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zarzutnierzetelnosci (
    id_zarzutu integer NOT NULL,
    typ_nierzetelnosci character varying(50) NOT NULL,
    status character varying(50),
    data_zgloszenia date,
    czy_wycofany boolean,
    id_artykulu integer
);


ALTER TABLE public.zarzutnierzetelnosci OWNER TO postgres;

--
-- Name: Widok_Wycofane_Artykuły_Wydawcy; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."Widok_Wycofane_Artykuły_Wydawcy" AS
 WITH artykuly_wydawcy AS (
         SELECT w.id_wydawcy,
            w.nazwa AS wydawca,
            count(a.id_artykulu) AS liczba_artykulow
           FROM ((public.wydawca w
             JOIN public.czasopisma c ON ((c.id_wydawcy = w.id_wydawcy)))
             JOIN public.artykul a ON ((a.id_czasopisma = c.id_czasopisma)))
          GROUP BY w.id_wydawcy, w.nazwa
        ), wycofane_wydawcy AS (
         SELECT w.id_wydawcy,
            count(DISTINCT zn.id_artykulu) AS liczba_wycofanych
           FROM (((public.wydawca w
             JOIN public.czasopisma c ON ((c.id_wydawcy = w.id_wydawcy)))
             JOIN public.artykul a ON ((a.id_czasopisma = c.id_czasopisma)))
             JOIN public.zarzutnierzetelnosci zn ON (((zn.id_artykulu = a.id_artykulu) AND (zn.czy_wycofany = true))))
          GROUP BY w.id_wydawcy
        )
 SELECT aw.id_wydawcy,
    aw.wydawca,
    COALESCE(ww.liczba_wycofanych, (0)::bigint) AS liczba_wycofanych,
    aw.liczba_artykulow,
        CASE
            WHEN (aw.liczba_artykulow > 0) THEN round((((COALESCE(ww.liczba_wycofanych, (0)::bigint))::numeric / (aw.liczba_artykulow)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS procent_wycofanych
   FROM (artykuly_wydawcy aw
     LEFT JOIN wycofane_wydawcy ww ON ((ww.id_wydawcy = aw.id_wydawcy)));


ALTER VIEW public."Widok_Wycofane_Artykuły_Wydawcy" OWNER TO postgres;

--
-- Name: afiliacja; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.afiliacja (
    id_afiliacji integer NOT NULL,
    nazwa character varying(255) NOT NULL,
    kraj character varying(100),
    miasto character varying(100)
);


ALTER TABLE public.afiliacja OWNER TO postgres;

--
-- Name: afiliacja_id_afiliacji_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.afiliacja_id_afiliacji_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.afiliacja_id_afiliacji_seq OWNER TO postgres;

--
-- Name: afiliacja_id_afiliacji_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.afiliacja_id_afiliacji_seq OWNED BY public.afiliacja.id_afiliacji;


--
-- Name: artykul_autor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.artykul_autor (
    id_artykulu integer NOT NULL,
    id_autora integer NOT NULL,
    kolejnosc_autora integer
);


ALTER TABLE public.artykul_autor OWNER TO postgres;

--
-- Name: artykul_id_artykulu_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.artykul_id_artykulu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.artykul_id_artykulu_seq OWNER TO postgres;

--
-- Name: artykul_id_artykulu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.artykul_id_artykulu_seq OWNED BY public.artykul.id_artykulu;


--
-- Name: artykul_zrodlofinansowania; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.artykul_zrodlofinansowania (
    id_artykulu integer NOT NULL,
    id_zrodla integer NOT NULL
);


ALTER TABLE public.artykul_zrodlofinansowania OWNER TO postgres;

--
-- Name: autor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.autor (
    id_autora integer NOT NULL,
    imie character varying(100),
    nazwisko character varying(150) NOT NULL,
    orcid character varying(50),
    id_afiliacji integer
);


ALTER TABLE public.autor OWNER TO postgres;

--
-- Name: autor_id_autora_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.autor_id_autora_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.autor_id_autora_seq OWNER TO postgres;

--
-- Name: autor_id_autora_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.autor_id_autora_seq OWNED BY public.autor.id_autora;


--
-- Name: cytowanie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cytowanie (
    id_cytowania integer NOT NULL,
    id_cytujacego integer,
    id_cytowanego integer,
    data_zdarzenia date
);


ALTER TABLE public.cytowanie OWNER TO postgres;

--
-- Name: cytowanie_id_cytowania_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cytowanie_id_cytowania_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cytowanie_id_cytowania_seq OWNER TO postgres;

--
-- Name: cytowanie_id_cytowania_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cytowanie_id_cytowania_seq OWNED BY public.cytowanie.id_cytowania;


--
-- Name: czasopisma_id_czasopisma_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.czasopisma_id_czasopisma_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.czasopisma_id_czasopisma_seq OWNER TO postgres;

--
-- Name: czasopisma_id_czasopisma_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.czasopisma_id_czasopisma_seq OWNED BY public.czasopisma.id_czasopisma;


--
-- Name: dyscypliny; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dyscypliny (
    id_dyscypliny integer NOT NULL,
    nazwa character varying(100) NOT NULL
);


ALTER TABLE public.dyscypliny OWNER TO postgres;

--
-- Name: dyscypliny_id_dyscypliny_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dyscypliny_id_dyscypliny_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dyscypliny_id_dyscypliny_seq OWNER TO postgres;

--
-- Name: dyscypliny_id_dyscypliny_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dyscypliny_id_dyscypliny_seq OWNED BY public.dyscypliny.id_dyscypliny;


--
-- Name: logoceny; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logoceny (
    id_logu integer NOT NULL,
    id_artykulu integer,
    data_obliczenia date NOT NULL,
    stary_wspolczynnik numeric(4,3),
    nowy_wspolczynnik numeric(4,3) NOT NULL,
    id_uzytkownika integer
);


ALTER TABLE public.logoceny OWNER TO postgres;

--
-- Name: logoceny_id_logu_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logoceny_id_logu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logoceny_id_logu_seq OWNER TO postgres;

--
-- Name: logoceny_id_logu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logoceny_id_logu_seq OWNED BY public.logoceny.id_logu;


--
-- Name: zrodlofinansowania; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zrodlofinansowania (
    id_zrodla integer NOT NULL,
    nazwa character varying(255) NOT NULL,
    typ character varying(100),
    kraj character varying(100)
);


ALTER TABLE public.zrodlofinansowania OWNER TO postgres;

--
-- Name: widok_ryzykowne_finansowanie; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.widok_ryzykowne_finansowanie AS
 SELECT zf.id_zrodla,
    zf.nazwa,
    zf.typ,
    zf.kraj,
    count(DISTINCT a.id_artykulu) AS liczba_artykulow,
    avg(a.wspolczynnik_rzetelnosci) AS sr_wspolczynnik,
    sum(
        CASE
            WHEN ((a.wspolczynnik_rzetelnosci IS NOT NULL) AND (a.wspolczynnik_rzetelnosci < 0.200)) THEN 1
            ELSE 0
        END) AS n_niskich,
    round(
        CASE
            WHEN (count(DISTINCT a.id_artykulu) > 0) THEN (((sum(
            CASE
                WHEN ((a.wspolczynnik_rzetelnosci IS NOT NULL) AND (a.wspolczynnik_rzetelnosci < 0.200)) THEN 1
                ELSE 0
            END))::numeric / (count(DISTINCT a.id_artykulu))::numeric) * (100)::numeric)
            ELSE (0)::numeric
        END, 2) AS procent_niskich
   FROM ((public.zrodlofinansowania zf
     LEFT JOIN public.artykul_zrodlofinansowania azf ON ((azf.id_zrodla = zf.id_zrodla)))
     LEFT JOIN public.artykul a ON ((a.id_artykulu = azf.id_artykulu)))
  GROUP BY zf.id_zrodla, zf.nazwa, zf.typ, zf.kraj
 HAVING (count(DISTINCT a.id_artykulu) > 0);


ALTER VIEW public.widok_ryzykowne_finansowanie OWNER TO postgres;

--
-- Name: wydawca_id_wydawcy_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wydawca_id_wydawcy_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wydawca_id_wydawcy_seq OWNER TO postgres;

--
-- Name: wydawca_id_wydawcy_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wydawca_id_wydawcy_seq OWNED BY public.wydawca.id_wydawcy;


--
-- Name: zarzutnierzetelnosci_id_zarzutu_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zarzutnierzetelnosci_id_zarzutu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zarzutnierzetelnosci_id_zarzutu_seq OWNER TO postgres;

--
-- Name: zarzutnierzetelnosci_id_zarzutu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zarzutnierzetelnosci_id_zarzutu_seq OWNED BY public.zarzutnierzetelnosci.id_zarzutu;


--
-- Name: zrodlofinansowania_id_zrodla_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zrodlofinansowania_id_zrodla_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zrodlofinansowania_id_zrodla_seq OWNER TO postgres;

--
-- Name: zrodlofinansowania_id_zrodla_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zrodlofinansowania_id_zrodla_seq OWNED BY public.zrodlofinansowania.id_zrodla;


--
-- Name: afiliacja id_afiliacji; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.afiliacja ALTER COLUMN id_afiliacji SET DEFAULT nextval('public.afiliacja_id_afiliacji_seq'::regclass);


--
-- Name: artykul id_artykulu; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul ALTER COLUMN id_artykulu SET DEFAULT nextval('public.artykul_id_artykulu_seq'::regclass);


--
-- Name: autor id_autora; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autor ALTER COLUMN id_autora SET DEFAULT nextval('public.autor_id_autora_seq'::regclass);


--
-- Name: cytowanie id_cytowania; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cytowanie ALTER COLUMN id_cytowania SET DEFAULT nextval('public.cytowanie_id_cytowania_seq'::regclass);


--
-- Name: czasopisma id_czasopisma; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.czasopisma ALTER COLUMN id_czasopisma SET DEFAULT nextval('public.czasopisma_id_czasopisma_seq'::regclass);


--
-- Name: dyscypliny id_dyscypliny; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyscypliny ALTER COLUMN id_dyscypliny SET DEFAULT nextval('public.dyscypliny_id_dyscypliny_seq'::regclass);


--
-- Name: logoceny id_logu; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logoceny ALTER COLUMN id_logu SET DEFAULT nextval('public.logoceny_id_logu_seq'::regclass);


--
-- Name: wydawca id_wydawcy; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wydawca ALTER COLUMN id_wydawcy SET DEFAULT nextval('public.wydawca_id_wydawcy_seq'::regclass);


--
-- Name: zarzutnierzetelnosci id_zarzutu; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zarzutnierzetelnosci ALTER COLUMN id_zarzutu SET DEFAULT nextval('public.zarzutnierzetelnosci_id_zarzutu_seq'::regclass);


--
-- Name: zrodlofinansowania id_zrodla; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zrodlofinansowania ALTER COLUMN id_zrodla SET DEFAULT nextval('public.zrodlofinansowania_id_zrodla_seq'::regclass);


--
-- Name: afiliacja afiliacja_nazwa_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.afiliacja
    ADD CONSTRAINT afiliacja_nazwa_key UNIQUE (nazwa);


--
-- Name: afiliacja afiliacja_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.afiliacja
    ADD CONSTRAINT afiliacja_pkey PRIMARY KEY (id_afiliacji);


--
-- Name: artykul_autor artykul_autor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_autor
    ADD CONSTRAINT artykul_autor_pkey PRIMARY KEY (id_artykulu, id_autora);


--
-- Name: artykul artykul_doi_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul
    ADD CONSTRAINT artykul_doi_key UNIQUE (doi);


--
-- Name: artykul artykul_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul
    ADD CONSTRAINT artykul_pkey PRIMARY KEY (id_artykulu);


--
-- Name: artykul_zrodlofinansowania artykul_zrodlofinansowania_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_zrodlofinansowania
    ADD CONSTRAINT artykul_zrodlofinansowania_pkey PRIMARY KEY (id_artykulu, id_zrodla);


--
-- Name: autor autor_orcid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autor
    ADD CONSTRAINT autor_orcid_key UNIQUE (orcid);


--
-- Name: autor autor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autor
    ADD CONSTRAINT autor_pkey PRIMARY KEY (id_autora);


--
-- Name: cytowanie cytowanie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cytowanie
    ADD CONSTRAINT cytowanie_pkey PRIMARY KEY (id_cytowania);


--
-- Name: czasopisma czasopisma_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.czasopisma
    ADD CONSTRAINT czasopisma_pkey PRIMARY KEY (id_czasopisma);


--
-- Name: czasopisma czasopisma_tytul_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.czasopisma
    ADD CONSTRAINT czasopisma_tytul_key UNIQUE (tytul);


--
-- Name: dyscypliny dyscypliny_nazwa_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyscypliny
    ADD CONSTRAINT dyscypliny_nazwa_key UNIQUE (nazwa);


--
-- Name: dyscypliny dyscypliny_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyscypliny
    ADD CONSTRAINT dyscypliny_pkey PRIMARY KEY (id_dyscypliny);


--
-- Name: logoceny logoceny_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logoceny
    ADD CONSTRAINT logoceny_pkey PRIMARY KEY (id_logu);


--
-- Name: wydawca wydawca_nazwa_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wydawca
    ADD CONSTRAINT wydawca_nazwa_key UNIQUE (nazwa);


--
-- Name: wydawca wydawca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wydawca
    ADD CONSTRAINT wydawca_pkey PRIMARY KEY (id_wydawcy);


--
-- Name: zarzutnierzetelnosci zarzutnierzetelnosci_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zarzutnierzetelnosci
    ADD CONSTRAINT zarzutnierzetelnosci_pkey PRIMARY KEY (id_zarzutu);


--
-- Name: zrodlofinansowania zrodlofinansowania_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zrodlofinansowania
    ADD CONSTRAINT zrodlofinansowania_pkey PRIMARY KEY (id_zrodla);


--
-- Name: idx_aa_id_artykulu; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aa_id_artykulu ON public.artykul_autor USING btree (id_artykulu);


--
-- Name: idx_aa_id_autora; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aa_id_autora ON public.artykul_autor USING btree (id_autora);


--
-- Name: idx_afiliacja_kraj; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_afiliacja_kraj ON public.afiliacja USING btree (kraj);


--
-- Name: idx_art_aut_id_artykulu; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_art_aut_id_artykulu ON public.artykul_autor USING btree (id_artykulu);


--
-- Name: idx_art_aut_id_autora; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_art_aut_id_autora ON public.artykul_autor USING btree (id_autora);


--
-- Name: idx_artykul_data_ostatniej_aktualizacji; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_artykul_data_ostatniej_aktualizacji ON public.artykul USING btree (data_ostatniej_aktualizacji);


--
-- Name: idx_artykul_rok_publikacji; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_artykul_rok_publikacji ON public.artykul USING btree (rok_publikacji);


--
-- Name: idx_artykul_wspolczynnik_rzetelnosci; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_artykul_wspolczynnik_rzetelnosci ON public.artykul USING btree (wspolczynnik_rzetelnosci);


--
-- Name: artykul_autor artykul_autor_id_artykulu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_autor
    ADD CONSTRAINT artykul_autor_id_artykulu_fkey FOREIGN KEY (id_artykulu) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: artykul_autor artykul_autor_id_autora_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_autor
    ADD CONSTRAINT artykul_autor_id_autora_fkey FOREIGN KEY (id_autora) REFERENCES public.autor(id_autora) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: artykul artykul_id_czasopisma_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul
    ADD CONSTRAINT artykul_id_czasopisma_fkey FOREIGN KEY (id_czasopisma) REFERENCES public.czasopisma(id_czasopisma) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: artykul_zrodlofinansowania artykul_zrodlofinansowania_id_artykulu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_zrodlofinansowania
    ADD CONSTRAINT artykul_zrodlofinansowania_id_artykulu_fkey FOREIGN KEY (id_artykulu) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: artykul_zrodlofinansowania artykul_zrodlofinansowania_id_zrodla_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artykul_zrodlofinansowania
    ADD CONSTRAINT artykul_zrodlofinansowania_id_zrodla_fkey FOREIGN KEY (id_zrodla) REFERENCES public.zrodlofinansowania(id_zrodla) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: autor autor_id_afiliacji_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autor
    ADD CONSTRAINT autor_id_afiliacji_fkey FOREIGN KEY (id_afiliacji) REFERENCES public.afiliacja(id_afiliacji) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cytowanie cytowanie_id_cytowanego_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cytowanie
    ADD CONSTRAINT cytowanie_id_cytowanego_fkey FOREIGN KEY (id_cytowanego) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cytowanie cytowanie_id_cytujacego_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cytowanie
    ADD CONSTRAINT cytowanie_id_cytujacego_fkey FOREIGN KEY (id_cytujacego) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: czasopisma czasopisma_id_dyscypliny_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.czasopisma
    ADD CONSTRAINT czasopisma_id_dyscypliny_fkey FOREIGN KEY (id_dyscypliny) REFERENCES public.dyscypliny(id_dyscypliny) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: czasopisma czasopisma_id_wydawcy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.czasopisma
    ADD CONSTRAINT czasopisma_id_wydawcy_fkey FOREIGN KEY (id_wydawcy) REFERENCES public.wydawca(id_wydawcy) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: logoceny logoceny_id_artykulu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logoceny
    ADD CONSTRAINT logoceny_id_artykulu_fkey FOREIGN KEY (id_artykulu) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: zarzutnierzetelnosci zarzutnierzetelnosci_id_artykulu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zarzutnierzetelnosci
    ADD CONSTRAINT zarzutnierzetelnosci_id_artykulu_fkey FOREIGN KEY (id_artykulu) REFERENCES public.artykul(id_artykulu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict V0YyBUKekw618JhzUYdDAUcYfu91ZGVkmE0phUpkOf3k4WWGF29G6a3GCLcgWgK

