-- ---------------------------------------------------
-- FUNCTION CREATION
-- ---------------------------------------------------

-- Contagem exata (não estimada) de cada tabela tb_*. Usada para comparar o banco
-- de origem com o restaurado. ONLY evita que tb_log_base some as linhas das filhas.
CREATE OR REPLACE FUNCTION fn_table_row_counts()
RETURNS TABLE (
    table_name TEXT,
    row_count BIGINT
)
LANGUAGE plpgsql
STABLE
AS
$$
DECLARE
    v_table RECORD;
BEGIN

    FOR v_table IN
        SELECT c.relname
        FROM pg_class c
        WHERE c.relnamespace = current_schema()::regnamespace
          AND c.relkind IN ('r', 'p')
          AND c.relname LIKE 'tb\_%'
        ORDER BY c.relname
    LOOP
        table_name := v_table.relname;
        EXECUTE format('SELECT COUNT(*) FROM ONLY %I', v_table.relname)
        INTO row_count;
        RETURN NEXT;
    END LOOP;

END;
$$;
