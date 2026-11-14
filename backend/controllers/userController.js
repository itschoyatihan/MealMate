/**
 * Profile controller: update display name and change password.
 */

const bcrypt = require('bcryptjs');
const { User } = require('../models');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  requiredString,
  requiredPassword,
} = require('../middleware/validate');

/** PATCH /api/users/me  { name } */
async function updateProfile(req, res, next) {
  try {
    const errors = new FieldErrors();
    const name = requiredString(req.body.name, 'name', errors, { min: 2, max: 80 });
    errors.throwIfAny();

    const user = await User.updateName(req.user.id, name);

    res.status(200).json({
      success: true,
      data: { user: User.toSafeJSON(user) },
    });
  } catch (err) {
    next(err);
  }
}

/** PATCH /api/users/me/password  { currentPassword, newPassword } */
async function changePassword(req, res, next) {
  try {
    const errors = new FieldErrors();
    const currentPassword = requiredPassword(req.body.currentPassword, 'currentPassword', errors);
    const newPassword = requiredPassword(req.body.newPassword, 'newPassword', errors);
    errors.throwIfAny();

    const user = await User.findById(req.user.id, { withPassword: true });
    if (!user || !(await bcrypt.compare(currentPassword, user.password_hash))) {
      throw ApiError.unauthorized('Your current password is incorrect.');
    }
    if (currentPassword === newPassword) {
      throw ApiError.unprocessable('The new password must be different from the current password.', [
        { field: 'newPassword', message: 'Choose a password you have not used before.' },
      ]);
    }

    await User.updatePassword(user.id, await bcrypt.hash(newPassword, 12));

    res.status(200).json({
      success: true,
      data: { message: 'Password updated successfully.' },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { updateProfile, changePassword };
