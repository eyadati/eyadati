# Review Checklist: State Management

## Purpose

Verify correctness and efficiency of state solution (Provider, Riverpod, Bloc, GetX, setState), data flow integrity, and leak prevention.

## Checklist

* Single source of truth: confirm where state is stored and consumed.
* Check lifecycles: providers disposed correctly; subscriptions cancelled.
* For streams: ensure `listen` is cancelled in `dispose`.
* Avoid exposing mutable state directly; use immutable models or unmodifiable views.
* Check for duplicated state across widgets.
* Confirm side effects (API calls) are in controllers/blocs not in UI.
* Evaluate granularity of notified listeners — avoid broad `notifyListeners()` causing full rebuild.
* For Riverpod/Bloc: ensure tests for provider logic and event handling.

## Reporting template

| File | Line(s) | Issue | Severity | Category | Suggested fix |
|---|---:|---|---:|---|---|
| `lib/clinic/clinicRegisterUi.dart` | 258 | `ClinicOnboardingProvider` handles complex registration flow without atomicity. Manual rollback (`user.delete()`) is used but not guaranteed if app crashes. | High | Reliability/Data Integrity | Use a Firebase Cloud Function for atomic User creation + Firestore doc write. |
| `lib/NavBarUi/UserNavBar.dart` | 41-70 | Favorite clinics are stored with full clinic data (name, address, etc.) in the user's `favorites` subcollection. Updates to the original clinic document will NOT propagate here. | High | Data Integrity | Store only the `clinicId` and fetch clinic data as needed, or use a Cloud Function to sync updates across all users who favorited the clinic. |
| `lib/clinic/clinicSettingsPage.dart` | 27 | `ClinicsettingProvider` instantiates `ClinicFirestore` directly. Many other providers do the same. | Low | Architecture | Inject `ClinicFirestore` as a dependency (singleton) to improve testability and reduce redundant object creation. |
| `lib/user/user_appointments.dart` | 44 | `UserAppointmentsProvider` creates `UserFirestore` in its constructor if not provided. | Low | Architecture | Same as above. Prefer Dependency Injection. |