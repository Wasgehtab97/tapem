--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-03-29 04:14:55

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 24777)
-- Name: affiliate_clicks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.affiliate_clicks (
    id integer NOT NULL,
    offer_id integer NOT NULL,
    user_id integer,
    clicked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.affiliate_clicks OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24776)
-- Name: affiliate_clicks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.affiliate_clicks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.affiliate_clicks_id_seq OWNER TO postgres;

--
-- TOC entry 4980 (class 0 OID 0)
-- Dependencies: 235
-- Name: affiliate_clicks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.affiliate_clicks_id_seq OWNED BY public.affiliate_clicks.id;


--
-- TOC entry 234 (class 1259 OID 24768)
-- Name: affiliate_offers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.affiliate_offers (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    affiliate_url text NOT NULL,
    image_url text,
    start_date date,
    end_date date,
    revenue_share numeric(5,2)
);


ALTER TABLE public.affiliate_offers OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 24767)
-- Name: affiliate_offers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.affiliate_offers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.affiliate_offers_id_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 233
-- Name: affiliate_offers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.affiliate_offers_id_seq OWNED BY public.affiliate_offers.id;


--
-- TOC entry 232 (class 1259 OID 24758)
-- Name: coaching_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.coaching_requests (
    id integer NOT NULL,
    coach_id integer NOT NULL,
    client_id integer NOT NULL,
    status character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.coaching_requests OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24757)
-- Name: coaching_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.coaching_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coaching_requests_id_seq OWNER TO postgres;

--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 231
-- Name: coaching_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.coaching_requests_id_seq OWNED BY public.coaching_requests.id;


--
-- TOC entry 238 (class 1259 OID 24806)
-- Name: custom_exercises; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_exercises (
    id integer NOT NULL,
    user_id integer NOT NULL,
    device_id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.custom_exercises OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24805)
-- Name: custom_exercises_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.custom_exercises_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.custom_exercises_id_seq OWNER TO postgres;

--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 237
-- Name: custom_exercises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.custom_exercises_id_seq OWNED BY public.custom_exercises.id;


--
-- TOC entry 222 (class 1259 OID 16439)
-- Name: devices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.devices (
    id integer NOT NULL,
    name text NOT NULL,
    exercise_mode text NOT NULL,
    secret_code character varying(32) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.devices OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16438)
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.devices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.devices_id_seq OWNER TO postgres;

--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 221
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;


--
-- TOC entry 224 (class 1259 OID 16449)
-- Name: feedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.feedback (
    id integer NOT NULL,
    user_id integer,
    device_id integer NOT NULL,
    feedback_text text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    status character varying(50) DEFAULT 'neu'::character varying
);


ALTER TABLE public.feedback OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16448)
-- Name: feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.feedback_id_seq OWNER TO postgres;

--
-- TOC entry 4985 (class 0 OID 0)
-- Dependencies: 223
-- Name: feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;


--
-- TOC entry 226 (class 1259 OID 16485)
-- Name: training_days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.training_days (
    id integer NOT NULL,
    user_id integer NOT NULL,
    training_date date NOT NULL
);


ALTER TABLE public.training_days OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16484)
-- Name: training_days_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.training_days_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.training_days_id_seq OWNER TO postgres;

--
-- TOC entry 4986 (class 0 OID 0)
-- Dependencies: 225
-- Name: training_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.training_days_id_seq OWNED BY public.training_days.id;


--
-- TOC entry 220 (class 1259 OID 16427)
-- Name: training_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.training_history (
    id integer NOT NULL,
    user_id integer NOT NULL,
    device_id integer NOT NULL,
    training_date date NOT NULL,
    exercise text NOT NULL,
    sets integer NOT NULL,
    reps integer NOT NULL,
    weight numeric(5,2) NOT NULL,
    CONSTRAINT training_history_reps_check CHECK ((reps > 0)),
    CONSTRAINT training_history_sets_check CHECK ((sets > 0)),
    CONSTRAINT training_history_weight_check CHECK ((weight >= (0)::numeric))
);


ALTER TABLE public.training_history OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16426)
-- Name: training_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.training_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.training_history_id_seq OWNER TO postgres;

--
-- TOC entry 4987 (class 0 OID 0)
-- Dependencies: 219
-- Name: training_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.training_history_id_seq OWNED BY public.training_history.id;


--
-- TOC entry 230 (class 1259 OID 16547)
-- Name: training_plan_exercises; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.training_plan_exercises (
    id integer NOT NULL,
    plan_id integer NOT NULL,
    device_id integer NOT NULL,
    exercise_order integer NOT NULL
);


ALTER TABLE public.training_plan_exercises OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16546)
-- Name: training_plan_exercises_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.training_plan_exercises_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.training_plan_exercises_id_seq OWNER TO postgres;

--
-- TOC entry 4988 (class 0 OID 0)
-- Dependencies: 229
-- Name: training_plan_exercises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.training_plan_exercises_id_seq OWNED BY public.training_plan_exercises.id;


--
-- TOC entry 228 (class 1259 OID 16533)
-- Name: training_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.training_plans (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'inaktiv'::character varying
);


ALTER TABLE public.training_plans OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16532)
-- Name: training_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.training_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.training_plans_id_seq OWNER TO postgres;

--
-- TOC entry 4989 (class 0 OID 0)
-- Dependencies: 227
-- Name: training_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.training_plans_id_seq OWNED BY public.training_plans.id;


--
-- TOC entry 218 (class 1259 OID 16390)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(100),
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    membership_number integer,
    current_streak integer DEFAULT 0,
    role character varying(50) DEFAULT 'user'::character varying,
    exp integer DEFAULT 0,
    exp_progress integer DEFAULT 0,
    division_index integer DEFAULT 0,
    coach_id integer,
    CONSTRAINT users_membership_number_check CHECK (((membership_number >= 1) AND (membership_number <= 3000)))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16389)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 4990 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4765 (class 2604 OID 24780)
-- Name: affiliate_clicks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affiliate_clicks ALTER COLUMN id SET DEFAULT nextval('public.affiliate_clicks_id_seq'::regclass);


--
-- TOC entry 4764 (class 2604 OID 24771)
-- Name: affiliate_offers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affiliate_offers ALTER COLUMN id SET DEFAULT nextval('public.affiliate_offers_id_seq'::regclass);


--
-- TOC entry 4762 (class 2604 OID 24761)
-- Name: coaching_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaching_requests ALTER COLUMN id SET DEFAULT nextval('public.coaching_requests_id_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 24809)
-- Name: custom_exercises id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_exercises ALTER COLUMN id SET DEFAULT nextval('public.custom_exercises_id_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 24766)
-- Name: devices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);


--
-- TOC entry 4754 (class 2604 OID 16452)
-- Name: feedback id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);


--
-- TOC entry 4757 (class 2604 OID 16488)
-- Name: training_days id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_days ALTER COLUMN id SET DEFAULT nextval('public.training_days_id_seq'::regclass);


--
-- TOC entry 4751 (class 2604 OID 16430)
-- Name: training_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_history ALTER COLUMN id SET DEFAULT nextval('public.training_history_id_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 16550)
-- Name: training_plan_exercises id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plan_exercises ALTER COLUMN id SET DEFAULT nextval('public.training_plan_exercises_id_seq'::regclass);


--
-- TOC entry 4758 (class 2604 OID 16536)
-- Name: training_plans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plans ALTER COLUMN id SET DEFAULT nextval('public.training_plans_id_seq'::regclass);


--
-- TOC entry 4745 (class 2604 OID 16393)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4972 (class 0 OID 24777)
-- Dependencies: 236
-- Data for Name: affiliate_clicks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affiliate_clicks (id, offer_id, user_id, clicked_at) FROM stdin;
\.


--
-- TOC entry 4970 (class 0 OID 24768)
-- Dependencies: 234
-- Data for Name: affiliate_offers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.affiliate_offers (id, title, description, affiliate_url, image_url, start_date, end_date, revenue_share) FROM stdin;
\.


--
-- TOC entry 4968 (class 0 OID 24758)
-- Dependencies: 232
-- Data for Name: coaching_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.coaching_requests (id, coach_id, client_id, status, created_at) FROM stdin;
1	15	1	accepted	2025-03-17 00:35:02.601005
\.


--
-- TOC entry 4974 (class 0 OID 24806)
-- Dependencies: 238
-- Data for Name: custom_exercises; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_exercises (id, user_id, device_id, name, created_at) FROM stdin;
2	21	23	Fly Reverse	2025-03-27 02:05:58.190644
3	21	23	Fly Reverse	2025-03-27 02:08:18.270241
\.


--
-- TOC entry 4958 (class 0 OID 16439)
-- Dependencies: 222
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.devices (id, name, exercise_mode, secret_code) FROM stdin;
9	Seated Calf Raise	single	5a512139d57d6899
10	Standing Calf Raise	single	5f2783823a255e69
11	Standing Vertical Press	single	82c40cd6c7450077
12	Standing Vertical Press	single	69c9997f34e14173
16	Vertikale Beinpresse	single	94d22a5c35a8ab8d
17	Donkey Calf Raises	single	511e93cbe72e0faa
18	Hip Thrust 	single	dcbd4df71c670faf
24	Precor Lat Pulldown	single	907362528d54fa2a
25	Matrix Latzug	single	bf3234dec9c085ab
27	Matrix Rudern	single	f475c0dda5013aee
30	Matrix Latzug	single	8e5f61621914fea6
31	Matrix Rudern	single	bbd5e6e4b9318795
34	Matrix Latzug	single	a52656bd5da8d4fc
35	Matrix Rudern	single	8e10e9863e1c272d
37	Proctor Rudern	single	d525fdaa9872eaea
101	101	single	0eac9db90d3ddeef
42	Gymleco Incline Press	single	8f72e7e551954be2
43	Gymleco Standing Lateral Raise	single	33ddfc96b78cf5f6
44	Gymleco Fly Machine	single	55c46ce214866bf4
45	Gym80 Fly Machine	single	8aee26e15bde3af9
47	Nautilus Vertical Press	single	54172f869d5ece93
48	Nautlius Vertical Press	single	b83ea3928231f560
49	Cybex Plate Loaded Chest Press	single	ed306b9d66d606b6
50	Nautilus Incline Press	single	e2638747ea6ee443
51	Nautilus Incline Press	single	ddc9cb3acc62f179
52	Cybex Row	single	27f747dcca23b93d
53	Gym80 Inner Chest Press	single	8ba11533890b875d
54	Cybex Row	single	b51b8f4da2a7e38e
55	Nautlius Compound Row	single	b3aff01b17037018
56	Nautilus Compound Row	single	19c3411255b40e7a
57	Nautilus Lat Pulldown Isolateral	single	0ff166c4012f977d
58	Nautilus Lat Pulldown	single	89890bfe4733efdd
59	Hoist Vertical Press	single	fcf88a29df7b81aa
60	Pure Kraft Plate Loaded Press	single	a370fd3755d70faa
61	Proctor Plate Loaded Press	single	70621b534e19b761
62	Hammer Strength Plate Loaded Press	single	774eaef65a5769bf
63	Hoist Shoulder Press	single	db56f2c188788e26
64	Precor Incline Press	single	94aea867419b861f
65	Hammer Strength low row	single	33dccfe93e987235
66	Hammer Strength Row	single	37b6314c3775a399
67	Hammer Strength High Row	single	ac1b1852e414eeee
68	Nautilus High Row	single	c77914dd78a2faf4
69	Panatta Fly	single	6208fed8bb6583a7
70	70	single	bd25dee69352e758
71	71	single	a89d607022990cd0
72	72	single	cac279b473056e31
73	73	single	ce4eddd2aa9040a3
74	74	single	89b49c70bf6dc53d
75	75	single	01d93b33aa24f452
76	76	single	36f29b7023d89a71
77	77	single	cd043f10a0ac2e2a
78	78	single	69a1b9c2888d49a8
79	79	single	27df9ad94371769c
80	80	single	c76a59a19757bc1c
81	81	single	f9b0973e27822f5f
82	82	single	cfe9c82066db43ca
83	83	single	32cd4a240d4f25cf
84	84	single	c47f748a47a1cc42
85	85	single	da573c06ba0544e5
86	86	single	12a3a3db89701592
87	87	single	2275ad6a4ce1b721
88	88	single	8136b454c9a85352
89	89	single	413cb65ad64c07ab
90	90	single	33211b1089465df6
91	91	single	6620086a4c0a6ecd
92	92	single	4d4c15ebf884017c
93	93	single	b683951aa328e2ca
94	94	single	70247d396f264e6c
95	95	single	5196c6716c70c0d8
96	96	single	9f870532562f3916
97	97	single	4a37ea9b1525ebf7
98	98	single	3f99693603941c38
99	99	single	84d8314d345ca512
100	100	single	920d8433ea823d50
102	102	single	ef51886754b56fc1
103	103	single	065eac8e5fa6c59e
104	104	single	255b0b54d946bbad
105	105	single	d38bb832324c45f6
106	106	single	22937fba930e2757
107	107	single	9f4006158ead835e
108	108	single	25778b33d61381b8
109	109	single	188375d88dac74f8
110	110	single	ebd90477659c6905
111	111	single	64848b4d05006eec
112	112	single	7916b471080becc6
113	113	single	2b82d8d15cf4a5b8
114	114	single	bf34a5e53b960992
115	115	single	bd334bab4440af63
116	116	single	e73c37d36fd3b05c
117	117	single	541597c4fec21de6
118	118	single	2b7cd4fe3a91cce9
119	119	single	c47298ff2b08b038
120	120	single	288e2eb0175ae672
121	121	single	75a5e14e3c9082d8
122	122	single	75ea10f1d23ddbb0
123	123	single	adc389c4163081f9
124	124	single	b064be30a626050b
125	125	single	4aa6f45024d6e38d
126	126	single	5c24ea2e5e1322e6
127	127	single	737dbfb842e690b2
128	128	single	17bd209dab9fdfd7
129	129	single	98d58fa614362e4f
130	130	single	01446fb76fc6f49a
131	131	single	5b9fcf622c05e05f
132	132	single	246706332c291e28
133	133	single	49936e887ea9213f
134	134	single	237e0375cf85b35b
135	135	single	6fb14f9837840021
136	136	single	1633cb26d4ff93d2
137	137	single	8d8e7e003852cf2f
138	138	single	7f1026ce78f77bd0
139	139	single	7de32ac23bad3d47
140	140	single	23da841b838efa5b
141	141	single	9e7dfac60e5f62b6
142	142	single	cacfd6051d0c39fe
143	143	single	9587bfd3000709ef
144	144	single	1eb314612774dcd5
145	145	single	256d1440d76a4f5e
146	146	single	f3d0cc31a9ab1105
147	147	single	0c8e936c480092f5
148	148	single	d1b409edd49934bd
149	149	single	d86f569d5a9bfb37
150	150	single	3cd7973136e3eb75
151	151	single	0b399bb4d9c8d732
152	152	single	443abac4c9268a2c
13	Benchpress	custom	eeee2c88225cc89f
14	Incline Benchpress	custom	2172294a036e4267
15	Dips / Shrugs	custom	f86edd8189de077c
22	Cybex Kraken	custom	97573f54920a6373
23	Gym80 Kraken	custom	7205e2284246f109
26	Matrix Kabelturm	custom	a31f54090957a9e6
28	Matrix Kabelturm	custom	354471719541f290
29	Matrix Kabelturm	custom	63069ef7ea47ef6e
32	Matrix Kabelturm	custom	ebf0151b93819132
33	Matrix Kabelturm	custom	3b2ce4da7a488695
36	Matrix Kabelturm	custom	565edc1bb29b4a2e
38	Precor Kabelturm	custom	ddbf445a2616e26f
39	Precor Kabelturm	custom	28176f9c0bf9bc18
40	Matrix Kabelturm	custom	b968c93a8e8ff297
41	Matrix Kabelturm	custom	9df8a0210ce4312f
46	Hammer Strength Ground Base	custom	e36dd566e02e9c94
1	Benchpress Eleiko	multi	2e286b32b00848d5
2	Benchpress ATX	multi	5972b19627bfc5b6
3	Deadlift	multi	7e9689aad6e19772
4	Eleiko Rack	multi	296e5e50f85177d5
5	Squat Rack	multi	e7be0c81376bdca8
6	Squat rack	multi	9e851d1c9ff691b7
7	Benchpress	multi	48ea17cfbb6a8cbf
8	Benchpress	multi	72bd6b2120f93fd3
19	Squat Rack 1	multi	3ab67400b395757e
20	Squat Rack 2 	multi	866e07f6e8fbb4b7
21	Squat Rack 3	multi	71c97d809e40d35a
\.


--
-- TOC entry 4960 (class 0 OID 16449)
-- Dependencies: 224
-- Data for Name: feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.feedback (id, user_id, device_id, feedback_text, created_at, status) FROM stdin;
\.


--
-- TOC entry 4962 (class 0 OID 16485)
-- Dependencies: 226
-- Data for Name: training_days; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.training_days (id, user_id, training_date) FROM stdin;
1	11	2025-02-10
3	13	2025-02-10
4	15	2025-02-10
6	16	2025-02-10
11	11	2025-02-11
12	15	2025-02-11
13	17	2025-02-11
18	19	2025-02-11
22	15	2025-02-12
24	15	2025-02-13
25	15	2025-02-17
26	15	2025-02-18
27	15	2025-03-06
28	11	2025-03-06
29	17	2025-03-06
33	15	2025-03-07
34	15	2025-03-08
36	15	2025-03-11
42	15	2025-03-12
59	15	2025-03-13
60	1	2025-03-13
61	1	2025-03-15
62	15	2025-03-15
\.


--
-- TOC entry 4956 (class 0 OID 16427)
-- Dependencies: 220
-- Data for Name: training_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.training_history (id, user_id, device_id, training_date, exercise, sets, reps, weight) FROM stdin;
1	11	1	2025-02-09	Gerät 1	1	5	100.00
2	11	1	2025-02-09	Gerät 1	2	5	100.00
3	11	1	2025-02-09	Gerät 1	3	5	100.00
4	11	14	2025-02-09	Gerät 14	1	10	40.00
5	11	14	2025-02-09	Gerät 14	2	10	40.00
6	11	14	2025-02-09	Gerät 14	3	9	40.00
7	12	8	2025-02-10	Gerät 8	1	69	420.00
8	12	8	2025-02-10	Gerät 8	2	69	420.00
9	12	8	2025-02-10	Gerät 8	3	67	420.00
10	11	1	2025-02-10	Gerät 1	1	6	100.00
11	11	1	2025-02-10	Gerät 1	2	6	100.00
12	11	1	2025-02-10	Gerät 1	3	6	100.00
13	11	2	2025-02-10	Gerät 2	1	123	123.00
14	11	2	2025-02-10	Gerät 2	2	123	123.00
15	11	4	2025-02-10	Gerät 4	1	6	10.00
16	11	4	2025-02-10	Gerät 4	2	6	20.00
17	11	4	2025-02-10	Gerät 4	3	6	30.00
18	11	5	2025-02-10	Gerät 5	1	123	123.00
19	11	5	2025-02-10	Gerät 5	2	123	123.00
20	13	1	2025-02-10	Gerät 1	1	12	123.00
21	13	1	2025-02-10	Gerät 1	2	12	123.00
22	13	1	2025-02-10	Gerät 1	3	12	123.00
23	15	24	2025-02-10	Gerät 24	1	10	55.00
24	15	24	2025-02-10	Gerät 24	2	110	55.00
25	15	13	2025-02-10	Gerät 13	1	123	112.00
26	15	13	2025-02-10	Gerät 13	2	123	123.00
27	15	13	2025-02-10	Gerät 13	3	123	123.00
28	16	1	2025-02-10	Gerät 1	1	12	60.00
29	16	3	2025-02-10	Gerät 3	1	1	100.00
31	16	8	2025-02-10	Gerät 8	1	12	45.00
32	16	10	2025-02-10	Gerät 10	1	33	33.00
33	16	4	2025-02-10	Gerät 4	1	1	24.56
34	11	1	2025-02-11	Gerät 1	1	7	100.00
35	11	1	2025-02-11	Gerät 1	2	7	100.00
36	11	1	2025-02-11	Gerät 1	3	7	100.00
37	15	13	2025-02-11	Gerät 13	1	123	112.00
38	15	13	2025-02-11	Gerät 13	2	123	123.00
39	15	13	2025-02-11	Gerät 13	3	123	123.00
40	17	1	2025-02-11	Gerät 1	1	123	123.00
41	17	1	2025-02-11	Gerät 1	2	123	123.00
42	17	1	2025-02-11	Gerät 1	3	123	123.00
43	15	1	2025-02-11	Gerät 1	1	10	45.00
44	15	1	2025-02-11	Gerät 1	2	10	45.00
45	15	2	2025-02-11	Gerät 2	1	8	65.00
46	15	2	2025-02-11	Gerät 2	2	8	67.50
47	15	3	2025-02-11	Gerät 3	1	8	50.00
48	15	3	2025-02-11	Gerät 3	2	8	52.50
49	15	4	2025-02-11	Gerät 4	1	12	94.00
50	15	4	2025-02-11	Gerät 4	2	12	94.00
51	19	1	2025-02-11	Gerät 1	1	10	45.00
52	19	1	2025-02-11	Gerät 1	2	10	45.00
53	19	2	2025-02-11	Gerät 2	1	8	65.00
54	19	2	2025-02-11	Gerät 2	2	8	67.50
55	19	3	2025-02-11	Gerät 3	1	8	50.00
56	19	3	2025-02-11	Gerät 3	2	8	52.50
57	19	4	2025-02-11	Gerät 4	1	12	94.00
58	19	4	2025-02-11	Gerät 4	2	12	94.00
59	15	5	2025-02-12	Gerät 5	1	123	112.00
60	15	5	2025-02-12	Gerät 5	2	123	123.00
61	15	1	2025-02-12	High Row Isolateral	1	10	55.00
62	15	1	2025-02-12	High Row Isolateral	2	10	55.00
63	15	1	2025-02-13	High Row Isolateral	1	11	55.00
64	15	1	2025-02-13	High Row Isolateral	2	10	55.00
65	15	17	2025-02-17	Gerät 17	1	12	123.00
66	15	17	2025-02-17	Gerät 17	2	12	123.00
67	15	15	2025-02-18	Bankdrücken Eleiko	1	10	80.00
68	15	15	2025-02-18	Bankdrücken Eleiko	2	10	80.00
69	15	15	2025-02-18	Bankdrücken Eleiko	3	8	80.00
70	15	3	2025-03-06	T-Bar Row 	1	12	123.00
71	15	3	2025-03-06	T-Bar Row 	2	12	123.00
72	15	3	2025-03-06	T-Bar Row 	3	12	123.00
73	11	10	2025-03-06	Beinstrecker Oldschoolding	1	12	123.00
74	11	10	2025-03-06	Beinstrecker Oldschoolding	2	12	123.00
75	11	10	2025-03-06	Beinstrecker Oldschoolding	3	12	123.00
76	17	8	2025-03-06	Seitheben Maschinne Sitzend	1	12	123.00
77	17	8	2025-03-06	Seitheben Maschinne Sitzend	2	12	123.00
78	17	8	2025-03-06	Seitheben Maschinne Sitzend	3	12	123.00
81	17	3	2025-03-06	T-Bar Row 	1	12	123.00
82	17	3	2025-03-06	T-Bar Row 	2	12	123.00
83	17	7	2025-03-06	Rudermaschine neben Tbar weiss	1	12	123.00
84	17	7	2025-03-06	Rudermaschine neben Tbar weiss	2	123	123.00
85	15	4	2025-03-06	Front Row Isolateral	1	12	123.00
86	15	4	2025-03-06	Front Row Isolateral	2	12	123.00
87	15	7	2025-03-07	Rudermaschine neben Tbar weiss	1	12	12.00
88	15	7	2025-03-07	Rudermaschine neben Tbar weiss	2	12	12.00
89	15	7	2025-03-08	Rudermaschine neben Tbar weiss	1	12	123.00
90	15	7	2025-03-08	Rudermaschine neben Tbar weiss	2	12	123.00
91	15	27	2025-03-08	Gerät 27	1	12	123.00
92	15	27	2025-03-08	Gerät 27	2	12	123.00
93	15	30	2025-03-11	Gerät 30	1	12	123.00
94	15	30	2025-03-11	Gerät 30	2	12	123.00
95	15	30	2025-03-11	Gerät 30	3	12	123.00
96	15	36	2025-03-11	Gerät 36	1	12	123.00
97	15	36	2025-03-11	Gerät 36	2	12	123.00
98	15	36	2025-03-11	Gerät 36	3	12	123.00
99	15	7	2025-03-11	Rudermaschine neben Tbar weiss	1	13	123.00
100	15	7	2025-03-11	Rudermaschine neben Tbar weiss	2	13	123.00
101	15	7	2025-03-11	Rudermaschine neben Tbar weiss	3	12	123.00
105	15	1	2025-03-11	High Row Isolateral	1	12	123.00
106	15	28	2025-03-12	Bankdrücken	1	5	80.00
107	15	28	2025-03-12	Bankdrücken	2	5	80.00
108	15	28	2025-03-12	Bankdrücken	3	5	80.00
109	15	29	2025-03-12	Bankdrücken	1	5	82.50
110	15	29	2025-03-12	Bankdrücken	2	5	82.50
111	15	29	2025-03-12	Bankdrücken	3	5	82.50
112	15	13	2025-03-12	Bizepcurl Oldschoolding	1	12	123.00
113	15	26	2025-03-12	Bankdrücken	1	12	123.00
114	15	26	2025-03-12	Bankdrücken	1	12	123.00
115	15	26	2025-03-12	Bankdrücken	1	12	123.00
116	15	26	2025-03-12	Bankdrücken	2	12	123.00
117	15	15	2025-03-12	Bankdrücken Eleiko	1	12	12.00
118	15	15	2025-03-12	Bankdrücken Eleiko	1	13	12.00
119	15	1	2025-03-12	High Row Isolateral	1	13	123.00
120	15	1	2025-03-12	High Row Isolateral	1	12	123.00
121	15	26	2025-03-12	Bankdrücken	1	7	80.00
122	15	26	2025-03-12	Bankdrücken	1	7	80.00
123	15	1	2025-03-12	High Row Isolateral	1	12	123.00
124	15	1	2025-03-12	High Row Isolateral	1	13	123.00
125	15	35	2025-03-12	Gerät 35	1	12	123.00
126	15	35	2025-03-12	Gerät 35	2	12	123.00
127	15	26	2025-03-12	Kniebeugen	1	12	12.00
128	15	4	2025-03-12	Front Row Isolateral	1	12	12.00
129	15	4	2025-03-13	Front Row Isolateral	1	12	12.00
130	1	1	2025-03-13	High Row Isolateral	1	12	1.00
131	1	1	2025-03-15	High Row Isolateral	1	12	123.00
132	15	11	2025-03-15	Chestpressmaschine Low	1	15	15.00
133	15	1	2025-03-15	High Row Isolateral	1	12	122.00
134	15	9	2025-03-15	Schulterdrücken maschine neben Seitheben	1	12	123.00
140	1	1	2025-03-24	Benchpress	2	166	73.00
141	15	2	2025-03-24	Squat	1	22	128.00
147	21	1	2025-03-24	Benchpress	1	5	90.00
148	21	1	2025-03-24	Benchpress	2	5	90.00
149	21	1	2025-03-24	Benchpress	3	5	90.00
150	21	1	2025-03-24	Benchpress	4	5	90.00
151	21	84	2025-03-25	84	1	10	40.00
152	21	84	2025-03-25	84	2	9	40.00
153	21	85	2025-03-25	85	1	10	20.00
154	21	97	2025-03-25	97	1	10	35.00
155	21	97	2025-03-25	97	2	10	35.00
156	21	97	2025-03-25	97	3	10	35.00
157	1	9	2025-03-25	Seated Calf Raise	1	1	50.00
158	15	9	2025-03-25	Seated Calf Raise	1	2	50.00
159	21	57	2025-03-26	Nautilus Lat Pulldown Isolateral	1	8	75.00
160	21	57	2025-03-26	Nautilus Lat Pulldown Isolateral	2	8	70.00
161	21	57	2025-03-26	Nautilus Lat Pulldown Isolateral	3	6	65.00
162	21	99	2025-03-26	99	1	10	50.00
163	21	99	2025-03-26	99	2	8	60.00
164	21	99	2025-03-26	99	3	8	70.00
165	21	52	2025-03-26	Cybex Row	1	10	10.00
166	21	52	2025-03-26	Cybex Row	2	10	9.00
167	21	52	2025-03-26	Cybex Row	3	10	9.00
168	21	79	2025-03-26	79	1	12	43.00
169	21	79	2025-03-26	79	2	12	57.00
170	21	79	2025-03-26	79	3	12	57.00
171	1	9	2025-03-26	Seated Calf Raise	1	2	50.00
\.


--
-- TOC entry 4966 (class 0 OID 16547)
-- Dependencies: 230
-- Data for Name: training_plan_exercises; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.training_plan_exercises (id, plan_id, device_id, exercise_order) FROM stdin;
\.


--
-- TOC entry 4964 (class 0 OID 16533)
-- Dependencies: 228
-- Data for Name: training_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.training_plans (id, user_id, name, created_at, status) FROM stdin;
2	15	PULL	2025-02-23 20:20:02.656314	aktiv
3	15	PUSH	2025-02-23 23:59:07.888223	aktiv
\.


--
-- TOC entry 4954 (class 0 OID 16390)
-- Dependencies: 218
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password, membership_number, current_streak, role, exp, exp_progress, division_index, coach_id) FROM stdin;
17	DerStreakTestende	Streaktest@dtm.de	$2a$10$imd6tV3cNBSL.JYaZ2NeLuGwAR4KUVpBLYKX8gPzDmAfQmogZsPkq	419	0	user	75	75	3	\N
2	asdasdasd	asdasda@gmail.com	$2a$10$IsjCK18gxByKFzVpwKeWb.oPDJUjE1G8m3S/Ra39Ju6sMV0KVhKUq	1102	0	user	0	0	0	\N
3	asdf	asdf@asdf.de	$2a$10$OQenyIDAmi08YuK86a.n9emYpo3dFI2UyfxfWNy49MCUgjXuJ4TWW	55	0	user	0	0	0	\N
4	hihi	hihi@web.de	$2a$10$ISjzdrIVMGlkmcpsQGyEKOhv5m55QFaBpG1m5DGFgzE43ld0tEUSy	1812	0	user	0	0	0	\N
5	Lucas	floethner@web.de	$2a$10$n8FDtXrOAbWp.5yNhwKOweFnfPI2VamKmY/mntfSZzHjhNlNvTQQu	33	0	user	0	0	0	\N
6	AlexanderBoss	alexander.messinger@gmx.de	$2a$10$K0F7z5MveVGSY6DnIVi4LuCveWsovKIWJcj8Rm5frzZoCadhJkYIC	3	0	user	0	0	0	\N
7	Justnasty	justnasty@gmx.de	$2a$10$KUl9yOYZPDU.S2CKLkQn6O.8dF7T2WevOWDFyJbor12PoSnwXNk4u	69	0	user	0	0	0	\N
8	Joshua Hillebrand	hillebrandjoshua@gmail.com	$2a$10$pWZNZdTwQEmJP2Uab85TpeNjbxfgbrNf.t.mgudt96E3xRSE.6Qsy	7	0	user	0	0	0	\N
9	Peter Pelzer	peterpelzers.mutter@gmail.com	$2a$10$WkrOqRtCtpXmiavIFtcDi.PhndqvSU/RnutJ7X3mmyAEltNHp8/Ma	666	0	user	0	0	0	\N
10	McTest	asd@asd.de	$2a$10$4SYAqmRbW5ILRMn.jtcL7eOU5Ra9zqABff0cc0xnANnD.sIbTKMDy	1997	0	user	0	0	0	\N
12	Leon Brüggemann	leon-brueggemann@gmx.de	$2a$10$YL.mcFx2NYuHllzl9p0xJub0f7Hyv.6sgWEjVRa8FqHWghCjaRxWi	420	1	user	0	0	0	\N
11	huansohn	huansohn@huansohn.huansohn	$2a$10$RdXPW/SsiNsTtIC/l2x0TuS3mfwglVuz2wzGLLU4ESZvSOdj42XMq	1500	1	user	0	0	0	\N
13	Testendertester	a@a	$2a$10$04VdcoDeDKCUb4yC49uMV.Y4Eeodc/Itk6q7zpfPGkUHShjDGXxX.	1283	0	user	0	0	0	\N
14	abc	aaa@aaa.aaa	$2a$10$67K6pV6ri19S3CoP5AquWuDFuG7ASURoGL3cxEu2POuYkoPqA/Tu6	1233	0	user	0	0	0	\N
16	Hurensohn069	dominik.misztal@web.de	$2a$10$k6OrWh3m7IH.Nt95tatEVOwSN5r3SC9HvGRBXumMJn40VFRW./0HS	1994	0	user	0	0	0	\N
18	Admin	admin@dtm.de	$2a$10$S0XLp4GG8EwkwmEbS3rR0.WGW2GGmA139owWREQGliQh7wvjhQ1..	3000	0	admin	0	0	0	\N
19	Daniel Misztal	dmisztal.1297@gmail.com	$2a$10$bXbAnHn3umcCvdhkoCSCJe.Ze874B2UVwDKk/X6oSfxXWXpj1wNay	2005	0	user	0	0	0	\N
15	TestenderTester	test@test.de	$2a$10$I8QocAu2yTh3z/YYZqPOn.kl0qVL7ON3gMujl3XJDOT3ouDjTj8i.	1992	0	coach	100	0	5	\N
1	wasgehtab1	testitesti@gmail.com	$2a$10$WCnqAbfp2fjCbYsu9jhaA.Qe4.dnKMZwcEfSuP3sMl12k7vIwHKZK	1	1	user	0	75	1	15
21	Ein Rebhuhn	dtm@gmail.com	$2a$10$z/7Y8nUgV69jzC80tIkWheLoAWn/uDVPVumL/9/CmmAoXOSPmmghi	243	3	user	0	25	0	\N
\.


--
-- TOC entry 4991 (class 0 OID 0)
-- Dependencies: 235
-- Name: affiliate_clicks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affiliate_clicks_id_seq', 9, true);


--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 233
-- Name: affiliate_offers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.affiliate_offers_id_seq', 1, false);


--
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 231
-- Name: coaching_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.coaching_requests_id_seq', 1, true);


--
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 237
-- Name: custom_exercises_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.custom_exercises_id_seq', 3, true);


--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 221
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.devices_id_seq', 152, true);


--
-- TOC entry 4996 (class 0 OID 0)
-- Dependencies: 223
-- Name: feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.feedback_id_seq', 1, false);


--
-- TOC entry 4997 (class 0 OID 0)
-- Dependencies: 225
-- Name: training_days_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.training_days_id_seq', 64, true);


--
-- TOC entry 4998 (class 0 OID 0)
-- Dependencies: 219
-- Name: training_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.training_history_id_seq', 171, true);


--
-- TOC entry 4999 (class 0 OID 0)
-- Dependencies: 229
-- Name: training_plan_exercises_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.training_plan_exercises_id_seq', 1, false);


--
-- TOC entry 5000 (class 0 OID 0)
-- Dependencies: 227
-- Name: training_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.training_plans_id_seq', 3, true);


--
-- TOC entry 5001 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 21, true);


--
-- TOC entry 4796 (class 2606 OID 24783)
-- Name: affiliate_clicks affiliate_clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affiliate_clicks
    ADD CONSTRAINT affiliate_clicks_pkey PRIMARY KEY (id);


--
-- TOC entry 4794 (class 2606 OID 24775)
-- Name: affiliate_offers affiliate_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affiliate_offers
    ADD CONSTRAINT affiliate_offers_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 24764)
-- Name: coaching_requests coaching_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.coaching_requests
    ADD CONSTRAINT coaching_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 4798 (class 2606 OID 24814)
-- Name: custom_exercises custom_exercises_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_exercises
    ADD CONSTRAINT custom_exercises_pkey PRIMARY KEY (id);


--
-- TOC entry 4780 (class 2606 OID 16446)
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- TOC entry 4782 (class 2606 OID 16458)
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- TOC entry 4784 (class 2606 OID 16490)
-- Name: training_days training_days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT training_days_pkey PRIMARY KEY (id);


--
-- TOC entry 4778 (class 2606 OID 16437)
-- Name: training_history training_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_history
    ADD CONSTRAINT training_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4790 (class 2606 OID 16552)
-- Name: training_plan_exercises training_plan_exercises_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT training_plan_exercises_pkey PRIMARY KEY (id);


--
-- TOC entry 4788 (class 2606 OID 16540)
-- Name: training_plans training_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plans
    ADD CONSTRAINT training_plans_pkey PRIMARY KEY (id);


--
-- TOC entry 4786 (class 2606 OID 16492)
-- Name: training_days unique_user_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT unique_user_date UNIQUE (user_id, training_date);


--
-- TOC entry 4774 (class 2606 OID 16397)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4776 (class 2606 OID 16395)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4805 (class 2606 OID 24784)
-- Name: affiliate_clicks affiliate_clicks_offer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.affiliate_clicks
    ADD CONSTRAINT affiliate_clicks_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.affiliate_offers(id) ON DELETE CASCADE;


--
-- TOC entry 4806 (class 2606 OID 24820)
-- Name: custom_exercises custom_exercises_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_exercises
    ADD CONSTRAINT custom_exercises_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- TOC entry 4807 (class 2606 OID 24815)
-- Name: custom_exercises custom_exercises_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_exercises
    ADD CONSTRAINT custom_exercises_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 4799 (class 2606 OID 16464)
-- Name: feedback fk_device; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT fk_device FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- TOC entry 4803 (class 2606 OID 16558)
-- Name: training_plan_exercises fk_device; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT fk_device FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- TOC entry 4804 (class 2606 OID 16553)
-- Name: training_plan_exercises fk_plan; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT fk_plan FOREIGN KEY (plan_id) REFERENCES public.training_plans(id) ON DELETE CASCADE;


--
-- TOC entry 4800 (class 2606 OID 16459)
-- Name: feedback fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 4802 (class 2606 OID 16541)
-- Name: training_plans fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_plans
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4801 (class 2606 OID 16493)
-- Name: training_days fk_user_training_days; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT fk_user_training_days FOREIGN KEY (user_id) REFERENCES public.users(id);


-- Completed on 2025-03-29 04:14:55

--
-- PostgreSQL database dump complete
--

