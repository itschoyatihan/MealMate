/**
 * Central error handling.
 *
 * Errors leave the API in a single envelope so the Flutter client can always
 * read `message` and field-level `details`:
 *   { "success": false, "message": "...", "details": [{ "field": "...", "message": "..." }] }
 *
 * PostgreSQL errors are translated to the same HTTP statuses the client
 * expects: unique violations -> 409, constraint violations -> 422, malformed
 * input values (e.g. a bad UUID or date) -> 400.
 */

class ApiError extends Error {
  constructor(statusCode, message, details = []) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
  }

  static badRequest(message, details = []) {
    return new ApiError(400, message, details);
  }

  static unauthorized(message = 'Authentication required. Please log in.') {
    return new ApiError(401, message);
  }

  static forbidden(message = 'You do not have permission to do this.') {
    return new ApiError(403, message);
  }

  static notFound(message = 'The requested resource was not found.') {
    return new ApiError(404, message);
  }

  static conflict(message, details = []) {
    return new ApiError(409, message, details);
  }

  static unprocessable(message, details = []) {
    return new ApiError(422, message, details);
  }
}

/** 404 for unmatched routes. */
function notFoundHandler(req, res, next) {
  next(ApiError.notFound(`Route ${req.method} ${req.originalUrl} was not found.`));
}

const CHECK_VIOLATION = '23514';
const FOREIGN_KEY_VIOLATION = '23503';
const NOT_NULL_VIOLATION = '23502';
const UNIQUE_VIOLATION = '23505';
const INVALID_TEXT_REPRESENTATION = '22P02';
const INVALID_DATE_FORMAT = '22007';
const DATETIME_FIELD_OVERFLOW = '22008';

/** Final Express error middleware. */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  let error = err;

  if (err && err.code === UNIQUE_VIOLATION) {
    error = ApiError.conflict('This record already exists.');
  } else if (
    err
    && [CHECK_VIOLATION, FOREIGN_KEY_VIOLATION, NOT_NULL_VIOLATION].includes(err.code)
  ) {
    error = ApiError.unprocessable(
      'Validation failed. Please check your input and try again.',
    );
  } else if (
    err
    && [INVALID_TEXT_REPRESENTATION, INVALID_DATE_FORMAT, DATETIME_FIELD_OVERFLOW].includes(
      err.code,
    )
  ) {
    error = ApiError.badRequest('A value in the request is not valid.');
  }

  if (!error.statusCode || !Number.isInteger(error.statusCode)) {
    // Unexpected/programming error: log it, hide internals from the client.
    console.error('[error]', err);
    error = new ApiError(500, 'Something went wrong on the server. Please try again.');
  }

  res.status(error.statusCode).json({
    success: false,
    message: error.message,
    details: Array.isArray(error.details) ? error.details : [],
  });
}

module.exports = { ApiError, notFoundHandler, errorHandler };
