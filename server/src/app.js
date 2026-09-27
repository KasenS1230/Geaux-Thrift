import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import { mkdirSync, createReadStream } from 'node:fs';
import { writeFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { listingSelect } from './database.js';

const categories = ['Apparel', 'Game Day', 'Dorm', 'Tickets', 'Books'];
const maxPrice = 100_000_000;
const maxImageBytes = 5 * 1024 * 1024;
// Content type -> file extension plus the leading magic bytes every such file starts with.
// Sniffing keeps a mislabelled Content-Type from parking arbitrary bytes under an image name.
const imageTypes = {
  'image/jpeg': { ext: 'jpg', magic: [[0xff, 0xd8, 0xff]] },
  'image/png': { ext: 'png', magic: [[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]] },
  'image/webp': { ext: 'webp', magic: [[0x52, 0x49, 0x46, 0x46]] },
};
const imageName = /^[0-9a-f-]{36}\.(jpg|png|webp)$/;
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
function imagePath(value, name) {
  if (value == null) return null;
  if (typeof value !== 'string' || !value.startsWith('/images/') ||
      !imageName.test(value.slice('/images/'.length))) {
    invalid(`${name} must be a path returned by POST /images`);
  }
  return value;
}
function validateListing(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) invalid('Expected a JSON object');
  const allowed = ['title', 'priceCents', 'category', 'size', 'condition', 'description', 'imageUrl'];
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
    imageUrl: imagePath(body.imageUrl, 'imageUrl'),
  };
}
function contentType(req) {
  return req.headers['content-type']?.split(';')[0].trim().toLowerCase() ?? '';
}
async function readBody(req, limit, limitLabel) {
  const chunks = [];
  let length = 0;
  // Keep the stream alive long enough to deliver the 413 response.
  for await (const chunk of req.iterator({ destroyOnReturn: false })) {
    length += chunk.length;
    if (length > limit) {
      req.resume();
      throw new ApiError(413, 'payload_too_large', `Request body exceeds ${limitLabel}`);
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
async function readJson(req) {
  if (contentType(req) !== 'application/json') {
    throw new ApiError(415, 'unsupported_media_type', 'Use Content-Type: application/json');
  }
  try { return JSON.parse((await readBody(req, 16_384, '16 KiB')).toString('utf8')); }
  catch (error) { if (error instanceof ApiError) throw error; invalid('Request body must contain valid JSON'); }
}
function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', ...headers });
  res.end(JSON.stringify(body));
}

export function createApp(db, { allowedOrigin = '', imageDir } = {}) {
  const images = imageDir ?? fileURLToPath(new URL('../data/images', import.meta.url));
  mkdirSync(images, { recursive: true });
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
          (id, title, priceCents, sellerId, category, size, condition, description, imageUrl, createdAt)
          VALUES (?, ?, ?, 'demo-seller', ?, ?, ?, ?, ?, ?)`)
          .run(id, item.title, item.priceCents, item.category, item.size, item.condition,
            item.description, item.imageUrl, new Date().toISOString());
        return send(res, 201, db.prepare(`${listingSelect} WHERE listings.id = ?`).get(id),
          { Location: `/listings/${id}` });
      }
      if (url.pathname === '/images' && req.method === 'POST') {
        const type = imageTypes[contentType(req)];
        if (!type) {
          throw new ApiError(415, 'unsupported_media_type',
            `Use Content-Type: ${Object.keys(imageTypes).join(', ')}`);
        }
        const bytes = await readBody(req, maxImageBytes, '5 MiB');
        if (!bytes.length) invalid('Image body is empty');
        if (!type.magic.some(magic => magic.every((byte, i) => bytes[i] === byte))) {
          invalid('Image bytes do not match the declared Content-Type');
        }
        const name = `${randomUUID()}.${type.ext}`;
        await writeFile(join(images, name), bytes, { flag: 'wx' });
        return send(res, 201, { url: `/images/${name}` }, { Location: `/images/${name}` });
      }
      if (url.pathname.startsWith('/images/') && req.method === 'GET') {
        const name = url.pathname.slice('/images/'.length);
        // The name pattern alone rules out traversal: no slashes or dots can survive it.
        if (imageName.test(name)) {
          const file = join(images, name);
          const info = await stat(file).catch(() => null);
          if (info?.isFile()) {
            const ext = name.split('.').pop();
            res.writeHead(200, {
              'Content-Type': ext === 'jpg' ? 'image/jpeg' : `image/${ext}`,
              'Content-Length': info.size,
              'Cache-Control': 'public, max-age=31536000, immutable',
            });
            return createReadStream(file).pipe(res);
          }
        }
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
