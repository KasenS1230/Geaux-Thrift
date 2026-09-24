import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import { listingSelect } from './database.js';

const categories = ['Apparel', 'Game Day', 'Dorm', 'Tickets', 'Books'];
const maxPrice = 100_000_000;
class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}
function invalid(message) { throw new ApiError(400, 'invalid_request', message); }
function text(value, name, max, fallback) {
  if (value === undefined && fallback !== undefined) return fallback;
  if (typeof value !== 'string' || value.trim().length > max ||
      (fallback === undefined && !value.trim())) invalid(`${name} must be a string of 1–${max} characters`);
  return value.trim();
}
function price(value, name) {
  if (!Number.isSafeInteger(value) || value < 0 || value > maxPrice) {
    invalid(`${name} must be integer cents between 0 and ${maxPrice}`);
  }
  return value;
}
function validateListing(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) invalid('Expected a JSON object');
  const allowed = ['title', 'priceCents', 'category', 'size', 'condition', 'description'];
  if (Object.keys(body).some(key => !allowed.includes(key))) invalid('Unknown listing field');
  const category = text(body.category, 'category', 30);
  if (!categories.includes(category)) invalid(`category must be one of: ${categories.join(', ')}`);
  return {
    title: text(body.title, 'title', 120),
    priceCents: price(body.priceCents, 'priceCents'),
    category,
    size: body.size == null ? null : text(body.size, 'size', 30),
    condition: text(body.condition, 'condition', 50, 'Good'),
    description: text(body.description, 'description', 5000, ''),
  };
}
async function readJson(req) {
  if (req.headers['content-type']?.split(';')[0].trim().toLowerCase() !== 'application/json') {
    throw new ApiError(415, 'unsupported_media_type', 'Use Content-Type: application/json');
  }
  const chunks = [];
  let length = 0;
  // Keep the stream alive long enough to deliver the 413 response.
  for await (const chunk of req.iterator({ destroyOnReturn: false })) {
    length += chunk.length;
    if (length > 16_384) {
      req.resume();
      throw new ApiError(413, 'payload_too_large', 'Request body exceeds 16 KiB');
    }
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { invalid('Request body must contain valid JSON'); }
}
function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', ...headers });
  res.end(JSON.stringify(body));
}

export function createApp(db, { allowedOrigin = '' } = {}) {
  return createServer(async (req, res) => {
    try {
      res.setHeader('Vary', 'Origin');
      if (allowedOrigin && req.headers.origin === allowedOrigin) {
        res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
      }
      const url = new URL(req.url, 'http://localhost');
      if (url.pathname === '/health' && req.method === 'GET') {
        db.prepare('SELECT 1').get();
        return send(res, 200, { status: 'ok' });
      }
      if (url.pathname === '/listings' && req.method === 'GET') {
        const params = url.searchParams;
        const allowed = ['q', 'category', 'minPriceCents', 'maxPriceCents', 'limit', 'offset'];
        for (const key of params.keys()) {
          if (!allowed.includes(key) || params.getAll(key).length !== 1) invalid('Unknown or repeated query parameter');
        }
        const where = [];
        const values = [];
        const q = text(params.get('q') ?? '', 'q', 120, '');
        if (q) {
          where.push("(instr(lower(title), lower(?)) > 0 OR instr(lower(description), lower(?)) > 0 OR instr(lower(category), lower(?)) > 0 OR instr(lower(sellers.name), lower(?)) > 0)");
          values.push(q, q, q, q);
        }
        const category = params.get('category');
        if (category !== null) {
          if (!categories.includes(category)) invalid('Unknown category');
          where.push('category = ?'); values.push(category);
        }
        function integerParam(key, fallback, max) {
          if (!params.has(key)) return fallback;
          const raw = params.get(key);
          if (!/^\d+$/.test(raw)) invalid(`${key} must be a non-negative integer`);
          const value = Number(raw);
          if (!Number.isSafeInteger(value) || value > max) invalid(`${key} is out of range`);
          return value;
        }
        const min = integerParam('minPriceCents', 0, maxPrice);
        const max = integerParam('maxPriceCents', maxPrice, maxPrice);
        if (min > max) invalid('minPriceCents cannot exceed maxPriceCents');
        where.push('priceCents BETWEEN ? AND ?'); values.push(min, max);
        const limit = integerParam('limit', 50, 100);
        if (limit === 0) invalid('limit must be between 1 and 100');
        const offset = integerParam('offset', 0, 1_000_000);
        const listings = db.prepare(`${listingSelect} WHERE ${where.join(' AND ')}
          ORDER BY createdAt DESC, listings.id DESC LIMIT ? OFFSET ?`).all(...values, limit, offset);
        return send(res, 200, { listings, limit, offset });
      }
      if (url.pathname === '/listings' && req.method === 'POST') {
        const item = validateListing(await readJson(req));
        const id = randomUUID();
        db.prepare(`INSERT INTO listings
          (id, title, priceCents, sellerId, category, size, condition, description, createdAt)
          VALUES (?, ?, ?, 'demo-seller', ?, ?, ?, ?, ?)`)
          .run(id, item.title, item.priceCents, item.category, item.size, item.condition,
            item.description, new Date().toISOString());
        return send(res, 201, db.prepare(`${listingSelect} WHERE listings.id = ?`).get(id),
          { Location: `/listings/${id}` });
      }
      if (/^\/listings\/[^/]+$/.test(url.pathname) && req.method === 'GET') {
        const listing = db.prepare(`${listingSelect} WHERE listings.id = ?`).get(url.pathname.slice(10));
        if (listing) return send(res, 200, listing);
      }
      throw new ApiError(404, 'not_found', 'Resource not found');
    } catch (error) {
      if (!(error instanceof ApiError)) console.error(error);
      send(res, error.status ?? 500, {
        error: { code: error.code && error instanceof ApiError ? error.code : 'internal_error',
          message: error instanceof ApiError ? error.message : 'An unexpected server error occurred' },
      });
    }
  });
}
