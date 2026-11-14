/**
 * /api/plans — saved meal plan lifecycle (FR-17..FR-26, FR-39..FR-44).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const planController = require('../controllers/planController');

const router = express.Router();

router.get('/', protect, planController.getPlan);
router.post('/', protect, planController.savePlan);
router.delete('/', protect, planController.deletePlan);

module.exports = router;
