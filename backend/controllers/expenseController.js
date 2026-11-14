/**
 * Actual expenses controller (FR-27..FR-34).
 *
 * Signed-in only. Expenses are fully independent from plans, budgets and
 * the catalog: the user manually enters food/drink names, quantities and
 * the actual unit prices paid. The date defaults to today; past dates are
 * allowed, future dates are rejected.
 *
 * All items for one date are written in one transaction, so a failed save
 * never persists a partial day (AT-14).
 */

const { Expense } = require('../models');
const { MEAL_TYPES, MAX_AMOUNT } = require('../utils/constants');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  requiredString,
  requiredQuantity,
  requiredAmount,
  oneOf,
  optionalDate,
} = require('../middleware/validate');

/** Validate and normalize a manually entered expense item list. */
function buildExpenseItems(items) {
  const errors = new FieldErrors();

  if (!Array.isArray(items) || items.length === 0) {
    throw ApiError.unprocessable('At least one expense item is required.', [
      { field: 'items', message: 'Add at least one food or drink you actually bought.' },
    ]);
  }

  const validated = items.map((item, index) => {
    const prefix = `items[${index}]`;
    const name = requiredString(item && item.name, `${prefix}.name`, errors, { max: 100 });
    const quantity = requiredQuantity(item && item.quantity, `${prefix}.quantity`, errors);
    const unitPrice = requiredAmount(item && item.unitPrice, `${prefix}.unitPrice`, errors, { min: 0 });
    const mealType = oneOf(item && item.mealType, `${prefix}.mealType`, MEAL_TYPES, errors);
    return { name, quantity, unitPrice, mealType };
  });

  errors.throwIfAny();
  return validated;
}

/**
 * POST /api/expenses  { date?, items: [{ name, quantity, unitPrice, mealType }] }
 * Saves (replaces) the full item list for the date.
 */
async function saveExpenses(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.body.date, 'date', errors, { allowFuture: false });
    errors.throwIfAny();

    const items = buildExpenseItems(req.body.items);
    const total = items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
    if (total > MAX_AMOUNT) {
      throw ApiError.unprocessable('The daily total is unreasonably large.', [
        { field: 'items', message: `Total must be at most ${MAX_AMOUNT} MMK per day.` },
      ]);
    }

    const { created, expense } = await Expense.replace(req.user.id, dateStr, { items, total });

    res.status(created ? 201 : 200).json({
      success: true,
      data: { expense },
    });
  } catch (err) {
    next(err);
  }
}

/** GET /api/expenses?date=YYYY-MM-DD (defaults to today) */
async function getExpenses(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.query.date, 'date', errors);
    errors.throwIfAny();

    const expense = await Expense.findByUserAndDate(req.user.id, dateStr);
    if (!expense) {
      throw ApiError.notFound(`No expenses recorded for ${dateStr}.`);
    }

    res.status(200).json({ success: true, data: { expense } });
  } catch (err) {
    next(err);
  }
}

/** DELETE /api/expenses?date=YYYY-MM-DD */
async function deleteExpenses(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.query.date, 'date', errors);
    errors.throwIfAny();

    const removed = await Expense.remove(req.user.id, dateStr);
    if (!removed) {
      throw ApiError.notFound(`No expenses recorded for ${dateStr}.`);
    }

    res.status(200).json({
      success: true,
      data: { message: `Expenses for ${dateStr} deleted.` },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { saveExpenses, getExpenses, deleteExpenses };
