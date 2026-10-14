-- ---------------------------------------------------
-- PROCEDURE CREATION
-- ---------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_register_backup(
    p_operation VARCHAR(20),
    p_status VARCHAR(10),
    p_file_name VARCHAR(255),
    p_started_at TIMESTAMPTZ,
    p_finished_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    p_file_size_bytes BIGINT DEFAULT NULL,
    p_checksum_sha256 VARCHAR(64) DEFAULT NULL,
    p_error_message VARCHAR DEFAULT NULL,
    p_database_name VARCHAR(63) DEFAULT NULL
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF p_status = 'FAILED' AND NULLIF(TRIM(p_error_message), '') IS NULL THEN
        RAISE EXCEPTION
            'Execução com falha precisa da mensagem de erro.';
    END IF;

    INSERT INTO tb_backup_history
    (
        operation,
        status,
        database_name,
        file_name,
        file_size_bytes,
        checksum_sha256,
        started_at,
        finished_at,
        error_message
    )
    VALUES
    (
        p_operation,
        p_status,
        COALESCE(p_database_name, current_database()),
        p_file_name,
        p_file_size_bytes,
        LOWER(p_checksum_sha256),
        p_started_at,
        p_finished_at,
        CASE WHEN p_status = 'FAILED' THEN LEFT(p_error_message, 1000) END
    );

END;
$$;

-- Desfaz uma operação auditada usando a linha de tb_log_* indicada:
--   DELETE -> reinsere a linha com os dados de previous_data
--   UPDATE -> volta a linha para previous_data
--   INSERT -> apaga a linha inserida
-- A própria recuperação passa pelas triggers, então também fica auditada.
CREATE OR REPLACE PROCEDURE sp_restore_from_audit(
    p_id_log INTEGER
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_log_table TEXT;
    v_target_table TEXT;
    v_target REGCLASS;
    v_operation VARCHAR(10);
    v_previous_data JSONB;
    v_new_data JSONB;
    v_pk_column TEXT;
    v_pk_value TEXT;
    v_columns TEXT;
    v_exists BOOLEAN;
    v_rows INTEGER;
BEGIN

    SELECT l.tableoid::regclass::text, l.operation, l.previous_data, l.new_data
    INTO v_log_table, v_operation, v_previous_data, v_new_data
    FROM tb_log_base l
    WHERE l.id_log = p_id_log;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Registro de auditoria % não encontrado.',
            p_id_log;
    END IF;

    -- tb_log_<entidade> audita tb_<entidade>
    v_target_table := 'tb_' || substr(v_log_table, length('tb_log_') + 1);
    v_target := to_regclass(v_target_table);

    IF v_target IS NULL THEN
        RAISE EXCEPTION
            'Tabela auditada % não existe mais.',
            v_target_table;
    END IF;

    SELECT a.attname
    INTO v_pk_column
    FROM pg_constraint c
    JOIN pg_attribute a
      ON a.attrelid = c.conrelid
     AND a.attnum = c.conkey[1]
    WHERE c.conrelid = v_target
      AND c.contype = 'p'
      AND array_length(c.conkey, 1) = 1;

    IF v_pk_column IS NULL THEN
        RAISE EXCEPTION
            'Tabela % não tem chave primária simples.',
            v_target_table;
    END IF;

    v_pk_value := COALESCE(v_previous_data, v_new_data) ->> v_pk_column;

    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s WHERE %I::text = $1)', v_target, v_pk_column)
    INTO v_exists
    USING v_pk_value;

    -- só as colunas que existem hoje e estão no JSON: coluna nova fica com o default
    SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum)
    INTO v_columns
    FROM pg_attribute a
    WHERE a.attrelid = v_target
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attgenerated = ''
      AND (v_operation = 'DELETE' OR a.attname <> v_pk_column)
      AND COALESCE(v_previous_data, '{}'::jsonb) ? a.attname;

    IF v_operation = 'DELETE' THEN

        IF v_exists THEN
            RAISE EXCEPTION
                'A linha %=% de % já existe; não há o que restaurar.',
                v_pk_column, v_pk_value, v_target_table;
        END IF;

        EXECUTE format(
            'INSERT INTO %s (%s) SELECT %s FROM jsonb_populate_record(NULL::%s, $1)',
            v_target, v_columns, v_columns, v_target
        )
        USING v_previous_data;

    ELSIF v_operation = 'UPDATE' THEN

        IF NOT v_exists THEN
            RAISE EXCEPTION
                'A linha %=% de % não existe mais; restaure primeiro o DELETE dela.',
                v_pk_column, v_pk_value, v_target_table;
        END IF;

        EXECUTE format(
            'UPDATE %s SET (%s) = (SELECT %s FROM jsonb_populate_record(NULL::%s, $1)) WHERE %I::text = $2',
            v_target, v_columns, v_columns, v_target, v_pk_column
        )
        USING v_previous_data, v_pk_value;

    ELSIF v_operation = 'INSERT' THEN

        IF NOT v_exists THEN
            RAISE EXCEPTION
                'A linha %=% de % já não existe; não há o que desfazer.',
                v_pk_column, v_pk_value, v_target_table;
        END IF;

        EXECUTE format('DELETE FROM %s WHERE %I::text = $1', v_target, v_pk_column)
        USING v_pk_value;

    ELSE
        RAISE EXCEPTION
            'Operação de auditoria % não suportada.',
            v_operation;
    END IF;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RAISE NOTICE
        'Log %: % desfeito em % (%=%), % linha(s).',
        p_id_log, v_operation, v_target_table, v_pk_column, v_pk_value, v_rows;

END;
$$;
