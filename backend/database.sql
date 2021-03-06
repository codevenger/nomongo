--
-- PostgreSQL database dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE messias;
ALTER ROLE messias WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md5b193f0d0aafa116bb5af2e40176759f7';






--
-- Database creation
--

CREATE DATABASE "any" WITH TEMPLATE = template0 OWNER = messias;


\connect "any"

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 10.10 (Ubuntu 10.10-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.10 (Ubuntu 10.10-0ubuntu0.18.04.1)

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
-- Name: system; Type: SCHEMA; Schema: -; Owner: messias
--

CREATE SCHEMA system;


ALTER SCHEMA system OWNER TO messias;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: mkmenu(character varying); Type: FUNCTION; Schema: system; Owner: messias
--

CREATE FUNCTION system.mkmenu(var_sid character varying) RETURNS json
    LANGUAGE plpgsql
    AS $_$DECLARE
   var_timeout integer := 120;
   var_user integer;
   var_res json;

BEGIN

    IF coalesce(TRIM(var_sid), '') = '' THEN
        var_sid := NULL;
    ELSIF var_sid !~ '^\d+$' THEN
        RETURN '{"status": 400, "message": "sid inválido"}';
    END IF;
        
    SELECT system.users_signin.user INTO var_user FROM system.users_signin where "sid" = var_sid;
    IF NOT FOUND THEN
        RETURN '{"status": 401, "message": "Acesso Negado"}';
    ELSE
        WITH RECURSIVE menu_from_parents AS (
        (select distinct system.menu_control.seq, system.menu_control.id, system.menu_control.descrp, '{}'::int[] as parents, 0 as var_level from  system.users_groups join system.menu_groups on system.users_groups.group = system.menu_groups.group join system.menu_control on system.menu_groups.menu = system.menu_control.id where system.users_groups.user = var_user and system.menu_control.parent is null order by system.menu_control.seq)
        union all
        (select distinct c.seq, c.id, c.descrp, parents || c.parent, var_level + 1 from  system.users_groups join system.menu_groups on system.users_groups.group = system.menu_groups.group join system.menu_control c on system.menu_groups.menu = c.id inner join menu_from_parents p on p.id = c.parent where system.users_groups.user = var_user and not c.id = any(parents) order by c.seq)
),
        menu_from_children as
            (
            (select c.parent,
                json_agg(row_to_json(c.*))::json as js from menu_from_parents tree
                join system.menu_control c using(id)
            where var_level > 0 and not id = any(parents)
            group by c.parent) union all (select c2.id,
                NULL as js from menu_from_parents tree
                join system.menu_control c2 using(id)
            where var_level = 0 and c2.goto != '' and not id = any(parents)
            group by c2.id
            )
            union all
            (select c.parent,
                replace(row_to_json(c.*)::text || json_build_object('submenu', js)::text, '}{', ', ')::json as js
            from menu_from_children tree
                join system.menu_control c on c.id = tree.parent
            order by c.seq)

        )

        select json_agg(js) INTO var_res
        from menu_from_children
        where parent IS NULL;

    END IF;
  
    IF var_res IS NULL THEN
        RETURN '{"status": 400), "message": menu indisponível"}';
    ELSE
        RETURN var_res;
    END IF;

END$_$;


ALTER FUNCTION system.mkmenu(var_sid character varying) OWNER TO messias;

--
-- Name: FUNCTION mkmenu(var_sid character varying); Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON FUNCTION system.mkmenu(var_sid character varying) IS 'Gera menu recursivo';


--
-- Name: password(text); Type: FUNCTION; Schema: system; Owner: messias
--

CREATE FUNCTION system.password(text) RETURNS text
    LANGUAGE sql
    AS $_$select crypt($1, '$1$@@$');$_$;


ALTER FUNCTION system.password(text) OWNER TO messias;

--
-- Name: FUNCTION password(text); Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON FUNCTION system.password(text) IS 'Função padrão de autenticação';


--
-- Name: signin(inet, character varying, character varying); Type: FUNCTION; Schema: system; Owner: messias
--

CREATE FUNCTION system.signin(var_ip inet, var_user character varying, var_pass character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$BEGIN
    RETURN sc_signin(var_ip, NULL, var_user, var_pass);
END$$;


ALTER FUNCTION system.signin(var_ip inet, var_user character varying, var_pass character varying) OWNER TO messias;

--
-- Name: FUNCTION signin(var_ip inet, var_user character varying, var_pass character varying); Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON FUNCTION system.signin(var_ip inet, var_user character varying, var_pass character varying) IS 'Login completo no backend, com geração de sid';


--
-- Name: signin(inet, character varying, character varying, character varying); Type: FUNCTION; Schema: system; Owner: messias
--

CREATE FUNCTION system.signin(var_ip inet, var_sid character varying, var_user character varying, var_pass character varying) RETURNS json
    LANGUAGE plpgsql
    AS $_$DECLARE
   var_timeout integer := 120;
   var_qtd integer;
   var_log bigint;
   var_res json;
   var_userid integer;
   var_entity integer;
BEGIN

    IF coalesce(TRIM(var_sid), '') = '' THEN
        var_sid := NULL;
    ELSIF var_sid !~ '^\d+$' THEN
        RETURN '{"status": 400, "message": "sid inválido"}';
    END IF;

    SELECT count(*) INTO STRICT var_qtd FROM system.users where "username" = var_user and "password" = system.password(var_pass) and "blocked" is null;
    CASE
        WHEN var_qtd = 0 THEN
            RETURN '{"status": 401, "message": "Usuário ou senha inválidos"}';
        WHEN var_qtd > 1 THEN
            RETURN '{"status": 400, "message": "Usuário duplicado"}';
        ELSE
            IF var_sid IS NOT NULL THEN
                 select system.users_signin.sid, system.users_signin.id, system.users_signin.user, system.users_signin.entity INTO var_sid, var_log, var_userid, var_entity from system.users_signin join system.users on system.users_signin.user = system.users.id where system.users.username = var_user and system.users_signin.sid = var_sid and system.users_signin.end > (now() - interval '1 minute' * var_timeout) order by system.users_signin.end desc limit 1;
            END IF;

            IF var_sid ~ '^\d+$'  THEN
                  UPDATE system.users_signin set "end" = now(), "ip" = var_ip, req = 'Relogou no sistema' where system.users_signin.id = var_log;
            ELSE
                  SELECT system.users_groups.user, system.users_groups.entity INTO var_userid, var_entity FROM system.users_groups JOIN system.users ON system.users_groups.user = system.users.id where system.users.username = var_user and system.users.password = system.password(var_pass) limit 1;
                  SELECT CONCAT(EXTRACT(EPOCH FROM NOW())::integer, (random() * 99999)::integer) INTO var_sid;
                  INSERT INTO system.users_signin ("user", "entity", "start", "end", "ip", "sid", "req") VALUES (var_userid, var_entity, now(), now(), var_ip, var_sid, 'Logou no sistema');

            END IF;

            SELECT row_to_json(r) INTO var_res from (SELECT system.users.id as code, system.users.username, system.users.name, row_to_json(languages) AS language, row_to_json(entities.*) AS entity, row_to_json(groups.*) AS group from system.users left join system.users_groups on system.users.id = system.users_groups.user join entities on system.users_groups.entity = entities.id join system.groups on system.users_groups.group = system.groups.id left join system.languages on system.users.language = system.languages.id where system.users.username = var_user and entities.disabled is NULL order by entities.dt_ins limit 1) r;

            RETURN CONCAT('{"status": 200, "message": "Credencial aceita", "sid": "', var_sid, '", "user": ', var_res, '}');

    END CASE;

END$_$;


ALTER FUNCTION system.signin(var_ip inet, var_sid character varying, var_user character varying, var_pass character varying) OWNER TO messias;

--
-- Name: FUNCTION signin(var_ip inet, var_sid character varying, var_user character varying, var_pass character varying); Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON FUNCTION system.signin(var_ip inet, var_sid character varying, var_user character varying, var_pass character varying) IS 'Login completo no backend, com retorno de sid';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: entities; Type: TABLE; Schema: public; Owner: messias
--

CREATE TABLE public.entities (
    id integer NOT NULL,
    name character varying(250) NOT NULL,
    alias character varying(150) NOT NULL,
    disabled timestamp with time zone,
    dt_ins timestamp with time zone NOT NULL,
    dt_upd timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.entities OWNER TO messias;

--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: messias
--

CREATE SEQUENCE public.entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entities_id_seq OWNER TO messias;

--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: messias
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- Name: users_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: messias
--

CREATE SEQUENCE public.users_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_groups_id_seq OWNER TO messias;

--
-- Name: groups; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.groups (
    id integer NOT NULL,
    descrp character varying(100) NOT NULL
);


ALTER TABLE system.groups OWNER TO messias;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.groups_id_seq OWNER TO messias;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.groups_id_seq OWNED BY system.groups.id;


--
-- Name: groups_tables; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.groups_tables (
    id integer NOT NULL,
    "table" character varying(50) NOT NULL,
    "group" smallint NOT NULL,
    level smallint DEFAULT 0 NOT NULL
);


ALTER TABLE system.groups_tables OWNER TO messias;

--
-- Name: groups_tables_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.groups_tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.groups_tables_id_seq OWNER TO messias;

--
-- Name: groups_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.groups_tables_id_seq OWNED BY system.groups_tables.id;


--
-- Name: languages; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.languages (
    id integer NOT NULL,
    descrp character varying(100) NOT NULL,
    abbr character varying(5) NOT NULL
);


ALTER TABLE system.languages OWNER TO messias;

--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.languages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.languages_id_seq OWNER TO messias;

--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.languages_id_seq OWNED BY system.languages.id;


--
-- Name: menu_control; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.menu_control (
    id integer NOT NULL,
    descrp character varying(100) NOT NULL,
    descri character varying(100) NOT NULL,
    goto character varying(200),
    parent integer,
    seq smallint DEFAULT 99,
    css character varying(50),
    icon character varying(10)
);


ALTER TABLE system.menu_control OWNER TO messias;

--
-- Name: TABLE menu_control; Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON TABLE system.menu_control IS 'Menu do sistema';


--
-- Name: menu_groups; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.menu_groups (
    menu integer NOT NULL,
    "group" integer NOT NULL
);


ALTER TABLE system.menu_groups OWNER TO messias;

--
-- Name: menu_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.menu_id_seq OWNER TO messias;

--
-- Name: menu_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.menu_id_seq OWNED BY system.menu_control.id;


--
-- Name: users; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.users (
    id integer NOT NULL,
    username character varying(200) NOT NULL,
    name character varying(200) NOT NULL,
    password character varying(200) NOT NULL,
    dt_ins timestamp with time zone NOT NULL,
    dt_upd timestamp with time zone DEFAULT now() NOT NULL,
    language smallint DEFAULT 1 NOT NULL,
    blocked timestamp with time zone,
    email character varying(500)
);


ALTER TABLE system.users OWNER TO messias;

--
-- Name: users_groups; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.users_groups (
    id integer DEFAULT nextval('public.users_groups_id_seq'::regclass) NOT NULL,
    entity integer NOT NULL,
    "user" integer NOT NULL,
    "group" integer NOT NULL,
    dt_ins timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE system.users_groups OWNER TO messias;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.users_id_seq OWNER TO messias;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.users_id_seq OWNED BY system.users.id;


--
-- Name: users_log; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.users_log (
    id bigint NOT NULL,
    "user" integer NOT NULL,
    dt timestamp with time zone NOT NULL,
    ip inet NOT NULL,
    req text,
    entity integer NOT NULL
);


ALTER TABLE system.users_log OWNER TO messias;

--
-- Name: users_log_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.users_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.users_log_id_seq OWNER TO messias;

--
-- Name: users_log_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.users_log_id_seq OWNED BY system.users_log.id;


--
-- Name: users_lostpassword; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.users_lostpassword (
    id integer NOT NULL,
    "user" integer NOT NULL,
    key character varying(50) NOT NULL,
    ip inet,
    dt_ins timestamp with time zone DEFAULT now(),
    dt_ok timestamp with time zone,
    email integer
);


ALTER TABLE system.users_lostpassword OWNER TO messias;

--
-- Name: users_lostpassword_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.users_lostpassword_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.users_lostpassword_id_seq OWNER TO messias;

--
-- Name: users_lostpassword_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.users_lostpassword_id_seq OWNED BY system.users_lostpassword.id;


--
-- Name: users_signin; Type: TABLE; Schema: system; Owner: messias
--

CREATE TABLE system.users_signin (
    id bigint NOT NULL,
    sid character varying(200),
    "user" smallint NOT NULL,
    entity integer NOT NULL,
    ip inet NOT NULL,
    start timestamp with time zone NOT NULL,
    "end" timestamp with time zone NOT NULL,
    req character varying(100) NOT NULL
);


ALTER TABLE system.users_signin OWNER TO messias;

--
-- Name: TABLE users_signin; Type: COMMENT; Schema: system; Owner: messias
--

COMMENT ON TABLE system.users_signin IS 'Lista de usuários ativos';


--
-- Name: users_signin_id_seq; Type: SEQUENCE; Schema: system; Owner: messias
--

CREATE SEQUENCE system.users_signin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE system.users_signin_id_seq OWNER TO messias;

--
-- Name: users_signin_id_seq; Type: SEQUENCE OWNED BY; Schema: system; Owner: messias
--

ALTER SEQUENCE system.users_signin_id_seq OWNED BY system.users_signin.id;


--
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: messias
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups ALTER COLUMN id SET DEFAULT nextval('system.groups_id_seq'::regclass);


--
-- Name: groups_tables id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups_tables ALTER COLUMN id SET DEFAULT nextval('system.groups_tables_id_seq'::regclass);


--
-- Name: languages id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.languages ALTER COLUMN id SET DEFAULT nextval('system.languages_id_seq'::regclass);


--
-- Name: menu_control id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.menu_control ALTER COLUMN id SET DEFAULT nextval('system.menu_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users ALTER COLUMN id SET DEFAULT nextval('system.users_id_seq'::regclass);


--
-- Name: users_log id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_log ALTER COLUMN id SET DEFAULT nextval('system.users_log_id_seq'::regclass);


--
-- Name: users_lostpassword id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_lostpassword ALTER COLUMN id SET DEFAULT nextval('system.users_lostpassword_id_seq'::regclass);


--
-- Name: users_signin id; Type: DEFAULT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_signin ALTER COLUMN id SET DEFAULT nextval('system.users_signin_id_seq'::regclass);


--
-- Data for Name: entities; Type: TABLE DATA; Schema: public; Owner: messias
--

COPY public.entities (id, name, alias, disabled, dt_ins, dt_upd) FROM stdin;
1	Modelo	Modelo	\N	2019-05-26 16:40:55.262218-03	2019-05-26 16:40:55.262218-03
2	Juliana Salviano da Silva	Jhully Imaginário	\N	2019-12-07 05:13:32.070231-03	2019-12-07 05:13:32.070231-03
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.groups (id, descrp) FROM stdin;
2	Supervisores
3	Colaboradores
1	Administradores
\.


--
-- Data for Name: groups_tables; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.groups_tables (id, "table", "group", level) FROM stdin;
1	groups	1	9
2	groups	2	5
3	groups	3	1
4	users	1	9
5	users	2	5
6	users	3	1
7	menu	1	9
8	menu	2	1
9	menu	3	1
10	entities	1	9
12	entities	2	5
14	entities	3	1
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.languages (id, descrp, abbr) FROM stdin;
1	English	en_US
2	Português	pt_BR
3	Español	es_ES
\.


--
-- Data for Name: menu_control; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.menu_control (id, descrp, descri, goto, parent, seq, css, icon) FROM stdin;
1	Início	Home	home	\N	1	fa-home	
2	Manutenção	Settings	\N	\N	5	fa-wrench	
5	Empresas	Companies	entities	\N	3	fa-briefcase	\N
4	Tipo de usuários	Users Types	groups	2	22	fa-users	
3	Cadastro de Usuários	Users	users	2	21	fa-user	
6	Cadastro de Menu	Menu	menu_control	2	26	fa-bars	
\.


--
-- Data for Name: menu_groups; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.menu_groups (menu, "group") FROM stdin;
1	1
1	2
2	1
2	2
3	1
3	2
4	1
4	2
5	1
5	2
6	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.users (id, username, name, password, dt_ins, dt_upd, language, blocked, email) FROM stdin;
1	admin	Administrador	$1$@@$mc9J3GbrhGh8ZBek5xFIO.	2019-05-25 19:50:35.382641-03	2019-05-25 19:50:35.382641-03	2	\N	lgbassani@gmail.com
\.


--
-- Data for Name: users_groups; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.users_groups (id, entity, "user", "group", dt_ins) FROM stdin;
1	1	1	1	2019-05-26 16:41:13.387276-03
\.


--
-- Data for Name: users_log; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.users_log (id, "user", dt, ip, req, entity) FROM stdin;
\.


--
-- Data for Name: users_lostpassword; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.users_lostpassword (id, "user", key, ip, dt_ins, dt_ok, email) FROM stdin;
\.


--
-- Data for Name: users_signin; Type: TABLE DATA; Schema: system; Owner: messias
--

COPY system.users_signin (id, sid, "user", entity, ip, start, "end", req) FROM stdin;
\.


--
-- Name: entities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: messias
--

SELECT pg_catalog.setval('public.entities_id_seq', 2, true);


--
-- Name: users_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: messias
--

SELECT pg_catalog.setval('public.users_groups_id_seq', 1, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.groups_id_seq', 15, true);


--
-- Name: groups_tables_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.groups_tables_id_seq', 14, true);


--
-- Name: languages_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.languages_id_seq', 3, true);


--
-- Name: menu_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.menu_id_seq', 6, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.users_id_seq', 1, true);


--
-- Name: users_log_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.users_log_id_seq', 1, false);


--
-- Name: users_lostpassword_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.users_lostpassword_id_seq', 1, false);


--
-- Name: users_signin_id_seq; Type: SEQUENCE SET; Schema: system; Owner: messias
--

SELECT pg_catalog.setval('system.users_signin_id_seq', 1, true);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: messias
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: groups groups_descrp_key; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups
    ADD CONSTRAINT groups_descrp_key UNIQUE (descrp);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: groups_tables groups_tables_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups_tables
    ADD CONSTRAINT groups_tables_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: menu_groups menu_groups_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.menu_groups
    ADD CONSTRAINT menu_groups_pkey PRIMARY KEY (menu, "group");


--
-- Name: menu_control menu_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.menu_control
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id);


--
-- Name: users_groups users_groups_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_groups
    ADD CONSTRAINT users_groups_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_signin users_signin_pkey; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_signin
    ADD CONSTRAINT users_signin_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: groups_tables groups_tables_group_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.groups_tables
    ADD CONSTRAINT groups_tables_group_fkey FOREIGN KEY ("group") REFERENCES system.groups(id);


--
-- Name: menu_groups menu_groups_group_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.menu_groups
    ADD CONSTRAINT menu_groups_group_fkey FOREIGN KEY ("group") REFERENCES system.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: menu_groups menu_groups_menu_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.menu_groups
    ADD CONSTRAINT menu_groups_menu_fkey FOREIGN KEY (menu) REFERENCES system.menu_control(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_groups users_groups_entity_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_groups
    ADD CONSTRAINT users_groups_entity_fkey FOREIGN KEY (entity) REFERENCES public.entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_groups users_groups_group_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_groups
    ADD CONSTRAINT users_groups_group_fkey FOREIGN KEY ("group") REFERENCES system.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_groups users_groups_user_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_groups
    ADD CONSTRAINT users_groups_user_fkey FOREIGN KEY ("user") REFERENCES system.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_language_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users
    ADD CONSTRAINT users_language_fkey FOREIGN KEY (language) REFERENCES system.languages(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: users_log users_log_user_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_log
    ADD CONSTRAINT users_log_user_fkey FOREIGN KEY ("user") REFERENCES system.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_signin users_signin_entity_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_signin
    ADD CONSTRAINT users_signin_entity_fkey FOREIGN KEY (entity) REFERENCES public.entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_signin users_signin_user_fkey; Type: FK CONSTRAINT; Schema: system; Owner: messias
--

ALTER TABLE ONLY system.users_signin
    ADD CONSTRAINT users_signin_user_fkey FOREIGN KEY ("user") REFERENCES system.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

