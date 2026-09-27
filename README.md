# LSU Pop

Flutter marketplace with a Node.js + SQLite listings server. Browsing, keyword
search, category/price filters, and posting a listing with one photo all use the
API. Messages still use demo data; authentication is future work.

## Run locally

Install Flutter and Node.js 24+. From this project folder, start the server in
one terminal and keep it open:

```powershell
cd server
node src/index.js
```

In a second terminal at the project root:

```powershell
flutter pub get
flutter run
```

Android emulator builds default to `http://10.0.2.2:3000`; other platforms default
to `http://127.0.0.1:3000`. Only Android **debug** builds permit local cleartext
HTTP. Release builds should use an HTTPS API. For physical Android devices, bind
Node to the LAN interface and supply your computer's actual LAN IP:

```powershell
# Server terminal (stop the existing server with Ctrl+C first)
$env:HOST = '0.0.0.0'
node src/index.js

# Flutter terminal; replace 192.168.1.10 with your computer's LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

Both devices must be on the same network, with port 3000 reachable through the
computer's firewall. The app includes macOS network-client entitlements; Apple
platforms may additionally require local-network/transport configuration for
local HTTP, or use an HTTPS API URL. Apple builds have not been tested on Windows.

### Browser

Allow the exact Flutter origin in the server terminal, then restart Node:

```powershell
$env:ALLOWED_ORIGIN = 'http://localhost:8080'
node src/index.js
```

In the Flutter terminal:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Changing the browser hostname or port requires updating `ALLOWED_ORIGIN`.
CORS is disabled by default. This remains an unauthenticated local demo server;
all posts belong to Demo Seller. See [server setup and API](server/README.md).

## Try the marketplace

1. Open Browse. The database starts empty; mock listings are no longer displayed.
2. Tap **+**, enter a title, price, category, and optional description, then post.
3. Browse refreshes after saving. Existing search/category/price filters still apply.
4. Search by text or category; enter optional minimum/maximum dollar prices and
   tap **Apply**. Clear the price fields and apply to remove the bounds.
5. Pull down to refresh; **Load more** appears after a full page of 50 listings.
6. Restart the app/server to verify the posted listing remains.

Failed requests show a retry option; failed posts preserve the form. Prices allow
up to two decimal places and are sent as integer cents.

## Verification

```powershell
flutter analyze
flutter test
node --test server/test/api.test.js
# Requires Node on PATH; creates and cleans up an isolated database:
flutter test --dart-define=RUN_SERVER_INTEGRATION=true test/server_integration_test.dart
```

The integration test creates a listing with the Flutter repository, restarts a
real Node server, and checks persistence and combined filters. Widget tests use
an injected HTTP client, never your development database.
