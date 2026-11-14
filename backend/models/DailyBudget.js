/**
 * DailyBudget — one budget per user per calendar day (FR-13..FR-16).
 * Budgets never create expense entries; editing a budget never modifies or
 * deletes a saved meal plan (critical business rules).
 */

const { randomUUID } = require('crypto');
const { run } = require('./helpers');

const COLUMNS = 'id, budget_date, amount, created_at, updated_at';

function toApiJSON(row) {
  return {
    id: row.id,
    date: row.budget_date,
    amount: row.amount,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function findByUserAndDate(userId, date, client = null) {
  const { rows } = await run(
    client,
    `SELECT ${COLUMNS} FROM daily_budgets WHERE user_id = $1 AND budget_date = $2`,
    [userId, date],
  );
  return rows[0] || null;
}

/** Insert or update the budget for one day (one row per user/day). */
async function upsert(userId, date, amount, client = null) {
  const { rows } = await run(
    client,
    `INSERT INTO daily_budgets (id, user_id, budget_date, amount)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id, budget_date)
     DO UPDATE SET amount = EXCLUDED.amount, updated_at = now()
     RETURNING ${COLUMNS}`,
    [randomUUID(), userId, date, amount],
  );
  return rows[0];
}

module.exports = { toApiJSON, findByUserAndDate, upsert };
