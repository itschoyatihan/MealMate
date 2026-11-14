/**
 * Schema initializer.
 *
 * Runs config/schema.sql on startup. Every statement is `IF NOT EXISTS`, so
 * this is safe to run repeatedly and keeps first-run setup zero-step for
 * local development (no manual migration command required).
 */

const fs = require('fs');
const path = require('path');
const { query } = require('./db');

async function initializeDatabase() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf8');
  await query(sql);
  console.log('[db] Schema ensured (users, foods, favorites, budgets, plans, expenses).');
}

module.exports = { initializeDatabase };
