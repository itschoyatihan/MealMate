/**
 * Expense — one actual-expense day per user (FR-27..FR-34).
 *
 * Expenses are completely independent from plans, budgets and the catalog:
 * names and actual unit prices are manually entered by the user. All items
 * for a date live in one expense day row + child item rows, written inside a
 * single transaction, so a failed save never persists a partial day.
 *
 * Meal History (FR-35/36) and Reports (FR-37/38) read these rows only —
 * planned totals are never used as spending totals.
 */

const { randomUUID } = require('crypto');
const { query, withTransaction } = require('../config/db');
const { run } = require('./helpers');
const { MEAL_TYPES } = require('../utils/constants');

const DAY_COLUMNS = 'id, expense_date, total, created_at, updated_at';
const ITEM_COLUMNS = 'name, quantity, unit_price, meal_type';

function emptyMealTotals() {
  return Object.fromEntries(MEAL_TYPES.map((type) => [type, 0]));
}

function toApiJSON(dayRow, itemRows) {
  const byMealType = emptyMealTotals();

  const items = itemRows.map((item) => {
    const lineTotal = item.quantity * item.unit_price;
    byMealType[item.meal_type] += lineTotal;
    return {
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unit_price,
      mealType: item.meal_type,
      lineTotal,
    };
  });

  return {
    id: dayRow.id,
    date: dayRow.expense_date,
    items,
    total: dayRow.total,
    byMealType,
    createdAt: dayRow.created_at,
    updatedAt: dayRow.updated_at,
  };
}

async function loadDay(dayId, client = null) {
  const dayResult = await run(
    client,
    `SELECT ${DAY_COLUMNS} FROM expense_days WHERE id = $1`,
    [dayId],
  );
  if (!dayResult.rows[0]) return null;

  const itemsResult = await run(
    client,
    `SELECT ${ITEM_COLUMNS} FROM expense_items
     WHERE expense_day_id = $1 ORDER BY sort_order ASC`,
    [dayId],
  );
  return toApiJSON(dayResult.rows[0], itemsResult.rows);
}

async function findByUserAndDate(userId, date, client = null) {
  const { rows } = await run(
    client,
    'SELECT id FROM expense_days WHERE user_id = $1 AND expense_date = $2',
    [userId, date],
  );
  if (!rows[0]) return null;
  return loadDay(rows[0].id, client);
}

/**
 * Replace the day's expense record and items atomically.
 * Returns { created, expense } where expense is the API-shaped object.
 */
async function replace(userId, date, { items, total }, activeClient = null) {
  const work = async (client) => {
    const existing = await client.query(
      'SELECT id FROM expense_days WHERE user_id = $1 AND expense_date = $2 FOR UPDATE',
      [userId, date],
    );

    const created = existing.rowCount === 0;
    let dayId;

    if (created) {
      dayId = randomUUID();
      await client.query(
        `INSERT INTO expense_days (id, user_id, expense_date, total)
         VALUES ($1, $2, $3, $4)`,
        [dayId, userId, date, total],
      );
    } else {
      dayId = existing.rows[0].id;
      await client.query('DELETE FROM expense_items WHERE expense_day_id = $1', [dayId]);
      await client.query(
        'UPDATE expense_days SET total = $2, updated_at = now() WHERE id = $1',
        [dayId, total],
      );
    }

    for (let index = 0; index < items.length; index += 1) {
      const item = items[index];
      await client.query(
        `INSERT INTO expense_items
           (id, expense_day_id, sort_order, name, quantity, unit_price, meal_type)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          randomUUID(),
          dayId,
          index,
          item.name,
          item.quantity,
          item.unitPrice,
          item.mealType,
        ],
      );
    }

    return { created, expense: await loadDay(dayId, client) };
  };

  if (activeClient) return work(activeClient);
  return withTransaction(work);
}

async function remove(userId, date) {
  const { rowCount } = await query(
    'DELETE FROM expense_days WHERE user_id = $1 AND expense_date = $2',
    [userId, date],
  );
  return rowCount > 0;
}

/** Meal-type totals keyed by day id for a set of expense day ids. */
async function mealTotalsByDayIds(dayIds) {
  if (dayIds.length === 0) return new Map();

  const { rows } = await query(
    `SELECT expense_day_id AS day_id, meal_type,
            SUM(quantity * unit_price)::bigint AS amount
     FROM expense_items
     WHERE expense_day_id = ANY($1::uuid[])
     GROUP BY expense_day_id, meal_type`,
    [dayIds],
  );

  const byDay = new Map();
  for (const row of rows) {
    if (!byDay.has(row.day_id)) byDay.set(row.day_id, emptyMealTotals());
    byDay.get(row.day_id)[row.meal_type] = Number(row.amount);
  }
  return byDay;
}

/** Paginated read-only history sourced only from persisted expenses. */
async function history(userId, from, to, { offset = 0, limit = 20 } = {}) {
  const [daysResult, countResult, sumResult] = await Promise.all([
    query(
      `SELECT d.id, d.expense_date, d.total, COUNT(i.id)::int AS item_count
       FROM expense_days d
       LEFT JOIN expense_items i ON i.expense_day_id = d.id
       WHERE d.user_id = $1 AND d.expense_date BETWEEN $2 AND $3
       GROUP BY d.id
       ORDER BY d.expense_date DESC
       LIMIT $4 OFFSET $5`,
      [userId, from, to, limit, offset],
    ),
    query(
      `SELECT COUNT(*)::int AS total FROM expense_days
       WHERE user_id = $1 AND expense_date BETWEEN $2 AND $3`,
      [userId, from, to],
    ),
    query(
      `SELECT COALESCE(SUM(total), 0)::bigint AS total_spent FROM expense_days
       WHERE user_id = $1 AND expense_date BETWEEN $2 AND $3`,
      [userId, from, to],
    ),
  ]);

  const mealTotals = await mealTotalsByDayIds(daysResult.rows.map((row) => row.id));

  const days = daysResult.rows.map((row) => ({
    id: row.id,
    date: row.expense_date,
    total: row.total,
    byMealType: mealTotals.get(row.id) || emptyMealTotals(),
    itemCount: row.item_count,
  }));

  return {
    days,
    total: countResult.rows[0].total,
    totalSpent: sumResult.rows[0].total_spent,
  };
}

/** Expense days (with meal-type totals) for report bucketing. */
async function reportDays(userId, from, to) {
  const daysResult = await query(
    `SELECT id, expense_date, total FROM expense_days
     WHERE user_id = $1 AND expense_date BETWEEN $2 AND $3
     ORDER BY expense_date ASC`,
    [userId, from, to],
  );

  const mealTotals = await mealTotalsByDayIds(daysResult.rows.map((row) => row.id));

  return daysResult.rows.map((row) => ({
    date: row.expense_date,
    total: row.total,
    byMealType: mealTotals.get(row.id) || emptyMealTotals(),
  }));
}

module.exports = {
  toApiJSON,
  findByUserAndDate,
  replace,
  remove,
  history,
  reportDays,
};
