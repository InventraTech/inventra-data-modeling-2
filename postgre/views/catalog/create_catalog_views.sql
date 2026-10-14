-- ---------------------------------------------------
-- VIEWS
-- ---------------------------------------------------

-- Uma linha por coluna: metadado de negócio do catálogo + metadado técnico do pg_catalog.
CREATE OR REPLACE VIEW vw_data_catalog AS
SELECT
    t.table_name,
    t.domain,
    t.description AS table_description,
    a.attnum AS column_position,
    cc.column_name,
    format_type(a.atttypid, a.atttypmod) AS data_type,
    CASE WHEN a.attnum IS NOT NULL THEN NOT a.attnotnull END AS is_nullable,
    EXISTS (
        SELECT 1 FROM pg_constraint pk
        WHERE pk.conrelid = a.attrelid
          AND pk.contype = 'p'
          AND a.attnum = ANY (pk.conkey)
    ) AS is_primary_key,
    (
        SELECT string_agg(fk.confrelid::regclass::text || '.' || ra.attname, ', ')
        FROM pg_constraint fk
        JOIN pg_attribute ra
          ON ra.attrelid = fk.confrelid
         AND ra.attnum = fk.confkey[array_position(fk.conkey, a.attnum)]
        WHERE fk.conrelid = a.attrelid
          AND fk.contype = 'f'
          AND a.attnum = ANY (fk.conkey)
    ) AS references_to,
    cc.description AS column_description,
    cc.business_rule,
    COALESCE(cl.code, tl.code) AS access_level,
    COALESCE(cl.level_rank, tl.level_rank) AS access_level_rank,
    (cc.id_access_level IS NULL) AS inherits_table_access,
    cc.is_personal_data,
    (cc.description IS NOT NULL) AS is_documented,
    (a.attnum IS NOT NULL) AS exists_in_schema
FROM tb_catalog_column cc
JOIN tb_catalog_table t ON t.id_catalog_table = cc.id_catalog_table
JOIN tb_catalog_access_level tl ON tl.id_access_level = t.id_access_level
LEFT JOIN tb_catalog_access_level cl ON cl.id_access_level = cc.id_access_level
LEFT JOIN pg_attribute a
       ON a.attrelid = to_regclass(t.table_name)
      AND a.attname = cc.column_name
      AND a.attnum > 0
      AND NOT a.attisdropped;

-- Uma linha por tabela: documentação, cobertura, dado pessoal e volume estimado.
CREATE OR REPLACE VIEW vw_data_catalog_table AS
SELECT
    t.table_name,
    t.domain,
    t.description,
    t.business_rules,
    al.code AS access_level,
    al.audience,
    t.data_owner,
    parent.relname::text AS inherits_from,
    GREATEST(c.reltuples, 0)::BIGINT AS estimated_rows,
    COUNT(cc.id_catalog_column) AS column_count,
    COUNT(cc.description) AS documented_column_count,
    ROUND(100.0 * COUNT(cc.description) / NULLIF(COUNT(cc.id_catalog_column), 0), 1) AS documentation_pct,
    COALESCE(BOOL_OR(cc.is_personal_data), false) AS contains_personal_data,
    (t.description IS NOT NULL) AS is_documented,
    (c.oid IS NOT NULL) AS exists_in_schema,
    t.updated_at
FROM tb_catalog_table t
JOIN tb_catalog_access_level al ON al.id_access_level = t.id_access_level
LEFT JOIN pg_class c ON c.oid = to_regclass(t.table_name)
LEFT JOIN pg_inherits i ON i.inhrelid = c.oid
LEFT JOIN pg_class parent ON parent.oid = i.inhparent
LEFT JOIN tb_catalog_column cc ON cc.id_catalog_table = t.id_catalog_table
GROUP BY t.id_catalog_table, al.id_access_level, c.oid, c.reltuples, parent.relname;
