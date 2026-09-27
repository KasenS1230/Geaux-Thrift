# LSU Pop listings server

Local development API using Node.js 24+ and its built-in SQLite module. No npm
dependencies or separate database installation are required. Node 24 may print
an experimental SQLite warning; see the [Node SQLite documentation](https://nodejs.org/docs/latest-v24.x/api/sqlite.html).

From the repository root:

```powershell
cd server
node src/index.js
```

These commands require `node` on your terminal's PATH; npm is not required.
Check with `node --version` (24 or newer). If Node is not recognized, install
Node.js 24 LTS from https://nodejs.org/ and reopen your terminal/editor.
If you have npm installed, `npm start` and `npm test` also work from `server/`.

The API listens at `http://127.0.0.1:3000`. Stop it with Ctrl+C. On first start,
schema migration 1 creates `server/data/listings.sqlite` and a demo seller.
Listings start empty and persist across restarts. Database files are ignored by Git.

Optional environment variables: `PORT` (default `3000`), `HOST` (default
`127.0.0.1`), `DB_PATH` (default `server/data/listings.sqlite`, resolved relative
to the server source; custom relative paths resolve from the working directory).
Use `HOST=0.0.0.0` only when you need access from another device on your local network.
Android emulator clients can use `http://10.0.2.2:3000`; physical devices use the
computer's LAN address with a suitable host binding and firewall configuration.
See the root README for Flutter networking and platform HTTP configuration.

This is an unauthenticated development server: every new listing is assigned to
`demo-seller` / `Demo Seller`. Clients cannot choose seller IDs. Add authentication
and server-enforced ownership before public deployment. Photo uploads and chat
are outside this version. Browser CORS is disabled by default. Set ALLOWED_ORIGIN to the exact Flutter web origin (for example http://localhost:8080) to enable it, then restart the server.

## API

| Method | Path | Result |
| --- | --- | --- |
| GET | `/health` | `{ "status": "ok" }`, checks database connectivity |
| GET | `/listings` | `{ "listings": [...], "limit": 50, "offset": 0 }` |
| GET | `/listings/:id` | One listing, or 404 |
| POST | `/listings` | Creates a listing; returns 201 and a Location header |

GET `/listings` accepts optional `q`, `category`, `minPriceCents`,
`maxPriceCents`, `limit` (1–100, default 50), and `offset` (0–1000000).
Filters combine with AND. Price bounds are inclusive. Search is a literal
substring across title, description, category, and seller name, case-insensitive
for ASCII text. Results sort by creation time descending with ID as a tie-breaker.
Omit `category` for all categories. Unknown or repeated query parameters return 400.

POST requires `Content-Type: application/json`, a body at most 16 KiB, and:

```json
{
  "title": "LSU Mug",
  "priceCents": 800,
  "category": "Dorm",
  "description": "Purple ceramic mug",
  "condition": "Good",
  "size": null
}
```

Required: nonblank title (max 120 characters), integer `priceCents` between 0 and
100000000, and category (`Apparel`, `Game Day`, `Dorm`, `Tickets`, `Books`).
Optional: description (max 5000, default empty), condition (max 50, default
`Good`), size (nonblank max 30 or null). Text is trimmed. Unknown fields are rejected.
The response also contains `id` (UUID), `sellerId`, `sellerName`, `createdAt`
(UTC ISO timestamp), and `imageUrl` (currently null). Money uses integer cents
throughout; the Flutter repository converts to dollars for its display model.

Example from another PowerShell terminal:

```powershell
$body = @{ title = 'LSU Mug'; priceCents = 800; category = 'Dorm' } | ConvertTo-Json
$listing = Invoke-RestMethod http://127.0.0.1:3000/listings -Method Post -ContentType 'application/json' -Body $body
Invoke-RestMethod "http://127.0.0.1:3000/listings/$($listing.id)"
Invoke-RestMethod 'http://127.0.0.1:3000/listings?q=mug&category=Dorm&maxPriceCents=1000'
```

Errors have the shape `{ "error": { "code": "invalid_request", "message": "..." } }`.
Status codes: 400 invalid input/JSON, 404 unknown resource, 413 oversized body,
415 unsupported content type, 500 unexpected server error. Unimplemented methods
also return 404. Database errors are logged locally without exposing details to clients.

## Tests

```powershell
cd server
node --test
```

Eleven HTTP integration tests cover creation/retrieval, database reopen persistence,
combined filters, literal searches, pagination, invalid input, malformed/oversized
bodies, and missing resources. Tests use isolated databases, never the development
database. Migration changes should increment `PRAGMA user_version` and preserve data.
