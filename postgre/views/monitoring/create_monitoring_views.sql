-- ---------------------------------------------------
-- VIEWS
-- ---------------------------------------------------

-- DAU (Daily Active Users): usuários distintos por dia, do primeiro dia registrado até hoje.
-- Dia sem acesso aparece com 0, para a média móvel e a variação não pularem dias.
-- MAU = usuários distintos nos 30 dias que terminam no dia; stickiness = DAU / MAU.
-- O MAU sai numa passada só pela tabela: cada acesso "cobre" o usuário do dia dele até
-- o próximo acesso (LEAD) ou por 30 dias, o que vier antes. As coberturas de um usuário
-- não se sobrepõem, então somar +1 no início e -1 no fim e acumular por dia
-- (SUM() OVER) dá exatamente o COUNT(DISTINCT) da janela de 30 dias.
CREATE OR REPLACE VIEW vw_dau AS
WITH bounds AS (
    SELECT
        MIN(access_date) AS first_day,
        GREATEST(MAX(access_date), CURRENT_DATE) AS last_day
    FROM tb_user_daily_access
),
days AS (
    SELECT generate_series(b.first_day, b.last_day, INTERVAL '1 day')::date AS access_date
    FROM bounds b
    WHERE b.first_day IS NOT NULL
),
daily AS (
    SELECT
        access_date,
        COUNT(*) AS dau,
        SUM(access_count) AS total_accesses
    FROM tb_user_daily_access
    GROUP BY access_date
),
mau_coverage AS (
    SELECT
        access_date AS covered_from,
        LEAST(
            LEAD(access_date) OVER (PARTITION BY id_user ORDER BY access_date),
            access_date + 30
        ) AS covered_until
    FROM tb_user_daily_access
),
mau_delta AS (
    SELECT
        change_date,
        SUM(delta) AS delta
    FROM (
        SELECT covered_from AS change_date, 1 AS delta FROM mau_coverage
        UNION ALL
        SELECT covered_until, -1 FROM mau_coverage
    ) AS changes
    GROUP BY change_date
),
series AS (
    SELECT
        d.access_date,
        COALESCE(dl.dau, 0) AS dau,
        COALESCE(dl.total_accesses, 0) AS total_accesses,
        SUM(COALESCE(md.delta, 0)) OVER (ORDER BY d.access_date)::BIGINT AS mau_30d
    FROM days d
    LEFT JOIN daily dl ON dl.access_date = d.access_date
    LEFT JOIN mau_delta md ON md.change_date = d.access_date
)
SELECT
    s.access_date,
    EXTRACT(ISODOW FROM s.access_date)::INTEGER AS iso_weekday,
    s.dau,
    s.total_accesses,
    s.dau - LAG(s.dau) OVER (ORDER BY s.access_date) AS dau_change_vs_previous_day,
    ROUND(AVG(s.dau) OVER (ORDER BY s.access_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS dau_moving_avg_7d,
    s.mau_30d,
    ROUND(100.0 * s.dau / NULLIF(s.mau_30d, 0), 1) AS stickiness_pct
FROM series s;

-- DAU por cozinha, com adoção (DAU / usuários ativos da cozinha) e ranking do dia.
-- A cozinha é a atual do usuário; usuário sem cozinha entra só em vw_dau.
CREATE OR REPLACE VIEW vw_dau_by_kitchen AS
WITH kitchen_users AS (
    SELECT
        id_kitchen,
        COUNT(*) FILTER (WHERE active) AS active_users
    FROM tb_user
    WHERE id_kitchen IS NOT NULL
    GROUP BY id_kitchen
),
daily AS (
    SELECT
        a.access_date,
        u.id_kitchen,
        COUNT(*) AS dau,
        SUM(a.access_count) AS total_accesses
    FROM tb_user_daily_access a
    JOIN tb_user u ON u.id_user = a.id_user
    WHERE u.id_kitchen IS NOT NULL
    GROUP BY a.access_date, u.id_kitchen
)
SELECT
    d.access_date,
    d.id_kitchen,
    k.name AS kitchen_name,
    d.dau,
    d.total_accesses,
    ku.active_users,
    ROUND(100.0 * d.dau / NULLIF(ku.active_users, 0), 1) AS adoption_pct,
    RANK() OVER (PARTITION BY d.access_date ORDER BY d.dau DESC) AS kitchen_rank_in_day
FROM daily d
JOIN tb_kitchen k ON k.id_kitchen = d.id_kitchen
LEFT JOIN kitchen_users ku ON ku.id_kitchen = d.id_kitchen;

-- ---------------------------------------------------
-- UI CLICK VIEWS
-- ---------------------------------------------------

-- Transforma as colunas do contador (uma linha só) em uma linha por elemento clicável.
-- Coluna nova no contador aparece aqui sozinha. platform e type_code saem do nome da coluna
-- (tipo_plataforma_tela_nome); a descrição vem do catálogo de dados. Elemento com 0 cliques
-- aparece com 0 (botão morto). share_pct e rank_in_platform comparam dentro da mesma plataforma.
CREATE OR REPLACE VIEW vw_ui_click_ranking AS
WITH counters AS (
    SELECT
        j.key AS column_name,
        j.value::BIGINT AS clicks
    FROM tb_ui_click_counter c
    CROSS JOIN LATERAL jsonb_each_text(to_jsonb(c) - 'id_counter') AS j
),
base AS (
    SELECT
        c.column_name,
        CASE split_part(c.column_name, '_', 2)
            WHEN 'wb' THEN 'WEB'
            WHEN 'mb' THEN 'MOBILE'
        END AS platform,
        split_part(c.column_name, '_', 1) AS type_code,
        cc.description,
        c.clicks
    FROM counters c
    LEFT JOIN tb_catalog_table t ON t.table_name = 'tb_ui_click_counter'
    LEFT JOIN tb_catalog_column cc ON cc.id_catalog_table = t.id_catalog_table AND cc.column_name = c.column_name
)
SELECT
    b.column_name,
    b.platform,
    b.type_code,
    b.description,
    b.clicks,
    ROUND(100.0 * b.clicks / NULLIF(SUM(b.clicks) OVER (PARTITION BY b.platform), 0), 1) AS share_pct,
    RANK() OVER (PARTITION BY b.platform ORDER BY b.clicks DESC) AS rank_in_platform
FROM base b;
