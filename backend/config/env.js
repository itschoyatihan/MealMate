/**
 * Environment configuration.
 * Loads backend/.env (regardless of the current working directory),
 * applies defaults and exposes a single typed config object.
 */

const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const getEnv = (key, fallback) => {
  const value = process.env[key];
  if (value === undefined || value.trim() === '') return fallback;
  return value.trim();
};

const parsedPort = Number.parseInt(getEnv('PORT', '4000'), 10);

const env = {
  nodeEnv: getEnv('NODE_ENV', 'development'),
  port: Number.isInteger(parsedPort) && parsedPort > 0 ? parsedPort : 4000,
  databaseUrl: getEnv(
    'DATABASE_URL',
    'postgresql://postgres:postgres@127.0.0.1:5432/mealmate',
  ),
  // Set PGSSL=true when connecting to a managed PostgreSQL that requires TLS.
  pgSsl: getEnv('PGSSL', 'false') === 'true',
  jwtSecret: getEnv('JWT_SECRET', ''),
  jwtExpiresIn: getEnv('JWT_EXPIRES_IN', '7d'),
  appTimezone: getEnv('APP_TIMEZONE', 'Asia/Yangon'),
  corsOrigin: getEnv('CORS_ORIGIN', '*'),
  seedCatalog: getEnv('SEED_CATALOG', 'true') === 'true',
  seedAdmin: getEnv('SEED_ADMIN', 'true') === 'true',
  adminName: getEnv('ADMIN_NAME', 'MealMate Admin'),
  adminEmail: getEnv('ADMIN_EMAIL', 'admin@mealmate.local').toLowerCase(),
  adminPassword: getEnv('ADMIN_PASSWORD', 'Admin#1234'),
};

if (!env.jwtSecret || env.jwtSecret.length < 32) {
  // Fail fast: signing tokens with a weak secret is a security risk.
  throw new Error(
    'JWT_SECRET is missing or too short. Set a long random value in backend/.env',
  );
}

module.exports = { env };
