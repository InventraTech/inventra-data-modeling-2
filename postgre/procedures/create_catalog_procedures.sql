-- ---------------------------------------------------
-- PROCEDURE CREATION
-- ---------------------------------------------------

-- Inclui no catálogo, sem descrição, toda tabela tb_* e coluna própria que ainda
-- não estiver lá (colunas herdadas ficam documentadas só na tabela-mãe).
-- Com p_prune = true remove do catálogo o que não existe mais no schema.
CREATE OR REPLACE PROCEDURE sp_sync_data_catalog(
    p_prune BOOLEAN DEFAULT false
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_default_level INTEGER;
    v_new_tables INTEGER;
    v_new_columns INTEGER;
    v_orphan_tables INTEGER;
    v_orphan_columns INTEGER;
    v_undocumented INTEGER;
BEGIN

    SELECT id_access_level
    INTO v_default_level
    FROM tb_catalog_access_level
    WHERE code = 'INTERNAL';

    IF v_default_level IS NULL THEN
        RAISE EXCEPTION
            'Nível de acesso INTERNAL não cadastrado no catálogo de dados.';
    END IF;

    INSERT INTO tb_catalog_table (table_name, id_access_level)
    SELECT c.relname, v_default_level
    FROM pg_class c
    WHERE c.relnamespace = current_schema()::regnamespace
      AND c.relkind IN ('r', 'p')
      AND c.relname LIKE 'tb\_%'
    ON CONFLICT (table_name) DO NOTHING;

    GET DIAGNOSTICS v_new_tables = ROW_COUNT;

    INSERT INTO tb_catalog_column (id_catalog_table, column_name)
    SELECT t.id_catalog_table, a.attname
    FROM tb_catalog_table t
    JOIN pg_class c
      ON c.relname = t.table_name
     AND c.relnamespace = current_schema()::regnamespace
    JOIN pg_attribute a
      ON a.attrelid = c.oid
     AND a.attnum > 0
     AND NOT a.attisdropped
     AND a.attislocal
    ON CONFLICT (id_catalog_table, column_name) DO NOTHING;

    GET DIAGNOSTICS v_new_columns = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_orphan_tables
    FROM tb_catalog_table t
    WHERE to_regclass(t.table_name) IS NULL;

    SELECT COUNT(*)
    INTO v_orphan_columns
    FROM tb_catalog_column cc
    JOIN tb_catalog_table t ON t.id_catalog_table = cc.id_catalog_table
    WHERE to_regclass(t.table_name) IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM pg_attribute a
          WHERE a.attrelid = to_regclass(t.table_name)
            AND a.attname = cc.column_name
            AND a.attnum > 0
            AND NOT a.attisdropped
      );

    IF p_prune THEN

        DELETE FROM tb_catalog_column cc
        USING tb_catalog_table t
        WHERE t.id_catalog_table = cc.id_catalog_table
          AND to_regclass(t.table_name) IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM pg_attribute a
              WHERE a.attrelid = to_regclass(t.table_name)
                AND a.attname = cc.column_name
                AND a.attnum > 0
                AND NOT a.attisdropped
          );

        DELETE FROM tb_catalog_table t
        WHERE to_regclass(t.table_name) IS NULL;

    END IF;

    SELECT COUNT(*)
    INTO v_undocumented
    FROM tb_catalog_column
    WHERE description IS NULL;

    RAISE NOTICE
        'Catálogo sincronizado: % tabela(s) e % coluna(s) novas; % tabela(s) e % coluna(s) fora do schema (%); % coluna(s) sem descrição.',
        v_new_tables, v_new_columns, v_orphan_tables, v_orphan_columns,
        CASE WHEN p_prune THEN 'removidas' ELSE 'mantidas' END,
        v_undocumented;

END;
$$;
