/**
 * Rate limiting.
 *
 * apiLimiter  — general throttle for every /api route.
 * authLimiter — stricter throttle for register/login to slow down
 *               credential-stuffing attempts.
 */

const { rateLimit } = require('express-rate-limit');

const baseOptions = {
  standardHeaders: 'draft-7',
  legacyHeaders: false,
};

const apiLimiter = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 300,
  message: {
    success: false,
    message: 'Too many requests. Please slow down and try again later.',
    details: [],
  },
});

const authLimiter = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000,
  limit: 20,
  message: {
    success: false,
    message: 'Too many authentication attempts. Please wait a few minutes and try again.',
    details: [],
  },
});

module.exports = { apiLimiter, authLimiter };
