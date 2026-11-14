/**
 * User — MealMate account (FR-01..FR-06).
 *
 * Plain SQL data access. Password hashes are only fetched when explicitly
 * requested (`withPassword`) and are never part of `toSafeJSON`.
 */

const { randomUUID } = require('crypto');
const { query } = require('../config/db');

const PUBLIC_COLUMNS = 'id, name, email, role, is_active, last_login_at, created_at, updated_at';

/** Public shape returned by every auth/profile endpoint. */
function toSafeJSON(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    role: row.role,
    isActive: row.is_active,
    lastLoginAt: row.last_login_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function findById(id, { withPassword = false } = {}) {
  const columns = withPassword ? `${PUBLIC_COLUMNS}, password_hash` : PUBLIC_COLUMNS;
  const { rows } = await query(`SELECT ${columns} FROM users WHERE id = $1`, [id]);
  return rows[0] || null;
}

async function findByEmail(email, { withPassword = false } = {}) {
  const columns = withPassword ? `${PUBLIC_COLUMNS}, password_hash` : PUBLIC_COLUMNS;
  const { rows } = await query(`SELECT ${columns} FROM users WHERE email = $1`, [email]);
  return rows[0] || null;
}

async function create({ name, email, passwordHash }) {
  const { rows } = await query(
    `INSERT INTO users (id, name, email, password_hash)
     VALUES ($1, $2, $3, $4)
     RETURNING ${PUBLIC_COLUMNS}`,
    [randomUUID(), name, email, passwordHash],
  );
  return rows[0];
}

async function updateName(id, name) {
  const { rows } = await query(
    `UPDATE users SET name = $2, updated_at = now()
     WHERE id = $1
     RETURNING ${PUBLIC_COLUMNS}`,
    [id, name],
  );
  return rows[0] || null;
}

async function updatePassword(id, passwordHash) {
  const { rows } = await query(
    `UPDATE users SET password_hash = $2, updated_at = now()
     WHERE id = $1
     RETURNING ${PUBLIC_COLUMNS}`,
    [id, passwordHash],
  );
  return rows[0] || null;
}

async function updateLastLogin(id) {
  const { rows } = await query(
    `UPDATE users SET last_login_at = now(), updated_at = now()
     WHERE id = $1
     RETURNING ${PUBLIC_COLUMNS}`,
    [id],
  );
  return rows[0] || null;
}

module.exports = {
  toSafeJSON,
  findById,
  findByEmail,
  create,
  updateName,
  updatePassword,
  updateLastLogin,
};
