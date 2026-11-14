/**
 * Meal plan controller (FR-17..FR-26, FR-39..FR-44).
 *
 * Server-side business rules (independently of the Flutter editors):
 *  - A daily budget for the date must exist before any plan is saved
 *    (planning gate, FR-13..FR-16).
 *  - Automatic plans must fit the budget — over-budget automatic
 *    suggestions are rejected, never saved (FR-19).
 *  - Manual plans may exceed the budget; the response flags overBudget
 *    so the client can warn, but Save is still permitted (FR-25).
 *  - Catalog entries are snapshotted at save time (immutable prices).
 *  - One plan per user per day; saving again replaces it
 *    (last-saved-plan-wins, FR-44). Deleting a plan keeps the budget.
 *  - Planning is not spending: no expense records are created here.
 */

const { DailyBudget, MealPlan, Food } = require('../models');
const { PLAN_METHODS, MEAL_TYPES, MAX_AMOUNT } = require('../utils/constants');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  oneOf,
  requiredUuid,
  requiredQuantity,
  optionalDate,
} = require('../middleware/validate');

/**
 * Validate a plan payload and build snapshot items.
 * Returns { items, plannedTotal }.
 * Exported for reuse by the guest-transfer controller.
 */
async function buildPlanItems({ method, items, budgetAmount }) {
  const errors = new FieldErrors();

  if (!Array.isArray(items) || items.length === 0) {
    throw ApiError.unprocessable('At least one meal item is required.', [
      { field: 'items', message: 'Add at least one food to the plan.' },
    ]);
  }

  // Automatic plans use one item per selected meal type with quantity 1
  // (matches the Automatic editor's model); at least one meal is required.
  const seenMealTypes = new Set();

  const validated = items.map((item, index) => {
    const prefix = `items[${index}]`;
    const foodId = requiredUuid(item && item.foodId, `${prefix}.foodId`, errors);
    const quantity = requiredQuantity(item && item.quantity, `${prefix}.quantity`, errors);
    const mealType = oneOf(item && item.mealType, `${prefix}.mealType`, MEAL_TYPES, errors);

    if (method === 'auto' && mealType) {
      if (quantity !== undefined && quantity !== 1) {
        errors.add(`${prefix}.quantity`, 'Automatic plans use one item per meal type.');
      }
      if (seenMealTypes.has(mealType)) {
        errors.add(`${prefix}.mealType`, 'Each meal type may appear once in an automatic plan.');
      }
      seenMealTypes.add(mealType);
    }

    return { foodId, quantity, mealType };
  });

  errors.throwIfAny();

  // Load referenced catalog entries in one query; the server decides the
  // prices (client-supplied prices are never trusted).
  const foods = await Food.findActiveByIds(validated.map((item) => item.foodId));
  const foodById = new Map(foods.map((food) => [food.id, food]));

  const snapshots = validated.map((item, index) => {
    const food = foodById.get(item.foodId);
    if (!food) {
      throw ApiError.unprocessable('Some foods in the plan were not found in the catalog.', [
        { field: `items[${index}].foodId`, message: 'Food not found in the catalog.' },
      ]);
    }
    return {
      foodId: food.id,
      name: food.name,
      shopName: food.shopName,
      category: food.category,
      imagePath: food.imagePath,
      price: food.price,
      quantity: item.quantity,
      mealType: item.mealType,
    };
  });

  const plannedTotal = snapshots.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );

  if (plannedTotal > MAX_AMOUNT) {
    throw ApiError.unprocessable('The planned total is unreasonably large.', [
      { field: 'items', message: `The plan total must be at most ${MAX_AMOUNT} MMK.` },
    ]);
  }

  // Over-budget automatic suggestions are refused (FR-19).
  if (method === 'auto' && plannedTotal > budgetAmount) {
    throw ApiError.unprocessable(
      'Cannot save an automatic plan above the daily budget. The plan was not saved.',
      [{ field: 'items', message: 'The generated plan exceeds the daily budget.' }],
    );
  }

  return { items: snapshots, plannedTotal };
}

/** GET /api/plans?date=YYYY-MM-DD (defaults to today) */
async function getPlan(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.query.date, 'date', errors);
    errors.throwIfAny();

    const plan = await MealPlan.findByUserAndDate(req.user.id, dateStr);
    if (!plan) {
      throw ApiError.notFound(`No meal plan saved for ${dateStr}.`);
    }

    const budget = await DailyBudget.findByUserAndDate(req.user.id, dateStr);
    const budgetAmount = budget ? budget.amount : plan.budgetAtSave;

    res.status(200).json({
      success: true,
      data: {
        plan,
        budget: budget ? DailyBudget.toApiJSON(budget) : null,
        remaining: budgetAmount - plan.plannedTotal,
        overBudget: plan.plannedTotal > budgetAmount,
      },
    });
  } catch (err) {
    next(err);
  }
}

/** POST /api/plans  { date?, method, items: [{ foodId, quantity, mealType }] } */
async function savePlan(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.body.date, 'date', errors, { allowFuture: false });
    const method = oneOf(req.body.method, 'method', PLAN_METHODS, errors);
    errors.throwIfAny();

    // Planning gate: budget must exist for this date.
    const budget = await DailyBudget.findByUserAndDate(req.user.id, dateStr);
    if (!budget) {
      throw ApiError.unprocessable(
        `Set a daily budget for ${dateStr} before saving a meal plan.`,
        [{ field: 'date', message: `No budget found for ${dateStr}.` }],
      );
    }

    const { items, plannedTotal } = await buildPlanItems({
      method,
      items: req.body.items,
      budgetAmount: budget.amount,
    });

    const { created, plan } = await MealPlan.replacePlan(req.user.id, dateStr, {
      method,
      items,
      plannedTotal,
      budgetAtSave: budget.amount,
    });

    res.status(created ? 201 : 200).json({
      success: true,
      data: {
        plan,
        budget: DailyBudget.toApiJSON(budget),
        remaining: budget.amount - plannedTotal,
        // Manual plans may exceed the budget (warning only, FR-25).
        overBudget: plannedTotal > budget.amount,
        replacedExisting: !created,
      },
    });
  } catch (err) {
    next(err);
  }
}

/** DELETE /api/plans?date=YYYY-MM-DD — removes the plan, keeps the budget (FR-43). */
async function deletePlan(req, res, next) {
  try {
    const errors = new FieldErrors();
    const dateStr = optionalDate(req.query.date, 'date', errors);
    errors.throwIfAny();

    const removed = await MealPlan.remove(req.user.id, dateStr);
    if (!removed) {
      throw ApiError.notFound(`No meal plan saved for ${dateStr}.`);
    }

    const budget = await DailyBudget.findByUserAndDate(req.user.id, dateStr);
    res.status(200).json({
      success: true,
      data: {
        message: `Meal plan for ${dateStr} deleted. The daily budget was kept.`,
        budget: budget ? DailyBudget.toApiJSON(budget) : null,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getPlan, savePlan, deletePlan, buildPlanItems };
