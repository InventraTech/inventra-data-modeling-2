// Confere, depois das migrations, que cada coleção tem o validador esperado, os índices
// esperados e que o $jsonSchema separa documentos válidos dos inválidos.
// Os documentos de teste são removidos no final.
const dbi = db.getSiblingDB(process.env.MONGO_DB || 'dbIAI');
const failures = [];
const check = (ok, msg) => { if (!ok) failures.push(msg); };

const info = (name) => dbi.getCollectionInfos({ name })[0];
for (const name of ['sessions', 'metrics']) {
  const options = (info(name) || {}).options || {};
  check(options.validator && options.validator.$jsonSchema, `${name}: sem validador $jsonSchema`);
  check(options.validationLevel === 'moderate', `${name}: validationLevel = ${options.validationLevel}`);
  check(options.validationAction === 'warn', `${name}: validationAction = ${options.validationAction}`);
}

const expectedIndexes = {
  sessions: { session_id_1: { session_id: 1 }, 'user_id_1_started_at_-1': { user_id: 1, started_at: -1 } },
  metrics: { 'timestamp_-1': { timestamp: -1 } },
};
for (const [coll, indexes] of Object.entries(expectedIndexes)) {
  const actual = Object.fromEntries(dbi[coll].getIndexes().map((i) => [i.name, i.key]));
  for (const [name, key] of Object.entries(indexes)) {
    check(JSON.stringify(actual[name]) === JSON.stringify(key), `${coll}: índice ${name} ausente ou diferente`);
  }
}

// Formato gravado pela IAI (memory.py e metrics.py, branch main).
const now = new Date();
const validSession = {
  _id: 'ci-valid-session', session_id: 'ci', user_id: 'ci-user', started_at: now, updated_at: now, summary: '',
  messages: [
    { role: 'human', content: 'quantos tomates temos?' },
    { role: 'iai', content: 'Há 12 kg.' },
    { role: 'judge', content: 'sem fato de estoque', confianca: 0.4 },
  ],
};
const invalidSessions = [
  { _id: 'ci-bad-role', session_id: 'ci', user_id: 'ci-user', started_at: now, updated_at: now, summary: '',
    messages: [{ role: 'admin', content: 'x' }] },
  { _id: 'ci-bad-date', session_id: 'ci', user_id: 'ci-user', started_at: '2026-01-01', updated_at: now, summary: '', messages: [] },
  { _id: 'ci-no-user', session_id: 'ci', started_at: now, updated_at: now, summary: '', messages: [] },
];
const validMetric = {
  timestamp: now, session_id: 'ci', user_id: 'ci-user', latencia_total_ms: 812.4, status: 'ok',
  nos: [{ no: 'roteador', ms: 120.5, erro: false }],
  chamadas: [{ modelo: 'gemini-2.5-flash', tokens_entrada: 900, tokens_saida: 120, custo_usd: 0.00057, latencia_ms: 640.1 }],
  tokens_entrada: 900, tokens_saida: 120, custo_usd: 0.00057, erros_componentes: [], resolvida: true,
  agentes_chamados: ['roteador', 'estoquista', 'juiz:aprovado'], ci: true,
};
const invalidMetrics = [
  { ...validMetric, status: 'timeout' },
  { ...validMetric, custo_usd: -1 },
  { ...validMetric, resolvida: 'sim' },
];

dbi.sessions.insertMany([validSession, ...invalidSessions]);
dbi.metrics.insertMany([validMetric, ...invalidMetrics].map((m) => ({ ...m, ci: true })));

const schemaOf = (name) => info(name).options.validator;
const ciSessions = { _id: { $regex: '^ci-' } };
check(dbi.sessions.countDocuments({ ...ciSessions, $nor: [schemaOf('sessions')] }) === invalidSessions.length,
  'sessions: o validador não separou os documentos inválidos');
check(dbi.sessions.countDocuments({ _id: 'ci-valid-session', ...schemaOf('sessions') }) === 1,
  'sessions: documento válido reprovado');
check(dbi.metrics.countDocuments({ ci: true, $nor: [schemaOf('metrics')] }) === invalidMetrics.length,
  'metrics: o validador não separou os documentos inválidos');

dbi.sessions.deleteMany(ciSessions);
dbi.metrics.deleteMany({ ci: true });

check(dbi.schema_migrations.countDocuments({ _id: 'V001' }) === 1, 'schema_migrations: V001 não registrada');

if (failures.length) {
  failures.forEach((f) => print(`FALHA: ${f}`));
  quit(1);
}
print('validadores e índices OK');
