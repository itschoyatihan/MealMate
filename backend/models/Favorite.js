/**
 * Favorite — per-user favorite catalog entry (FR-12).
 * Guests cannot persist favorites; the route requires authentication.
 */

const { randomUUID } = require('crypto');
const { query } = require('../config/db');
const { toApiJSON: foodToApiJSON } = require('./Food');

const FOOD_COLUMNS = `
  fd.id AS food_id, fd.name, fd.shop_name, fd.location, fd.category,
  fd.price, fd.image_path, fd.is_active, fd.created_at AS food_created_at,
  fd.updated_at AS food_updated_at
`;

function favoriteToApiJSON(row) {
  const food = foodToApiJSON({
    id: row.food_id,
    name: row.name,
    shop_name: row.shop_name,
    location: row.location,
    category: row.category,
    price: row.price,
    image_path: row.image_path,
    is_active: row.is_active,
    created_at: row.food_created_at,
    updated_at: row.food_updated_at,
  });
  return { id: row.favorite_id, food, createdAt: row.favorite_created_at };
}

async function listForUser(userId) {
  const { rows } = await query(
    `SELECT fv.id AS favorite_id, fv.created_at AS favorite_created_at, ${FOOD_COLUMNS}
     FROM favorites fv
     JOIN foods fd ON fd.id = fv.food_id
     WHERE fv.user_id = $1 AND fd.is_active = true
     ORDER BY fv.created_at DESC`,
    [userId],
  );
  return rows.map(favoriteToApiJSON);
}

async function exists(userId, foodId) {
  const { rowCount } = await query(
    'SELECT 1 FROM favorites WHERE user_id = $1 AND food_id = $2',
    [userId, foodId],
  );
  return rowCount > 0;
}

async function create({ userId, foodId }) {
  const { rows } = await query(
    `INSERT INTO favorites (id, user_id, food_id)
     VALUES ($1, $2, $3)
     RETURNING id, created_at`,
    [randomUUID(), userId, foodId],
  );
  return { id: rows[0].id, createdAt: rows[0].created_at };
}

async function remove(userId, foodId) {
  const { rowCount } = await query(
    'DELETE FROM favorites WHERE user_id = $1 AND food_id = $2',
    [userId, foodId],
  );
  return rowCount > 0;
}

async function removeByFoodId(foodId) {
  await query('DELETE FROM favorites WHERE food_id = $1', [foodId]);
}

module.exports = { listForUser, exists, create, remove, removeByFoodId };
