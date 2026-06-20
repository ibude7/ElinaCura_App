# ElinaCura — Mobile (Flutter, iOS + Android)

AI-assisted personal health & longevity companion. Brand inspired by "Elina" who lived to 102 — calm, careful, premium liquid-glass design system (warm terracotta `#C03F0C` + forest green `#1A3C34`, frosted glass surfaces, 3D cards).

## Tech stack
- Flutter (Dart ^3.11.4), Riverpod, go_router, Firebase (auth/firestore/storage/messaging), flutter_animate.
- Design system: `lib/core/theme/ec_tokens.dart`, `ec_theme.dart`; glass widgets in `lib/shared/widgets/ec_glass.dart`; brand mark `ec_logo.dart`.

## Core requirements (static)
- Firebase auth (email, Google, guest) + role selection (patient / caregiver).
- Onboarding story flow, dashboard, medications/OCR/scanner, vitals, social/messages, profile, emergency.

## What's been implemented (this session — Jun 2026)
- **New premium logo (updated to user reference)**: forest-green circular "E-ring" with two leaves and a terracotta orange center dot, glossy 3D — recreated from the user's reference image. Cleanly keyed to transparent, derived light mark, dark mark (soft green halo for near-black), deep-forest full-bleed app icon. Regenerated ALL iOS AppIcon sizes, Android launcher/adaptive/splash, and iOS/Android launch images. Assets: `assets/images/{logo,logo_light,logo_dark,splash_logo}.png`.
- **Auth pages redesigned** (`lib/features/auth/auth_screens.dart`): premium brand hero (logo on frosted glass medallion + breathing glow), elevated glass role cards with gradient icon tiles, animated role-aware ambient glow, segmented Sign in / Create account toggle, glass text fields with icons + show/hide, animated error banner, "or" divider, Google + guest, trust row (privacy/PIPEDA/encryption), polished biometric unlock. **All existing auth logic preserved** (no auth flow changes).
- **Onboarding welcome slide** (`lib/features/auth/onboarding_view.dart`): added frosted liquid-glass medallion behind the new mark for a premium centerpiece.

## Validation
- `dart analyze` on changed files + full `lib`: **0 errors, 0 warnings** (only pre-existing `info` lints). Logo edge-quality QA: clean (8/10), no checkerboard/fringe.
- Sign in with Apple added (Jun 2026): `sign_in_with_apple ^6.1.4` + `crypto`; `AuthService.signInWithApple()` uses Firebase `OAuthProvider('apple.com')` with SHA256 nonce; Apple HIG button (black/white) shown on iOS/macOS in the auth form; iOS `Runner.entitlements` (com.apple.developer.applesignin) created + `CODE_SIGN_ENTITLEMENTS` wired into all 3 Runner build configs. Resolves & analyzes clean.
- NOTE: live on-device/simulator preview NOT run — this Linux/arm64 container can't run the Flutter tool (x64-only) or iOS rendering. A faithful HTML mock was used to preview visuals. Verify in Xcode/simulator.

## USER ACTION REQUIRED for Sign in with Apple (console/Xcode)
1. Apple Developer portal → Identifiers → App ID `com.elinacura.app` → enable **Sign in with Apple** capability.
2. Firebase Console → Authentication → Sign-in method → enable **Apple** provider.
3. Xcode → Runner target → Signing & Capabilities → **+ Capability → Sign in with Apple** (entitlements file already present), then `flutter pub get`.

## Backlog / Next action items
- P1: Apply the same liquid-glass refresh to dashboard, medications, profile screens for consistency.
- P1: Run on iOS simulator/device to visually confirm glow/blur performance; tune blur sigmas if needed on low-end devices.
- P2: Forgot-password flow on the sign-in form.
