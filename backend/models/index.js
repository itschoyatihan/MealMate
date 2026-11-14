/**
 * Model registry.
 *
 * Every model is a small module of parameterized SQL queries returning the
 * same camelCase API shapes the Flutter client already consumes. Controllers
 * always import models from here, never from the individual files.
 */

const User = require('./User');
const Food = require('./Food');
const Favorite = require('./Favorite');
const DailyBudget = require('./DailyBudget');
const MealPlan = require('./MealPlan');
const Expense = require('./Expense');

module.exports = {
  User,
  Food,
  Favorite,
  DailyBudget,
  MealPlan,
  Expense,
};
