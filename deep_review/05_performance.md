# Review Checklist: Performance

## Purpose

Pinpoint performance hotspots and actionable improvements (render, memory, CPU, start time).

## Findings

| File | Line(s) | Issue | Severity | Category | Suggested fix |
|---|---:|---|---|---|---|
| `lib/NavBarUi/UserNavBar.dart` | 347 | `CachedNetworkImageProvider` used without `maxHeight`/`maxWidth` or `memCacheWidth`/`memCacheHeight`. Large clinic images can consume excessive memory. | Medium | Memory | Use `ResizeImage` wrapper or `memCacheWidth` to downscale images in memory. |
| `lib/clinic/clinic_appointments.dart` | 155 | `fetchHeatMapData` is called on `onPageChanged`. Rapid swiping of calendar might trigger many overlapping Firestore queries. | Low | Performance | Add a debounce or cancel previous query before starting a new one. |
| `lib/Appointments/clinicsList.dart` | 130 | Geo-query radius is hardcoded to 100km. Large result sets might impact UI rendering if not paginated (Geo-queries here are not paginated). | Medium | Performance | Implement client-side slicing or radius adjustment if results > 50. |

## Verified
* [x] `ListView.builder` used for long lists (Clinics, Appointments).
* [x] `FutureBuilder` futures refactored to `State` (mostly).
* [x] Slidable used correctly without blocking UI.