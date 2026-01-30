# Review Checklist: Firebase

## Purpose

Review all Firebase usage: initialization, auth, Firestore/RTDB rules, Cloud Functions calls, storage, offline handling, batching, costs and security rules.

## Scope

* `android/ios/firebase` config files
* `lib/**` files that reference `firebase_*` packages
* Cloud Functions code (if present)

## Line-by-line checklist

For each file that touches Firebase:

* Confirm initialization occurs exactly once and uses correct environment config.
* Verify `await`/`then` usage — no unhandled futures.
* Check use of `.get()` vs `.snapshots()` for frequency (cost).
* Check query filters and indexes — no client-side filtering of large collections.
* Verify batched writes and transactions where needed.
* Check offline persistence and merge/conflict handling.
* Ensure no logging of secrets or user PII.
* Confirm security rules exist and match client assumptions.
* Confirm use of `securityRules` tests and emulator for local testing.
* Validate Storage rules for path scoping and content-type checks.

## Common issues to flag

* Multiple app initializations.
* Client-side hot queries (no limits/pagination).
* Unbounded listeners on large collections.
* Rules that allow `read: true` or `write: true` broadly.
* Missing input validation before writes.

## Automated checks to run

* `flutter analyze`
* Unit tests for firebase mocks (use emulator)
* Run Firestore emulator + rules unit tests

## Reporting template (copy per finding)

| File | Line(s) | Issue | Severity | Category | Suggested fix | Tests to add |
|---|---:|---|---:|---|---|---|
| `lib/main.dart` | 86 | `DataSeeder.seedClinics()` is uncommented and runs on every app launch. This creates 50+ documents per launch. | **Critical** | Cost/Correctness | Remove or comment out the line. Move to a dev-only flag or dedicated CLI command. | N/A |
| `firestore.rules` | 15-17 | `/clinics/{clinicId}/appointments/{appointmentId}` allows `read, write` for any authenticated user. Any user can delete/modify any clinic's appointments. | **Critical** | Security | Restrict write: `allow write: if request.auth.uid == clinicId;` (and handle user creation via backend or stricter rule). | Test rule with user trying to delete another's appointment. |
| `lib/clinic/clinicAuth.dart` | 17-57 | `clinicLoginIn` (via dialog) signs in user without verifying if they are actually a clinic (role check missing). Redirects to `Clinichome` immediately. | High | Security/Logic | Add role verification check (read Firestore `clinics/{uid}`) after auth, similar to `ClinicLoginPage`. | Integration test trying to login as 'user' on clinic form. |
| `lib/user/user_firestore.dart` | 27, 43 | `addUser` and `updateUser` use `.set({...})` without `SetOptions(merge: true)`. This overwrites the entire document, potentially deleting existing fields. | High | Data Integrity | Use `.set({...}, SetOptions(merge: true))` or `.update({...})`. | Unit test: update user profile, assert other fields persist. |
| `lib/clinic/clinicAuth.dart` | 55 | Swallows specific `FirebaseAuthException` codes and shows generic "login_failed". | Medium | UX | Catch `FirebaseAuthException` and show specific error messages (e.g., wrong password, user not found). | N/A |
| `lib/main.dart` | 91 | `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED` used. Could fill up user device storage. | Low | Performance | Use default size or set a reasonable limit (e.g., 100MB). | N/A |