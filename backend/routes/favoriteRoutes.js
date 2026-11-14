/**
 * /api/favorites — per-user favorites over catalog entries (FR-12).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const favoriteController = require('../controllers/favoriteController');

const router = express.Router();

router.get('/', protect, favoriteController.getFavorites);
router.post('/', protect, favoriteController.addFavorite);
router.delete('/:foodId', protect, favoriteController.removeFavorite);

module.exports = router;
