# INVENTORY

A **Flutter** inventory and light-POS app with **Firebase** (optional), **BDT (৳)** money formatting, **QR** workflows for stock and sales, **role-based access** (owner / admin / staff), and a **premium Material 3** UI with bottom navigation, responsive layout, and **light / dark** themes.

---

## Highlights

| Area | What you get |
|------|----------------|
| **UI** | Premium app chrome (`PremiumAppBar`, cards, gradients, shared tokens), **shell** with bottom nav (Home · Products · Sell · Settings), **appearance** control (System / Light / Dark). |
| **Auth & SaaS roles** | Email/password; Firestore `users` document drives **owner**, **admin**, or **staff** (profit/loss, business settings, team, product CRUD). |
| **Demo mode** | Runs without Firebase when options are missing or init fails; fixed **demo** emails + password for local QA (see [Demo mode](#demo-mode)). |
| **Products** | List, detail, add/edit (admin), optional **Storage** image when Firebase is on. |
| **QR** | Per-product codes (`inv:product:` + id); **scan** for stock-in path or POS cart; manual ID fallback on web/camera issues. |
| **Stock in** | Receive quantity per product (writes through `ProductService`). |
| **POS / cart** | Search, QR add, cart lines, **checkout** (writes sales + stock via `SaleService`). |
| **Dashboard** | KPIs, shortcuts to reports, AI, team, QR. |
| **Reports** | Sales, stock valuation, profit/loss (owner/admin). |
| **AI** | Assistant (local rules + optional **OpenAI / Gemini** via `.env` or `--dart-define`), recognition (mock), smart insights, restock hints, analytics charts. |
| **Team** | Owner/admin: **User management** (Firebase); demo role switcher when Firebase is off. |
| **Settings** | Business name (owner), backend mode, version, appearance, logout. |

---

## Tech stack

- **Flutter** (Dart SDK ≥ 3.2), **Material 3**, `google_fonts`, `intl`
- **Firebase** (optional): Auth, Firestore, Storage
- **State:** `provider`
- **QR:** `qr_flutter`, `mobile_scanner`
- **Media:** `image_picker`, `cached_network_image`
- **Charts:** `fl_chart` (analytics)
- **Config:** `flutter_dotenv` (optional `.env`)

---

## Routes & entry

Named routes live in **`lib/routes/app_router.dart`**. After login, **`/dashboard`** opens **`AppShellScreen`** (bottom nav + tab stack). Pushed routes (product detail, QR, reports, etc.) stack on top as before.

| Screen | Route constant |
|--------|------------------|
| Splash | `AppRoutes.splash` `/` |
| Login | `AppRoutes.login` |
| Dashboard (in shell) | `AppRoutes.dashboard` |
| Products · Add/Edit · Detail | `AppRoutes.products` … |
| QR generate / scan | `AppRoutes.qrGenerate` · `AppRoutes.qrScan` |
| Stock in · Sell · Cart | `AppRoutes.stockIn` · `AppRoutes.sell` · `AppRoutes.cart` |
| Reports | `AppRoutes.reportSales` · `reportStock` · `reportPnL` |
| AI | `AppRoutes.aiRecognition` · `aiAssistant` · `aiInsights` · `aiRestock` · `aiAnalytics` |
| Team · Settings | `AppRoutes.team` · `AppRoutes.settings` |

Missing arguments show **`MissingRouteArgumentScreen`** (`lib/routes/route_errors.dart`).

---

## Demo mode

If Firebase is **not** configured or initialization fails, the app runs in **demo/local** mode:

- No Firestore writes for business data (in-memory / local services as implemented).
- Sign in with **`owner@inventory.com`**, **`staff@inventory.com`**, or **`admin@inventory.com`** and password **`123456`** (see `AuthService` in `lib/services/auth_service.dart`).
- **Do not** use these defaults in production-facing builds; replace with Firebase or your own auth.

---

## Firebase & FlutterFire

1. Create a project in [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication → Email/Password**.
3. Create **Firestore** and **Storage** (apply **production rules** before launch).
4. Run **`flutterfire configure`** to regenerate **`lib/firebase_options.dart`** and platform files.
5. Place **`google-services.json`** / **`GoogleService-Info.plist`** per FlutterFire output.
6. Seed **`users/{uid}`** with `businessId`, `role` (`owner` \| `admin` \| `staff`), etc.

QR payloads: see **`lib/core/utils/qr_payload.dart`** (`inv:product:` + product id).

---

## Environment variables (AI)

Copy **`.env.example`** → **`.env`** (ignored by git). Variables are documented in the example file.

Alternatively:

```bash
flutter run -d chrome --dart-define=AI_PROVIDER=openai --dart-define=AI_API_KEY=YOUR_KEY --dart-define=AI_MODEL=gpt-4o-mini
```

Never commit real API keys. **`lib/firebase_options.dart`** in template form uses **`YOUR_*`** placeholders until you run FlutterFire.

---

## Install & run

**Prerequisites:** Flutter SDK (stable), optional Firebase project.

```bash
git clone <your-repo-url>
cd INVENTORY
flutter pub get
```

```bash
flutter devices
flutter run                    # device / emulator
flutter run -d chrome          # web (recommended for quick UI checks)
flutter analyze
flutter test
flutter build web              # production web bundle
```

Release for mobile: follow [Flutter deployment](https://docs.flutter.dev/deployment).

---

## Folder structure (selected)

```
lib/
├── main.dart                    # Providers, theme, MaterialApp
├── firebase_options.dart        # FlutterFire output (placeholders until configure)
├── core/
│   ├── theme/                   # AppTheme, ThemeModeController
│   ├── widgets/premium/         # Shared premium UI components
│   └── ...
├── models/
├── providers/
├── routes/
├── screens/
│   ├── shell/app_shell_screen.dart
│   ├── splash/, auth/, dashboard/, products/, qr/, stock/, sell/, cart/
│   ├── reports/, ai/, users/, settings/
├── services/
test/
```

---

## Docs & community

| Doc | Purpose |
|-----|---------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting |
| [CHANGELOG.md](CHANGELOG.md) | Release notes |
| [LICENSE](LICENSE) | MIT |

---

## Screenshots

Add your own under `docs/images/` and link them here (dashboard, products, QR, cart, settings).

---

## Roadmap (ideas)

- Example **Firestore security rules** in-repo + CI  
- **Offline** queue and sync indicators  
- **1D barcodes** alongside QR  
- Stronger **multi-tenant** admin UX  
- **CSV/PDF** exports  
- Deeper **on-device ML** for recognition  
- **Integration tests** with Firebase Emulator Suite  

---

## License

**MIT** — see [LICENSE](LICENSE).
