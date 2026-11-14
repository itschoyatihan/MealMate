/**
 * Request validation helpers.
 *
 * The server independently validates amounts, dates, ownership and allowed
 * actions (PDF §6): controllers collect field errors through these helpers
 * and throw one 422 ApiError carrying `details`, which the Flutter client
 * renders next to the offending fields.
 */

const {
  EMAIL_REGEX,
  UUID_REGEX,
  MIN_PASSWORD_LENGTH,
  MAX_QUANTITY,
  MAX_AMOUNT,
} = require('../utils/constants');
const { todayInAppTimezone, parseDateOnly, isFutureDate } = require('../utils/dates');
const { ApiError } = require('./error');

/** Collects { field, message } pairs until the controller throws them. */
class FieldErrors {
  constructor() {
    this.items = [];
  }

  add(field, message) {
    this.items.push({ field, message });
  }

  get hasErrors() {
    return this.items.length > 0;
  }

  throwIfAny(message = 'Validation failed. Please check your input and try again.') {
    if (this.hasErrors) throw ApiError.unprocessable(message, this.items);
  }
}

/** Required trimmed string with length bounds. */
function requiredString(raw, field, errors, { min = 1, max = 100 } = {}) {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    errors.add(field, 'This field is required.');
    return undefined;
  }
  const value = raw.trim();
  if (value.length < min) {
    errors.add(field, `Must be at least ${min} characters.`);
  }
  if (value.length > max) {
    errors.add(field, `Must be at most ${max} characters.`);
  }
  return value;
}

/** Required email (lowercased). */
function requiredEmail(raw, field, errors) {
  if (typeof raw !== 'string' || raw.trim().length === 0) {
    errors.add(field, 'Email is required.');
    return undefined;
  }
  const value = raw.trim().toLowerCase();
  if (!EMAIL_REGEX.test(value)) {
    errors.add(field, 'Enter a valid email address.');
    return undefined;
  }
  return value;
}

/** Required password (min length mirrors the Flutter sign-up form). */
function requiredPassword(raw, field, errors) {
  if (typeof raw !== 'string' || raw.length === 0) {
    errors.add(field, 'Password is required.');
    return undefined;
  }
  if (raw.length < MIN_PASSWORD_LENGTH) {
    errors.add(field, `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`);
    return undefined;
  }
  return raw;
}

/**
 * Required whole-number amount in MMK. Accepts numbers or numeric strings
 * (commas tolerated, e.g. '10,000'), enforces [min, MAX_AMOUNT].
 */
function requiredAmount(raw, field, errors, { min = 1 } = {}) {
  let value;
  if (typeof raw === 'number') {
    value = raw;
  } else if (typeof raw === 'string' && raw.trim().length > 0) {
    value = Number(raw.replace(/,/g, '').trim());
  } else {
    errors.add(field, 'A valid amount is required.');
    return undefined;
  }

  if (!Number.isInteger(value) || value < min || value > MAX_AMOUNT) {
    errors.add(field, `Amount must be a whole number between ${min} and ${MAX_AMOUNT}.`);
    return undefined;
  }
  return value;
}

/** Required quantity (1..MAX_QUANTITY). */
function requiredQuantity(raw, field, errors) {
  const value = typeof raw === 'string' && raw.trim().length > 0
    ? Number(raw.trim())
    : raw;
  if (!Number.isInteger(value) || value < 1 || value > MAX_QUANTITY) {
    errors.add(field, `Quantity must be a whole number between 1 and ${MAX_QUANTITY}.`);
    return undefined;
  }
  return value;
}

/** Required value constrained to an allow-list. */
function oneOf(raw, field, allowed, errors) {
  if (typeof raw !== 'string' || !allowed.includes(raw)) {
    errors.add(field, `Must be one of: ${allowed.join(', ')}.`);
    return undefined;
  }
  return raw;
}

/** Required UUID string (all database ids are UUIDs). */
function requiredUuid(raw, field, errors) {
  if (typeof raw !== 'string' || !UUID_REGEX.test(raw.trim())) {
    errors.add(field, 'A valid id is required.');
    return undefined;
  }
  return raw.trim().toLowerCase();
}

/**
 * Optional date ('YYYY-MM-DD'). Returns today (app timezone) when omitted.
 * With allowFuture=false, future dates are rejected — used by meal plans
 * and actual expenses (FR-28: past dates allowed, future dates excluded).
 */
function optionalDate(raw, field, errors, { allowFuture = true } = {}) {
  if (raw === undefined || raw === null || raw === '') {
    return todayInAppTimezone();
  }
  const value = typeof raw === 'string' ? raw.trim() : raw;
  if (!parseDateOnly(value)) {
    errors.add(field, 'Date must be a valid calendar date in YYYY-MM-DD format.');
    return undefined;
  }
  if (!allowFuture && isFutureDate(value)) {
    errors.add(field, 'Future dates are not allowed.');
  }
  return value;
}

/** Clamp ?page and ?limit query parameters for list endpoints. */
function pageParams(query) {
  const page = Number.parseInt(query.page, 10);
  const limit = Number.parseInt(query.limit, 10);
  return {
    page: Number.isInteger(page) && page > 0 ? page : 1,
    limit: Number.isInteger(limit) && limit > 0 ? Math.min(limit, 100) : 20,
  };
}

/** Escape user input before embedding it in a RegExp. */
function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = {
  FieldErrors,
  requiredString,
  requiredEmail,
  requiredPassword,
  requiredAmount,
  requiredQuantity,
  oneOf,
  requiredUuid,
  optionalDate,
  pageParams,
  escapeRegex,
};
