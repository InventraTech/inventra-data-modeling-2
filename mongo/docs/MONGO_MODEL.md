# Modelo MongoDB (`dbIAI`)

Banco de documentos da IA do Inventra ([`inventra-artificial-intelligence-2`](https://github.com/InventraTech/inventra-artificial-intelligence-2)). Guarda o log das conversas do chat e as métricas de cada requisição. Não guarda nada do estoque: a IA consulta o PostgreSQL pela API Spring.

| | |
|---|---|
| **Banco** | `dbIAI` (variável `MONGO_CONNECTION` na IAI) |
| **Coleções** | `sessions`, `metrics` (+ `schema_migrations`, controle desta esteira) |
| **Quem escreve** | `iai/app/memory.py` (sessions) e `iai/app/metrics.py` (metrics) |
| **Contrato** | `$jsonSchema` em `schemas/*.schema.json`, aplicado por `migrations/V001__init_dbiai.js` |

## Por que documento e não tabela

Uma conversa é lida e escrita sempre inteira: o app abre a sessão, empilha mensagens e no fim gera um resumo. As mensagens não são consultadas fora da sessão e o formato delas muda com o grafo de agentes (o juiz, por exemplo, grava `confianca`). Guardar a sessão como um documento com o array `messages` embutido evita join e migração a cada mudança do grafo. As métricas seguem o mesmo raciocínio: cada requisição gera um documento com listas de nós e de chamadas de LLM de tamanho variável.

## `sessions`

Uma conversa. Fica **ativa** enquanto `summary` está vazio; `POST /chat/encerrar` gera o resumo via LLM e fecha a sessão. Um `session_id` pode se repetir: cada encerramento separa uma sessão da próxima.

| Campo | Tipo | Regra |
|-------|------|-------|
| `_id` | string | UUID v4 gerado pela IAI; é o `doc_id` devolvido em `/chat/historico` |
| `session_id` | string | Identificador da conversa enviado pelo app |
| `user_id` | string | Dono da conversa. Deve ser o `tb_user.id_user` (UUID) do PostgreSQL; hoje a IAI aceita o valor informado pelo chamador |
| `started_at` / `updated_at` | date | UTC |
| `summary` | string | Vazio = sessão ativa |
| `messages[]` | array | `{role, content, confianca?}` |
| `messages[].role` | enum | `human` (usuário), `iai` (resposta final), `judge` (reprovação do juiz, só auditoria) |
| `messages[].content` | string | Texto **já anonimizado** pelo guardrail (e-mail, CPF, RG e telefone viram tokens) |
| `messages[].confianca` | number 0–1 | Só em `role = judge` |

```json
{
  "_id": "6f1c0a4e-6a51-4a3e-9d0c-1b7e2f9a8c11",
  "session_id": "app-3f9a1c2b7d4e",
  "user_id": "0b9c7f8e-2d1a-4c3b-9e8f-7a6b5c4d3e2f",
  "started_at": { "$date": "2026-10-10T13:02:11Z" },
  "updated_at": { "$date": "2026-10-10T13:05:40Z" },
  "summary": "Usuário consultou o estoque de tomate e os lotes que vencem na semana.",
  "messages": [
    { "role": "human", "content": "quantos kg de tomate temos?" },
    { "role": "judge", "content": "Resposta sem fato correspondente nas tools.", "confianca": 0.4 },
    { "role": "iai", "content": "Há 12,5 kg de tomate em 2 lotes." }
  ]
}
```

## `metrics`

Um documento por requisição de `/chat`, gravado pelo `ColetorMetricas`. O texto do prompt **não** é guardado. `GET /metrics` agrega a janela de 7 ou 30 dias.

| Campo | Tipo | Regra |
|-------|------|-------|
| `timestamp` | date | Momento da requisição (UTC) |
| `session_id`, `user_id` | string | Mesmos valores da sessão |
| `latencia_total_ms` | number ≥ 0 | |
| `status` | enum | `ok`, `bloqueado` (guardrail de entrada recusou, não é erro), `erro` (exceção) |
| `nos[]` | array | `{no, ms, erro}` por nó do grafo |
| `chamadas[]` | array | `{modelo, tokens_entrada, tokens_saida, custo_usd, latencia_ms}` por chamada de LLM |
| `tokens_entrada`, `tokens_saida`, `custo_usd` | number ≥ 0 | Somas de `chamadas[]` |
| `erros_componentes[]` | string[] | `llm:*`, `tool:*`, `chain:*`, inclusive os recuperados por fallback |
| `resolvida` | bool | Um especialista respondeu e o juiz aprovou |
| `agentes_chamados[]` | string[] | Ex.: `guardrail_insulto:aprovado`, `estoquista`, `juiz:aprovado` |

## Índices

| Coleção | Índice | Consulta atendida |
|---------|--------|-------------------|
| `sessions` | `session_id_1` | Sessão ativa de um `session_id` (`doc_id_da_sessao`) |
| `sessions` | `user_id_1_started_at_-1` | Histórico do usuário, mais recente primeiro (`recuperar_historico`, tool `buscar_historico`) |
| `metrics` | `timestamp_-1` | Janela de `GET /metrics` |

Os nomes seguem o padrão do driver porque a IAI também chama `create_index` no startup. Se o nome fosse outro para a mesma chave, o MongoDB recusaria o índice da aplicação.

## Validação

As duas coleções têm validador `$jsonSchema` com `validationLevel: moderate` e `validationAction: warn`:

- campo a mais é sempre aceito (o schema não usa `additionalProperties: false`);
- documento fora do contrato é **gravado** e o `mongod` registra um aviso no log. A IAI grava o chat no meio da resposta, e um campo renomeado não pode derrubar a conversa antes de o contrato ser atualizado aqui;
- para auditar, a mesma consulta que o seed usa no final lista o que está fora do contrato:

```js
const v = db.getCollectionInfos({ name: 'metrics' })[0].options.validator;
db.metrics.find({ $nor: [v] });
```

Quando o formato estabilizar, a troca para `validationAction: error` é uma migration nova com `collMod`.

## Retenção e privacidade

- Nenhuma coleção tem TTL. As sessões são o histórico de longo prazo da IA (a tool `buscar_historico` lê os resumos), então não devem expirar sem uma decisão de produto.
- `metrics` cresce um documento por mensagem e `GET /metrics` só lê 30 dias. Uma retenção de 90 dias pode ser feita convertendo o índice existente em TTL, sem criar outro: `db.runCommand({ collMod: 'metrics', index: { name: 'timestamp_-1', expireAfterSeconds: 7776000 } })`. Fica como decisão do time, em migration própria.
- `content` já chega anonimizado; o `user_id` é o único identificador pessoal. A exclusão de um usuário no PostgreSQL deve ser acompanhada de `db.sessions.deleteMany({ user_id })` e `db.metrics.deleteMany({ user_id })`.

## Esteira

| Pasta | Papel |
|-------|-------|
| `schemas/` | Contrato de cada coleção em JSON Schema (dicionário). `rollback/remove_validators.js` tira os validadores sem apagar dados |
| `indexes/` | `create_indexes.js` (dicionário) + `rollback/drop_indexes.js` |
| `migrations/` | `V001__init_dbiai.js`, idempotente (`createCollection` ou `collMod`; `createIndex` não duplica). `rollback/drop_everything.js` apaga as coleções |
| `seeds/` | `seed.ipynb`: conversas e métricas fictícias, com `user_id` lidos de `tb_user` quando o PostgreSQL está no `.env` |
| `tests/` | `check_migrations.sh`: aplica 2×, valida contrato e índices, compara dicionário × migrations, rollback e reaplica |

Cada migration aplicada é registrada em `schema_migrations` (`_id = 'V001'`, `applied_at`).

```bash
cd mongo
for f in migrations/V*.js; do mongosh "$MONGO_CONNECTION" --file "$f"; done
```

`MONGO_DB` muda o banco alvo (padrão `dbIAI`). Os testes usam `dbIAI_ci` e apagam as coleções: nunca rodar contra o banco real.

## Mudanças em andamento na IAI

A branch `feat/INV2-42` da IAI (não mergeada) troca o modelo: sessões passam a ser identificadas por usuário + cozinha + `session_id` com índice único parcial em `active`, `metrics` passa a usar `created_at` e `kitchen_id`, e surgem as coleções `approvals` (propostas de ação aguardando o Supervisor, com auditoria embutida) e `notifications`. Quando ela entrar na `main`, o contrato muda em `V002__...js`, junto com a atualização de `schemas/`.
