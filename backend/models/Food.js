/**
 * Food — admin-maintained campus catalog entry (FR-07..FR-12).
 * One row is one food sold by one shop; ordinary users get read-only access,
 * admins maintain the catalog.
 */

const { randomUUID } = require('crypto');
const { query } = require('../config/db');
const { escapeLike } = require('./helpers');

const COLUMNS = 'id, name, shop_name, location, category, price, image_path, is_active, created_at, updated_at';

function toApiJSON(row) {
  return {
    id: row.id,
    name: row.name,
    shopName: row.shop_name,
    location: row.location,
    category: row.category,
    price: row.price,
    imagePath: row.image_path,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

const SORT_SQL = {
  name: 'name ASC',
  price: 'price ASC',
  '-price': 'price DESC',
  newest: 'created_at DESC',
};

function buildFilter({ category, search, includeInactive = false } = {}) {
  const conditions = [];
  const params = [];

  if (!includeInactive) conditions.push('is_active = true');

  if (category && category !== 'All') {
    params.push(category);
    conditions.push(`category = $${params.length}`);
  }

  if (search) {
    params.push(`%${escapeLike(search)}%`);
    const placeholder = `$${params.length}`;
    // Search spans food and shop names across all categories (FR-09).
    conditions.push(
      `(name ILIKE ${placeholder} ESCAPE '\\' OR shop_name ILIKE ${placeholder} ESCAPE '\\')`,
    );
  }

  return {
    where: conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '',
    params,
  };
}

async function list({ category, search, sort, offset = 0, limit = 20 } = {}) {
  const { where, params } = buildFilter({ category, search });
  const orderBy = SORT_SQL[sort] || SORT_SQL.name;
  params.push(limit, offset);
  const { rows } = await query(
    `SELECT ${COLUMNS} FROM foods
     ${where}
     ORDER BY ${orderBy}
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params,
  );
  return rows.map(toApiJSON);
}

async function count({ category, search } = {}) {
  const { where, params } = buildFilter({ category, search });
  const { rows } = await query(`SELECT COUNT(*)::int AS total FROM foods ${where}`, params);
  return rows[0].total;
}

async function findById(id) {
  const { rows } = await query(`SELECT ${COLUMNS} FROM foods WHERE id = $1`, [id]);
  return rows[0] || null;
}

/** Load active catalog rows for a list of ids (plan snapshot source). */
async function findActiveByIds(ids) {
  if (!Array.isArray(ids) || ids.length === 0) return [];
  const { rows } = await query(
    `SELECT ${COLUMNS} FROM foods WHERE id = ANY($1::uuid[]) AND is_active = true`,
    [ids],
  );
  return rows.map(toApiJSON);
}

async function create({ name, shopName, location, category, price, imagePath }) {
  const { rows } = await query(
    `INSERT INTO foods (id, name, shop_name, location, category, price, image_path)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING ${COLUMNS}`,
    [randomUUID(), name, shopName, location ?? '', category, price, imagePath ?? null],
  );
  return rows[0];
}

const UPDATE_COLUMNS = {
  name: 'name',
  shopName: 'shop_name',
  location: 'location',
  category: 'category',
  price: 'price',
  imagePath: 'image_path',
  isActive: 'is_active',
};

/** Apply a partial update; returns the updated row (or null when missing). */
async function update(id, fields) {
  const assignments = [];
  const params = [id];

  for (const [key, column] of Object.entries(UPDATE_COLUMNS)) {
    if (fields[key] === undefined) continue;
    params.push(fields[key]);
    assignments.push(`${column} = $${params.length}`);
  }

  if (assignments.length === 0) return findById(id);

  assignments.push('updated_at = now()');
  const { rows } = await query(
    `UPDATE foods SET ${assignments.join(', ')}
     WHERE id = $1
     RETURNING ${COLUMNS}`,
    params,
  );
  return rows[0] || null;
}

/** Soft delete: hidden from browsing, snapshots in saved plans survive. */
async function softDelete(id) {
  const { rows } = await query(
    `UPDATE foods SET is_active = false, updated_at = now()
     WHERE id = $1
     RETURNING ${COLUMNS}`,
    [id],
  );
  return rows[0] || null;
}

module.exports = {
  toApiJSON,
  list,
  count,
  findById,
  findActiveByIds,
  create,
  update,
  softDelete,
};
