/**
 * Auth controller (FR-01..FR-06): register, login, session, logout.
 *
 * Response contract consumed by the Flutter app
 * (lib/repositories/remote_auth_repository.dart):
 *   { success: true, data: { token, user } }
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { env } = require('../config/env');
const { User } = require('../models');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  requiredString,
  requiredEmail,
  requiredPassword,
} = require('../middleware/validate');

const SALT_ROUNDS = 12;

function signToken(user) {
  return jwt.sign(
    { id: user.id, role: user.role },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn },
  );
}

/** POST /api/auth/register */
async function register(req, res, next) {
  try {
    const errors = new FieldErrors();
    const name = requiredString(req.body.name, 'name', errors, { min: 2, max: 80 });
    const email = requiredEmail(req.body.email, 'email', errors);
    const password = requiredPassword(req.body.password, 'password', errors);
    errors.throwIfAny();

    const existing = await User.findByEmail(email);
    if (existing) {
      throw ApiError.conflict('An account with this email already exists.');
    }

    const user = await User.create({
      name,
      email,
      passwordHash: await bcrypt.hash(password, SALT_ROUNDS),
    });

    res.status(201).json({
      success: true,
      data: { token: signToken(user), user: User.toSafeJSON(user) },
    });
  } catch (err) {
    next(err);
  }
}

/** POST /api/auth/login */
async function login(req, res, next) {
  try {
    const errors = new FieldErrors();
    const email = requiredEmail(req.body.email, 'email', errors);
    const password = requiredPassword(req.body.password, 'password', errors);
    errors.throwIfAny();

    const user = await User.findByEmail(email, { withPassword: true });
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      // Same message for unknown email and wrong password (no user enumeration).
      throw ApiError.unauthorized('Incorrect email or password.');
    }
    if (!user.is_active) {
      throw ApiError.forbidden('This account has been deactivated.');
    }

    const updated = await User.updateLastLogin(user.id);

    res.status(200).json({
      success: true,
      data: { token: signToken(updated), user: User.toSafeJSON(updated) },
    });
  } catch (err) {
    next(err);
  }
}

/** GET /api/auth/me */
async function me(req, res, next) {
  try {
    res.status(200).json({
      success: true,
      data: { user: User.toSafeJSON(req.user) },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/auth/logout
 * Tokens are stateless JWTs, so logout succeeds on the client by discarding
 * the token; this endpoint simply acknowledges it. Short JWT lifetimes
 * (JWT_EXPIRES_IN) bound the exposure window of a leaked token.
 */
async function logout(req, res, next) {
  try {
    res.status(200).json({
      success: true,
      data: { message: 'Logged out. Please discard the token on this device.' },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, me, logout };
