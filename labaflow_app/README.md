# LabaFlow Flutter App

**Lab-a-Day Laundry Management System** — converted from single-file HTML to full-stack Flutter app supporting Web, iOS, and Android.

## Project Structure

```
labaflow_app/
├── lib/
│   ├── main.dart                          # App entry point, GoRouter, MaterialApp
│   ├── theme/
│   │   └── app_theme.dart                 # AppColors and the fixed light ThemeData
│   ├── models/
│   │   └── models.dart                    # All data models + enums + pricing results
│   ├── services/
│   │   ├── db_service.dart                # SharedPreferences data layer + seed + migration
│   │   └── pricing_service.dart           # calcPrice, applyPromo, calcLoads
│   ├── providers/
│   │   └── app_provider.dart              # ChangeNotifier state management
│   ├── widgets/
│   │   └── shared_widgets.dart            # StatusBadge, StatCard, AppCard, dialogs, etc.
│   └── screens/
│       ├── landing/landing_screen.dart    # Full landing page (hero, services, pricing, FAQ...)
│       ├── auth/auth_screen.dart          # Sign In / Register floating modal
│       ├── admin/admin_shell.dart         # Admin dashboard + all admin pages
│       ├── seller/seller_shell.dart       # Seller shell + orders/inventory/reports/messages/RFID
│       └── customer/customer_shell.dart   # Customer portal + my orders/book/messages/loyalty/profile
├── web/
│   ├── index.html                         # Flutter web entrypoint with splash screen
│   └── manifest.json                      # PWA manifest
├── android/
│   └── app/src/main/AndroidManifest.xml  # Android permissions + deep links
├── ios/
│   └── Runner/Info.plist                  # iOS permissions
└── pubspec.yaml                           # Dependencies
```

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0

### Install dependencies
```bash
cd labaflow_app
flutter pub get
```

### Run on Web
```bash
flutter run -d chrome
# or for production build:
flutter build web
```

### Run on Android
```bash
flutter run -d android
# or build APK:
flutter build apk
```

### Run on iOS (macOS required)
```bash
flutter run -d ios
# or build IPA:
flutter build ipa
```

## Authentication setup

Demo credentials have been removed. Configure Firebase and create the first administrator using the steps in [`../FIREBASE_SETUP.md`](../FIREBASE_SETUP.md).

## Features

- **Landing Page** — Hero, services, pricing, reviews, FAQ, CTA, footer with a consistent light theme
- **Auth** — Sign in + register with loading indicators; role-based routing
- **Admin Portal** — Dashboard with fl_chart charts, analytics, inventory monitor, promo codes, user management
- **Seller Portal** — Orders with auto-suggest search, RFID assignment, inventory, reports (all white text), messaging, RFID tags
- **Customer Portal** — My orders with QR codes, book service, messages, LabaPoints loyalty, profile picture
- **Payment Gate** — Cash and GCash (with QR + reference number); blocks releasing unpaid orders
- **Notifications** — Push-style notifications for order status changes

## Architecture

| Layer | Implementation |
|-------|---------------|
| State | `provider` (ChangeNotifier) |
| Storage | `shared_preferences` (mirrors localStorage) |
| Navigation | `go_router` with role-based redirects |
| Charts | `fl_chart` |
| QR codes | `qr_flutter` |
| Image pick | `image_picker` |

## Data Persistence

All data is stored in `SharedPreferences` under `lf3_*` keys — identical to the HTML app's localStorage approach, ensuring data compatibility and portability.
