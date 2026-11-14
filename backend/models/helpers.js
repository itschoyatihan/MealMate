/**
 * Small shared helpers for the SQL model layer.
 */

const { query } = require('../config/db');

/**
 * Run a query either on a transaction client or on the shared pool.
 * Model functions accept an optional client so multi-table writes can be
 * composed inside one transaction (guest transfer, plan/expense replaces).
 */
function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

/** Escape LIKE/ILIKE wildcards in user-supplied search text. */
function escapeLike(value) {
  return value.replace(/[\\%_]/g, '\\$&');
}

module.exports = { run, escapeLike };
