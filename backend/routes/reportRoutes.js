/**
 * /api/reports — read-only spending reports from actual expenses (FR-37..FR-38).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const reportController = require('../controllers/reportController');

const router = express.Router();

router.get('/', protect, reportController.getReport);

module.exports = router;
