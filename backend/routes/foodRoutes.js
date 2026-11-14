/**
 * /api/foods — campus catalog (FR-07..FR-11).
 * Browse/search is public (guest-first); maintenance is admin-only.
 */

const express = require('express');
const { protect, authorize } = require('../middleware/auth');
const foodController = require('../controllers/foodController');

const router = express.Router();

// Public: browse, search by food/shop, category chips, pagination.
router.get('/', foodController.getFoods);
router.get('/:id', foodController.getFoodById);

// Admin-only maintenance.
router.post('/', protect, authorize('admin'), foodController.createFood);
router.patch('/:id', protect, authorize('admin'), foodController.updateFood);
router.delete('/:id', protect, authorize('admin'), foodController.deleteFood);

module.exports = router;
