import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { once } from 'node:events';
import { openDatabase } from '../src/database.js';
import { createApp } from '../src/app.js';

async function start(path = ':memory:', options = {}) {
  const db = openDatabase(path);
  // Never let a test write uploads into the real server/data/images directory.
  const server = createApp(db, { imageDir: mkdtempSync(join(tmpdir(), 'lsupop-images-')), ...options });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  return {
    request: (path, options) => fetch(`http://127.0.0.1:${server.address().port}${path}`, options),
    close: () => new Promise((resolve, reject) => {
      server.close(error => { db.close(); error ? reject(error) : resolve(); });
      server.closeAllConnections();
    }),
  };
}
const item = { title: 'LSU Mug', priceCents: 800, category: 'Dorm', description: 'Purple ceramic' };
test('CORS permits only the configured Flutter browser origin', async t => {
  const app = await start(':memory:', { allowedOrigin: 'http://localhost:8080' });
  t.after(app.close);
  const response = await app.request('/listings', { method: 'OPTIONS', headers: {
    Origin: 'http://localhost:8080', 'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type',
  } });
  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:8080');
  assert.equal(response.headers.get('access-control-allow-headers'), 'Content-Type');
  const denied = await app.request('/listings', { headers: { Origin: 'http://untrusted.example' } });
  assert.equal(denied.headers.get('access-control-allow-origin'), null);
});
function post(body) {
  return { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) };
}
async function fixture(t) { const app = await start(); t.after(app.close); return app; }

test('health and initially empty marketplace', async t => {
  const app = await fixture(t);
  assert.deepEqual(await (await app.request('/health')).json(), { status: 'ok' });
  assert.deepEqual((await (await app.request('/listings')).json()).listings, []);
});
test('creates and retrieves a normalized listing with server identity', async t => {
  const app = await fixture(t);
  const response = await app.request('/listings', post({ ...item, title: ' LSU Mug ' }));
  assert.equal(response.status, 201);
  const saved = await response.json();
  assert.equal(saved.title, 'LSU Mug');
  assert.equal(saved.priceCents, 800);
  assert.equal(saved.sellerId, 'demo-seller');
  assert.equal(saved.sellerName, 'Demo Seller');
  assert.ok(Number.isFinite(Date.parse(saved.createdAt)));
  assert.equal(response.headers.get('location'), `/listings/${saved.id}`);
  assert.deepEqual(await (await app.request(`/listings/${saved.id}`)).json(), saved);
});
test('listing survives closing and reopening server and database', async t => {
  const dir = mkdtempSync(join(tmpdir(), 'lsupop-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const path = join(dir, 'test.sqlite');
  const first = await start(path);
  let saved;
  try { saved = await (await first.request('/listings', post(item))).json(); }
  finally { await first.close(); }
  const second = await start(path);
  try { assert.deepEqual(await (await second.request(`/listings/${saved.id}`)).json(), saved); }
  finally { await second.close(); }
});
test('combines keyword, category and inclusive price filters', async t => {
  const app = await fixture(t);
  await app.request('/listings', post(item));
  await app.request('/listings', post({ ...item, title: 'Jersey', category: 'Apparel', priceCents: 3500 }));
  const result = await (await app.request('/listings?q=PURPLE&category=Dorm&minPriceCents=800&maxPriceCents=800')).json();
  assert.equal(result.listings.length, 1);
  assert.equal(result.listings[0].title, 'LSU Mug');
  assert.equal((await (await app.request('/listings?q=missing')).json()).listings.length, 0);
});
test('treats SQL and wildcard characters as literal search text', async t => {
  const app = await fixture(t);
  await app.request('/listings', post(item));
  for (const q of ["' OR 1=1 --", '%', '_']) {
    assert.equal((await (await app.request(`/listings?q=${encodeURIComponent(q)}`)).json()).listings.length, 0);
  }
});
test('pagination returns separate results', async t => {
  const app = await fixture(t);
  await app.request('/listings', post(item));
  await app.request('/listings', post({ ...item, title: 'Book' }));
  const page1 = await (await app.request('/listings?limit=1')).json();
  const page2 = await (await app.request('/listings?limit=1&offset=1')).json();
  assert.equal(page1.listings.length, 1);
  assert.equal(page2.listings.length, 1);
  assert.notEqual(page1.listings[0].id, page2.listings[0].id);
});
test('rejects invalid listing fields without saving', async t => {
  const app = await fixture(t);
  for (const body of [null, [], {}, { ...item, title: ' ' }, { ...item, title: 'x'.repeat(121) },
    { ...item, priceCents: -1 }, { ...item, priceCents: 1.2 }, { ...item, priceCents: '800' },
    { ...item, priceCents: 100_000_001 }, { ...item, category: 'All' },
    { ...item, sellerId: 'spoofed' }, { ...item, description: 123 }, { ...item, size: {} }]) {
    const response = await app.request('/listings', post(body));
    assert.equal(response.status, 400, JSON.stringify(body));
    assert.equal((await response.json()).error.code, 'invalid_request');
  }
  assert.equal((await (await app.request('/listings')).json()).listings.length, 0);
});
test('rejects invalid and duplicate query parameters', async t => {
  const app = await fixture(t);
  for (const query of ['minPriceCents=-1', 'minPriceCents=9&maxPriceCents=8', 'maxPriceCents=abc',
    'limit=0', 'limit=101', 'offset=1.5', 'category=All', 'q=a&q=b', 'unknown=1']) {
    assert.equal((await app.request(`/listings?${query}`)).status, 400, query);
  }
});
test('returns consistent errors for malformed, oversized and non-JSON bodies', async t => {
  const app = await fixture(t);
  for (const [body, contentType, status] of [['{', 'application/json', 400],
    ['x'.repeat(17000), 'application/json', 413], ['{}', 'text/plain', 415]]) {
    const response = await app.request('/listings', {
      method: 'POST', headers: { 'Content-Type': contentType }, body,
    });
    assert.equal(response.status, status);
    assert.equal(typeof (await response.json()).error.message, 'string');
  }
});
test('unknown resources return 404', async t => {
  const app = await fixture(t);
  for (const path of ['/unknown', '/listings/missing']) {
    const response = await app.request(path);
    assert.equal(response.status, 404);
    assert.equal((await response.json()).error.code, 'not_found');
  }
});

const pngBytes = Buffer.from(
  '89504e470d0a1a0a0000000d4948445200000001000000010806000000' +
  '1f15c4890000000a49444154789c6360000002000100ffff0300000600' +
  '05572f9f3c0000000049454e44ae426082', 'hex');
function postImage(bytes, type = 'image/png') {
  return { method: 'POST', headers: { 'Content-Type': type }, body: bytes };
}
test('uploads an image, serves it back and attaches it to a listing', async t => {
  const app = await fixture(t);
  const upload = await app.request('/images', postImage(pngBytes));
  assert.equal(upload.status, 201);
  const { url } = await upload.json();
  assert.match(url, /^\/images\/[0-9a-f-]{36}\.png$/);
  assert.equal(upload.headers.get('location'), url);

  const served = await app.request(url);
  assert.equal(served.status, 200);
  assert.equal(served.headers.get('content-type'), 'image/png');
  assert.deepEqual(Buffer.from(await served.arrayBuffer()), pngBytes);

  const saved = await (await app.request('/listings', post({ ...item, imageUrl: url }))).json();
  assert.equal(saved.imageUrl, url);
  assert.equal((await (await app.request('/listings')).json()).listings[0].imageUrl, url);
});
test('listings without a photo keep a null imageUrl', async t => {
  const app = await fixture(t);
  const saved = await (await app.request('/listings', post(item))).json();
  assert.equal(saved.imageUrl, null);
});
test('rejects uploads that are not real images of a supported type', async t => {
  const app = await fixture(t);
  const cases = [
    [postImage(pngBytes, 'image/gif'), 415],
    [postImage(pngBytes, 'application/json'), 415],
    [postImage(Buffer.from('<?php ?>'), 'image/png'), 400],   // mislabelled bytes
    [postImage(Buffer.alloc(0)), 400],
    [postImage(Buffer.alloc(5 * 1024 * 1024 + 1)), 413],
  ];
  for (const [options, status] of cases) {
    const response = await app.request('/images', options);
    assert.equal(response.status, status, `${options.headers['Content-Type']} ${status}`);
    assert.equal(typeof (await response.json()).error.message, 'string');
  }
});
test('rejects listing imageUrls the server did not issue', async t => {
  const app = await fixture(t);
  for (const imageUrl of ['/images/../database.js', 'http://evil.example/x.png',
    '/images/not-a-uuid.png', '/images/00000000-0000-4000-8000-000000000000.gif', 42]) {
    const response = await app.request('/listings', post({ ...item, imageUrl }));
    assert.equal(response.status, 400, String(imageUrl));
  }
  assert.equal((await (await app.request('/listings')).json()).listings.length, 0);
});
test('unknown or missing images are 404, not server errors', async t => {
  const app = await fixture(t);
  for (const path of ['/images/00000000-0000-4000-8000-000000000000.png',
    '/images/%2e%2e%2fdatabase.js', '/images/']) {
    assert.equal((await app.request(path)).status, 404, path);
  }
});
