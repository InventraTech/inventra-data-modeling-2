// Remove os índices criados por create_indexes.js (o _id_ fica).
const dbi = db.getSiblingDB(process.env.MONGO_DB || 'dbIAI');

const drop = (coll, name) => {
  if (dbi[coll].getIndexes().some((i) => i.name === name)) dbi[coll].dropIndex(name);
};
drop('sessions', 'session_id_1');
drop('sessions', 'user_id_1_started_at_-1');
drop('metrics', 'timestamp_-1');
