/**
 * Meal history controller (FR-35..FR-36).
 *
 * Read-only. Records are sourced exclusively from successfully saved actual
 * expenses — planned meals and budget amounts never appear here. Each day
 * entry carries its date so the client can navigate to Expenses for
 * corrections (which then update history).
 */

const { Expense } = require('../models');
const { parseDateOnly, addDays, todayInAppTimezone } = require('../utils/dates');
const { DEFAULT_HISTORY_DAYS, MAX_REPORT_RANGE_DAYS } = require('../utils/constants');
const { ApiError } = require('../middleware/error');
const { pageParams } = require('../middleware/validate');

function resolveRange(query) {
  const today = todayInAppTimezone();
  const from = query.from && parseDateOnly(String(query.from).trim())
    ? String(query.from).trim()
    : addDays(today, -DEFAULT_HISTORY_DAYS + 1);
  const to = query.to && parseDateOnly(String(query.to).trim())
    ? String(query.to).trim()
    : today;

  if (parseDateOnly(from) > parseDateOnly(to)) {
    throw ApiError.badRequest("'from' must not be after 'to'.");
  }

  const spanDays = Math.round(
    (parseDateOnly(to) - parseDateOnly(from)) / 86400000,
  );
  if (spanDays > MAX_REPORT_RANGE_DAYS) {
    throw ApiError.badRequest(
      `The requested range is too large. Use at most ${MAX_REPORT_RANGE_DAYS} days.`,
    );
  }

  return { from, to };
}

/** GET /api/history?from=&to=&page=&limit= */
async function getHistory(req, res, next) {
  try {
    const { from, to } = resolveRange(req.query);
    const { page, limit } = pageParams(req.query);

    const { days, total, totalSpent } = await Expense.history(req.user.id, from, to, {
      offset: (page - 1) * limit,
      limit,
    });

    const totalPages = Math.max(Math.ceil(total / limit), 1);

    res.status(200).json({
      success: true,
      data: {
        days,
        summary: {
          from,
          to,
          dayCount: total,
          totalSpent,
          averagePerDay: total > 0 ? Math.round(totalSpent / total) : 0,
        },
        pagination: {
          page,
          limit,
          total,
          totalPages,
          hasMore: page < totalPages,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getHistory };
