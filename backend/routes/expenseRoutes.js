/**
 * /api/expenses — actual expense CRUD per date (FR-27..FR-34).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const expenseController = require('../controllers/expenseController');

const router = express.Router();

router.get('/', protect, expenseController.getExpenses);
router.post('/', protect, expenseController.saveExpenses);
router.delete('/', protect, expenseController.deleteExpenses);

module.exports = router;
