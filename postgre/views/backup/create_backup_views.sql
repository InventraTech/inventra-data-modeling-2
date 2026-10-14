-- ---------------------------------------------------
-- VIEWS
-- ---------------------------------------------------

-- Uma linha: último backup e último restore com sucesso, falhas recentes e situação.
-- OVERDUE = mais de 26 h sem backup (rotina diária + 2 h de folga).
CREATE OR REPLACE VIEW vw_backup_status AS
WITH last_success AS (
    SELECT DISTINCT ON (operation)
        operation,
        database_name,
        file_name,
        file_size_bytes,
        finished_at
    FROM tb_backup_history
    WHERE status = 'SUCCESS'
    ORDER BY operation, finished_at DESC
)
SELECT
    b.database_name AS last_backup_database,
    b.file_name AS last_backup_file,
    b.file_size_bytes AS last_backup_size_bytes,
    b.finished_at AS last_backup_at,
    ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - b.finished_at)) / 3600, 1) AS hours_since_last_backup,
    r.file_name AS last_restore_file,
    r.database_name AS last_restore_database,
    r.finished_at AS last_restore_at,
    (
        SELECT COUNT(*)
        FROM tb_backup_history f
        WHERE f.status = 'FAILED'
          AND f.finished_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    ) AS failures_last_7_days,
    CASE
        WHEN b.finished_at IS NULL THEN 'NEVER'
        WHEN b.finished_at < CURRENT_TIMESTAMP - INTERVAL '26 hours' THEN 'OVERDUE'
        ELSE 'OK'
    END AS backup_status
FROM (SELECT 1) AS one_row
LEFT JOIN last_success b ON b.operation = 'BACKUP'
LEFT JOIN last_success r ON r.operation = 'RESTORE';
