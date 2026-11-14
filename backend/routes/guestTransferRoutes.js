/**
 * /api/guest-transfer — conflict-aware guest-to-account transfer (FR-04/FR-05).
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const guestTransferController = require('../controllers/guestTransferController');

const router = express.Router();

router.post('/', protect, guestTransferController.transferGuestData);

module.exports = router;
