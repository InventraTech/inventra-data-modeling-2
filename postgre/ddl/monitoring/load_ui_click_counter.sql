-- ---------------------------------------------------
-- UI CLICK COUNTER (LINHA ÚNICA)
-- ---------------------------------------------------

-- Cria a única linha do contador, com todas as colunas em 0. Reexecutar não zera os contadores.
INSERT INTO tb_ui_click_counter (id_counter)
VALUES (1)
ON CONFLICT (id_counter) DO NOTHING;
