# INVENTORY

Modern inventory and sales management built with Flutter, Firebase, and a premium adaptive UI.

INVENTORY helps small businesses track stock, process sales, scan QR labels, and gain AI-assisted insights with role-based access for multi-user operations.

## Key Features

- Premium responsive UI (mobile, tablet, web) with light and dark theme support
- Product inventory management with category, pricing, quantity, and optional image
- QR-powered inventory workflow for product labels, scanning, and quick stock actions
- POS and checkout flow with cart, quantity control, and stock-safe sale completion
- Sales, stock, and profit/loss reporting dashboards
- SaaS-friendly roles: owner, admin, and staff
- Demo mode for local development without Firebase setup

## AI-Powered Features

- AI Assistant for inventory and sales questions
- AI Product Recognition flow (mock-ready pipeline for real model integration)
- Smart Insights and restock prediction screens
- Advanced analytics view with trend charts

## QR Inventory Features

- Generate product QR labels (`inv:product:<productId>`)
- Scan QR for stock-in workflow
- Scan QR directly into POS/cart workflow
- Manual ID fallback for devices without camera access

## POS / Sales System

- Sell screen with search and quick add
- Cart with quantity updates and stock validation
- Checkout flow that records sales and updates stock atomically through services
- BDT (Tk) currency formatting across sales flows and reports

## SaaS Multi-User Roles

- `owner`: full business control, team management, settings, reports
- `admin`: product and operational management
- `staff`: day-to-day operations (sell, stock in, scanning)

Role and business scoping are driven by user profile data in Firestore (or demo fallback behavior).

## Tech Stack

- Flutter (Dart, Material 3)
- Provider state management
- Firebase Authentication, Cloud Firestore, Firebase Storage (optional/fallback-safe)
- QR: `qr_flutter`, `mobile_scanner`
- AI integration layer via optional environment variables (`flutter_dotenv`, HTTP APIs)
- Charts and analytics with `fl_chart`

## Screenshots (Placeholder)

Add screenshots under `docs/images/` and update this section.

Suggested captures:
- Splash/Login
- Dashboard
- Product list/details
- QR generate/scan
- Sell + Cart checkout
- Reports
- AI assistant/insights
- Settings (theme switch)

## Installation

Prerequisites:
- Flutter SDK (stable)
- Git
- Optional Firebase project for live backend mode

```bash
git clone <your-repo-url>
cd INVENTORY
flutter pub get
```

Run:

```bash
flutter run
```

Web (Chrome):

```bash
flutter run -d chrome
```

Quality checks:

```bash
flutter analyze
flutter test
```

## Firebase Setup (Summary)

1. Create a Firebase project.
2. Enable Email/Password in Firebase Authentication.
3. Create Firestore and Storage.
4. Run `flutterfire configure`.
5. Verify `lib/firebase_options.dart` is generated for your targets.
6. Configure roles/business documents for your users.

Detailed guide: [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)

## Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Supported keys:
- `AI_PROVIDER`
- `AI_API_KEY`
- `AI_MODEL`

`.env` is gitignored. Never commit real secrets.

## GitHub Workflow

Recommended flow:
1. Create branch from `main`
2. Make focused changes
3. Run analyze/tests locally
4. Open PR with clear summary and test notes

See full workflow: [`docs/GITHUB_WORKFLOW.md`](docs/GITHUB_WORKFLOW.md)

## Project Documentation

- [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md)
- [`docs/FEATURES.md`](docs/FEATURES.md)
- [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)
- [`docs/GITHUB_WORKFLOW.md`](docs/GITHUB_WORKFLOW.md)
- [`CONTRIBUTING.md`](CONTRIBUTING.md)
- [`SECURITY.md`](SECURITY.md)
- [`CHANGELOG.md`](CHANGELOG.md)

## Roadmap

- Production-grade Firestore/Storage rule templates
- Offline-first sync improvements
- Export reports (CSV/PDF)
- Enhanced AI model integration for recognition and forecasting
- End-to-end integration tests with Firebase emulator suite
- Granular tenant and plan controls for SaaS usage

## License

MIT License. See [`LICENSE`](LICENSE).
