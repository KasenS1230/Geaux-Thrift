import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

export function openDatabase(path) {
  if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path, { timeout: 5000 });
  db.exec('PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;');
  const version = db.prepare('PRAGMA user_version').get().user_version;
  if (version > 1) {
    db.close();
    throw new Error('Database schema is newer than this server supports');
  }
  if (version === 0) {
    try {
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
    } catch (error) {
      if (db.isTransaction) db.exec('ROLLBACK');
      db.close();
      throw error;
    }
  }
  return db;
}

export const listingSelect = `SELECT listings.*, sellers.name AS sellerName
  FROM listings JOIN sellers ON sellers.id = listings.sellerId`;
