/**
 * /api/history — read-only meal history from actual expenses (FR-35..FR-36).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const historyController = require('../controllers/historyController');

const router = express.Router();

router.get('/', protect, historyController.getHistory);

module.exports = router;
