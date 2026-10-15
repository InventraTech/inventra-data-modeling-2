// V001: coleções do dbIAI (chat e métricas da IA) com validador $jsonSchema e índices.
// Idempotente: cria a coleção ou atualiza o validador com collMod; createIndex não duplica.
// Uso: mongosh "$MONGO_URI" --file migrations/V001__init_dbiai.js
// O contrato de cada documento também está em schemas/*.schema.json (tests/check_dictionary_sync.js compara).
const dbi = db.getSiblingDB(process.env.MONGO_DB || 'dbIAI');

// moderate + warn: documento fora do contrato é aceito e registrado no log do mongod.
// A IAI grava o chat no meio da resposta e ainda está evoluindo o formato (branch INV2-42);
// Campo extra é sempre aceito; com "error", um campo renomeado (ex.: timestamp -> created_at)
// derrubaria a conversa antes de o contrato ser atualizado aqui.
function ensureCollection(name, schema) {
  const options = { validator: { $jsonSchema: schema }, validationLevel: 'moderate', validationAction: 'warn' };
  if (dbi.getCollectionNames().includes(name)) {
    dbi.runCommand({ collMod: name, ...options });
  } else {
    dbi.createCollection(name, options);
  }
}

ensureCollection('sessions', {
  "bsonType": "object",
  "title": "dbIAI.sessions",
  "description": "Uma conversa do chat da IA. Ativa enquanto summary está vazio; /chat/encerrar grava o resumo e fecha a sessão.",
  "required": [
    "_id",
    "session_id",
    "user_id",
    "started_at",
    "updated_at",
    "summary",
    "messages"
  ],
  "properties": {
    "_id": {
      "bsonType": "string",
      "description": "UUID v4 gerado pela IAI (doc_id devolvido em /chat/historico)"
    },
    "session_id": {
      "bsonType": "string",
      "description": "Identificador da conversa enviado pelo app; pode se repetir entre sessões encerradas"
    },
    "user_id": {
      "bsonType": "string",
      "description": "Dono da conversa; isola o histórico (tool buscar_historico)"
    },
    "started_at": {
      "bsonType": "date"
    },
    "updated_at": {
      "bsonType": "date"
    },
    "summary": {
      "bsonType": "string",
      "description": "Resumo gerado pelo LLM ao encerrar; vazio = sessão ativa"
    },
    "messages": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": [
          "role",
          "content"
        ],
        "properties": {
          "role": {
            "enum": [
              "human",
              "iai",
              "judge"
            ],
            "description": "judge = reprovação do juiz, só para auditoria"
          },
          "content": {
            "bsonType": "string",
            "description": "Texto já anonimizado (e-mail, CPF, RG e telefone viram tokens)"
          },
          "confianca": {
            "bsonType": [
              "double",
              "int"
            ],
            "minimum": 0,
            "maximum": 1,
            "description": "Só em role = judge"
          }
        }
      }
    }
  }
});

ensureCollection('metrics', {
  "bsonType": "object",
  "title": "dbIAI.metrics",
  "description": "Um documento por requisição de /chat (ColetorMetricas). Não guarda o texto do prompt.",
  "required": [
    "timestamp",
    "session_id",
    "user_id",
    "latencia_total_ms",
    "status",
    "nos",
    "chamadas",
    "tokens_entrada",
    "tokens_saida",
    "custo_usd",
    "erros_componentes",
    "resolvida",
    "agentes_chamados"
  ],
  "properties": {
    "timestamp": {
      "bsonType": "date",
      "description": "Janela de GET /metrics (7 ou 30 dias)"
    },
    "session_id": {
      "bsonType": "string"
    },
    "user_id": {
      "bsonType": "string"
    },
    "latencia_total_ms": {
      "bsonType": [
        "double",
        "int"
      ],
      "minimum": 0
    },
    "status": {
      "enum": [
        "ok",
        "bloqueado",
        "erro"
      ],
      "description": "bloqueado = guardrail de entrada recusou; não conta como erro"
    },
    "nos": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": [
          "no",
          "ms",
          "erro"
        ],
        "properties": {
          "no": {
            "bsonType": "string",
            "description": "Nó do grafo LangGraph"
          },
          "ms": {
            "bsonType": [
              "double",
              "int"
            ],
            "minimum": 0
          },
          "erro": {
            "bsonType": "bool"
          }
        }
      }
    },
    "chamadas": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": [
          "modelo",
          "tokens_entrada",
          "tokens_saida",
          "custo_usd",
          "latencia_ms"
        ],
        "properties": {
          "modelo": {
            "bsonType": "string"
          },
          "tokens_entrada": {
            "bsonType": [
              "int",
              "long"
            ],
            "minimum": 0
          },
          "tokens_saida": {
            "bsonType": [
              "int",
              "long"
            ],
            "minimum": 0
          },
          "custo_usd": {
            "bsonType": [
              "double",
              "int"
            ],
            "minimum": 0
          },
          "latencia_ms": {
            "bsonType": [
              "double",
              "int"
            ],
            "minimum": 0
          }
        }
      }
    },
    "tokens_entrada": {
      "bsonType": [
        "int",
        "long"
      ],
      "minimum": 0
    },
    "tokens_saida": {
      "bsonType": [
        "int",
        "long"
      ],
      "minimum": 0
    },
    "custo_usd": {
      "bsonType": [
        "double",
        "int"
      ],
      "minimum": 0
    },
    "erros_componentes": {
      "bsonType": "array",
      "items": {
        "bsonType": "string"
      },
      "description": "llm:*, tool:*, chain:*"
    },
    "resolvida": {
      "bsonType": "bool",
      "description": "Especialista respondeu e o juiz aprovou"
    },
    "agentes_chamados": {
      "bsonType": "array",
      "items": {
        "bsonType": "string"
      }
    }
  }
});

dbi.sessions.createIndex({ session_id: 1 }, { name: 'session_id_1' });
dbi.sessions.createIndex({ user_id: 1, started_at: -1 }, { name: 'user_id_1_started_at_-1' });
dbi.metrics.createIndex({ timestamp: -1 }, { name: 'timestamp_-1' });

dbi.schema_migrations.updateOne(
  { _id: 'V001' },
  { $set: { description: 'init_dbiai' }, $setOnInsert: { applied_at: new Date() } },
  { upsert: true }
);
