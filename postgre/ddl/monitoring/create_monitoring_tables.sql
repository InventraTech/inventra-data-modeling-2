-- ---------------------------------------------------
-- DAILY ACCESS TABLE CREATION
-- ---------------------------------------------------

-- Uma linha por usuário por dia de uso: o DAU de um dia é o COUNT(*) do dia.
-- Gravada só pela trigger trg_register_daily_access (tb_user.last_login).
-- A data fica só em access_date; primeiro e último acesso guardam só a hora
-- (com TIMESTAMP, a data se repetiria e a tabela sairia da FNBC).
CREATE TABLE tb_user_daily_access (
	id_user UUID NOT NULL,
	access_date DATE NOT NULL,
	first_access_time TIME NOT NULL,
	last_access_time TIME NOT NULL,
	access_count INTEGER NOT NULL DEFAULT 1,
	PRIMARY KEY (id_user, access_date)
);

-- ---------------------------------------------------
-- FOREIGN KEYS CREATION
-- ---------------------------------------------------

-- apagar o usuário apaga o histórico de acesso dele (dado pessoal, LGPD)
ALTER TABLE tb_user_daily_access
ADD CONSTRAINT fk_useraccess_user
FOREIGN KEY (id_user) REFERENCES tb_user (id_user)
ON UPDATE NO ACTION ON DELETE CASCADE;

-- ---------------------------------------------------
-- CHECK CONSTRAINTS
-- ---------------------------------------------------

ALTER TABLE tb_user_daily_access
ADD CONSTRAINT ck_useraccess_count
CHECK (access_count > 0);

-- o primeiro acesso do dia nunca é depois do último
ALTER TABLE tb_user_daily_access
ADD CONSTRAINT ck_useraccess_period
CHECK (last_access_time >= first_access_time);

-- ---------------------------------------------------
-- INDEX CREATION
-- ---------------------------------------------------

-- a PK começa por id_user; as views de DAU agrupam e filtram por dia
CREATE INDEX idx_useraccess_date
ON tb_user_daily_access (access_date);
