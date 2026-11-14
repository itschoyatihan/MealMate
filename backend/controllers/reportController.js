/**
 * Reports controller (FR-37..FR-38).
 *
 * Read-only daily/weekly/monthly spending totals and meal-type breakdowns,
 * computed solely from persisted actual expense records (never from planned
 * totals). SQL provides the day rows and meal-type sums; this controller only
 * groups them into calendar buckets.
 */

const { Expense } = require('../models');
const {
  parseDateOnly,
  formatDateOnly,
  addDays,
  todayInAppTimezone,
  isoWeek,
} = require('../utils/dates');
const { REPORT_PERIODS, MAX_REPORT_RANGE_DAYS } = require('../utils/constants');
const { ApiError } = require('../middleware/error');
const { FieldErrors, oneOf } = require('../middleware/validate');

function resolveRange(query) {
  const today = todayInAppTimezone();
  const from = query.from && parseDateOnly(String(query.from).trim())
    ? String(query.from).trim()
    : addDays(today, -29);
  const to = query.to && parseDateOnly(String(query.to).trim())
    ? String(query.to).trim()
    : today;

  if (parseDateOnly(from) > parseDateOnly(to)) {
    throw ApiError.badRequest("'from' must not be after 'to'.");
  }
  const spanDays = Math.round((parseDateOnly(to) - parseDateOnly(from)) / 86400000);
  if (spanDays > MAX_REPORT_RANGE_DAYS) {
    throw ApiError.badRequest(
      `The requested range is too large. Use at most ${MAX_REPORT_RANGE_DAYS} days.`,
    );
  }
  return { from, to };
}

function bucketFor(dateString, period) {
  const date = parseDateOnly(dateString);

  switch (period) {
    case 'weekly': {
      const { isoYear, week } = isoWeek(date);
      const padded = String(week).padStart(2, '0');
      return { key: `${isoYear}-W${padded}`, label: `Week ${week}, ${isoYear}` };
    }
    case 'monthly': {
      const key = dateString.slice(0, 7);
      return { key, label: key };
    }
    case 'daily':
    default: {
      const key = formatDateOnly(date);
      return { key, label: key };
    }
  }
}

/** GET /api/reports?period=daily|weekly|monthly&from=&to= */
async function getReport(req, res, next) {
  try {
    const periodErrors = new FieldErrors();
    const period = req.query.period
      ? oneOf(req.query.period, 'period', REPORT_PERIODS, periodErrors)
      : 'daily';
    periodErrors.throwIfAny();
    const { from, to } = resolveRange(req.query);

    const days = await Expense.reportDays(req.user.id, from, to);

    const buckets = new Map();
    for (const day of days) {
      const { key, label } = bucketFor(day.date, period);
      if (!buckets.has(key)) {
        buckets.set(key, {
          key,
          label,
          total: 0,
          dayCount: 0,
          byMealType: {},
        });
      }
      const bucket = buckets.get(key);
      bucket.total += day.total;
      bucket.dayCount += 1;
      for (const [mealType, amount] of Object.entries(day.byMealType)) {
        bucket.byMealType[mealType] = (bucket.byMealType[mealType] || 0) + amount;
      }
    }

    const bucketList = [...buckets.values()].sort((a, b) => a.key.localeCompare(b.key));
    const totalSpent = bucketList.reduce((sum, bucket) => sum + bucket.total, 0);
    const activeDays = bucketList.reduce((sum, bucket) => sum + bucket.dayCount, 0);

    const byMealType = {};
    for (const bucket of bucketList) {
      for (const [mealType, amount] of Object.entries(bucket.byMealType)) {
        byMealType[mealType] = (byMealType[mealType] || 0) + amount;
      }
    }

    res.status(200).json({
      success: true,
      data: {
        period,
        from,
        to,
        buckets: bucketList,
        summary: {
          totalSpent,
          activeDays,
          averagePerDay: activeDays > 0 ? Math.round(totalSpent / activeDays) : 0,
          byMealType,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getReport };
