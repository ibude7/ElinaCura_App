# ElinaCura Mobile (Flutter)

Native iOS and Android app for ElinaCura — AI-assisted personal health companion.

## Prerequisites

- Flutter SDK (stable, 3.11+)
- Xcode 16+ (iOS)
- Android Studio / SDK 26+ (Android)
- Firebase project `elinacura`

## Setup

```bash
cd elinacura_mobile
flutter pub get
flutterfire configure --project=elinacura
```

Set backend URL for local development:

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:8000
```

## Run

```bash
flutter run
```

## Project structure

- `lib/core/` — auth, API client, Firebase, notifications, theme, router
- `lib/features/` — screens by domain (auth, dashboard, medications, social, profile)
- `lib/shared/` — models, widgets, utilities

## MVP features

- Firebase auth (email, Google, guest) with role selection
- Dashboard with health overview states
- OCR medication capture, barcode scanner, reminders, refill calendar
- Health, profile, settings (PIPEDA consent, biometrics)
- Emergency screen, messages (Firestore), caregiver dashboard
- FCM device registration + local medication notifications
