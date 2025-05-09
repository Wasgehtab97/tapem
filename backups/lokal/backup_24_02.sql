PGDMP                      }            gymapp    17.2    17.2 =    8           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            9           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            :           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            ;           1262    16388    gymapp    DATABASE     z   CREATE DATABASE gymapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'German_Germany.1252';
    DROP DATABASE gymapp;
                     postgres    false            �            1259    16439    devices    TABLE     r   CREATE TABLE public.devices (
    id integer NOT NULL,
    name text NOT NULL,
    exercise_mode text NOT NULL
);
    DROP TABLE public.devices;
       public         heap r       postgres    false            �            1259    16438    devices_id_seq    SEQUENCE     �   CREATE SEQUENCE public.devices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.devices_id_seq;
       public               postgres    false    222            <           0    0    devices_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;
          public               postgres    false    221            �            1259    16449    feedback    TABLE       CREATE TABLE public.feedback (
    id integer NOT NULL,
    user_id integer,
    device_id integer NOT NULL,
    feedback_text text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    status character varying(50) DEFAULT 'neu'::character varying
);
    DROP TABLE public.feedback;
       public         heap r       postgres    false            �            1259    16448    feedback_id_seq    SEQUENCE     �   CREATE SEQUENCE public.feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.feedback_id_seq;
       public               postgres    false    224            =           0    0    feedback_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.feedback_id_seq OWNED BY public.feedback.id;
          public               postgres    false    223            �            1259    16485    training_days    TABLE     ~   CREATE TABLE public.training_days (
    id integer NOT NULL,
    user_id integer NOT NULL,
    training_date date NOT NULL
);
 !   DROP TABLE public.training_days;
       public         heap r       postgres    false            �            1259    16484    training_days_id_seq    SEQUENCE     �   CREATE SEQUENCE public.training_days_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.training_days_id_seq;
       public               postgres    false    226            >           0    0    training_days_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.training_days_id_seq OWNED BY public.training_days.id;
          public               postgres    false    225            �            1259    16427    training_history    TABLE     �  CREATE TABLE public.training_history (
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
 $   DROP TABLE public.training_history;
       public         heap r       postgres    false            �            1259    16426    training_history_id_seq    SEQUENCE     �   CREATE SEQUENCE public.training_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.training_history_id_seq;
       public               postgres    false    220            ?           0    0    training_history_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.training_history_id_seq OWNED BY public.training_history.id;
          public               postgres    false    219            �            1259    16547    training_plan_exercises    TABLE     �   CREATE TABLE public.training_plan_exercises (
    id integer NOT NULL,
    plan_id integer NOT NULL,
    device_id integer NOT NULL,
    exercise_order integer NOT NULL
);
 +   DROP TABLE public.training_plan_exercises;
       public         heap r       postgres    false            �            1259    16546    training_plan_exercises_id_seq    SEQUENCE     �   CREATE SEQUENCE public.training_plan_exercises_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.training_plan_exercises_id_seq;
       public               postgres    false    230            @           0    0    training_plan_exercises_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.training_plan_exercises_id_seq OWNED BY public.training_plan_exercises.id;
          public               postgres    false    229            �            1259    16533    training_plans    TABLE       CREATE TABLE public.training_plans (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'inaktiv'::character varying
);
 "   DROP TABLE public.training_plans;
       public         heap r       postgres    false            �            1259    16532    training_plans_id_seq    SEQUENCE     �   CREATE SEQUENCE public.training_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.training_plans_id_seq;
       public               postgres    false    228            A           0    0    training_plans_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.training_plans_id_seq OWNED BY public.training_plans.id;
          public               postgres    false    227            �            1259    16390    users    TABLE     �  CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(100),
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    membership_number integer,
    current_streak integer DEFAULT 0,
    role character varying(50) DEFAULT 'user'::character varying,
    CONSTRAINT users_membership_number_check CHECK (((membership_number >= 1) AND (membership_number <= 3000)))
);
    DROP TABLE public.users;
       public         heap r       postgres    false            �            1259    16389    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public               postgres    false    218            B           0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public               postgres    false    217            r           2604    16442 
   devices id    DEFAULT     h   ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);
 9   ALTER TABLE public.devices ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    222    221    222            s           2604    16452    feedback id    DEFAULT     j   ALTER TABLE ONLY public.feedback ALTER COLUMN id SET DEFAULT nextval('public.feedback_id_seq'::regclass);
 :   ALTER TABLE public.feedback ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    224    223    224            v           2604    16488    training_days id    DEFAULT     t   ALTER TABLE ONLY public.training_days ALTER COLUMN id SET DEFAULT nextval('public.training_days_id_seq'::regclass);
 ?   ALTER TABLE public.training_days ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    225    226    226            q           2604    16430    training_history id    DEFAULT     z   ALTER TABLE ONLY public.training_history ALTER COLUMN id SET DEFAULT nextval('public.training_history_id_seq'::regclass);
 B   ALTER TABLE public.training_history ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    219    220    220            z           2604    16550    training_plan_exercises id    DEFAULT     �   ALTER TABLE ONLY public.training_plan_exercises ALTER COLUMN id SET DEFAULT nextval('public.training_plan_exercises_id_seq'::regclass);
 I   ALTER TABLE public.training_plan_exercises ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    229    230    230            w           2604    16536    training_plans id    DEFAULT     v   ALTER TABLE ONLY public.training_plans ALTER COLUMN id SET DEFAULT nextval('public.training_plans_id_seq'::regclass);
 @   ALTER TABLE public.training_plans ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    227    228    228            n           2604    16393    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    217    218    218            -          0    16439    devices 
   TABLE DATA           :   COPY public.devices (id, name, exercise_mode) FROM stdin;
    public               postgres    false    222   �I       /          0    16449    feedback 
   TABLE DATA           ]   COPY public.feedback (id, user_id, device_id, feedback_text, created_at, status) FROM stdin;
    public               postgres    false    224   �K       1          0    16485    training_days 
   TABLE DATA           C   COPY public.training_days (id, user_id, training_date) FROM stdin;
    public               postgres    false    226   KL       +          0    16427    training_history 
   TABLE DATA           o   COPY public.training_history (id, user_id, device_id, training_date, exercise, sets, reps, weight) FROM stdin;
    public               postgres    false    220   �L       5          0    16547    training_plan_exercises 
   TABLE DATA           Y   COPY public.training_plan_exercises (id, plan_id, device_id, exercise_order) FROM stdin;
    public               postgres    false    230   �N       3          0    16533    training_plans 
   TABLE DATA           O   COPY public.training_plans (id, user_id, name, created_at, status) FROM stdin;
    public               postgres    false    228   ;O       )          0    16390    users 
   TABLE DATA           c   COPY public.users (id, name, email, password, membership_number, current_streak, role) FROM stdin;
    public               postgres    false    218   �O       C           0    0    devices_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.devices_id_seq', 30, true);
          public               postgres    false    221            D           0    0    feedback_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.feedback_id_seq', 3, true);
          public               postgres    false    223            E           0    0    training_days_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.training_days_id_seq', 26, true);
          public               postgres    false    225            F           0    0    training_history_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.training_history_id_seq', 69, true);
          public               postgres    false    219            G           0    0    training_plan_exercises_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.training_plan_exercises_id_seq', 28, true);
          public               postgres    false    229            H           0    0    training_plans_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.training_plans_id_seq', 3, true);
          public               postgres    false    227            I           0    0    users_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.users_id_seq', 19, true);
          public               postgres    false    217            �           2606    16446    devices devices_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.devices DROP CONSTRAINT devices_pkey;
       public                 postgres    false    222            �           2606    16458    feedback feedback_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.feedback DROP CONSTRAINT feedback_pkey;
       public                 postgres    false    224            �           2606    16490     training_days training_days_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT training_days_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.training_days DROP CONSTRAINT training_days_pkey;
       public                 postgres    false    226            �           2606    16437 &   training_history training_history_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.training_history
    ADD CONSTRAINT training_history_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.training_history DROP CONSTRAINT training_history_pkey;
       public                 postgres    false    220            �           2606    16552 4   training_plan_exercises training_plan_exercises_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT training_plan_exercises_pkey PRIMARY KEY (id);
 ^   ALTER TABLE ONLY public.training_plan_exercises DROP CONSTRAINT training_plan_exercises_pkey;
       public                 postgres    false    230            �           2606    16540 "   training_plans training_plans_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.training_plans
    ADD CONSTRAINT training_plans_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.training_plans DROP CONSTRAINT training_plans_pkey;
       public                 postgres    false    228            �           2606    16492    training_days unique_user_date 
   CONSTRAINT     k   ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT unique_user_date UNIQUE (user_id, training_date);
 H   ALTER TABLE ONLY public.training_days DROP CONSTRAINT unique_user_date;
       public                 postgres    false    226    226            �           2606    16397    users users_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_key;
       public                 postgres    false    218            �           2606    16395    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public                 postgres    false    218            �           2606    16464    feedback fk_device    FK CONSTRAINT     u   ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT fk_device FOREIGN KEY (device_id) REFERENCES public.devices(id);
 <   ALTER TABLE ONLY public.feedback DROP CONSTRAINT fk_device;
       public               postgres    false    4742    222    224            �           2606    16558 !   training_plan_exercises fk_device    FK CONSTRAINT     �   ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT fk_device FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.training_plan_exercises DROP CONSTRAINT fk_device;
       public               postgres    false    222    4742    230            �           2606    16553    training_plan_exercises fk_plan    FK CONSTRAINT     �   ALTER TABLE ONLY public.training_plan_exercises
    ADD CONSTRAINT fk_plan FOREIGN KEY (plan_id) REFERENCES public.training_plans(id) ON DELETE CASCADE;
 I   ALTER TABLE ONLY public.training_plan_exercises DROP CONSTRAINT fk_plan;
       public               postgres    false    228    4750    230            �           2606    16459    feedback fk_user    FK CONSTRAINT     o   ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id);
 :   ALTER TABLE ONLY public.feedback DROP CONSTRAINT fk_user;
       public               postgres    false    218    4738    224            �           2606    16541    training_plans fk_user    FK CONSTRAINT     �   ALTER TABLE ONLY public.training_plans
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
 @   ALTER TABLE ONLY public.training_plans DROP CONSTRAINT fk_user;
       public               postgres    false    228    4738    218            �           2606    16493 #   training_days fk_user_training_days    FK CONSTRAINT     �   ALTER TABLE ONLY public.training_days
    ADD CONSTRAINT fk_user_training_days FOREIGN KEY (user_id) REFERENCES public.users(id);
 M   ALTER TABLE ONLY public.training_days DROP CONSTRAINT fk_user_training_days;
       public               postgres    false    226    4738    218            -   �  x�u�An�0��5}
] Ed����E�M�"βY",�2eP2�<=Fw�Xi'�m�͎x��T>7�]|�=d���>lZ7�d�1�ގY�YN��Mɦd�̒	��)��d�����O�tv�bI�K�&�H-�4���,"��"��,"��"��,"�(��O���X,��$���!8���Cp�!8���Cp��8��P�Cq(š8��P�Cq(š8��P�Gao�e̎��=O�ܗC��жuw�׾k��Ų�_W=tǌ/g�b�s��
5ߺ���eK��>��wYpk�/~����OnN�;}f��P��+S+��뷄�Y9?4���/ũz�'�haVU��0����ڦ�7�i��n����]��ُ�N����<E��ظ~8+�xE��-}�P5��^7>m�v�����f�ܾ:���m������,˰���u~�1˫�yu9�.����0�L�Q��#      /   �   x�]���0��sR�6 ��	 9ӁW/V���Кؘ�A���H)RM{�f�zm�n�&��k����GY#r�5`혜�j��(Y�tC�4�{V�6�	zy�c����n��*��(*__6X��U�8/�$*��qn��?��\k��>5<      1   N   x�U���0�f��R;�/���x�G�D#MS>�'�qU~�^9�Q9�:@P�H����c��PO��y�&���q!�      +   7  x����n�0 ��y�)J�u�����.�lE��
�����FQ�-���C���hJ�~�s��@O��h>�o_w�)g���t�B]ᢼ(�c�/VƋ�-�[�8�h�4+�T⤁K:���:C���$��Oí$�h*:ÊI�� �0zB���4QAWySI���$���u��0같p+Pm���9�A�@wX;��C�M��N$�o���YR����o�q 4lѶ@q�bC�;a����cf��(�c�e�mM~��Y#HR��ʽ5ȃ�����ʣ�{
��fr��<8�T,�+���N��-�t�-�t�s��:�:6�=�M-AMm�6{�3����|�%�
���w�{b%]��]T��.y���w�/�y�r�Y�A�8d�_3�U5#��^���j�QV�jFAWK�(fu�fIguͤՍ ﮎ�Â�a�ă[-I0����}���}�}9^��ù>�<U�zw����"��Q�(�F\B�Nbs	��%�k0���b2/�׷�OǗ�����t)�I�[z,����5U"��a�?>H�      5   ;   x�ʱ  ������s����%�0��D��Դ�*��[V����F���
      3   M   x�3�44���4202�50�52V02�2��20׳��022�L�.�,�2�(��AQj`DFzf�fƆ&P�1z\\\ cP!      )      x�e�˒�����Oу5�%wa����4����^�\D}�=;/v�{����Y��Y%4�Q�EZܴ�g��Jr��b�/���(�Y�	S�;6���H�[���0V���B�۰�*��l|��3�d P�kp�� �_�g�7cޤ�A��ur3�w���x�ܨ�C�ѺHXk�C���feS��3�i�yb؇x�>�)����6We�P�3D�B��X�l0�3�[x��I+��n����x�)́8�����c���J�A=�Wz��j��M3��'<���I�ӄW�it�86�V;X7@��k�<Xv>j@����\� �Tm�z-{N���ƺ��"���G�hC�t�������v��}�@���'e� �\A��&)����7�AM�w~u��n���	��v��b̝���;��T*(��q��p]��io }f?�\�����z���l[k(��q�e�����+k�ٔVѻf�u@��,�&���,�s��CA��<��������y
��V#�s@���+l��5���aI��$h�ugiP�670~B%��-��78��T�E��7�tm��ȟW'���]���Kt�O[_M�&.���:�vE�.�.K�M��֜U�h�� O(M�������_�"g�3�y?_�VL[9���C��,O�}�Z�f��f�퍕:�O�^%6\�x����/�0AE���?^���~�q	�?�2汛��=�*��<*�n(4�������̉b%E��� �����Ť�p:ES��+�x&���7n�gd5���۹2ʙ+��,��}��ݝ���ry�4�t��A�1�j�<��ǂG����7�@O}���T�j(��)�ԭlx�4\�h�f�y|��fV���{u!���w���B�*Bp�?���!T�P'�d�J���s�t��ǲuؕ����Z�l��1+7gy��A����?{���Q��#|�B��厹�c�>:O�ͺ�YN���xm�ѪKs�]��=[vj�O�>��B� f]�?[O�,(IR$$IsoQ�c&eºvb���3h�ߢV�׽e�5k)���&nGV�����΁#jf=x܋7*����({V���-��KH �6�k	GtbL���^�q���&ˣ���9ܒ2:5��8�5/h��P@��Cݢ�e�麨�YO4�b��at��4+���Ӷz�l�qI�-!`��bԗ��@RQ���}��0���i��\�\O.f�_�qV*������17av���J+���[�to�`(��M������uH     