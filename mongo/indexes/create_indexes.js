// Índices do dbIAI. Os nomes repetem o padrão do driver (campo_ordem) porque a IAI
// também chama create_index no startup: nome diferente para a mesma chave gera erro.
// Uso: mongosh "$MONGO_URI" --file indexes/create_indexes.js
const dbi = db.getSiblingDB(process.env.MONGO_DB || 'dbIAI');

// sessions: sessão ativa por session_id (doc_id_da_sessao)
dbi.sessions.createIndex({ session_id: 1 }, { name: 'session_id_1' });
// sessions: histórico do usuário, mais recente primeiro (recuperar_historico)
dbi.sessions.createIndex({ user_id: 1, started_at: -1 }, { name: 'user_id_1_started_at_-1' });

// metrics: janela de 7/30 dias de GET /metrics
dbi.metrics.createIndex({ timestamp: -1 }, { name: 'timestamp_-1' });
