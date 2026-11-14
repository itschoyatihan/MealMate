/**
 * Shared domain constants for the MealMate API.
 * Kept in one place so the SQL schema, validation middleware and
 * controllers always agree on the allowed values.
 */

// Meal types used by meal plans and actual expenses (FR-17, FR-27).
const MEAL_TYPES = ['breakfast', 'lunch', 'snacks', 'dinner'];

// Catalog browse chips (FR-08/FR-09): All, Rice Dishes, Noodles, Soups, Salads, Others.
// 'All' is handled as "no category filter" and is intentionally not stored.
const FOOD_CATEGORIES = ['Rice Dishes', 'Noodles', 'Soups', 'Salads', 'Others'];

// Meal plan creation methods (FR-17 automatic, FR-23 manual).
const PLAN_METHODS = ['auto', 'manual'];

// Report aggregation periods (FR-37).
const REPORT_PERIODS = ['daily', 'weekly', 'monthly'];

// Guest-to-account transfer conflict resolutions (FR-04/FR-05).
const GUEST_RESOLUTIONS = ['keep-account', 'replace-with-guest'];

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// UUID v4 (all database primary keys are generated with crypto.randomUUID()).
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Passwords must be at least 8 characters (matches the Flutter sign-up form).
const MIN_PASSWORD_LENGTH = 8;

// Sanity caps for quantities and monetary amounts (MMK, whole kyat).
const MAX_QUANTITY = 50;
const MAX_AMOUNT = 10000000;

// History/report query windows.
const DEFAULT_HISTORY_DAYS = 30;
const MAX_REPORT_RANGE_DAYS = 400;

module.exports = {
  MEAL_TYPES,
  FOOD_CATEGORIES,
  PLAN_METHODS,
  REPORT_PERIODS,
  GUEST_RESOLUTIONS,
  EMAIL_REGEX,
  UUID_REGEX,
  MIN_PASSWORD_LENGTH,
  MAX_QUANTITY,
  MAX_AMOUNT,
  DEFAULT_HISTORY_DAYS,
  MAX_REPORT_RANGE_DAYS,
};
