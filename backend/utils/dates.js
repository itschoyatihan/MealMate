/**
 * Date-only helpers.
 *
 * MealMate records (daily budget, meal plan, expense day) are keyed by a
 * calendar date, not a timestamp. Dates travel over the API as
 * 'YYYY-MM-DD' strings and are stored as UTC midnight instants, so every
 * user works with the same calendar day regardless of their device clock.
 * 'Today' is resolved in the configured application timezone
 * (APP_TIMEZONE, default Asia/Yangon — Myanmar local time, FR / risk item).
 */

const { env } = require('../config/env');

const DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/;

/** Today as 'YYYY-MM-DD' in the application timezone. */
function todayInAppTimezone() {
  // The 'en-CA' locale formats as YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', { timeZone: env.appTimezone }).format(
    new Date(),
  );
}

/**
 * Parse 'YYYY-MM-DD' into a Date at UTC midnight.
 * Returns null for malformed strings and impossible calendar dates
 * (e.g. 2026-02-31).
 */
function parseDateOnly(value) {
  if (typeof value !== 'string' || !DATE_ONLY_REGEX.test(value)) return null;
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime())) return null;
  if (date.toISOString().slice(0, 10) !== value) return null;
  return date;
}

/** Date -> 'YYYY-MM-DD'. */
function formatDateOnly(date) {
  return date.toISOString().slice(0, 10);
}

/** True when the date string is after today (in the app timezone). */
function isFutureDate(dateString) {
  return dateString > todayInAppTimezone();
}

/** Shift a date string by N days and return the new 'YYYY-MM-DD'. */
function addDays(dateString, days) {
  const date = parseDateOnly(dateString) ?? new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return formatDateOnly(date);
}

/** ISO-8601 week number for a date ({ isoYear, week }). */
function isoWeek(date) {
  const utc = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
  const dayNumber = utc.getUTCDay() || 7; // Mon = 1 .. Sun = 7
  utc.setUTCDate(utc.getUTCDate() + 4 - dayNumber); // Thursday of this ISO week
  const yearStart = new Date(Date.UTC(utc.getUTCFullYear(), 0, 1));
  const week = Math.ceil(
    ((utc.getTime() - yearStart.getTime()) / 86400000 + 1) / 7,
  );
  return { isoYear: utc.getUTCFullYear(), week };
}

module.exports = {
  todayInAppTimezone,
  parseDateOnly,
  formatDateOnly,
  isFutureDate,
  addDays,
  isoWeek,
};
