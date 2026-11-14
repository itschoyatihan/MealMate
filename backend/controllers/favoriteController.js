/**
 * Favorites controller (FR-12).
 * Favorites are per authenticated user + catalog entry; guests only get a
 * login prompt (no persistence on the server for guests).
 */

const { Favorite, Food } = require('../models');
const { ApiError } = require('../middleware/error');
const { FieldErrors, requiredUuid } = require('../middleware/validate');

/** GET /api/favorites */
async function getFavorites(req, res, next) {
  try {
    const favorites = await Favorite.listForUser(req.user.id);
    res.status(200).json({ success: true, data: { favorites } });
  } catch (err) {
    next(err);
  }
}

/** POST /api/favorites  { foodId } */
async function addFavorite(req, res, next) {
  try {
    const errors = new FieldErrors();
    const foodId = requiredUuid(req.body.foodId, 'foodId', errors);
    errors.throwIfAny();

    const food = await Food.findById(foodId);
    if (!food || !food.is_active) {
      throw ApiError.notFound('Food not found in the catalog.');
    }

    if (await Favorite.exists(req.user.id, foodId)) {
      throw ApiError.conflict('This food is already in your favorites.');
    }

    const favorite = await Favorite.create({ userId: req.user.id, foodId });
    res.status(201).json({
      success: true,
      data: {
        favorite: {
          id: favorite.id,
          food: Food.toApiJSON(food),
          createdAt: favorite.createdAt,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

/** DELETE /api/favorites/:foodId */
async function removeFavorite(req, res, next) {
  try {
    const errors = new FieldErrors();
    const foodId = requiredUuid(req.params.foodId, 'foodId', errors);
    errors.throwIfAny();

    const removed = await Favorite.remove(req.user.id, foodId);
    if (!removed) {
      throw ApiError.notFound('This food is not in your favorites.');
    }

    res.status(200).json({
      success: true,
      data: { message: 'Removed from your favorites.' },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getFavorites, addFavorite, removeFavorite };
