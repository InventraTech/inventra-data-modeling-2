# Regras de Negócio no Banco

Functions, procedures e triggers que implementam as regras do Inventra direto no PostgreSQL. Definidos em `migrations/V002__business_rules.sql` (negócio) e `migrations/V003__audit_logs.sql` (auditoria).

## Functions de negócio

Arquivo: `functions/create_functions.sql`. São regras automáticas, disparadas por trigger e não chamadas diretamente.

| Function | Trigger que chama | O que faz |
|----------|--------------------|-----------|
| `fn_validate_stock` | `trg_validate_stock` | Impede `current_quantity` negativo em `tb_stock_batch` |
| `fn_update_batch_status` | `trg_update_batch_status` | Marca o lote como `WRITTEN_OFF` quando a quantidade chega a zero |
| `fn_calculate_divergence` | `trg_calculate_divergence` | Calcula `divergence` (física − registrada) em `tb_inventory_count` |
| `fn_requisition_approval` | `trg_requisition_approval` | Preenche `approved_at` quando o status muda para `APPROVED` |
| `fn_stock_alert` | `trg_stock_alert` | Cria alerta `STOCK` (`HIGH`) quando a soma dos lotes ativos e não vencidos fica **abaixo** do mínimo cadastrado; não duplica se já há um alerta `STOCK` não lido |
| `fn_expiration_alert` | `trg_expiration_alert` | Cria alerta quando um lote já passou da validade |

## Procedures

Arquivo: `procedures/create_procedures.sql`. Rotinas de negócio chamadas explicitamente via `CALL`.

| Procedure | O que faz |
|-----------|-----------|
| `sp_approve_requisition` | Aprova uma requisição que está em análise |
| `sp_reject_requisition` | Rejeita uma requisição em análise, com motivo |
| `sp_cancel_requisition` | Cancela requisição em análise ou já aprovada |
| `sp_register_stock_entry` | Registra entrada de quantidade num lote |
| `sp_write_off_stock` | Dá baixa de quantidade num lote (valida se há saldo suficiente) |
| `sp_close_inventory` | Fecha um inventário que está aberto |
| `sp_expire_batches` | Marca lotes vencidos como `EXPIRED` e gera os alertas (chamada diariamente pela API) |

## Triggers de negócio

Arquivo: `triggers/create_trg.sql`.

| Trigger | Tabela | Quando dispara | Function |
|---------|--------|-----------------|----------|
| `trg_validate_stock` | `tb_stock_batch` | BEFORE INSERT/UPDATE de `current_quantity` | `fn_validate_stock` |
| `trg_update_batch_status` | `tb_stock_batch` | BEFORE INSERT/UPDATE de `current_quantity`, `status` | `fn_update_batch_status` |
| `trg_calculate_divergence` | `tb_inventory_count` | BEFORE INSERT/UPDATE de `registered_quantity`, `physical_quantity` | `fn_calculate_divergence` |
| `trg_requisition_approval` | `tb_requisition` | BEFORE UPDATE de `status` | `fn_requisition_approval` |
| `trg_stock_alert` | `tb_stock_batch` | AFTER INSERT/UPDATE de `current_quantity` | `fn_stock_alert` |
| `trg_expiration_alert` | `tb_stock_batch` | AFTER INSERT/UPDATE de `expiration_date` | `fn_expiration_alert` |

## Auditoria

Functions em `functions/create_log_functions.sql` e triggers em `triggers/create_log_trg.sql`, uma dupla por tabela auditada:

| Tabela auditada | Function | Trigger | Destino |
|-----------------|----------|---------|---------|
| `tb_user` | `fn_log_user` | `trg_log_user` | `tb_log_user` |
| `tb_product` | `fn_log_product` | `trg_log_product` | `tb_log_product` |
| `tb_supplier` | `fn_log_supplier` | `trg_log_supplier` | `tb_log_supplier` |
| `tb_stock_batch` | `fn_log_stock_batch` | `trg_log_stock_batch` | `tb_log_stock_batch` |
| `tb_requisition` | `fn_log_requisition` | `trg_log_requisition` | `tb_log_requisition` |
| `tb_inventory` | `fn_log_inventory` | `trg_log_inventory` | `tb_log_inventory` |
| `tb_alert` | `fn_log_alert` | `trg_log_alert` | `tb_log_alert` |

Todas disparam **AFTER INSERT OR UPDATE OR DELETE** e gravam o registro inteiro (antes e depois, em JSON) usando `NEW`, `OLD`, `TG_OP` e `CURRENT_USER`. Veja [a herança das tabelas de log](ARCHITECTURE.md#herança-de-tabela-nas-tabelas-de-log).
