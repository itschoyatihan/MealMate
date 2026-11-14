/**
 * PostgreSQL connection pool (node-postgres / `pg`).
 *
 * - A single Pool is shared by every model; requests borrow and release
 *   connections automatically through `query`.
 * - `withTransaction` runs a unit of work on one dedicated client so plan and
 *   expense replacements are all-or-nothing.
 * - Type parsers keep the API stable: DATE columns return 'YYYY-MM-DD'
 *   strings (no timezone shifting) and BIGINT aggregates return numbers.
 */

const { Pool, types } = require('pg');
const { env } = require('./env');

// DATE (OID 1082) -> 'YYYY-MM-DD' string instead of a local-midnight Date.
types.setTypeParser(1082, (value) => value);
// BIGINT (OID 20) -> Number for COUNT()/SUM() results (safe for our ranges).
types.setTypeParser(20, (value) => Number.parseInt(value, 10));

const pool = new Pool({
  connectionString: env.databaseUrl,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  ssl: env.pgSsl ? { rejectUnauthorized: false } : undefined,
});

let connected = false;

pool.on('error', (err) => {
  connected = false;
  console.error(`[db] PostgreSQL pool error: ${err.message}`);
});

/** Open the pool and verify the connection before the server starts. */
async function connectDatabase() {
  const client = await pool.connect();
  try {
    const { rows } = await client.query('SELECT current_database() AS name');
    connected = true;
    console.log(`[db] PostgreSQL connected: ${rows[0].name}`);
  } finally {
    client.release();
  }
  return pool;
}

async function disconnectDatabase() {
  await pool.end();
  connected = false;
}

/** Run one parameterized query on the shared pool. */
function query(text, params) {
  return pool.query(text, params);
}

/**
 * Run `work(client)` inside BEGIN/COMMIT on a dedicated connection.
 * Any thrown error rolls the whole unit back.
 */
async function withTransaction(work) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error(`[db] Rollback failed: ${rollbackErr.message}`);
    }
    throw err;
  } finally {
    client.release();
  }
}

function getDatabaseStatus() {
  return connected ? 'connected' : 'disconnected';
}

module.exports = {
  pool,
  connectDatabase,
  disconnectDatabase,
  query,
  withTransaction,
  getDatabaseStatus,
};
