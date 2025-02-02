PGDMP  %    ,                |            postgres    16.1 (Homebrew)    16.0 G    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    5    postgres    DATABASE     j   CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';
    DROP DATABASE postgres;
                martinamele    false            �           0    0    DATABASE postgres    COMMENT     N   COMMENT ON DATABASE postgres IS 'default administrative connection database';
                   martinamele    false    3717            �            1255    16641    fun_autore_frase()    FUNCTION     �   CREATE FUNCTION public.fun_autore_frase() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.idautore = (SELECT idautore FROM pagina WHERE idpagina = NEW.idpagina);
    RETURN NEW;
END;
$$;
 )   DROP FUNCTION public.fun_autore_frase();
       public          martinamele    false            �            1255    16676    fun_autore_new()    FUNCTION     (  CREATE FUNCTION public.fun_autore_new() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.idautore <> OLD.idautore AND NEW.idautore IS NOT NULL THEN
        UPDATE frase
        SET idautore = NEW.idautore
        WHERE idpagina = NEW.idpagina;
    END IF;
    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.fun_autore_new();
       public          martinamele    false            �            1255    16678    fun_autore_null()    FUNCTION     �  CREATE FUNCTION public.fun_autore_null() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    IF NEW.idautore IS NULL THEN
        UPDATE frase
	SET idautore = NEW.idutente
	WHERE idpagina = NEW.idpagina;
	UPDATE pagina
	SET idautore = NEW.idutente
	WHERE idpagina = NEW.idpagina;
        --setto i valori per la tupla appena inserita manualmente
        NEW.idautore := NEW.idutente;
        NEW.accettata := TRUE;
        NEW.visibile := TRUE;
    END IF;
	
RETURN NEW;
END;
$$;
 (   DROP FUNCTION public.fun_autore_null();
       public          martinamele    false            �            1255    16674    fun_del_autore()    FUNCTION     �  CREATE FUNCTION public.fun_del_autore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
BEGIN
    --Verifica se l'autore eliminato ha creato qualche pagina
    IF OLD.idutente IN (SELECT idautore FROM pagina) THEN 
        --Verifica che ci siano delle proposte
        IF NOT EXISTS (SELECT idutente FROM frase WHERE idautore = OLD.idutente) THEN
            RETURN OLD;
        ELSE
            UPDATE pagina
            SET idautore = (
                SELECT idutente
                FROM (
                    SELECT idutente, COUNT(*) AS count_interazione
                    FROM frase
                    WHERE idutente IS NOT NULL AND 
                      idutente <> OLD.idutente AND 
                      idautore = OLD.idutente
                    GROUP BY idutente
                    ORDER BY COUNT(*) DESC
                    FETCH FIRST ROW ONLY))
            WHERE idautore = OLD.idutente;
            
        END IF;
    END IF;
    RETURN OLD;
END;
$$;
 '   DROP FUNCTION public.fun_del_autore();
       public          martinamele    false            �            1255    16643    fun_ins_frase()    FUNCTION     q  CREATE FUNCTION public.fun_ins_frase() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Caso in cui la modifica sia dell'autore
    IF NEW.idutente = NEW.idautore THEN
        --Attiva la proposta
        NEW.accettata := true;
        NEW.visibile := true;
        --Disattiva frase visibile al momento
        UPDATE frase
        SET visibile = FALSE
        WHERE idpagina = NEW.idpagina 
            AND posizione = NEW.posizione 
            AND visibile;
    --Caso in cui sia di un altro utente
    ELSE
        NEW.accettata := NULL;
        NEW.visibile := NULL;
    END IF;
    
    RETURN NEW;
END;
$$;
 &   DROP FUNCTION public.fun_ins_frase();
       public          martinamele    false            �            1255    16649    fun_ins_visita()    FUNCTION     �  CREATE FUNCTION public.fun_ins_visita() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    --Ci assicuriamo che le visite dell'autore non pesino nel conteggio
    IF NEW.idutente <> (SELECT idautore FROM pagina WHERE idpagina = NEW.idpagina) THEN
        UPDATE pagina
        SET numvisite = numvisite+1
        WHERE idpagina = NEW.idpagina;
    END IF;
        
    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.fun_ins_visita();
       public          martinamele    false            �            1255    16647    fun_link_dom()    FUNCTION     �  CREATE FUNCTION public.fun_link_dom() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    /*Ricrodiamo che i titoli delle pagine sono in maiuscolo, per questo usiamo la funzione UPPER nel confronto tra stringhe*/
     IF NEW.idlink IS NULL OR (NEW.idlink IS NOT NULL AND POSITION((SELECT titolo FROM pagina WHERE idpagina = NEW.idlink) IN UPPER(NEW.stringa)) <> 0) THEN
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;
 %   DROP FUNCTION public.fun_link_dom();
       public          martinamele    false            �            1255    16639    fun_punto()    FUNCTION     G  CREATE FUNCTION public.fun_punto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    -- Aggiungi un punto finale se non presente
    IF RIGHT(TRIM(NEW.stringa), 1) <> '.' THEN
        NEW.stringa = TRIM(NEW.stringa) || '.';
    ELSE
        NEW.stringa = TRIM(NEW.stringa);
    END IF;

    RETURN NEW;
END;
$$;
 "   DROP FUNCTION public.fun_punto();
       public          martinamele    false            �            1255    16637    fun_upper_titolo()    FUNCTION     �   CREATE FUNCTION public.fun_upper_titolo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
        NEW.titolo = UPPER(TRIM(NEW.titolo));
        RETURN NEW;
END;
$$;
 )   DROP FUNCTION public.fun_upper_titolo();
       public          martinamele    false            �            1255    16645    fun_visibile()    FUNCTION     �  CREATE FUNCTION public.fun_visibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.accettata = TRUE) THEN
        NEW.visibile := TRUE;
        --Disattiva frase visibile al momento
        UPDATE frase
        SET visibile = FALSE
        WHERE idpagina = NEW.idpagina 
            AND posizione = NEW.posizione 
            AND visibile;
    ELSEIF (NEW.accettata = FALSE) THEN
        NEW.visibile := FALSE;
    END IF;
    
    RETURN NEW;
END;
$$;
 %   DROP FUNCTION public.fun_visibile();
       public          martinamele    false            �            1255    16651 8   ins_frasi_originali(character varying, integer, integer)    FUNCTION     �  CREATE FUNCTION public.ins_frasi_originali(itesto character varying, ipagina integer, iutente integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    occ integer := 0;
BEGIN
    LOOP
        occ := occ + 1;
        --Termina quando arriva all'ultima frase
        EXIT WHEN SPLIT_PART(itesto, '.', occ) = SPLIT_PART(itesto, '.', -1);
        
        -- Elimina gli spazi dopo il punto con la funzione TRIM e aggiunge il punto finale
        INSERT INTO frase (Stringa, Posizione, IdPagina, IdUtente, IdAutore)
        VALUES (TRIM(SPLIT_PART(itesto, '.', occ)) || '.', occ, ipagina, iutente, iutente);
    END LOOP;
    
    RETURN;
END;
$$;
 f   DROP FUNCTION public.ins_frasi_originali(itesto character varying, ipagina integer, iutente integer);
       public          martinamele    false            �            1255    16669    proposte_autore(integer)    FUNCTION     �  CREATE FUNCTION public.proposte_autore(ricerca integer) RETURNS TABLE(pagina character varying, posizione integer, visibile character varying, proposta character varying, collegamento character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
        SELECT s.titolo, s.posizione, s.attiva, s.proposta, s.collegamento
        FROM proposte AS s
        WHERE s.idautore = ricerca;
END;
$$;
 7   DROP FUNCTION public.proposte_autore(ricerca integer);
       public          martinamele    false            �            1255    16657     ricerca_pagina_visibile(integer)    FUNCTION     P  CREATE FUNCTION public.ricerca_pagina_visibile(ricerca integer) RETURNS TABLE(pagina character varying, testo character varying, link character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    RETURN QUERY
        SELECT titolo, stringa, collegamento
        FROM pagine_frasi_visibili
        WHERE idpagina=ricerca;
END;
$$;
 ?   DROP FUNCTION public.ricerca_pagina_visibile(ricerca integer);
       public          martinamele    false            �            1255    16663    ricerca_storico_autore(integer)    FUNCTION     �  CREATE FUNCTION public.ricerca_storico_autore(ricerca integer) RETURNS TABLE(pagina character varying, posizione integer, visibile boolean, accettata boolean, testo character varying, collegamento character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    RETURN QUERY
        SELECT s.titolo, s.posizione, s.visibile, s.accettata, s.stringa, s.collegamento
        FROM  pagine_con_storico AS s
        WHERE s.idautore = ricerca;
END;
$$;
 >   DROP FUNCTION public.ricerca_storico_autore(ricerca integer);
       public          martinamele    false            �            1255    16687    tutte_proposte_utente(integer)    FUNCTION     �  CREATE FUNCTION public.tutte_proposte_utente(ricerca integer) RETURNS TABLE(pagina character varying, posizione integer, visibile boolean, accettata boolean, proposta character varying, collegamento character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
        SELECT s.titolo, s.posizione, s.visibile, s.accettata, s.proposta, s.collegamento
        FROM tutte_proposte AS s
        WHERE s.idutente = ricerca;
END;
$$;
 =   DROP FUNCTION public.tutte_proposte_utente(ricerca integer);
       public          martinamele    false            �            1259    16572    pagina    TABLE     C  CREATE TABLE public.pagina (
    idpagina integer NOT NULL,
    titolo character varying(128) NOT NULL,
    numvisite integer DEFAULT 0,
    data date DEFAULT CURRENT_DATE,
    ora time without time zone DEFAULT LOCALTIME,
    idautore integer,
    CONSTRAINT check_lunghezza_titolo CHECK ((length((titolo)::text) > 0))
);
    DROP TABLE public.pagina;
       public         heap    martinamele    false            �            1259    16563    utente    TABLE     �   CREATE TABLE public.utente (
    idutente integer NOT NULL,
    email character varying(128) NOT NULL,
    password character varying(128) NOT NULL,
    CONSTRAINT check_email CHECK (((email)::text ~~ '_%@_%._%'::text))
);
    DROP TABLE public.utente;
       public         heap    martinamele    false            �            1259    16670    classifica_pagine    VIEW     �   CREATE VIEW public.classifica_pagine AS
 SELECT n.numvisite AS visualizzazioni,
    n.titolo,
    u.email AS autore
   FROM (public.pagina n
     JOIN public.utente u ON ((n.idautore = u.idutente)))
  ORDER BY n.numvisite DESC, n.titolo;
 $   DROP VIEW public.classifica_pagine;
       public          martinamele    false    218    216    216    218    218            �            1259    16590    frase    TABLE     �  CREATE TABLE public.frase (
    idfrase integer NOT NULL,
    stringa character varying(500) NOT NULL,
    posizione integer NOT NULL,
    visibile boolean,
    accettata boolean,
    data date DEFAULT CURRENT_DATE,
    ora time without time zone DEFAULT LOCALTIME,
    idpagina integer NOT NULL,
    idutente integer,
    idlink integer,
    idautore integer,
    CONSTRAINT check_carattere_frase CHECK (((regexp_match((stringa)::text, '[a-z]'::text) IS NOT NULL) OR (regexp_match((stringa)::text, '[A-Z]'::text) IS NOT NULL))),
    CONSTRAINT check_lunghezza_frase CHECK ((length((stringa)::text) > 1)),
    CONSTRAINT check_visibile_accettata CHECK (((visibile = accettata) OR ((accettata = true) AND (visibile = false))))
);
    DROP TABLE public.frase;
       public         heap    martinamele    false            �            1259    16588    frase_idfrase_seq    SEQUENCE     �   CREATE SEQUENCE public.frase_idfrase_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.frase_idfrase_seq;
       public          martinamele    false    221            �           0    0    frase_idfrase_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.frase_idfrase_seq OWNED BY public.frase.idfrase;
          public          martinamele    false    219            �            1259    16589    frase_idpagina_seq    SEQUENCE     �   CREATE SEQUENCE public.frase_idpagina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.frase_idpagina_seq;
       public          martinamele    false    221            �           0    0    frase_idpagina_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.frase_idpagina_seq OWNED BY public.frase.idpagina;
          public          martinamele    false    220            �            1259    16571    pagina_idpagina_seq    SEQUENCE     �   CREATE SEQUENCE public.pagina_idpagina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.pagina_idpagina_seq;
       public          martinamele    false    218            �           0    0    pagina_idpagina_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.pagina_idpagina_seq OWNED BY public.pagina.idpagina;
          public          martinamele    false    217            �            1259    16658    pagine_con_storico    VIEW     �  CREATE VIEW public.pagine_con_storico AS
 SELECT l.titolo,
    f.posizione,
    f.visibile,
    f.accettata,
    f.stringa,
    l.idpagina,
    l.idautore,
    n.titolo AS collegamento
   FROM ((public.frase f
     JOIN public.pagina l ON ((l.idpagina = f.idpagina)))
     LEFT JOIN public.pagina n ON ((f.idlink = n.idpagina)))
  WHERE (f.accettata IS NOT NULL)
  ORDER BY l.idpagina, f.posizione, f.visibile DESC, f.accettata DESC, f.data DESC, f.ora DESC;
 %   DROP VIEW public.pagine_con_storico;
       public          martinamele    false    221    221    218    218    221    218    221    221    221    221    221            �            1259    16652    pagine_frasi_visibili    VIEW     [  CREATE VIEW public.pagine_frasi_visibili AS
 SELECT l.titolo,
    f.posizione,
    f.stringa,
    f.idpagina,
    n.titolo AS collegamento
   FROM ((public.frase f
     JOIN public.pagina l ON ((l.idpagina = f.idpagina)))
     LEFT JOIN public.pagina n ON ((f.idlink = n.idpagina)))
  WHERE (f.visibile = true)
  ORDER BY f.idpagina, f.posizione;
 (   DROP VIEW public.pagine_frasi_visibili;
       public          martinamele    false    221    221    221    221    221    218    218            �            1259    16664    proposte    VIEW       CREATE VIEW public.proposte AS
 SELECT l.titolo,
    l.idpagina,
    f.posizione,
    f.stringa AS proposta,
    l.idautore,
    n.titolo AS collegamento,
    v.stringa AS attiva
   FROM (((public.frase f
     JOIN public.pagina l ON ((l.idpagina = f.idpagina)))
     LEFT JOIN public.frase v ON (((v.idpagina = f.idpagina) AND (v.posizione = f.posizione) AND (v.visibile IS TRUE))))
     LEFT JOIN public.pagina n ON ((f.idlink = n.idpagina)))
  WHERE (f.accettata IS NULL)
  ORDER BY l.idpagina, f.posizione, f.data DESC, f.ora DESC;
    DROP VIEW public.proposte;
       public          martinamele    false    221    221    221    221    221    218    218    218    221    221    221            �            1259    16682    tutte_proposte    VIEW     �  CREATE VIEW public.tutte_proposte AS
 SELECT l.titolo,
    l.idpagina,
    f.posizione,
    f.visibile,
    f.accettata,
    f.stringa AS proposta,
    f.idautore,
    f.idutente,
    n.titolo AS collegamento
   FROM ((public.frase f
     JOIN public.pagina l ON ((l.idpagina = f.idpagina)))
     LEFT JOIN public.pagina n ON ((f.idlink = n.idpagina)))
  WHERE (f.idutente <> f.idautore)
  ORDER BY l.idpagina, f.posizione, f.data DESC, f.ora DESC;
 !   DROP VIEW public.tutte_proposte;
       public          martinamele    false    221    221    221    218    218    221    221    221    221    221    221    221            �            1259    16562    utente_idutente_seq    SEQUENCE     �   CREATE SEQUENCE public.utente_idutente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.utente_idutente_seq;
       public          martinamele    false    216            �           0    0    utente_idutente_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.utente_idutente_seq OWNED BY public.utente.idutente;
          public          martinamele    false    215            �            1259    16621    visita    TABLE     T   CREATE TABLE public.visita (
    idpagina integer NOT NULL,
    idutente integer
);
    DROP TABLE public.visita;
       public         heap    martinamele    false            �           2604    16593    frase idfrase    DEFAULT     n   ALTER TABLE ONLY public.frase ALTER COLUMN idfrase SET DEFAULT nextval('public.frase_idfrase_seq'::regclass);
 <   ALTER TABLE public.frase ALTER COLUMN idfrase DROP DEFAULT;
       public          martinamele    false    221    219    221            �           2604    16596    frase idpagina    DEFAULT     p   ALTER TABLE ONLY public.frase ALTER COLUMN idpagina SET DEFAULT nextval('public.frase_idpagina_seq'::regclass);
 =   ALTER TABLE public.frase ALTER COLUMN idpagina DROP DEFAULT;
       public          martinamele    false    220    221    221            �           2604    16575    pagina idpagina    DEFAULT     r   ALTER TABLE ONLY public.pagina ALTER COLUMN idpagina SET DEFAULT nextval('public.pagina_idpagina_seq'::regclass);
 >   ALTER TABLE public.pagina ALTER COLUMN idpagina DROP DEFAULT;
       public          martinamele    false    218    217    218            �           2604    16566    utente idutente    DEFAULT     r   ALTER TABLE ONLY public.utente ALTER COLUMN idutente SET DEFAULT nextval('public.utente_idutente_seq'::regclass);
 >   ALTER TABLE public.utente ALTER COLUMN idutente DROP DEFAULT;
       public          martinamele    false    215    216    216            ~          0    16590    frase 
   TABLE DATA           �   COPY public.frase (idfrase, stringa, posizione, visibile, accettata, data, ora, idpagina, idutente, idlink, idautore) FROM stdin;
    public          martinamele    false    221   jq       {          0    16572    pagina 
   TABLE DATA           R   COPY public.pagina (idpagina, titolo, numvisite, data, ora, idautore) FROM stdin;
    public          martinamele    false    218   j�       y          0    16563    utente 
   TABLE DATA           ;   COPY public.utente (idutente, email, password) FROM stdin;
    public          martinamele    false    216   �                 0    16621    visita 
   TABLE DATA           4   COPY public.visita (idpagina, idutente) FROM stdin;
    public          martinamele    false    222   #�       �           0    0    frase_idfrase_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.frase_idfrase_seq', 87, true);
          public          martinamele    false    219            �           0    0    frase_idpagina_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.frase_idpagina_seq', 1, false);
          public          martinamele    false    220            �           0    0    pagina_idpagina_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.pagina_idpagina_seq', 7, true);
          public          martinamele    false    217            �           0    0    utente_idutente_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.utente_idutente_seq', 20, true);
          public          martinamele    false    215            �           2606    16600    frase pk_frase 
   CONSTRAINT     Q   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT pk_frase PRIMARY KEY (idfrase);
 8   ALTER TABLE ONLY public.frase DROP CONSTRAINT pk_frase;
       public            martinamele    false    221            �           2606    16580    pagina pk_pagina 
   CONSTRAINT     T   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT pk_pagina PRIMARY KEY (idpagina);
 :   ALTER TABLE ONLY public.pagina DROP CONSTRAINT pk_pagina;
       public            martinamele    false    218            �           2606    16568    utente pk_utente 
   CONSTRAINT     T   ALTER TABLE ONLY public.utente
    ADD CONSTRAINT pk_utente PRIMARY KEY (idutente);
 :   ALTER TABLE ONLY public.utente DROP CONSTRAINT pk_utente;
       public            martinamele    false    216            �           2606    16582    pagina uk_pagina 
   CONSTRAINT     M   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT uk_pagina UNIQUE (titolo);
 :   ALTER TABLE ONLY public.pagina DROP CONSTRAINT uk_pagina;
       public            martinamele    false    218            �           2606    16570    utente uk_utente 
   CONSTRAINT     L   ALTER TABLE ONLY public.utente
    ADD CONSTRAINT uk_utente UNIQUE (email);
 :   ALTER TABLE ONLY public.utente DROP CONSTRAINT uk_utente;
       public            martinamele    false    216            �           2620    16642    frase trig_autore_frase    TRIGGER     x   CREATE TRIGGER trig_autore_frase BEFORE INSERT ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_autore_frase();
 0   DROP TRIGGER trig_autore_frase ON public.frase;
       public          martinamele    false    221    244            �           2620    16677    pagina trig_autore_new    TRIGGER     �   CREATE TRIGGER trig_autore_new AFTER UPDATE OF idautore ON public.pagina FOR EACH ROW EXECUTE FUNCTION public.fun_autore_new();
 /   DROP TRIGGER trig_autore_new ON public.pagina;
       public          martinamele    false    241    218    218            �           2620    16679    frase trig_autore_null    TRIGGER     v   CREATE TRIGGER trig_autore_null BEFORE INSERT ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_autore_null();
 /   DROP TRIGGER trig_autore_null ON public.frase;
       public          martinamele    false    253    221            �           2620    16646    frase trig_check_bit    TRIGGER     }   CREATE TRIGGER trig_check_bit AFTER UPDATE OF accettata ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_visibile();
 -   DROP TRIGGER trig_check_bit ON public.frase;
       public          martinamele    false    246    221    221            �           2620    16675    utente trig_del_autore    TRIGGER     u   CREATE TRIGGER trig_del_autore BEFORE DELETE ON public.utente FOR EACH ROW EXECUTE FUNCTION public.fun_del_autore();
 /   DROP TRIGGER trig_del_autore ON public.utente;
       public          martinamele    false    252    216            �           2620    16644    frase trig_ins_frase    TRIGGER     �   CREATE TRIGGER trig_ins_frase BEFORE INSERT OR UPDATE OF idautore ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_ins_frase();
 -   DROP TRIGGER trig_ins_frase ON public.frase;
       public          martinamele    false    221    245    221            �           2620    16650    visita trig_ins_visita    TRIGGER     t   CREATE TRIGGER trig_ins_visita AFTER INSERT ON public.visita FOR EACH ROW EXECUTE FUNCTION public.fun_ins_visita();
 /   DROP TRIGGER trig_ins_visita ON public.visita;
       public          martinamele    false    248    222            �           2620    16648    frase trig_link_dom    TRIGGER     �   CREATE TRIGGER trig_link_dom BEFORE INSERT OR UPDATE OF idlink ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_link_dom();
 ,   DROP TRIGGER trig_link_dom ON public.frase;
       public          martinamele    false    221    221    247            �           2620    16640    frase trig_punto    TRIGGER        CREATE TRIGGER trig_punto BEFORE INSERT OR UPDATE OF stringa ON public.frase FOR EACH ROW EXECUTE FUNCTION public.fun_punto();
 )   DROP TRIGGER trig_punto ON public.frase;
       public          martinamele    false    221    221    243            �           2620    16638    pagina trig_upper_titolo    TRIGGER     �   CREATE TRIGGER trig_upper_titolo BEFORE INSERT OR UPDATE OF titolo ON public.pagina FOR EACH ROW EXECUTE FUNCTION public.fun_upper_titolo();
 1   DROP TRIGGER trig_upper_titolo ON public.pagina;
       public          martinamele    false    218    242    218            �           2606    16616    frase fk_frase_autore    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_autore FOREIGN KEY (idautore) REFERENCES public.utente(idutente) ON UPDATE CASCADE ON DELETE SET NULL;
 ?   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_autore;
       public          martinamele    false    216    3530    221            �           2606    16606    frase fk_frase_link    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_link FOREIGN KEY (idlink) REFERENCES public.pagina(idpagina) ON UPDATE CASCADE ON DELETE SET NULL;
 =   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_link;
       public          martinamele    false    218    3534    221            �           2606    16601    frase fk_frase_pagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_pagina FOREIGN KEY (idpagina) REFERENCES public.pagina(idpagina) ON UPDATE CASCADE ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_pagina;
       public          martinamele    false    218    3534    221            �           2606    16611    frase fk_frase_utente    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_utente FOREIGN KEY (idutente) REFERENCES public.utente(idutente) ON UPDATE CASCADE ON DELETE SET NULL;
 ?   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_utente;
       public          martinamele    false    221    3530    216            �           2606    16583    pagina fk_pagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT fk_pagina FOREIGN KEY (idautore) REFERENCES public.utente(idutente) ON UPDATE CASCADE ON DELETE SET NULL;
 :   ALTER TABLE ONLY public.pagina DROP CONSTRAINT fk_pagina;
       public          martinamele    false    216    3530    218            �           2606    16624    visita fk_visita_pagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.visita
    ADD CONSTRAINT fk_visita_pagina FOREIGN KEY (idpagina) REFERENCES public.pagina(idpagina) ON UPDATE CASCADE ON DELETE CASCADE;
 A   ALTER TABLE ONLY public.visita DROP CONSTRAINT fk_visita_pagina;
       public          martinamele    false    222    218    3534            �           2606    16629    visita fk_visita_utente    FK CONSTRAINT     �   ALTER TABLE ONLY public.visita
    ADD CONSTRAINT fk_visita_utente FOREIGN KEY (idutente) REFERENCES public.utente(idutente) ON UPDATE CASCADE ON DELETE SET NULL;
 A   ALTER TABLE ONLY public.visita DROP CONSTRAINT fk_visita_utente;
       public          martinamele    false    3530    222    216            ~   �  x��Z�r�]�_ѥ��
�"@�����S��2e�o3��3ӓy@E��J%��Yƕ���˕�Y����/�9��``Z2�8�(vAU��}��{�����Ye~�/L���_S�ص5ma~�ڬ����v�"q3�u0����E�+Iȝ��q��K��dEoR�e��I囦����������r+�-(B����&wx7�+WY)�f?��YU.��ןW�6?�.�//��Y=4_���AF�ݾ��`hlԢr����b��_�-�+�w��A���h<�w4�7:��F�ǣ��x>�L��h����ho2�70RbsW4й��A;�4�_��	4[��s����8��ƯE�Ɨ���f����t������0��~m����_]�Uc��.,�BY�*o��ǅ�P�-���>_���9��UH�M,.9Sz[�Ft��M(��]�\w3K.|�[�%o4�49�T��U.CЄ��n���+�*���m��ʖe�x*{�CA���r=(��5��ĥ��"^�*fi+x�ƓX���/L_��\F�����Mij]��wW�x�+a�L#dH�bݜY�mB��/�]��4�=_0�6�a !��o�A��E��@ɂ�.��_w�B|�pt5�x�o�W��`�����Y/�5+��̕�F�"\ �l�?�@:��B3�𰴹�@�9A��U�S�C�������}�4[S�N��	M�\��_;��3�( S�P4-�/�s�@k�w(.��--�v ��@���/|��\�Ԟ._d�W	cfw�P��1�lt>F�/�~|��떂@ G ��������3����ȅ�����|%͋���f�V!��x���~賶
e3�Q��Ī��p-�U	 3��9���$���$�
��=X�^ �ɷ&W/�|����|�P!6`=��.��k(�qi(5� ��QAc� ףF������|�+#T�¨��*�a�T� ��>�QiakL���5_\!����$�M ����)��춌��FV�ڈ���<w�(��=d�OܝR�7�}���4�]@��wa�&��r�L��
;��[╖i!��P�P���ٿ�czD9�>u�!�pb��
PCpK�R_��]ʢc�TH�O�e-]���Iu+`���+�C�R�at8�r�MGb���+ �&fC)�:h:(�@-����Cz�یO%P�,i@1 l��(����!Gh�'�X��`$�J�V��?E�ZZ =�&4��,P��U
-C[���� 2^�[o�D/K�]x'!/z��5|DqwH�� ǃ��`7C^�l\~U�c|�	���ZW>]9����X׮2[G��QL&f5(]Cx�{i@�p�!�ܒ3]�ռ���C>���HӴ����l�,�����C���M:����׌�>�.�/Yv����l��
��H1���qg��!�vMQSʖ�Eb\P�o
�'ꦕ�� V G�m��|��~�I��$��b�ZK6z�6c�g����\t�E��@�X?ҸZ^Pj+�=�깻��"�Ah2'��`�rd�><�`X
�=��^�?�MC3�%*�8�ͧ柿���n�Ǒv��|v|@@R�S�`F�0X	�p7E���2�rN��'�S���vI��� �C�=��-/ܴ�[C�+]O��L��X[���)�>A�^���fi�rb	��+naY
�bn�pꠊ�/+�t%�R 8*�a#ʤ�m���C*]H�J��_��`���Hi��Mo�B�#hf��m��c� @���⏆�eF��VQ�,�Z ���m��
ӽ�f��-�M��^�U�� �j�o;I�TI�5��pC(�Z�eE#�����WH2�`���'�A�Vzlv���'
L�B;ib�V����E�?�Dca��{��,�u�$�����Et�Tb{�ma�.;rȖ$6Eӕ=i,��(�A��cڏYȃ�����n]I��<�`��mH?rcK�LrC�k�DoV�DBY�X�� ��P�J�y##f������VW_mנx�8�n���@�n�$�B!����+^L+�f�p�h�ǒ�� A}/dBIb��>�K�ԍ9�4�\7:���ɓ�/���5����EnvB�v�"�̯�Y��W���B�X�R��^�(�ǡ��M����yP�����$�س�
V/bLd",-�3�Txs�{��̮N��e��8��l�l�;J�@H�"4gd�n�hD��2r��$6���@��l�w2��J��J�r�,Ee;�D=+�!(faY���fF
-�󤸎�Qo(�MZ�ݨ�P�����ʖ>��iދ{̺�%]�~�.���:dmO�H���#5%,dp����Ȓ��JPŶ�BWڢ���j�ҡ�O����P�B/k�&ɂ��g��d���x2x�;�������Tn��*0��iH� #�7�%�@:bKY�X����.IH�%1�+�TfFh�_p�ٸ�`����V��/ю��湎pR�5�>!�.��b��"ԭ�����d��d�B$�̶�]v|��q�?��i8�̫������˗x��"
�[��H�p x7OU#|���׾֗P�[i�%��V)dJ���6��eQ]�>پ�[(*nvN����텘uBL�; Mw�V��Cmm�9��r'�GT�q��ə8�Ы���@�҂�d*�䁧�c����k��(��.dd���)U�lT��u �K�D5O�N�>:;���n�Q|��|�:G�%�E���� a�r-��]�+��׊@��7ރ�p����&�{m�;�hE�'!��I�6����*�@41r�w��Be���@�v+�����m)�	��;��o2��^dAC%�ۓg��q����Ғq����F@)<�*�Z��"9�=��˒}�hK?&&��Zֱ܂l�C5&��{c^�1��h���X�!_�rG,5�~ߏi��q�w��k'�\��IE� >d������b���}^��C&��`7�b��f��)+�%�z�~ټ�6�6���9s2��@b��)A�=z	��6Pl�[6��󑒬% ���[q����͏�a�:�H�,�L�z��[VK�+�V4q��$��Z̽T��%�Q�krq����V�9�'PPJm)�X�_�j.�;r �6����4�΁������F��WO����:i<!BQ�)?L3~Ǩ�Ԩ���	kgm�L���p��[�)��	���}���nI���m��7(�c��F&� ��׎����ȼW����L�9@�&`���*��P��;�,F�$Шc	�\� ��Ҝ_�`|���`�w't&d茻5d!>�xr�L�Dg����Ϗ��а�J)!�t�V��i<zx~v�S09�	Q!�\�r�(%*��:�/v�������ґ)}�d摭}��+��14��h*��z�R�
�<��n8�[t
�<�����-�pC�`+MS����ߊɽ�����O�����_~��7����f�;�?��>�Sl��r�S��l���=��G���מ�G4~����D�ُO�iTm�������e~ȉ��2�qE��f��c��&��Cl��D*k��8��tް�:qT�Q�0w���q�J�[y'?�Hy���I=$�s0$����{�3D,}��Ƙ�1�G����L��ϒ�'�2foA���!XI�wNJ/�<^*qO}�����K��^�~�@��U9�M=\����C�'?�C�[�6��N�������b�OT<�����J�K@����;���T�c�pϏ�)���e!���(��=�~�� ���~<E8�yu��A���T鏌l�b\2��CȻP_^��a���A���9 Q�s�G?m�67���F$v�9ܴ��!�#�Bk�\�<{�\�!��@��XN��Oeg���|�e�}t6� ���S8Ǎ�'?�:g8��yh�`ڐ��Jay��2F�}�?#�;`�2w�^Kc����lh�8	�v�E'��DGm�׌�����нs}*g����i��,�&����ݪ�LQq�7���9�Nl�u������޿ ^��\      {   �   x�}�A� ����Sx�XZwD�N������?G���˛R:"ذ���ayv����5YH�Ǭ�!�,���-q�)\k�ԂLc�oY���S`[|$�p�R�r���G/�o5�n�/Y��IW���y��d-���Z��w �v�?�      y     x�]�1n�0Eg��@ٱOmPYڥY��a��@�;���bF�/<R_���������ݴ8b��40�]��B]o��aQ���8�`�/����w0�ͫ�g��!��0�f,x-���"=O�Te,�ƍ|���d�>o|M���jka�]���B�n��J��+	�m~Ik�{!2��zzi�v�蛦�?s�Kj��)�f��37�ԥ.�;J���D~�}yc�_�ٳ��c� ���         P   x���� ��UL�C/鿎H<nf^�ȁ�T���m_0c*}Y��(��I���N鵂��ik��(�9� ?}�     