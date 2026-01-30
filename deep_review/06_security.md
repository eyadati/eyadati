# Review Checklist: Security

## Purpose

Find security vulnerabilities: secrets, unsafe deserialization, insecure storage, auth flows, improper permissions.

## Checklist

* No API keys, service account json, or secrets in repo.
* Check `google-services.json` / `GoogleService-Info.plist` for sensitive entries.
* Validate inputs before sending to backend.
* Prevent log of sensitive info (tokens, passwords, PII).
* Use secure storage for tokens (Keychain/EncryptedSharedPreferences).
* Ensure proper auth state handling (token expiry, refresh).
* Confirm WebView content blocked from loading arbitrary JS if not required.
* For platform channels, validate incoming messages and sanitize inputs.

## Reporting template

| File | Line(s) | Issue | Severity | Category | Suggested fix |
|---|---:|---|---:|---|---|
| `lib/chargili/paiment.dart` | 23 | Hardcoded Chargily Pay Secret Key (`test_sk_...`). Even if a test key, it should not be in source control. | High | Security | Move to a secure environment variable or a local `secrets.dart` file that is ignored by git. |
| `firestore.rules` | 15-17 | `match /clinics/{clinicId}/appointments/{appointmentId}` allows `read, write` to ANY authenticated user. | **Critical** | Security | Restrict write access so only the owner or the booking user can modify. |
| `lib/clinic/clinicAuth.dart` | 17-57 | No role verification after login. A 'user' could potentially access clinic-only data if they know the UID. | High | Security | Verify `clinics/{uid}` exists immediately after login. |
| `lib/main.dart` | 64 | Supabase `anonKey` is hardcoded. | Low | Security | Generally acceptable for client-side if RLS is strict, but better to use environment variables. |