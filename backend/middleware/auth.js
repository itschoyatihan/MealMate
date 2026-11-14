/**
 * Authentication & authorization middleware (FR-01..FR-03).
 *
 * `protect`  — requires a valid Bearer JWT and attaches the account row to
 *              req.user. Guests (no token) get 401 and the Flutter app
 *              routes them to Login/Sign Up.
 * `authorize` — restricts a route to specific roles (e.g. catalog admin).
 */

const jwt = require('jsonwebtoken');
const { env } = require('../config/env');
const { User } = require('../models');
const { UUID_REGEX } = require('../utils/constants');
const { ApiError } = require('./error');

function extractBearerToken(req) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return null;
  const token = header.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
}

async function protect(req, res, next) {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      throw ApiError.unauthorized('Authentication required. Please log in.');
    }

    let payload;
    try {
      payload = jwt.verify(token, env.jwtSecret);
    } catch (err) {
      const expired = err instanceof jwt.TokenExpiredError;
      throw ApiError.unauthorized(
        expired
          ? 'Your session has expired. Please log in again.'
          : 'Invalid session token. Please log in again.',
      );
    }

    if (!payload || typeof payload.id !== 'string' || !UUID_REGEX.test(payload.id)) {
      throw ApiError.unauthorized('Invalid session token. Please log in again.');
    }

    const user = await User.findById(payload.id);
    if (!user || !user.is_active) {
      throw ApiError.unauthorized('Account not found or deactivated. Please log in again.');
    }

    req.user = user;
    return next();
  } catch (err) {
    return next(err);
  }
}

/** Allow only the given roles, e.g. authorize('admin'). */
function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required. Please log in.'));
    }
    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden('Admin access is required for this action.'));
    }
    return next();
  };
}

module.exports = { protect, authorize };
