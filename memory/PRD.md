# ElinaCura — Mobile (Flutter, iOS + Android)

AI-assisted personal health & longevity companion. Brand inspired by "Elina" who lived to 102 — calm, careful, premium liquid-glass design system (warm terracotta `#C03F0C` + forest green `#1A3C34`, frosted glass surfaces, 3D cards).

## Tech stack
- Flutter (Dart ^3.11.4), Riverpod, go_router, Firebase (auth/firestore/storage/messaging), flutter_animate.
- Design system: `lib/core/theme/ec_tokens.dart`, `ec_theme.dart`; glass widgets in `lib/shared/widgets/ec_glass.dart`; brand mark `ec_logo.dart`.

## Core requirements (static)
- Firebase auth (email, Google, guest) + role selection (patient / caregiver).
- Onboarding story flow, dashboard, medications/OCR/scanner, vitals, social/messages, profile, emergency.

## What's been implemented (this session — Jun 2026)
- **New premium logo**: glossy heart+leaf liquid-glass emblem (terracotta/amber + emerald). Generated master, cleanly keyed to transparent, derived light mark, dark mark (warm halo for near-black), full-bleed app icon. Regenerated ALL iOS AppIcon sizes, Android launcher/adaptive/splash, and iOS/Android launch images. Assets: `assets/images/{logo,logo_light,logo_dark,splash_logo}.png`.
- **Auth pages redesigned** (`lib/features/auth/auth_screens.dart`): premium brand hero (logo on frosted glass medallion + breathing glow), elevated glass role cards with gradient icon tiles, animated role-aware ambient glow, segmented Sign in / Create account toggle, glass text fields with icons + show/hide, animated error banner, "or" divider, Google + guest, trust row (privacy/PIPEDA/encryption), polished biometric unlock. **All existing auth logic preserved** (no auth flow changes).
- **Onboarding welcome slide** (`lib/features/auth/onboarding_view.dart`): added frosted liquid-glass medallion behind the new mark for a premium centerpiece.

## Validation
- `dart analyze` on changed files + full `lib`: **0 errors, 0 warnings** (only pre-existing `info` lints). Logo edge-quality QA: clean (8/10), no checkerboard/fringe.
- NOTE: live on-device/simulator preview NOT run — this Linux/arm64 container can't run the Flutter tool (x64-only) or iOS rendering. Verify visually in Xcode/simulator.

## Backlog / Next action items
- P1: Apply the same liquid-glass refresh to dashboard, medications, profile screens for consistency.
- P1: Run on iOS simulator/device to visually confirm glow/blur performance; tune blur sigmas if needed on low-end devices.
- P2: Add "Sign in with Apple" (App Store requirement when offering Google) — requires integration_expert + auth service method.
- P2: Forgot-password flow on the sign-in form.
