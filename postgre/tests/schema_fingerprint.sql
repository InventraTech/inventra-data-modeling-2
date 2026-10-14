-- "Impressão digital" do schema atual: uma linha por objeto, ordenada, sem depender da ordem
-- física das colunas (ALTER TABLE ADD COLUMN põe a coluna no fim; o CREATE TABLE do dicionário,
-- no meio). Usada por check_dictionary_sync.sh para comparar dois bancos.
-- Rotinas aparecem como md5 do corpo: o diff aponta qual mudou; o detalhe se vê no arquivo.

WITH objects AS (

    SELECT format('column     %s.%s %s%s%s%s',
               c.relname, a.attname, format_type(a.atttypid, a.atttypmod),
               CASE WHEN a.attnotnull THEN ' NOT NULL' ELSE '' END,
               CASE a.attidentity WHEN 'd' THEN ' IDENTITY BY DEFAULT' WHEN 'a' THEN ' IDENTITY ALWAYS' ELSE '' END,
               COALESCE(' DEFAULT ' || pg_get_expr(d.adbin, d.adrelid), '')) AS line
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE c.relnamespace = current_schema()::regnamespace
      AND c.relkind IN ('r', 'p', 'v')
      AND a.attnum > 0
      AND NOT a.attisdropped

    UNION ALL
    SELECT format('constraint %s.%s %s', c.relname, con.conname, pg_get_constraintdef(con.oid))
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    WHERE c.relnamespace = current_schema()::regnamespace

    UNION ALL
    SELECT format('index      %s', indexdef)
    FROM pg_indexes
    WHERE schemaname = current_schema()

    UNION ALL
    SELECT format('view       %s %s', viewname, md5(definition))
    FROM pg_views
    WHERE schemaname = current_schema()

    UNION ALL
    SELECT format('routine    %s %s', p.oid::regprocedure, md5(pg_get_functiondef(p.oid)))
    FROM pg_proc p
    WHERE p.pronamespace = current_schema()::regnamespace

    UNION ALL
    SELECT format('trigger    %s', pg_get_triggerdef(t.oid))
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    WHERE c.relnamespace = current_schema()::regnamespace
      AND NOT t.tgisinternal

    UNION ALL
    SELECT format('inherits   %s -> %s', child.relname, parent.relname)
    FROM pg_inherits i
    JOIN pg_class child ON child.oid = i.inhrelid
    JOIN pg_class parent ON parent.oid = i.inhparent
    WHERE child.relnamespace = current_schema()::regnamespace

    UNION ALL
    SELECT format('sequence   %s', c.relname)
    FROM pg_class c
    WHERE c.relnamespace = current_schema()::regnamespace
      AND c.relkind = 'S'

    -- conteúdo do catálogo de dados: dicionário e migrations precisam documentar o mesmo
    UNION ALL
    SELECT format('catalog    %s.%s %s', table_name, column_name,
               md5(concat_ws('|', domain, table_description, column_description, business_rule, access_level, is_personal_data)))
    FROM vw_data_catalog

)
SELECT line
FROM objects
ORDER BY line;
