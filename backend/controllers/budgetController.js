/**
 * Daily budget controller (FR-13..FR-16).
 *
 * One budget per user per calendar day. Editing a budget never creates
 * expense entries (planning is not spending) and never silently modifies or
 * deletes a saved meal plan — when a plan exists for the date, the response
 * reports the resulting over-budget state as a warning only.
 */

const { DailyBudget, MealPlan } = require('../models');
const { ApiError } = require('../middleware/error');
const { FieldErrors, requiredAmount, optionalDate } = require('../middleware/validate');

/** GET /api/budget?date=YYYY-MM-DD (defaults to today) */
async function getBudget(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.query.date, 'date', errors);
    errors.throwIfAny();

    const budget = await DailyBudget.findByUserAndDate(req.user.id, dateStr);
    if (!budget) {
      throw ApiError.notFound(`No daily budget set for ${dateStr}.`);
    }

    res.status(200).json({
      success: true,
      data: { budget: DailyBudget.toApiJSON(budget) },
    });
  } catch (err) {
    next(err);
  }
}

/** PUT /api/budget  { date?, amount } — same form for first entry and editing. */
async function setBudget(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.body.date, 'date', errors);
    const amount = requiredAmount(req.body.amount, 'amount', errors);
    errors.throwIfAny();

    const budget = await DailyBudget.upsert(req.user.id, dateStr, amount);

    // Warning only: the saved plan is intentionally left untouched.
    const plan = await MealPlan.findByUserAndDate(req.user.id, dateStr);
    const data = { budget: DailyBudget.toApiJSON(budget) };
    if (plan) {
      data.plan = {
        plannedTotal: plan.plannedTotal,
        remaining: amount - plan.plannedTotal,
        overBudget: plan.plannedTotal > amount,
      };
    }

    res.status(200).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = { getBudget, setBudget };
