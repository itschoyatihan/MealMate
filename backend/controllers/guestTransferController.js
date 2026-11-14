/**
 * Guest-to-account transfer controller (FR-04/FR-05, AT-10).
 *
 * After login or sign-up the client can push today's guest budget and/or
 * saved meal plan to the account. The server detects collisions per item
 * (budget, plan) and NEVER silently overwrites: when the account already
 * has data for the date, the server replies 409 with the conflicting items
 * and the client must resubmit with an explicit resolution:
 *   - 'keep-account'        -> keep the account's existing items
 *   - 'replace-with-guest'  -> overwrite with the guest items
 * Non-conflicting items are always transferred. The writes run in one
 * transaction so a failed transfer never leaves a partial budget/plan pair.
 */

const { withTransaction } = require('../config/db');
const { DailyBudget, MealPlan } = require('../models');
const { GUEST_RESOLUTIONS, PLAN_METHODS } = require('../utils/constants');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  requiredAmount,
  oneOf,
  optionalDate,
} = require('../middleware/validate');
const { buildPlanItems } = require('./planController');

/** POST /api/guest-transfer  { date?, budget?, plan?, resolution? } */
async function transferGuestData(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.body.date, 'date', errors, { allowFuture: false });
    errors.throwIfAny();

    const { budget: guestBudget, plan: guestPlan } = req.body || {};
    const hasGuestBudget = guestBudget != null;
    const hasGuestPlan = guestPlan != null;
    if (!hasGuestBudget && !hasGuestPlan) {
      throw ApiError.badRequest(
        "Nothing to transfer: provide 'budget' and/or 'plan' from the guest session.",
      );
    }

    // ---- Validate the guest payload before touching the database. ----

    let guestBudgetAmount;
    if (hasGuestBudget) {
      guestBudgetAmount = requiredAmount(
        guestBudget && guestBudget.amount,
        'budget.amount',
        errors,
      );
    }

    let guestPlanMethod;
    if (hasGuestPlan) {
      guestPlanMethod = oneOf(
        guestPlan && guestPlan.method,
        'plan.method',
        PLAN_METHODS,
        errors,
      );
    }

    const resolution = req.body.resolution !== undefined
      ? oneOf(req.body.resolution, 'resolution', GUEST_RESOLUTIONS, errors)
      : undefined;
    errors.throwIfAny();

    const accountBudget = await DailyBudget.findByUserAndDate(req.user.id, dateStr);
    const accountPlan = await MealPlan.findByUserAndDate(req.user.id, dateStr);

    // ---- Detect collisions independently per item. ----

    const conflicts = [];
    if (hasGuestBudget && accountBudget) {
      conflicts.push({
        field: 'budget',
        message: `The account already has a budget of ${accountBudget.amount} MMK for ${dateStr}.`,
      });
    }
    if (hasGuestPlan && accountPlan) {
      conflicts.push({
        field: 'plan',
        message: `The account already has a saved meal plan for ${dateStr}.`,
      });
    }

    if (conflicts.length > 0 && !resolution) {
      throw ApiError.conflict(
        'Account data conflicts with guest data for this date. '
          + "Resubmit with resolution 'keep-account' or 'replace-with-guest'.",
        conflicts,
      );
    }

    // Which values end up on the account after the transfer?
    const resultingBudgetAmount = hasGuestBudget
      ? (conflicts.some((c) => c.field === 'budget') && resolution === 'keep-account'
        ? accountBudget.amount
        : guestBudgetAmount)
      : (accountBudget ? accountBudget.amount : null);

    // Validate the guest plan against the resulting budget before writing.
    let guestPlanItems;
    let plannedTotal;
    if (hasGuestPlan) {
      if (!resultingBudgetAmount) {
        throw ApiError.unprocessable(
          `Set a daily budget for ${dateStr} before transferring a meal plan.`,
          [{ field: 'budget', message: `No budget found for ${dateStr}.` }],
        );
      }
      ({ items: guestPlanItems, plannedTotal } = await buildPlanItems({
        method: guestPlanMethod,
        items: guestPlan.items,
        budgetAmount: resultingBudgetAmount,
      }));
    }

    // ---- Apply the transfer (validation passed; all-or-nothing). ----

    const data = await withTransaction(async (client) => {
      const transferred = { budget: false, plan: false };
      const result = { transferred, conflicts, resolution: resolution || null };

      if (hasGuestBudget) {
        const keepAccountBudget = conflicts.some((c) => c.field === 'budget')
          && resolution === 'keep-account';
        if (!keepAccountBudget) {
          const budget = await DailyBudget.upsert(
            req.user.id,
            dateStr,
            guestBudgetAmount,
            client,
          );
          transferred.budget = true;
          result.budget = DailyBudget.toApiJSON(budget);
        } else {
          result.budget = DailyBudget.toApiJSON(accountBudget);
        }
      }

      if (hasGuestPlan) {
        const keepAccountPlan = conflicts.some((c) => c.field === 'plan')
          && resolution === 'keep-account';
        if (!keepAccountPlan) {
          const { plan } = await MealPlan.replacePlan(
            req.user.id,
            dateStr,
            {
              method: guestPlanMethod,
              items: guestPlanItems,
              plannedTotal,
              budgetAtSave: resultingBudgetAmount,
            },
            client,
          );
          transferred.plan = true;
          result.plan = plan;
          result.remaining = resultingBudgetAmount - plannedTotal;
          result.overBudget = plannedTotal > resultingBudgetAmount;
        } else {
          result.plan = accountPlan;
        }
      }

      return result;
    });

    res.status(200).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = { transferGuestData };
