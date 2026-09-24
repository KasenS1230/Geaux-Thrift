import { fileURLToPath } from 'node:url';
import { openDatabase } from './database.js';
import { createApp } from './app.js';

const port = Number(process.env.PORT ?? 3000);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT must be 1–65535');
const db = openDatabase(process.env.DB_PATH ?? fileURLToPath(new URL('../data/listings.sqlite', import.meta.url)));
const server = createApp(db, { allowedOrigin: process.env.ALLOWED_ORIGIN ?? '' });
const host = process.env.HOST ?? '127.0.0.1';
server.on('error', error => { console.error(error); db.close(); process.exitCode = 1; });
server.listen(port, host, () => console.log(`LSU Pop API listening on http://${host}:${port}`));
let closing = false;
function stop() {
  if (closing) return;
  closing = true;
  server.close(() => db.close());
}
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
