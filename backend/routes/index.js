/**
 * API route registry — every endpoint group mounted under /api.
 */

const express = require('express');
const { getDatabaseStatus } = require('../config/db');

const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const foodRoutes = require('./foodRoutes');
const favoriteRoutes = require('./favoriteRoutes');
const budgetRoutes = require('./budgetRoutes');
const planRoutes = require('./planRoutes');
const expenseRoutes = require('./expenseRoutes');
const historyRoutes = require('./historyRoutes');
const reportRoutes = require('./reportRoutes');
const guestTransferRoutes = require('./guestTransferRoutes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      database: getDatabaseStatus(),
      uptimeSeconds: Math.round(process.uptime()),
    },
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/foods', foodRoutes);
router.use('/favorites', favoriteRoutes);
router.use('/budget', budgetRoutes);
router.use('/plans', planRoutes);
router.use('/expenses', expenseRoutes);
router.use('/history', historyRoutes);
router.use('/reports', reportRoutes);
router.use('/guest-transfer', guestTransferRoutes);

module.exports = router;
