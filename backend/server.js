/**
 * MealMate backend — Express entry point.
 *
 * Structure:
 *   config/       database connection, environment, first-run seed
 *   controllers/  business logic for the routes
 *   middleware/   auth, validation, rate limiting, error handling
 *   models/       SQL data-access modules (User, Food, Favorite, DailyBudget, MealPlan, Expense)
 *   routes/       Express API route endpoints
 *   utils/        shared constants and date helpers
 *
 * Business rules are enforced server-side (PDF §5/§6): planning is not
 * spending, expenses are independent manual records, history/reports are
 * derived only from actual expenses, and no cross-account access is allowed.
 */

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');

const { env } = require('./config/env');
const { connectDatabase, disconnectDatabase } = require('./config/db');
const { initializeDatabase } = require('./config/migrate');
const { seedInitialData } = require('./config/seed');
const apiRouter = require('./routes');
const { apiLimiter } = require('./middleware/rateLimit');
const { notFoundHandler, errorHandler } = require('./middleware/error');

const app = express();

// Behind a reverse proxy, req.ip still resolves correctly for rate limiting.
app.set('trust proxy', 1);

app.use(helmet());
app.use(
  cors({
    // '*' (dev) reflects any origin; set a comma-separated list in production.
    origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(',').map((o) => o.trim()),
  }),
);

if (env.nodeEnv !== 'test') {
  app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
}

app.use(express.json({ limit: '100kb' }));

// All API routes share the general rate limiter.
app.use('/api', apiLimiter, apiRouter);

app.use(notFoundHandler);
app.use(errorHandler);

async function start() {
  await connectDatabase();
  await initializeDatabase();
  await seedInitialData();

  const server = app.listen(env.port, () => {
    console.log(`[api] MealMate backend listening on http://localhost:${env.port}/api`);
    console.log(`[api] Environment: ${env.nodeEnv} | timezone for 'today': ${env.appTimezone}`);
  });

  // Close HTTP connections, then the PostgreSQL pool, on container stops.
  const shutdown = (signal) => {
    console.log(`[api] ${signal} received. Shutting down...`);
    server.close(async () => {
      try {
        await disconnectDatabase();
      } finally {
        process.exit(0);
      }
    });
    // Do not hang forever on open keep-alive connections.
    setTimeout(() => process.exit(1), 10000).unref();
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

process.on('unhandledRejection', (reason) => {
  console.error('[api] Unhandled rejection:', reason);
});

start().catch((err) => {
  console.error('[api] Failed to start:', err.message);
  process.exit(1);
});
