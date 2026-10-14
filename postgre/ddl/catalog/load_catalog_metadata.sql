-- ---------------------------------------------------
-- ACCESS LEVELS
-- ---------------------------------------------------

INSERT INTO tb_catalog_access_level (code, level_rank, description, audience)
VALUES
	('PUBLIC', 1,
	 'Dado de referência, sem risco se exposto.',
	 'Qualquer usuário autenticado (supervisor, estoquista, comprador) e ferramentas de BI.'),
	('INTERNAL', 2,
	 'Dado operacional da cozinha, de uso interno.',
	 'Usuários da própria cozinha, filtrados pela API; BI somente agregado.'),
	('RESTRICTED', 3,
	 'Dado comercial (preço, fornecedor) ou pessoal (LGPD); acesso por necessidade.',
	 'Supervisor e comprador; BI somente agregado ou anonimizado.'),
	('CONFIDENTIAL', 4,
	 'Credencial, identificador de autenticação ou trilha de auditoria.',
	 'Somente DBA e a conta de serviço da API; nunca exposto no app ou no BI.')
ON CONFLICT (code) DO UPDATE
SET level_rank = EXCLUDED.level_rank,
    description = EXCLUDED.description,
    audience = EXCLUDED.audience;

-- ---------------------------------------------------
-- TABLE METADATA
-- ---------------------------------------------------

INSERT INTO tb_catalog_table (table_name, domain, description, business_rules, id_access_level, data_owner)
SELECT v.table_name, v.domain, v.description, v.business_rules, al.id_access_level, v.data_owner
FROM (VALUES
	('tb_user', 'MASTER_DATA',
	 'Usuários do sistema (login por senha ou Google).',
	 'Cada usuário tem um perfil (N:1) e, opcionalmente, uma cozinha (N:1). Desativação é lógica (active = false). Toda alteração é auditada em tb_log_user.',
	 'RESTRICTED', 'Administração do sistema'),
	('tb_profile', 'MASTER_DATA',
	 'Perfis de acesso aceitos pela API.',
	 'Três perfis: supervisor, estoquista e comprador. Código em minúsculas e único.',
	 'PUBLIC', 'Administração do sistema'),
	('tb_kitchen', 'MASTER_DATA',
	 'Cozinhas industriais atendidas, com endereço e localização.',
	 'Código curto único. Latitude/longitude alimentam a busca por proximidade no app.',
	 'INTERNAL', 'Operações'),
	('tb_product', 'MASTER_DATA',
	 'Catálogo de produtos controlados no estoque.',
	 'Todo produto tem unidade de medida; categoria é opcional. Código de barras é único quando informado. Alterações auditadas em tb_log_product.',
	 'PUBLIC', 'Compras'),
	('tb_category', 'MASTER_DATA',
	 'Categorias de produto (ex.: carnes, laticínios, secos).',
	 'Nome único.',
	 'PUBLIC', 'Compras'),
	('tb_measurement_unit', 'MASTER_DATA',
	 'Unidades de medida dos produtos.',
	 'Símbolo único (ex.: kg, L, un).',
	 'PUBLIC', 'Compras'),
	('tb_supplier', 'MASTER_DATA',
	 'Fornecedores (pessoa jurídica).',
	 'CNPJ único. Avaliação de 1 a 5. Alterações auditadas em tb_log_supplier.',
	 'RESTRICTED', 'Compras'),
	('tb_product_supplier', 'RELATIONSHIP',
	 'Associativa N:N entre produto e fornecedor, com condições comerciais.',
	 'PK composta (id_product, id_supplier): um fornecedor aparece uma única vez por produto.',
	 'RESTRICTED', 'Compras'),
	('tb_product_kitchen_parameter', 'RELATIONSHIP',
	 'Associativa N:N entre produto e cozinha, com os parâmetros de estoque.',
	 'PK composta (id_product, id_kitchen). O estoque mínimo dispara o alerta STOCK (fn_stock_alert).',
	 'INTERNAL', 'Operações'),
	('tb_stock_batch', 'TRANSACTION',
	 'Lotes de estoque: cada entrada de produto numa cozinha.',
	 'Saldo nunca negativo (fn_validate_stock). Saldo zero vira WRITTEN_OFF (fn_update_batch_status). Vencido vira EXPIRED (sp_expire_batches). Alterações auditadas em tb_log_stock_batch.',
	 'INTERNAL', 'Operações'),
	('tb_requisition', 'TRANSACTION',
	 'Requisições de compra, transferência ou consumo.',
	 'Fluxo DRAFT -> UNDER_REVIEW -> APPROVED/REJECTED; CANCELLED a partir de DRAFT, UNDER_REVIEW ou APPROVED (estorna o estoque). Alterações auditadas em tb_log_requisition.',
	 'INTERNAL', 'Operações'),
	('tb_requisition_item', 'TRANSACTION',
	 'Itens (produto e quantidade) de cada requisição.',
	 'Uma requisição tem N itens (1:N).',
	 'INTERNAL', 'Operações'),
	('tb_inventory', 'TRANSACTION',
	 'Inventários (contagens físicas) por cozinha.',
	 'Status OPEN, CLOSED ou CANCELLED; fechamento via sp_close_inventory. Alterações auditadas em tb_log_inventory.',
	 'INTERNAL', 'Operações'),
	('tb_inventory_count', 'TRANSACTION',
	 'Contagem de cada lote dentro de um inventário.',
	 'Divergência calculada automaticamente (física - registrada) por fn_calculate_divergence.',
	 'INTERNAL', 'Operações'),
	('tb_stock_movement', 'TRANSACTION',
	 'Histórico de movimentações de estoque por lote.',
	 'ENTRY e WRITE_OFF com quantidade > 0; ADJUSTMENT com sinal. Motivo obrigatório só no WRITE_OFF. Gravada pelas procedures de entrada, baixa e cancelamento.',
	 'INTERNAL', 'Operações'),
	('tb_alert', 'EVENT',
	 'Alertas de estoque mínimo e de validade.',
	 'Gerados por trigger e pelo job diário; não duplica enquanto houver alerta aberto do mesmo tipo. Destinatário nulo = cozinha inteira. Com lote, produto e cozinha vêm do lote (trg_alert_batch_consistency). Alterações auditadas em tb_log_alert.',
	 'INTERNAL', 'Operações'),
	('tb_alert_read', 'EVENT',
	 'Leitura de alerta por usuário.',
	 'PK composta (id_alert, id_user). Apagada em cascata junto com o alerta.',
	 'INTERNAL', 'Operações'),
	('tb_log_base', 'AUDIT',
	 'Tabela-mãe da auditoria: colunas comuns herdadas (INHERITS) pelas 7 tabelas tb_log_*.',
	 'Gravada só pelas triggers de auditoria (NEW, OLD, TG_OP, CURRENT_USER). Nunca editada manualmente. SELECT nela retorna as linhas de todas as filhas.',
	 'CONFIDENTIAL', 'DBA'),
	('tb_log_user', 'AUDIT', 'Auditoria de tb_user.', 'Herda de tb_log_base; gravada por trg_log_user.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_product', 'AUDIT', 'Auditoria de tb_product.', 'Herda de tb_log_base; gravada por trg_log_product.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_supplier', 'AUDIT', 'Auditoria de tb_supplier.', 'Herda de tb_log_base; gravada por trg_log_supplier.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_stock_batch', 'AUDIT', 'Auditoria de tb_stock_batch.', 'Herda de tb_log_base; gravada por trg_log_stock_batch.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_requisition', 'AUDIT', 'Auditoria de tb_requisition.', 'Herda de tb_log_base; gravada por trg_log_requisition.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_inventory', 'AUDIT', 'Auditoria de tb_inventory.', 'Herda de tb_log_base; gravada por trg_log_inventory.', 'CONFIDENTIAL', 'DBA'),
	('tb_log_alert', 'AUDIT', 'Auditoria de tb_alert.', 'Herda de tb_log_base; gravada por trg_log_alert.', 'CONFIDENTIAL', 'DBA'),
	('tb_catalog_access_level', 'GOVERNANCE',
	 'Níveis de acesso usados para classificar tabelas e colunas.',
	 'Quanto maior o level_rank, mais restrito.',
	 'PUBLIC', 'Governança de dados'),
	('tb_catalog_table', 'GOVERNANCE',
	 'Catálogo de dados: metadados de negócio de cada tabela.',
	 'Uma linha por tabela do schema; novas tabelas entram via sp_sync_data_catalog como UNCLASSIFIED.',
	 'INTERNAL', 'Governança de dados'),
	('tb_catalog_column', 'GOVERNANCE',
	 'Catálogo de dados: metadados de negócio de cada coluna.',
	 'Nível de acesso nulo herda o da tabela. Colunas herdadas (INHERITS) são documentadas só na tabela-mãe.',
	 'INTERNAL', 'Governança de dados')
) AS v(table_name, domain, description, business_rules, access_code, data_owner)
JOIN tb_catalog_access_level al ON al.code = v.access_code
ON CONFLICT (table_name) DO UPDATE
SET domain = EXCLUDED.domain,
    description = EXCLUDED.description,
    business_rules = EXCLUDED.business_rules,
    id_access_level = EXCLUDED.id_access_level,
    data_owner = EXCLUDED.data_owner,
    updated_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------
-- COLUMN METADATA
-- ---------------------------------------------------

-- access_code nulo = herda o nível da tabela
INSERT INTO tb_catalog_column (id_catalog_table, column_name, description, business_rule, id_access_level, is_personal_data)
SELECT t.id_catalog_table, v.column_name, v.description, v.business_rule, al.id_access_level, v.is_personal_data
FROM (VALUES
	-- tb_user
	('tb_user', 'id_user', 'Identificador do usuário (UUID gerado pela API).', NULL, NULL, false),
	('tb_user', 'name', 'Nome completo do usuário.', NULL, NULL, true),
	('tb_user', 'email', 'E-mail usado no login.', 'Único (UNIQUE).', NULL, true),
	('tb_user', 'password_hash', 'Hash da senha gerado pela API.', 'Nulo em conta criada pelo login Google. Nunca guarda senha em texto puro.', 'CONFIDENTIAL', true),
	('tb_user', 'firebase_uid', 'Identificador do usuário no Firebase Auth (login Google).', 'Único quando preenchido (uq_user_firebase_uid).', 'CONFIDENTIAL', true),
	('tb_user', 'id_kitchen', 'Cozinha à qual o usuário pertence.', 'Nulo enquanto o usuário não for vinculado a uma cozinha.', NULL, false),
	('tb_user', 'id_profile', 'Perfil de acesso do usuário.', 'Obrigatório.', NULL, false),
	('tb_user', 'active', 'Indica se a conta está ativa.', 'Desativação lógica: o registro não é apagado.', NULL, false),
	('tb_user', 'last_login', 'Data e hora do último login.', NULL, NULL, true),
	('tb_user', 'created_at', 'Data e hora de criação da conta.', NULL, NULL, false),
	-- tb_profile
	('tb_profile', 'id_profile', 'Identificador do perfil.', NULL, NULL, false),
	('tb_profile', 'access_type', 'Código do perfil (supervisor, estoquista, comprador).', 'Único, em minúsculas.', NULL, false),
	('tb_profile', 'description', 'Descrição do perfil.', NULL, NULL, false),
	-- tb_kitchen
	('tb_kitchen', 'id_kitchen', 'Identificador da cozinha.', NULL, NULL, false),
	('tb_kitchen', 'name', 'Nome da cozinha.', NULL, NULL, false),
	('tb_kitchen', 'code', 'Código curto da cozinha.', 'Único (UNIQUE).', NULL, false),
	('tb_kitchen', 'address', 'Endereço da cozinha.', NULL, NULL, false),
	('tb_kitchen', 'city', 'Cidade da cozinha.', NULL, NULL, false),
	('tb_kitchen', 'state', 'UF da cozinha.', 'Duas letras maiúsculas (ck_kitchen_state).', NULL, false),
	('tb_kitchen', 'latitude', 'Latitude da cozinha.', 'Entre -90 e 90 (ck_kitchen_latitude).', NULL, false),
	('tb_kitchen', 'longitude', 'Longitude da cozinha.', 'Entre -180 e 180 (ck_kitchen_longitude).', NULL, false),
	('tb_kitchen', 'accepting_requests', 'Indica se a cozinha aceita novos pedidos de acesso.', NULL, NULL, false),
	('tb_kitchen', 'active', 'Indica se a cozinha está ativa.', 'Desativação lógica.', NULL, false),
	('tb_kitchen', 'created_at', 'Data e hora de cadastro.', NULL, NULL, false),
	-- tb_product
	('tb_product', 'id_product', 'Identificador do produto.', NULL, NULL, false),
	('tb_product', 'name', 'Nome do produto.', NULL, NULL, false),
	('tb_product', 'brand', 'Marca do produto.', NULL, NULL, false),
	('tb_product', 'id_category', 'Categoria do produto.', 'Opcional.', NULL, false),
	('tb_product', 'id_unit', 'Unidade de medida do produto.', 'Obrigatória.', NULL, false),
	('tb_product', 'barcode', 'Código de barras (EAN).', 'Único quando informado.', NULL, false),
	('tb_product', 'photo_url', 'URL da foto do produto.', NULL, NULL, false),
	('tb_product', 'active', 'Indica se o produto está ativo.', 'Desativação lógica.', NULL, false),
	('tb_product', 'created_at', 'Data e hora de cadastro.', NULL, NULL, false),
	-- tb_category
	('tb_category', 'id_category', 'Identificador da categoria.', NULL, NULL, false),
	('tb_category', 'name', 'Nome da categoria.', 'Único (UNIQUE).', NULL, false),
	('tb_category', 'description', 'Descrição da categoria.', NULL, NULL, false),
	-- tb_measurement_unit
	('tb_measurement_unit', 'id_unit', 'Identificador da unidade.', NULL, NULL, false),
	('tb_measurement_unit', 'symbol', 'Símbolo da unidade (kg, L, un).', 'Único (UNIQUE).', NULL, false),
	('tb_measurement_unit', 'description', 'Nome por extenso da unidade.', NULL, NULL, false),
	-- tb_supplier
	('tb_supplier', 'id_supplier', 'Identificador do fornecedor.', NULL, NULL, false),
	('tb_supplier', 'legal_name', 'Razão social.', NULL, NULL, false),
	('tb_supplier', 'cnpj', 'CNPJ do fornecedor.', 'Único (UNIQUE).', NULL, false),
	('tb_supplier', 'email', 'E-mail de contato.', 'Pode identificar a pessoa de contato (LGPD).', NULL, true),
	('tb_supplier', 'whatsapp', 'WhatsApp de contato.', 'Pode identificar a pessoa de contato (LGPD).', NULL, true),
	('tb_supplier', 'rating', 'Avaliação interna do fornecedor.', 'Entre 1 e 5 (ck_supplier_rating).', NULL, false),
	('tb_supplier', 'active', 'Indica se o fornecedor está ativo.', 'Desativação lógica.', NULL, false),
	('tb_supplier', 'created_at', 'Data e hora de cadastro.', NULL, NULL, false),
	-- tb_product_supplier
	('tb_product_supplier', 'id_product', 'Produto fornecido.', 'Parte da PK composta.', NULL, false),
	('tb_product_supplier', 'id_supplier', 'Fornecedor do produto.', 'Parte da PK composta.', NULL, false),
	('tb_product_supplier', 'supplier_code', 'Código do produto no catálogo do fornecedor.', NULL, NULL, false),
	('tb_product_supplier', 'reference_price', 'Preço de referência negociado.', NULL, NULL, false),
	('tb_product_supplier', 'lead_time_days', 'Prazo de entrega em dias.', NULL, NULL, false),
	-- tb_product_kitchen_parameter
	('tb_product_kitchen_parameter', 'id_product', 'Produto parametrizado.', 'Parte da PK composta.', NULL, false),
	('tb_product_kitchen_parameter', 'id_kitchen', 'Cozinha do parâmetro.', 'Parte da PK composta.', NULL, false),
	('tb_product_kitchen_parameter', 'min_stock', 'Estoque mínimo do produto na cozinha.', 'Soma dos lotes ativos e não vencidos abaixo deste valor gera alerta STOCK.', NULL, false),
	('tb_product_kitchen_parameter', 'max_stock', 'Estoque máximo desejado.', NULL, NULL, false),
	('tb_product_kitchen_parameter', 'average_daily_consumption', 'Consumo médio diário estimado.', NULL, NULL, false),
	-- tb_stock_batch
	('tb_stock_batch', 'id_batch', 'Identificador do lote.', NULL, NULL, false),
	('tb_stock_batch', 'id_product', 'Produto do lote.', NULL, NULL, false),
	('tb_stock_batch', 'id_kitchen', 'Cozinha onde o lote está.', NULL, NULL, false),
	('tb_stock_batch', 'id_supplier', 'Fornecedor do lote.', 'Opcional.', NULL, false),
	('tb_stock_batch', 'batch_number', 'Número do lote impresso na embalagem.', NULL, NULL, false),
	('tb_stock_batch', 'invoice_number', 'Número da nota fiscal de entrada.', NULL, NULL, false),
	('tb_stock_batch', 'initial_quantity', 'Quantidade na entrada do lote.', NULL, NULL, false),
	('tb_stock_batch', 'current_quantity', 'Saldo atual do lote.', 'Nunca negativo (fn_validate_stock); zero muda o status para WRITTEN_OFF.', NULL, false),
	('tb_stock_batch', 'entry_date', 'Data de entrada do lote.', NULL, NULL, false),
	('tb_stock_batch', 'expiration_date', 'Data de validade.', 'Vencido gera alerta EXPIRATION e vira EXPIRED no job diário.', NULL, false),
	('tb_stock_batch', 'unit_price', 'Preço unitário pago.', 'Dado comercial.', 'RESTRICTED', false),
	('tb_stock_batch', 'status', 'Situação do lote.', 'ACTIVE, WRITTEN_OFF, EXPIRED ou CANCELLED (ck_batch_status).', NULL, false),
	-- tb_requisition
	('tb_requisition', 'id_requisition', 'Identificador da requisição.', NULL, NULL, false),
	('tb_requisition', 'requisition_type', 'Tipo da requisição.', 'PURCHASE, TRANSFER ou CONSUMPTION (ck_requisition_type).', NULL, false),
	('tb_requisition', 'origin', 'Canal que originou a requisição (ex.: MOBILE_APP, SYSTEM).', 'Texto livre, sem CHECK.', NULL, false),
	('tb_requisition', 'status', 'Situação da requisição.', 'DRAFT, UNDER_REVIEW, APPROVED, REJECTED ou CANCELLED (ck_requisition_status).', NULL, false),
	('tb_requisition', 'reason', 'Justificativa da requisição.', NULL, NULL, false),
	('tb_requisition', 'id_kitchen', 'Cozinha solicitante.', NULL, NULL, false),
	('tb_requisition', 'id_requester_user', 'Usuário que abriu a requisição.', NULL, NULL, false),
	('tb_requisition', 'id_approver_user', 'Usuário que aprovou ou rejeitou.', 'Preenchido só na decisão.', NULL, false),
	('tb_requisition', 'created_at', 'Data e hora de abertura.', NULL, NULL, false),
	('tb_requisition', 'approved_at', 'Data e hora da aprovação.', 'Preenchido por trg_requisition_approval ao mudar para APPROVED.', NULL, false),
	-- tb_requisition_item
	('tb_requisition_item', 'id_requisition_item', 'Identificador do item.', NULL, NULL, false),
	('tb_requisition_item', 'id_requisition', 'Requisição a que o item pertence.', NULL, NULL, false),
	('tb_requisition_item', 'id_product', 'Produto requisitado.', NULL, NULL, false),
	('tb_requisition_item', 'id_suggested_supplier', 'Fornecedor sugerido.', 'Opcional.', NULL, false),
	('tb_requisition_item', 'quantity', 'Quantidade requisitada.', NULL, NULL, false),
	('tb_requisition_item', 'estimated_price', 'Preço estimado do item.', 'Dado comercial.', 'RESTRICTED', false),
	('tb_requisition_item', 'note', 'Observação do item.', NULL, NULL, false),
	-- tb_inventory
	('tb_inventory', 'id_inventory', 'Identificador do inventário.', NULL, NULL, false),
	('tb_inventory', 'id_kitchen', 'Cozinha inventariada.', NULL, NULL, false),
	('tb_inventory', 'id_responsible_user', 'Usuário responsável pela contagem.', NULL, NULL, false),
	('tb_inventory', 'started_at', 'Data e hora de abertura.', NULL, NULL, false),
	('tb_inventory', 'closed_at', 'Data e hora de fechamento.', 'Preenchido por sp_close_inventory.', NULL, false),
	('tb_inventory', 'status', 'Situação do inventário.', 'OPEN, CLOSED ou CANCELLED (ck_inventory_status).', NULL, false),
	('tb_inventory', 'note', 'Observação do inventário.', NULL, NULL, false),
	-- tb_inventory_count
	('tb_inventory_count', 'id_count', 'Identificador da contagem.', NULL, NULL, false),
	('tb_inventory_count', 'id_inventory', 'Inventário da contagem.', NULL, NULL, false),
	('tb_inventory_count', 'id_batch', 'Lote contado.', NULL, NULL, false),
	('tb_inventory_count', 'registered_quantity', 'Saldo do lote no sistema no momento da contagem.', NULL, NULL, false),
	('tb_inventory_count', 'physical_quantity', 'Quantidade contada fisicamente.', NULL, NULL, false),
	('tb_inventory_count', 'divergence', 'Diferença entre o contado e o registrado.', 'Calculada por fn_calculate_divergence (física - registrada) em todo INSERT e UPDATE; valor escrito à mão é sobrescrito.', NULL, false),
	('tb_inventory_count', 'note', 'Observação da contagem.', NULL, NULL, false),
	-- tb_stock_movement
	('tb_stock_movement', 'id_movement', 'Identificador da movimentação.', NULL, NULL, false),
	('tb_stock_movement', 'id_batch', 'Lote movimentado.', NULL, NULL, false),
	('tb_stock_movement', 'id_user', 'Usuário que fez a movimentação.', 'Nulo quando gerada pelo sistema.', NULL, false),
	('tb_stock_movement', 'id_requisition', 'Requisição que causou a baixa ou o estorno.', NULL, NULL, false),
	('tb_stock_movement', 'type', 'Tipo da movimentação.', 'ENTRY, WRITE_OFF ou ADJUSTMENT (ck_movement_type).', NULL, false),
	('tb_stock_movement', 'reason', 'Motivo da baixa.', 'Obrigatório só em WRITE_OFF: USAGE, LOSS, EXPIRED ou REQUISITION (ck_movement_reason).', NULL, false),
	('tb_stock_movement', 'quantity', 'Quantidade movimentada.', '> 0 em ENTRY e WRITE_OFF; com sinal e diferente de 0 em ADJUSTMENT (ck_movement_quantity).', NULL, false),
	('tb_stock_movement', 'balance_after', 'Saldo do lote logo após a movimentação.', NULL, NULL, false),
	('tb_stock_movement', 'created_at', 'Data e hora da movimentação.', NULL, NULL, false),
	-- tb_alert
	('tb_alert', 'id_alert', 'Identificador do alerta.', NULL, NULL, false),
	('tb_alert', 'type', 'Tipo do alerta (STOCK, EXPIRATION, EXPIRING).', NULL, NULL, false),
	('tb_alert', 'severity', 'Gravidade do alerta.', 'LOW, MEDIUM, HIGH ou CRITICAL (ck_alert_severity).', NULL, false),
	('tb_alert', 'id_batch', 'Lote relacionado.', 'Nulo em alerta de estoque mínimo. Com lote, produto e cozinha do alerta são os do lote.', NULL, false),
	('tb_alert', 'id_product', 'Produto relacionado.', 'Com lote, é sempre o produto do lote: vazio é preenchido e diferente é recusado (trg_alert_batch_consistency).', NULL, false),
	('tb_alert', 'id_kitchen', 'Cozinha do alerta.', 'Obrigatório. Com lote, é sempre a cozinha do lote (trg_alert_batch_consistency).', NULL, false),
	('tb_alert', 'id_user', 'Usuário destinatário.', 'Nulo junto com id_target_profile = alerta para a cozinha inteira.', NULL, false),
	('tb_alert', 'id_target_profile', 'Perfil destinatário.', NULL, NULL, false),
	('tb_alert', 'ref_key', 'Referência da origem (id da requisição, do pedido ou código de barras).', NULL, NULL, false),
	('tb_alert', 'message', 'Texto exibido ao usuário.', NULL, NULL, false),
	('tb_alert', 'is_read', 'Leitura do alerta inteiro (modelo antigo).', 'Alerta aberto = is_read false e nenhuma linha em tb_alert_read.', NULL, false),
	('tb_alert', 'created_at', 'Data e hora de criação.', NULL, NULL, false),
	-- tb_alert_read
	('tb_alert_read', 'id_alert', 'Alerta lido.', 'Parte da PK composta; cascata ao apagar o alerta.', NULL, false),
	('tb_alert_read', 'id_user', 'Usuário que leu.', 'Parte da PK composta.', NULL, false),
	('tb_alert_read', 'read_at', 'Data e hora da leitura.', NULL, NULL, false),
	-- tb_log_base (colunas herdadas pelas 7 tabelas tb_log_*)
	('tb_log_base', 'id_log', 'Identificador do registro de log.', 'Sequência seq_log_id compartilhada por todas as filhas.', NULL, false),
	('tb_log_base', 'operation', 'Operação auditada.', 'INSERT, UPDATE ou DELETE (TG_OP).', NULL, false),
	('tb_log_base', 'db_user', 'Usuário do banco que executou a operação.', 'CURRENT_USER no momento da operação.', NULL, false),
	('tb_log_base', 'operation_date', 'Data e hora da operação.', NULL, NULL, false),
	('tb_log_base', 'previous_data', 'Linha antes da operação, em JSON.', 'OLD; nulo em INSERT.', NULL, true),
	('tb_log_base', 'new_data', 'Linha depois da operação, em JSON.', 'NEW; nulo em DELETE.', NULL, true),
	('tb_log_user', 'id_user', 'Usuário auditado.', NULL, NULL, false),
	('tb_log_product', 'id_product', 'Produto auditado.', NULL, NULL, false),
	('tb_log_supplier', 'id_supplier', 'Fornecedor auditado.', NULL, NULL, false),
	('tb_log_stock_batch', 'id_batch', 'Lote auditado.', NULL, NULL, false),
	('tb_log_requisition', 'id_requisition', 'Requisição auditada.', NULL, NULL, false),
	('tb_log_inventory', 'id_inventory', 'Inventário auditado.', NULL, NULL, false),
	('tb_log_alert', 'id_alert', 'Alerta auditado.', NULL, NULL, false),
	-- tb_catalog_access_level
	('tb_catalog_access_level', 'id_access_level', 'Identificador do nível de acesso.', NULL, NULL, false),
	('tb_catalog_access_level', 'code', 'Código do nível (PUBLIC, INTERNAL, RESTRICTED, CONFIDENTIAL).', 'Único.', NULL, false),
	('tb_catalog_access_level', 'level_rank', 'Ordem de restrição.', 'Único e maior que zero; quanto maior, mais restrito.', NULL, false),
	('tb_catalog_access_level', 'description', 'O que caracteriza o nível.', NULL, NULL, false),
	('tb_catalog_access_level', 'audience', 'Quem pode ler dados deste nível.', NULL, NULL, false),
	-- tb_catalog_table
	('tb_catalog_table', 'id_catalog_table', 'Identificador da tabela catalogada.', NULL, NULL, false),
	('tb_catalog_table', 'table_name', 'Nome físico da tabela.', 'Único.', NULL, false),
	('tb_catalog_table', 'domain', 'Grupo de negócio da tabela.', 'MASTER_DATA, RELATIONSHIP, TRANSACTION, EVENT, AUDIT, GOVERNANCE ou UNCLASSIFIED.', NULL, false),
	('tb_catalog_table', 'description', 'Para que a tabela serve.', 'Nulo = tabela ainda não documentada.', NULL, false),
	('tb_catalog_table', 'business_rules', 'Regras de negócio que valem para a tabela.', NULL, NULL, false),
	('tb_catalog_table', 'id_access_level', 'Nível de acesso da tabela.', 'Obrigatório; vale para as colunas sem nível próprio.', NULL, false),
	('tb_catalog_table', 'data_owner', 'Área responsável pelo dado.', NULL, NULL, false),
	('tb_catalog_table', 'created_at', 'Data e hora de entrada no catálogo.', NULL, NULL, false),
	('tb_catalog_table', 'updated_at', 'Data e hora da última atualização.', NULL, NULL, false),
	-- tb_catalog_column
	('tb_catalog_column', 'id_catalog_column', 'Identificador da coluna catalogada.', NULL, NULL, false),
	('tb_catalog_column', 'id_catalog_table', 'Tabela da coluna.', 'Cascata ao remover a tabela do catálogo.', NULL, false),
	('tb_catalog_column', 'column_name', 'Nome físico da coluna.', 'Único por tabela.', NULL, false),
	('tb_catalog_column', 'description', 'O que a coluna guarda.', 'Nulo = coluna ainda não documentada.', NULL, false),
	('tb_catalog_column', 'business_rule', 'Regra de negócio da coluna.', NULL, NULL, false),
	('tb_catalog_column', 'id_access_level', 'Nível de acesso próprio da coluna.', 'Nulo = herda o da tabela.', NULL, false),
	('tb_catalog_column', 'is_personal_data', 'Indica dado pessoal (LGPD).', NULL, NULL, false),
	('tb_catalog_column', 'updated_at', 'Data e hora da última atualização.', NULL, NULL, false)
) AS v(table_name, column_name, description, business_rule, access_code, is_personal_data)
JOIN tb_catalog_table t ON t.table_name = v.table_name
LEFT JOIN tb_catalog_access_level al ON al.code = v.access_code
ON CONFLICT (id_catalog_table, column_name) DO UPDATE
SET description = EXCLUDED.description,
    business_rule = EXCLUDED.business_rule,
    id_access_level = EXCLUDED.id_access_level,
    is_personal_data = EXCLUDED.is_personal_data,
    updated_at = CURRENT_TIMESTAMP;

-- ---------------------------------------------------
-- BACKUP HISTORY METADATA (V011)
-- ---------------------------------------------------

INSERT INTO tb_catalog_table (table_name, domain, description, business_rules, id_access_level, data_owner)
SELECT
	'tb_backup_history', 'GOVERNANCE',
	'Histórico das execuções de backup e restore.',
	'Gravada por postgre/backup/backup.sh e restore.sh via sp_register_backup. Falha sempre tem mensagem de erro. vw_backup_status indica OVERDUE após 26 h sem backup.',
	al.id_access_level, 'DBA'
FROM tb_catalog_access_level al
WHERE al.code = 'INTERNAL'
ON CONFLICT (table_name) DO UPDATE
SET domain = EXCLUDED.domain,
    description = EXCLUDED.description,
    business_rules = EXCLUDED.business_rules,
    id_access_level = EXCLUDED.id_access_level,
    data_owner = EXCLUDED.data_owner,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO tb_catalog_column (id_catalog_table, column_name, description, business_rule, id_access_level, is_personal_data)
SELECT t.id_catalog_table, v.column_name, v.description, v.business_rule, NULL, false
FROM (VALUES
	('id_backup', 'Identificador da execução.', NULL),
	('operation', 'Tipo da execução.', 'BACKUP ou RESTORE (ck_backuphistory_operation).'),
	('status', 'Resultado da execução.', 'SUCCESS ou FAILED (ck_backuphistory_status).'),
	('database_name', 'Banco copiado (BACKUP) ou restaurado (RESTORE).', NULL),
	('file_name', 'Nome do arquivo .dump.', NULL),
	('file_size_bytes', 'Tamanho do arquivo em bytes.', NULL),
	('checksum_sha256', 'Hash SHA-256 do arquivo, conferido antes de restaurar.', '64 caracteres hexadecimais (ck_backuphistory_checksum).'),
	('started_at', 'Início da execução (relógio da máquina que rodou o script).', NULL),
	('finished_at', 'Fim da execução.', 'Nunca antes do início (ck_backuphistory_period).'),
	('executed_by', 'Usuário do banco que registrou a execução.', 'CURRENT_USER.'),
	('error_message', 'Motivo da falha.', 'Obrigatório quando FAILED e nulo quando SUCCESS (ck_backuphistory_error).')
) AS v(column_name, description, business_rule)
JOIN tb_catalog_table t ON t.table_name = 'tb_backup_history'
ON CONFLICT (id_catalog_table, column_name) DO UPDATE
SET description = EXCLUDED.description,
    business_rule = EXCLUDED.business_rule,
    id_access_level = EXCLUDED.id_access_level,
    is_personal_data = EXCLUDED.is_personal_data,
    updated_at = CURRENT_TIMESTAMP;
