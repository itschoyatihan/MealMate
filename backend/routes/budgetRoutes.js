/**
 * /api/budget — daily budget set/edit (FR-13..FR-16).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const budgetController = require('../controllers/budgetController');

const router = express.Router();

router.get('/', protect, budgetController.getBudget);
router.put('/', protect, budgetController.setBudget);

module.exports = router;
