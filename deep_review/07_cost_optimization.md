# Review Checklist: Cost Optimization

## Purpose

Identify app behaviors that drive cloud costs (Firestore reads/writes, functions invocations, storage, network egress).

## Findings

| File | Line(s) | Issue | Severity | Category | Suggested fix |
|---|---:|---|---|---|---|
| `lib/NavBarUi/UserNavBar.dart` | 42 | `favoriteClinicsStream` has no limit. A user with 100+ favorites would trigger many document reads. | Low | Cost | Add `.limit(20)` and implement pagination if needed. |
| `lib/Appointments/clinicsList.dart` | 135 | `geoRef.fetchWithin` returns all results in range. If a city has 500+ clinics, this triggers 500 reads at once. | Medium | Cost | Implement radius clamping or client-side result limiting. |
| `lib/clinic/clinic_appointments.dart` | 155 | Heatmap query (`fetchHeatMapData`) runs on every swipe. | Low | Cost | Cache heatmap data by month so it only re-fetches when switching to a month not in memory. |

## Verified
* [x] Firestore persistence enabled in `main.dart` (helps reduce repeat reads).
* [x] Pagination implemented for Standard clinic search.