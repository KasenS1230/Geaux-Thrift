import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

/// Categories every database starts with. After migration 2 the table is the
/// only authority — this list seeds it and is never consulted again.
export const seedCategories = ['Apparel', 'Game Day', 'Dorm', 'Tickets', 'Books'];

export function openDatabase(path) {
  if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path, { timeout: 5000 });
  db.exec('PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;');
  const version = db.prepare('PRAGMA user_version').get().user_version;
  if (version > 2) {
    db.close();
    throw new Error('Database schema is newer than this server supports');
  }
  try {
    if (version === 0) {
      db.exec(`
        BEGIN IMMEDIATE;
        CREATE TABLE sellers (id TEXT PRIMARY KEY, name TEXT NOT NULL) STRICT;
        INSERT INTO sellers VALUES ('demo-seller', 'Demo Seller');
        CREATE TABLE listings (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          priceCents INTEGER NOT NULL CHECK(priceCents >= 0),
          sellerId TEXT NOT NULL REFERENCES sellers(id),
          category TEXT NOT NULL,
          size TEXT,
          condition TEXT NOT NULL,
          description TEXT NOT NULL,
          imageUrl TEXT,
          createdAt TEXT NOT NULL
        ) STRICT;
        CREATE INDEX listings_category_price ON listings(category, priceCents);
        PRAGMA user_version = 1;
        COMMIT;
      `);
    }
    if (version <= 1) {
      // NOCASE keeps 'Shoes' and 'shoes' from becoming two categories.
      db.exec(`
        BEGIN IMMEDIATE;
        CREATE TABLE categories (
          name TEXT PRIMARY KEY COLLATE NOCASE,
          createdAt TEXT NOT NULL
        ) STRICT;
        PRAGMA user_version = 2;
        COMMIT;
      `);
      // Seed the built-ins, then adopt anything existing listings already use,
      // so rows written before this migration stay valid and filterable.
      const insert = db.prepare(
        'INSERT OR IGNORE INTO categories (name, createdAt) VALUES (?, ?)');
      const now = new Date().toISOString();
      db.exec('BEGIN IMMEDIATE');
      for (const name of seedCategories) insert.run(name, now);
      for (const row of db.prepare('SELECT DISTINCT category FROM listings').all()) {
        insert.run(row.category, now);
      }
      db.exec('COMMIT');
    }
  } catch (error) {
    if (db.isTransaction) db.exec('ROLLBACK');
    db.close();
    throw error;
  }
  return db;
}

export const listingSelect = `SELECT listings.*, sellers.name AS sellerName
  FROM listings JOIN sellers ON sellers.id = listings.sellerId`;
