/**
 * Food catalog controller (FR-07..FR-11).
 *
 * Browse/search is public (guest-first design). Category chips and the
 * cross-category search by food or shop name mirror the Flutter Foods page.
 * Write access is admin-only: the catalog is admin-maintained and read-only
 * to ordinary users.
 */

const { Food, Favorite } = require('../models');
const { ApiError } = require('../middleware/error');
const {
  FieldErrors,
  requiredString,
  requiredAmount,
  oneOf,
  pageParams,
} = require('../middleware/validate');
const { FOOD_CATEGORIES, UUID_REGEX } = require('../utils/constants');

/** Path ids are validated before hitting the database for a clean 400. */
function assertUuidParam(raw, label = 'id') {
  if (typeof raw !== 'string' || !UUID_REGEX.test(raw)) {
    throw ApiError.badRequest(`Invalid ${label}.`);
  }
  return raw.toLowerCase();
}

/**
 * GET /api/foods?category=&search=&sort=&page=&limit=
 * Guests may browse; no authentication required.
 */
async function getFoods(req, res, next) {
  try {
    const { category } = req.query;
    if (category && category !== 'All' && !FOOD_CATEGORIES.includes(category)) {
      throw ApiError.badRequest(
        `Unknown category. Valid categories: All, ${FOOD_CATEGORIES.join(', ')}.`,
      );
    }

    const search = typeof req.query.search === 'string' ? req.query.search.trim() : '';
    const { page, limit } = pageParams(req.query);

    const [foods, total] = await Promise.all([
      Food.list({
        category,
        search,
        sort: req.query.sort,
        offset: (page - 1) * limit,
        limit,
      }),
      Food.count({ category, search }),
    ]);

    const totalPages = Math.max(Math.ceil(total / limit), 1);
    res.status(200).json({
      success: true,
      data: {
        foods,
        pagination: {
          page,
          limit,
          total,
          totalPages,
          hasMore: page < totalPages,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

/** GET /api/foods/:id */
async function getFoodById(req, res, next) {
  try {
    const id = assertUuidParam(req.params.id);
    const food = await Food.findById(id);
    if (!food || !food.is_active) {
      throw ApiError.notFound('Food not found in the catalog.');
    }
    res.status(200).json({ success: true, data: { food: Food.toApiJSON(food) } });
  } catch (err) {
    next(err);
  }
}

/** POST /api/foods (admin) */
async function createFood(req, res, next) {
  try {
    const errors = new FieldErrors();
    const name = requiredString(req.body.name, 'name', errors, { max: 100 });
    const shopName = requiredString(req.body.shopName, 'shopName', errors, { max: 100 });
    const category = oneOf(req.body.category, 'category', FOOD_CATEGORIES, errors);
    const price = requiredAmount(req.body.price, 'price', errors);
    const location = typeof req.body.location === 'string' ? req.body.location.trim() : '';
    const imagePath = typeof req.body.imagePath === 'string' && req.body.imagePath.trim().length > 0
      ? req.body.imagePath.trim()
      : null;
    errors.throwIfAny();

    const food = await Food.create({ name, shopName, location, category, price, imagePath });
    res.status(201).json({ success: true, data: { food: Food.toApiJSON(food) } });
  } catch (err) {
    next(err);
  }
}

/** PATCH /api/foods/:id (admin) */
async function updateFood(req, res, next) {
  try {
    const id = assertUuidParam(req.params.id);
    const existing = await Food.findById(id);
    if (!existing) {
      throw ApiError.notFound('Food not found in the catalog.');
    }

    const errors = new FieldErrors();
    const fields = {};
    if (req.body.name !== undefined) {
      fields.name = requiredString(req.body.name, 'name', errors, { max: 100 });
    }
    if (req.body.shopName !== undefined) {
      fields.shopName = requiredString(req.body.shopName, 'shopName', errors, { max: 100 });
    }
    if (req.body.location !== undefined) {
      if (typeof req.body.location === 'string') {
        fields.location = req.body.location.trim();
      } else {
        errors.add('location', 'Location must be text.');
      }
    }
    if (req.body.category !== undefined) {
      fields.category = oneOf(req.body.category, 'category', FOOD_CATEGORIES, errors);
    }
    if (req.body.price !== undefined) {
      fields.price = requiredAmount(req.body.price, 'price', errors);
    }
    if (req.body.imagePath !== undefined) {
      fields.imagePath = typeof req.body.imagePath === 'string' && req.body.imagePath.trim().length > 0
        ? req.body.imagePath.trim()
        : null;
    }
    if (req.body.isActive !== undefined) {
      fields.isActive = req.body.isActive === true || req.body.isActive === 'true';
    }
    errors.throwIfAny();

    const food = await Food.update(id, fields);
    res.status(200).json({ success: true, data: { food: Food.toApiJSON(food) } });
  } catch (err) {
    next(err);
  }
}

/**
 * DELETE /api/foods/:id (admin)
 * Soft delete: the entry is hidden from browsing, favorites referencing it
 * are removed, and saved plans keep their immutable snapshots.
 */
async function deleteFood(req, res, next) {
  try {
    const id = assertUuidParam(req.params.id);
    const food = await Food.findById(id);
    if (!food) {
      throw ApiError.notFound('Food not found in the catalog.');
    }

    await Food.softDelete(id);
    await Favorite.removeByFoodId(id);

    res.status(200).json({
      success: true,
      data: { message: `${food.name} was removed from the catalog.` },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getFoods, getFoodById, createFood, updateFood, deleteFood };
