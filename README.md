# Reconex

Reconex is a Flutter attack-surface monitor. It tracks the externally reachable
assets of domains you own — subdomains, open ports, DNS, SSL certificates,
technologies, security headers and exposed resources — runs scans, records what
changes between scans, and raises alerts. It also includes a Fing-style local
network scanner that discovers devices on the Wi-Fi the phone is connected to.

The app talks to a Node.js / Express / Prisma / PostgreSQL backend (see the
`reconex_backend` repository).

## Features

- **Auth** — register and login; the bearer token is kept in secure storage, and
  a `401` clears it and returns to login.
- **Domains** — add, edit and delete domains; per-domain dashboard with a summary
  of subdomains, ports, DNS, SSL, technologies, security headers, exposed
  resources, alerts and recent changes.
- **Scans** — start a full background scan, poll its progress step by step, and
  browse scan history.
- **Changes** — differences detected between scans, filterable by category,
  type and severity.
- **Subdomains / Ports / DNS / Technologies / SSL** — live checks and stored
  results, plus an asset-relationship map.
- **Security** — security-header and exposed-resource checks with history.
- **Alerts** — one feed across all domains and local networks, severity-filtered.
- **Local network scanner** — detects the current Wi-Fi and lists connected
  devices (IP, hostname, MAC and vendor when the OS exposes them), with an
  on-demand per-device port check. Runs entirely on the phone; no private
  address is sent to the backend.

## Tech stack

| Area | Choice |
|------|--------|
| State management & routing | [GetX](https://pub.dev/packages/get) |
| HTTP | [Dio](https://pub.dev/packages/dio) + [pretty_dio_logger](https://pub.dev/packages/pretty_dio_logger) |
| Secure token storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Local network discovery | [network_info_plus](https://pub.dev/packages/network_info_plus), [network_tools](https://pub.dev/packages/network_tools) |
| Permissions | [permission_handler](https://pub.dev/packages/permission_handler) |
| On-disk cache | [path_provider](https://pub.dev/packages/path_provider) |

## Architecture

```
lib/
  core/
    network/        ApiClient (Dio), response envelope, pagination, exceptions
    storage/        token storage, JSON disk cache
    controllers/    PagedController base for paginated lists
    custom_widgets/ shared UI (cards, badges, filters, states, nav bar, ...)
    themes/         colors, spacing, radius, text tokens, icons
    utils/          formatters, validators, JSON helpers
  data/
    models/         typed API models
    services/       one service per backend area (auth, domain, scan, risk, ...)
  features/         screens + GetX controllers, grouped by feature
  routes/           named routes and their bindings
  main.dart         GetMaterialApp + InitialBinding
```

- **Services** wrap the API; **controllers** hold screen state; **screens**
  render it. Every list screen extends `PagedController` for pagination with
  loading, empty, error and load-more states.
- The API envelope is `{ success, message, data }`; `ApiClient` unwraps `data`
  and turns failures into `ApiException`.
- The home tabs are built lazily, so a tab's work (such as the network scan)
  only runs when that tab is first opened.

## Getting started

Requires the Flutter SDK (Dart `^3.10.7`).

```sh
flutter pub get
flutter run
```

The backend base URL is set in `lib/core/network/api_client.dart`
(`ApiClient.baseUrl`). Point it at your own `reconex_backend` instance if needed.

## Permissions

The local network scanner needs:

- **Android** — `INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`,
  `ACCESS_FINE_LOCATION` and `NEARBY_WIFI_DEVICES`. Location is required to read
  the Wi-Fi name; the scan itself works without it.
- **iOS** — Local Network permission (`NSLocalNetworkUsageDescription`) and,
  for the SSID, location.

Platform limits: on modern Android and iOS, apps usually can't read other
devices' MAC addresses, so MAC and manufacturer are often shown as "Unknown".
The phone sees only its own subnet.

## Testing

```sh
flutter test
```

`test/` covers the API client, pagination, model parsing, and a widget test that
renders every screen against a fake API and saves screenshots when
`SCREENSHOT_DIR` is set:

```sh
SCREENSHOT_DIR=/path/to/out flutter test test/screens_render_test.dart
```

## Status

The external attack-surface and local-network features are in use. The
attack-surface risk-scoring feature exists in the codebase but is currently
disabled (commented out) pending backend availability.
