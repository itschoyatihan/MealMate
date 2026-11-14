/**
 * MealPlan — one saved plan per user per calendar day (FR-17..FR-26, FR-39..FR-44).
 *
 * Items store an immutable snapshot of the catalog entry at save time (name,
 * shop, category, image, price), so later catalog price changes never mutate
 * a saved plan. Planning is NOT spending: saving a plan never creates expense
 * rows. Last-saved-plan-wins is enforced by the unique (user_id, plan_date)
 * constraint plus the replace-on-save transaction.
 */

const { randomUUID } = require('crypto');
const { query, withTransaction } = require('../config/db');
const { run } = require('./helpers');

const PLAN_COLUMNS = 'id, plan_date, method, planned_total, budget_at_save, created_at, updated_at';
const ITEM_COLUMNS = 'food_id, name, shop_name, category, image_path, price, quantity, meal_type';

function toApiJSON(planRow, itemRows) {
  return {
    id: planRow.id,
    date: planRow.plan_date,
    method: planRow.method,
    plannedTotal: planRow.planned_total,
    budgetAtSave: planRow.budget_at_save,
    items: itemRows.map((item) => ({
      food: item.food_id,
      name: item.name,
      shopName: item.shop_name,
      category: item.category,
      imagePath: item.image_path,
      price: item.price,
      quantity: item.quantity,
      mealType: item.meal_type,
      lineTotal: item.price * item.quantity,
    })),
    createdAt: planRow.created_at,
    updatedAt: planRow.updated_at,
  };
}

async function loadPlan(planId, client = null) {
  const planResult = await run(
    client,
    `SELECT ${PLAN_COLUMNS} FROM meal_plans WHERE id = $1`,
    [planId],
  );
  if (!planResult.rows[0]) return null;

  const itemsResult = await run(
    client,
    `SELECT ${ITEM_COLUMNS} FROM meal_plan_items
     WHERE plan_id = $1 ORDER BY sort_order ASC`,
    [planId],
  );
  return toApiJSON(planResult.rows[0], itemsResult.rows);
}

async function findByUserAndDate(userId, date, client = null) {
  const { rows } = await run(
    client,
    'SELECT id FROM meal_plans WHERE user_id = $1 AND plan_date = $2',
    [userId, date],
  );
  if (!rows[0]) return null;
  return loadPlan(rows[0].id, client);
}

/**
 * Replace the day's plan and its items atomically.
 * Returns { created, plan } where plan is the API-shaped object.
 */
async function replacePlan(userId, date, { method, items, plannedTotal, budgetAtSave }, activeClient = null) {
  const work = async (client) => {
    const existing = await client.query(
      'SELECT id FROM meal_plans WHERE user_id = $1 AND plan_date = $2 FOR UPDATE',
      [userId, date],
    );

    const created = existing.rowCount === 0;
    let planId;

    if (created) {
      planId = randomUUID();
      await client.query(
        `INSERT INTO meal_plans (id, user_id, plan_date, method, planned_total, budget_at_save)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [planId, userId, date, method, plannedTotal, budgetAtSave],
      );
    } else {
      planId = existing.rows[0].id;
      await client.query('DELETE FROM meal_plan_items WHERE plan_id = $1', [planId]);
      await client.query(
        `UPDATE meal_plans
         SET method = $2, planned_total = $3, budget_at_save = $4, updated_at = now()
         WHERE id = $1`,
        [planId, method, plannedTotal, budgetAtSave],
      );
    }

    for (let index = 0; index < items.length; index += 1) {
      const item = items[index];
      await client.query(
        `INSERT INTO meal_plan_items
           (id, plan_id, sort_order, food_id, name, shop_name, category, image_path, price, quantity, meal_type)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          randomUUID(),
          planId,
          index,
          item.foodId || null,
          item.name,
          item.shopName,
          item.category,
          item.imagePath ?? null,
          item.price,
          item.quantity,
          item.mealType,
        ],
      );
    }

    return { created, plan: await loadPlan(planId, client) };
  };

  if (activeClient) return work(activeClient);
  return withTransaction(work);
}

/** Delete only the plan (items cascade); the day's budget is untouched. */
async function remove(userId, date) {
  const { rowCount } = await query(
    'DELETE FROM meal_plans WHERE user_id = $1 AND plan_date = $2',
    [userId, date],
  );
  return rowCount > 0;
}

module.exports = { toApiJSON, findByUserAndDate, replacePlan, remove };
