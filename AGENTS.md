# Eyadati - Agent Instructions

## Build Commands

```bash
flutter analyze      # lint + static analysis
flutter run          # run on device/emulator
flutter build web   # build PWA
flutter build apk   # build Android APK
```

## Key Architecture

- **Two user flows**: Clinic owners and regular users
- **Backend**: Firebase (Auth/Firestore) + Supabase (Storage/Edge Functions)
- **Payments**: Chargily Pay via Supabase edge function `create-chargily-checkout`
- **State management**: Provider package
- **i18n**: easy_localization (en, fr, ar) in `assets/translations/`

## Critical Quirks

### Web vs Native Guards
`kIsWeb` is used throughout to disable Firebase Messaging and Crashlytics on web:
```dart
if (!kIsWeb) { FirebaseMessaging... }
```

### Supabase Edge Functions
- `supabase/functions/chargily-webhook/index.ts` - payment webhook handler
- `supabase/functions/fcm_notifications/index.ts` - FCM notifications
- Webhook secret is hardcoded (test key in repo)

### Firestore Settings (Mobile Only)
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
This is guarded with `if (!kIsWeb)`.

### Provider Initialization
```dart
Provider.debugCheckInvalidValueType = null;  // Required in main.dart
```

### Image Storage
Clinic avatars uploaded to Supabase Storage, not Firebase Storage.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `lib/clinic/` | Clinic registration, login, appointments, settings |
| `lib/user/` | User profile, appointments |
| `lib/Appointments/` | Booking logic, clinic lists, slots UI |
| `lib/NavBarUi/` | Floating bottom navigation bars |
| `lib/chargili/` | Chargily payment integration |
| `lib/Themes/` | Light/dark theme definitions |
| `lib/FCM/` | Firebase Cloud Messaging |
| `supabase/functions/` | Supabase Edge Functions (backend) |

## Entry Point

`lib/main.dart` → `flow.dart` → routes to clinic or user flow based on auth state.

## No Existing Tests

The project has `flutter_test` as a dev dependency but no test files or test scripts configured.