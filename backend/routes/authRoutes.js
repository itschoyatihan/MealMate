/**
 * /api/auth — register, login, session, logout (FR-01..FR-06).
 */

const express = require('express');
const { authLimiter } = require('../middleware/rateLimit');
const { protect } = require('../middleware/auth');
const authController = require('../controllers/authController');

const router = express.Router();

router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.get('/me', protect, authController.me);
router.post('/logout', protect, authController.logout);

module.exports = router;
