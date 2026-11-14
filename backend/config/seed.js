/**
 * Seed script — first-run convenience for local development.
 *
 * Inserts the sample campus catalog (matching the Flutter sample catalog)
 * and an admin account when the database is empty. Disable via .env
 * (SEED_CATALOG / SEED_ADMIN). Change ADMIN_* values before any deployment.
 */

const { randomUUID } = require('crypto');
const bcrypt = require('bcryptjs');
const { env } = require('./env');
const { query } = require('./db');

// Mirrors lib/ui/foods_page.dart sampleFoodCatalog.
const SAMPLE_CATALOG = [
  { name: 'Mohinga', price: 2000, shopName: 'Shop A', location: 'Hlaing', category: 'Soups', imagePath: 'assets/img/mohinga.jpg' },
  { name: 'Chicken Rice', price: 4000, shopName: 'Shop B', location: 'Kamayut', category: 'Rice Dishes', imagePath: 'assets/img/chickenrice.jpg' },
  { name: 'Fried Noodles', price: 3000, shopName: 'Shop C', location: 'Hlaing', category: 'Noodles', imagePath: null },
  { name: 'Tea Leaf Salad', price: 2500, shopName: 'Shop A', location: 'Insein', category: 'Salads', imagePath: 'assets/img/tealeafsalad.jpg' },
  { name: 'Fried Rice', price: 3500, shopName: 'Shop A', location: 'Hlaing', category: 'Rice Dishes', imagePath: 'assets/img/fried_rice.jpg' },
  { name: 'Mohinga', price: 2300, shopName: 'Shop B', location: 'Kamayut', category: 'Soups', imagePath: null },
  { name: 'Shan Noodles', price: 3000, shopName: 'Shop D', location: 'Insein', category: 'Noodles', imagePath: 'assets/img/shannoodles.jpg' },
  { name: 'Papaya Salad', price: 2200, shopName: 'Shop C', location: 'Hlaing', category: 'Salads', imagePath: 'assets/img/papayasalad.jpg' },
  { name: 'Steamed Bun', price: 1500, shopName: 'Shop E', location: 'Kamayut', category: 'Others', imagePath: null },
  { name: 'Mohinga', price: 2500, shopName: 'Shop C', location: 'Insein', category: 'Soups', imagePath: null },
];

async function seedInitialData() {
  if (env.seedCatalog) {
    const { rows } = await query('SELECT COUNT(*)::int AS total FROM foods');
    if (rows[0].total === 0) {
      for (const food of SAMPLE_CATALOG) {
        await query(
          `INSERT INTO foods (id, name, shop_name, location, category, price, image_path)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            randomUUID(),
            food.name,
            food.shopName,
            food.location,
            food.category,
            food.price,
            food.imagePath,
          ],
        );
      }
      console.log(`[seed] Inserted ${SAMPLE_CATALOG.length} sample catalog foods.`);
    }
  }

  if (env.seedAdmin) {
    const { rowCount } = await query('SELECT 1 FROM users WHERE email = $1', [
      env.adminEmail,
    ]);
    if (rowCount === 0) {
      await query(
        `INSERT INTO users (id, name, email, password_hash, role)
         VALUES ($1, $2, $3, $4, 'admin')`,
        [
          randomUUID(),
          env.adminName,
          env.adminEmail,
          await bcrypt.hash(env.adminPassword, 12),
        ],
      );
      console.log(`[seed] Created admin account ${env.adminEmail} (change this password in production).`);
    }
  }
}

module.exports = { seedInitialData };
