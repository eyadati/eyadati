# Review Checklist: Architecture

## Purpose

High-level architecture sanity: module boundaries, dependency inversion, single responsibility, scalability.

## Findings

| File | Issue | Severity | Suggested fix |
|---|---|---|---|
| Entire `lib/` | Dependency Inversion: Firestore repositories are often instantiated directly in Providers (`ClinicsettingProvider`, `UserAppointmentsProvider`). | Medium | Use `GetIt` or a global Service Locator to inject singletons. |
| `lib/NavBarUi/ClinicNavBar.dart` | Mixing UI navigation with Data simulation and Firestore listening. | Medium | Extract notification logic into a separate `NotificationProvider`. |
| `lib/Appointments/slotsUi.dart` | Massive file containing both UI and complex slot generation logic. | Medium | Extract slot generation into a dedicated `SlotService`. |

## Verified
* [x] Logic is mostly separated into `Provider` classes.
* [x] Feature-based folder structure is followed (`clinic/`, `user/`, `Appointments/`).