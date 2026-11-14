/**
 * /api/users — profile management for the signed-in account.
 */

const express = require('express');
const { protect } = require('../middleware/auth');
const userController = require('../controllers/userController');

const router = express.Router();

router.patch('/me', protect, userController.updateProfile);
router.patch('/me/password', protect, userController.changePassword);

module.exports = router;
