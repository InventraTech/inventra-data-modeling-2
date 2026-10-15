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

-- ---------------------------------------------------
-- UI CLICK COUNTER TABLE CREATION
-- ---------------------------------------------------

-- Contador de cliques do Inventra: UMA linha só (id_counter = 1) e uma coluna por coisa clicável,
-- web (wb) e mobile (mb). A cada clique, o método do sistema soma 1 na coluna do elemento, por exemplo:
--   UPDATE tb_ui_click_counter SET bt_mb_profile_data_save = bt_mb_profile_data_save + 1;
-- Nome da coluna: tipo_plataforma_tela_nome, em inglês (tipo: bt button, toggle, tab, nav navigation item,
-- chip, filter, radio, checkbox, link, fab floating action button, icon icon button, page pagination,
-- select dropdown, card item clicável).
-- Campo de digitação e touch de login não entram. Não guarda quem clicou nem quando: é só o total.
-- Elemento novo no produto = ALTER TABLE ... ADD COLUMN numa migration nova (e metadado no catálogo).
-- Exceção consciente da 1FN (colunas repetidas): veja docs/normalization/NORMALIZATION.md.
CREATE TABLE tb_ui_click_counter (
	id_counter SMALLINT NOT NULL DEFAULT 1,
	-- WEB · GLOBAL
	nav_wb_global_dashboard BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_requisitions BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_stock BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_inventories BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_products BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_suppliers BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_history BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_kitchen BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_team_access BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_account_settings BIGINT NOT NULL DEFAULT 0,
	nav_wb_global_accessibility BIGINT NOT NULL DEFAULT 0,
	icon_wb_topbar_notifications BIGINT NOT NULL DEFAULT 0,
	icon_wb_topbar_avatar BIGINT NOT NULL DEFAULT 0,
	bt_wb_topbar_logout BIGINT NOT NULL DEFAULT 0,
	fab_wb_global_chatbot BIGINT NOT NULL DEFAULT 0,
	-- WEB · Login
	bt_wb_login_sign_in BIGINT NOT NULL DEFAULT 0,
	bt_wb_login_google BIGINT NOT NULL DEFAULT 0,
	checkbox_wb_login_remember_me BIGINT NOT NULL DEFAULT 0,
	link_wb_login_forgot_password BIGINT NOT NULL DEFAULT 0,
	link_wb_login_request_access BIGINT NOT NULL DEFAULT 0,
	-- WEB · Cadastro
	icon_wb_signup_password_visibility BIGINT NOT NULL DEFAULT 0,
	icon_wb_signup_confirm_password_visibility BIGINT NOT NULL DEFAULT 0,
	checkbox_wb_signup_accept_terms BIGINT NOT NULL DEFAULT 0,
	bt_wb_signup_create_account BIGINT NOT NULL DEFAULT 0,
	link_wb_signup_sign_in BIGINT NOT NULL DEFAULT 0,
	-- WEB · Cadastro de cozinha
	bt_wb_signup_kitchen_create BIGINT NOT NULL DEFAULT 0,
	link_wb_signup_kitchen_skip BIGINT NOT NULL DEFAULT 0,
	-- WEB · Dashboard
	bt_wb_dashboard_new_requisition BIGINT NOT NULL DEFAULT 0,
	bt_wb_dashboard_ocr_entry BIGINT NOT NULL DEFAULT 0,
	card_wb_dashboard_alert BIGINT NOT NULL DEFAULT 0,
	link_wb_dashboard_build_with_ai BIGINT NOT NULL DEFAULT 0,
	link_wb_dashboard_view_history BIGINT NOT NULL DEFAULT 0,
	-- WEB · Requisição
	select_wb_requisition_type BIGINT NOT NULL DEFAULT 0,
	chip_wb_requisition_reason_restock BIGINT NOT NULL DEFAULT 0,
	chip_wb_requisition_reason_expiry BIGINT NOT NULL DEFAULT 0,
	chip_wb_requisition_reason_damaged_packaging BIGINT NOT NULL DEFAULT 0,
	chip_wb_requisition_reason_consumption BIGINT NOT NULL DEFAULT 0,
	radio_wb_requisition_channel_whatsapp BIGINT NOT NULL DEFAULT 0,
	radio_wb_requisition_channel_email BIGINT NOT NULL DEFAULT 0,
	bt_wb_requisition_send BIGINT NOT NULL DEFAULT 0,
	link_wb_requisition_view_all BIGINT NOT NULL DEFAULT 0,
	card_wb_requisition_pending_item BIGINT NOT NULL DEFAULT 0,
	card_wb_requisition_build_with_ai BIGINT NOT NULL DEFAULT 0,
	-- WEB · Estoque
	bt_wb_stock_sort BIGINT NOT NULL DEFAULT 0,
	card_wb_stock_product BIGINT NOT NULL DEFAULT 0,
	card_wb_stock_add_product BIGINT NOT NULL DEFAULT 0,
	-- WEB · Overlay Ordenar
	radio_wb_sort_expiry BIGINT NOT NULL DEFAULT 0,
	radio_wb_sort_alphabetical BIGINT NOT NULL DEFAULT 0,
	radio_wb_sort_category BIGINT NOT NULL DEFAULT 0,
	-- WEB · Overlay Calendário
	icon_wb_calendar_previous BIGINT NOT NULL DEFAULT 0,
	icon_wb_calendar_next BIGINT NOT NULL DEFAULT 0,
	bt_wb_calendar_day BIGINT NOT NULL DEFAULT 0,
	-- WEB · Overlay Chatbot
	icon_wb_chatbot_close BIGINT NOT NULL DEFAULT 0,
	chip_wb_chatbot_suggestion_expiring_products BIGINT NOT NULL DEFAULT 0,
	chip_wb_chatbot_suggestion_below_minimum BIGINT NOT NULL DEFAULT 0,
	chip_wb_chatbot_suggestion_build_requisition BIGINT NOT NULL DEFAULT 0,
	bt_wb_chatbot_build_requisition_restock BIGINT NOT NULL DEFAULT 0,
	icon_wb_chatbot_send BIGINT NOT NULL DEFAULT 0,
	-- WEB · Overlay Notificações
	card_wb_notifications_item BIGINT NOT NULL DEFAULT 0,
	link_wb_notifications_mark_all_read BIGINT NOT NULL DEFAULT 0,
	link_wb_notifications_view_all BIGINT NOT NULL DEFAULT 0,
	-- WEB · Histórico
	tab_wb_history_withdrawals BIGINT NOT NULL DEFAULT 0,
	tab_wb_history_requests BIGINT NOT NULL DEFAULT 0,
	filter_wb_history_all BIGINT NOT NULL DEFAULT 0,
	filter_wb_history_under_review BIGINT NOT NULL DEFAULT 0,
	filter_wb_history_approved BIGINT NOT NULL DEFAULT 0,
	filter_wb_history_rejected BIGINT NOT NULL DEFAULT 0,
	filter_wb_history_canceled BIGINT NOT NULL DEFAULT 0,
	icon_wb_history_expand_requisition BIGINT NOT NULL DEFAULT 0,
	-- WEB · Fornecedores
	bt_wb_suppliers_new_supplier BIGINT NOT NULL DEFAULT 0,
	card_wb_suppliers_new_supplier BIGINT NOT NULL DEFAULT 0,
	card_wb_suppliers_supplier BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_all BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_dry BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_fruits BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_vegetables BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_greens BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_meat BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_chicken BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_fish BIGINT NOT NULL DEFAULT 0,
	filter_wb_suppliers_sweets BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos
	tab_wb_products_catalog BIGINT NOT NULL DEFAULT 0,
	tab_wb_products_categories_units BIGINT NOT NULL DEFAULT 0,
	bt_wb_products_new_product BIGINT NOT NULL DEFAULT 0,
	select_wb_products_category_filter BIGINT NOT NULL DEFAULT 0,
	filter_wb_products_status_all BIGINT NOT NULL DEFAULT 0,
	filter_wb_products_status_active BIGINT NOT NULL DEFAULT 0,
	filter_wb_products_status_inactive BIGINT NOT NULL DEFAULT 0,
	icon_wb_products_edit BIGINT NOT NULL DEFAULT 0,
	icon_wb_products_more_actions BIGINT NOT NULL DEFAULT 0,
	page_wb_products_previous BIGINT NOT NULL DEFAULT 0,
	page_wb_products_number BIGINT NOT NULL DEFAULT 0,
	page_wb_products_next BIGINT NOT NULL DEFAULT 0,
	select_wb_products_items_per_page BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Estados
	bt_wb_products_clear_filters BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Detalhes e novo produto
	icon_wb_product_back BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Detalhes
	bt_wb_product_deactivate BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_edit BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_change_photo BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_remove_photo BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_link_supplier BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_save_parameters BIGINT NOT NULL DEFAULT 0,
	link_wb_product_view_batches BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Novo produto
	select_wb_product_new_category BIGINT NOT NULL DEFAULT 0,
	select_wb_product_new_unit BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_new_choose_photo BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_new_cancel BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_new_save BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Categorias e unidades
	bt_wb_categories_new_category BIGINT NOT NULL DEFAULT 0,
	icon_wb_categories_edit BIGINT NOT NULL DEFAULT 0,
	icon_wb_categories_delete BIGINT NOT NULL DEFAULT 0,
	icon_wb_categories_error_close BIGINT NOT NULL DEFAULT 0,
	bt_wb_units_new_unit BIGINT NOT NULL DEFAULT 0,
	icon_wb_units_edit BIGINT NOT NULL DEFAULT 0,
	icon_wb_units_delete BIGINT NOT NULL DEFAULT 0,
	bt_wb_units_cancel BIGINT NOT NULL DEFAULT 0,
	bt_wb_units_save BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Estados
	bt_wb_product_photo_retry BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_photo_continue_without_photo BIGINT NOT NULL DEFAULT 0,
	-- WEB · Produtos · Confirmar desativação
	bt_wb_product_deactivation_cancel BIGINT NOT NULL DEFAULT 0,
	bt_wb_product_deactivation_confirm BIGINT NOT NULL DEFAULT 0,
	-- WEB · Estados
	bt_wb_state_clear_search BIGINT NOT NULL DEFAULT 0,
	bt_wb_state_retry BIGINT NOT NULL DEFAULT 0,
	bt_wb_state_create_kitchen BIGINT NOT NULL DEFAULT 0,
	-- WEB · Acessibilidade
	bt_wb_accessibility_restore_default BIGINT NOT NULL DEFAULT 0,
	bt_wb_accessibility_save_preferences BIGINT NOT NULL DEFAULT 0,
	bt_wb_accessibility_font_size_minus BIGINT NOT NULL DEFAULT 0,
	bt_wb_accessibility_font_size_plus BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_font_size_default BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_font_size_medium BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_font_size_large BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_font_size_extra_large BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_dyslexia_font BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_reading_ruler BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_high_contrast BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_vlibras BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_voice_reading BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_reduce_animations BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_large_cursor BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_voice_control BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_eye_tracking BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_keyboard_focus BIGINT NOT NULL DEFAULT 0,
	toggle_wb_accessibility_visual_alerts BIGINT NOT NULL DEFAULT 0,
	select_wb_accessibility_dyslexia_font_family BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_ruler_color_yellow BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_ruler_color_purple BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_ruler_color_gray BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_contrast_dark BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_contrast_light_reinforced BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_contrast_yellow_on_black BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_colorblind_none BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_colorblind_protanopia BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_colorblind_deuteranopia BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_colorblind_tritanopia BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_vlibras_position_bottom_right BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_vlibras_position_bottom_left BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_reading_on_focus BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_reading_on_hover BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_reading_full_screen BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_animations_reduce BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_animations_remove_all BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_size_medium BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_size_large BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_size_extra_large BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_color_purple BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_color_yellow BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_color_black BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_cursor_color_white BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_command_open_stock BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_command_back BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_command_search_rice BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_voice_command_open_requisitions BIGINT NOT NULL DEFAULT 0,
	bt_wb_accessibility_calibrate_camera BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_focus_style_default BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_focus_style_reinforced BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_alert_style_banner BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_alert_style_icon_color BIGINT NOT NULL DEFAULT 0,
	chip_wb_accessibility_alert_style_banner_icon BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · GLOBAL
	nav_mb_global_requisitions BIGINT NOT NULL DEFAULT 0,
	nav_mb_global_suppliers BIGINT NOT NULL DEFAULT 0,
	nav_mb_global_home BIGINT NOT NULL DEFAULT 0,
	nav_mb_global_stock BIGINT NOT NULL DEFAULT 0,
	nav_mb_global_profile BIGINT NOT NULL DEFAULT 0,
	fab_mb_global_ocr_entry BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Tela de Login
	bt_mb_login_sign_in BIGINT NOT NULL DEFAULT 0,
	bt_mb_login_google BIGINT NOT NULL DEFAULT 0,
	link_mb_login_forgot_password BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Tela de Cadastro
	bt_mb_signup_role_supervisor BIGINT NOT NULL DEFAULT 0,
	bt_mb_signup_role_stockist BIGINT NOT NULL DEFAULT 0,
	bt_mb_signup_create BIGINT NOT NULL DEFAULT 0,
	link_mb_signup_have_account BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Tela Inicial
	icon_mb_home_notifications BIGINT NOT NULL DEFAULT 0,
	card_mb_home_priority_product BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Notificações
	icon_mb_notifications_back BIGINT NOT NULL DEFAULT 0,
	chip_mb_notifications_all BIGINT NOT NULL DEFAULT 0,
	chip_mb_notifications_alerts BIGINT NOT NULL DEFAULT 0,
	chip_mb_notifications_info BIGINT NOT NULL DEFAULT 0,
	chip_mb_notifications_orders BIGINT NOT NULL DEFAULT 0,
	card_mb_notifications_item BIGINT NOT NULL DEFAULT 0,
	link_mb_notifications_view_all BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Chatbot
	icon_mb_chatbot_back BIGINT NOT NULL DEFAULT 0,
	icon_mb_chatbot_menu BIGINT NOT NULL DEFAULT 0,
	chip_mb_chatbot_suggestion_expiring_this_week BIGINT NOT NULL DEFAULT 0,
	chip_mb_chatbot_suggestion_below_minimum BIGINT NOT NULL DEFAULT 0,
	chip_mb_chatbot_suggestion_best_supplier BIGINT NOT NULL DEFAULT 0,
	icon_mb_chatbot_send BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Busca de cozinhas
	icon_mb_kitchens_close BIGINT NOT NULL DEFAULT 0,
	icon_mb_kitchens_filter BIGINT NOT NULL DEFAULT 0,
	tab_mb_kitchens_list BIGINT NOT NULL DEFAULT 0,
	tab_mb_kitchens_map BIGINT NOT NULL DEFAULT 0,
	bt_mb_kitchens_request_entry BIGINT NOT NULL DEFAULT 0,
	icon_mb_kitchens_map_pin BIGINT NOT NULL DEFAULT 0,
	card_mb_kitchens_map_card BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Solicitação enviada
	bt_mb_kitchens_got_it BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Criar cozinha
	icon_mb_kitchen_create_close BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Criar e editar cozinha
	chip_mb_kitchen_type_headquarters BIGINT NOT NULL DEFAULT 0,
	chip_mb_kitchen_type_branch BIGINT NOT NULL DEFAULT 0,
	chip_mb_kitchen_type_restaurant BIGINT NOT NULL DEFAULT 0,
	chip_mb_kitchen_type_industrial_kitchen BIGINT NOT NULL DEFAULT 0,
	chip_mb_kitchen_type_bakery BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Criar cozinha
	bt_mb_kitchen_create_create BIGINT NOT NULL DEFAULT 0,
	bt_mb_kitchen_create_cancel BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Editar cozinha
	icon_mb_kitchen_edit_back BIGINT NOT NULL DEFAULT 0,
	bt_mb_kitchen_edit_save BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Gerenciar membros
	icon_mb_members_close BIGINT NOT NULL DEFAULT 0,
	bt_mb_members_approve BIGINT NOT NULL DEFAULT 0,
	bt_mb_members_reject BIGINT NOT NULL DEFAULT 0,
	select_mb_members_role BIGINT NOT NULL DEFAULT 0,
	bt_mb_members_remove BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Estoque
	icon_mb_stock_filter BIGINT NOT NULL DEFAULT 0,
	chip_mb_stock_category_all BIGINT NOT NULL DEFAULT 0,
	chip_mb_stock_category_meats BIGINT NOT NULL DEFAULT 0,
	chip_mb_stock_category_dairy BIGINT NOT NULL DEFAULT 0,
	chip_mb_stock_category_frozen BIGINT NOT NULL DEFAULT 0,
	card_mb_stock_product BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Estoque · Filtros
	link_mb_stock_filter_clear BIGINT NOT NULL DEFAULT 0,
	radio_mb_stock_filter_sort_name BIGINT NOT NULL DEFAULT 0,
	radio_mb_stock_filter_sort_expiry BIGINT NOT NULL DEFAULT 0,
	radio_mb_stock_filter_sort_quantity BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_category_grains BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_category_dairy BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_category_meats BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_category_drinks BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_category_cleaning BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_status_expiring_soon BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_status_expired BIGINT NOT NULL DEFAULT 0,
	filter_mb_stock_filter_status_on_time BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Produto
	icon_mb_product_back BIGINT NOT NULL DEFAULT 0,
	link_mb_product_view_all_batches BIGINT NOT NULL DEFAULT 0,
	card_mb_product_batch BIGINT NOT NULL DEFAULT 0,
	bt_mb_product_history_entries BIGINT NOT NULL DEFAULT 0,
	bt_mb_product_history_exits BIGINT NOT NULL DEFAULT 0,
	bt_mb_product_edit BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Ver lotes
	icon_mb_batches_back BIGINT NOT NULL DEFAULT 0,
	card_mb_batches_batch BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Dar baixa
	icon_mb_write_off_back BIGINT NOT NULL DEFAULT 0,
	icon_mb_write_off_quantity_minus BIGINT NOT NULL DEFAULT 0,
	icon_mb_write_off_quantity_plus BIGINT NOT NULL DEFAULT 0,
	bt_mb_write_off_confirm BIGINT NOT NULL DEFAULT 0,
	bt_mb_write_off_cancel BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Scan OCR
	icon_mb_ocr_back BIGINT NOT NULL DEFAULT 0,
	icon_mb_ocr_flash BIGINT NOT NULL DEFAULT 0,
	bt_mb_ocr_scan BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Revisar entrada
	icon_mb_ocr_review_back BIGINT NOT NULL DEFAULT 0,
	icon_mb_ocr_review_quantity_minus BIGINT NOT NULL DEFAULT 0,
	icon_mb_ocr_review_quantity_plus BIGINT NOT NULL DEFAULT 0,
	select_mb_ocr_review_expiry_date BIGINT NOT NULL DEFAULT 0,
	select_mb_ocr_review_supplier BIGINT NOT NULL DEFAULT 0,
	bt_mb_ocr_review_insert BIGINT NOT NULL DEFAULT 0,
	bt_mb_ocr_review_cancel BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Requisições
	tab_mb_requisitions_pending BIGINT NOT NULL DEFAULT 0,
	tab_mb_requisitions_history BIGINT NOT NULL DEFAULT 0,
	bt_mb_requisitions_approve BIGINT NOT NULL DEFAULT 0,
	bt_mb_requisitions_reject BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Solicitar compra
	icon_mb_purchase_back BIGINT NOT NULL DEFAULT 0,
	icon_mb_purchase_quantity_minus BIGINT NOT NULL DEFAULT 0,
	icon_mb_purchase_quantity_plus BIGINT NOT NULL DEFAULT 0,
	select_mb_purchase_supplier BIGINT NOT NULL DEFAULT 0,
	bt_mb_purchase_confirm BIGINT NOT NULL DEFAULT 0,
	bt_mb_purchase_cancel BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Fornecedores
	icon_mb_suppliers_filter BIGINT NOT NULL DEFAULT 0,
	card_mb_suppliers_supplier BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Fornecedor
	icon_mb_supplier_back BIGINT NOT NULL DEFAULT 0,
	link_mb_supplier_phone BIGINT NOT NULL DEFAULT 0,
	link_mb_supplier_email BIGINT NOT NULL DEFAULT 0,
	link_mb_supplier_address BIGINT NOT NULL DEFAULT 0,
	card_mb_supplier_product BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Perfil
	bt_mb_profile_profile_data BIGINT NOT NULL DEFAULT 0,
	bt_mb_profile_view_members BIGINT NOT NULL DEFAULT 0,
	bt_mb_profile_kitchen_info BIGINT NOT NULL DEFAULT 0,
	bt_mb_profile_preferences BIGINT NOT NULL DEFAULT 0,
	bt_mb_profile_logout BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Dados do perfil
	bt_mb_profile_data_save BIGINT NOT NULL DEFAULT 0,
	bt_mb_profile_data_discard BIGINT NOT NULL DEFAULT 0,
	-- MOBILE · Preferências
	toggle_mb_preferences_notify_expiring BIGINT NOT NULL DEFAULT 0,
	toggle_mb_preferences_notify_below_minimum BIGINT NOT NULL DEFAULT 0,
	chip_mb_preferences_theme_light BIGINT NOT NULL DEFAULT 0,
	chip_mb_preferences_theme_dark BIGINT NOT NULL DEFAULT 0,
	chip_mb_preferences_theme_system BIGINT NOT NULL DEFAULT 0,
	link_mb_preferences_language BIGINT NOT NULL DEFAULT 0,
	PRIMARY KEY (id_counter)
);

-- ---------------------------------------------------
-- UI CLICK COUNTER CHECK CONSTRAINTS
-- ---------------------------------------------------

-- garante a linha única: qualquer outro id_counter é recusado
ALTER TABLE tb_ui_click_counter
ADD CONSTRAINT ck_uiclickcounter_single
CHECK (id_counter = 1);
