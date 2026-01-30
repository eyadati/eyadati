# Review Checklist: Networking

## Purpose

Check HTTP client usage, retry/backoff, timeout handling, serialization security, error mapping, caching.

## Findings

The application primarily uses specialized SDKs (Firebase, Supabase, Chargily) rather than direct HTTP clients.

| File | Line(s) | Issue | Severity | Category | Suggested fix |
|---|---:|---|---|---|---|
| `lib/FCM/notificationsService.dart` | 14 | Supabase Edge Function call has no explicit timeout. | Medium | Reliability | Configure a timeout for `supabase.functions.invoke`. |
| `lib/chargili/paiment.dart` | 30 | `ChargilyClient` is instantiated within `_SubscribeScreenState`. | Low | Maintainability | Move to a central service or provide via Dependency Injection. |

## Verified
* [x] No plaintext secrets in headers (Firebase/Supabase SDKs handle this).
* [x] SDKs handle content type and status codes.
* [x] SDKs generally handle retry/backoff (Firestore).