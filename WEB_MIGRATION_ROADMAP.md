# Web-Only Migration Roadmap: Eyadati

## Goal
Transform Eyadati from Android/Web hybrid to **Web-Only PWA** serving all platforms via browser.

---

## Phase 1: Package Audit & Cleanup

### 1.1 Remove Native-Only Packages

| Package | Action | Reason |
|---------|--------|--------|
| `mobile_scanner` | **Remove** | Not web-compatible |
| `geolocator` | **Remove** | Not web-compatible |
| `permission_handler` | **Remove** | Native SDK only |
| `add_2_calendar` | **Remove** | Replace with .ics export |
| `firebase_messaging` | **Remove** | Use Web Push instead |
| `firebase_crashlytics` | **Remove** | Not needed for web |
| `firebase_analytics` | **Remove** | Use Supabase analytics |
| `geolocator_web` | Not needed | No geolocator |
| `geolocator_platform_interface` | Not needed | No geolocator |

### 1.2 Keep Web-Compatible Packages

| Package | Keep | Notes |
|---------|------|-------|
| `firebase_core` | ✅ | Web SDK works |
| `firebase_auth` | ✅ | Works on web |
| `cloud_firestore` | ✅ | Works on web |
| `supabase_flutter` | ✅ | Works on web |
| `file_picker` | ✅ | Web file input |
| `google_places_flutter` | ✅ | Web Places API |
| `url_launcher` | ✅ | Open external links |
| `easy_localization` | ✅ | i18n support |
| `provider` | ✅ | State management |
| `pwa_install` | ✅ | PWA install prompt |
| `connectivity_plus` | ✅ | Online/offline detection |

### 1.3 Verify Web Compatibility
```bash
flutter doctor
flutter config --enable-web
flutter build web
```

---

## Phase 2: Code Refactoring

### 2.1 Remove kIsWeb Guards
Search and replace pattern:
```dart
// BEFORE
if (!kIsWeb) { FirebaseMessaging... }

// AFTER (delete entirely)
```

Files to update:
- [ ] `lib/main.dart` - Remove kIsWeb guards
- [ ] `lib/firebase_options.dart` - Remove kIsWeb branch
- [ ] `lib/NavBarUi/appointments_management.dart` - Remove kIsWeb guard
- [ ] `lib/Appointments/slotsUi.dart` - Remove kIsWeb guards
- [ ] `lib/clinic/clinic_appointments.dart` - Remove kIsWeb check
- [ ] `lib/user/user_appointments.dart` - Remove kIsWeb check

### 2.2 Replace Native Features

| Feature | Native Code | Web Replacement |
|---------|-------------|---------------|
| QR Scanner | `mobile_scanner` | `file_picker` + `qr_flutter` decode image |
| Location | `geolocator` | Google Places Autocomplete |
| Calendar | `add_2_calendar` | `.ics` file download + url_launcher |
| Notifications | `firebase_messaging` | Optional: Web Push API |
| Image Upload | camera/gallery | `file_picker` (web input) |

### 2.3 Update Clinic Registration
- [ ] `lib/clinic/clinic_register_ui_widgets.dart` - Remove camera conditionals
- [ ] `lib/clinic/clinic_register_provider.dart` - Remove dart:io usage
- [ ] `lib/clinic/clinic_edit_profile.dart` - Remove dart:io usage

---

## Phase 3: PWA Optimization

### 3.1 Web Manifest
```json
// web/manifest.json
{
  "name": "Eyadati",
  "short_name": "Eyadati",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#2196F3",
  "icons": [...]
}
```

### 3.2 Service Worker
- [ ] Offline page caching
- [ ] API response caching
- [ ] Background sync for offline actions

### 3.3 Install Prompt
- [ ] Keep `pwa_install` package
- [ ] Customize install banner UI

---

## Phase 4: Responsive UI

### 4.1 Breakpoints
```dart
const double phoneBreakpoint = 600;
const double tabletBreakpoint = 900;
const double desktopBreakpoint = 1200;
```

### 4.2 Layout Adaptation
- [ ] Phone: Bottom navigation, full-width cards
- [ ] Tablet: Side navigation, multi-column
- [ ] Desktop: Persistent sidebar, spacious layout

### 4.3 Touch vs Mouse
- [ ] Larger tap targets for mobile browsers
- [ ] Hover states for desktop
- [ ] Right-click context menus (desktop)

---

## Phase 5: Web Push Notifications (Optional)

### 5.1 Implementation Options
1. **Firebase Web SDK** - VAPID keys, service worker registration
2. **OneSignal** - Third-party, easier setup
3. **Supabase Realtime** - WebSocket notifications

### 5.2 Fallback
- Email notifications via Supabase Edge Function

---

## Phase 6: Testing & Deployment

### 6.1 Browser Testing
- [ ] Chrome (mobile + desktop)
- [ ] Safari (iOS)
- [ ] Firefox
- [ ] Edge

### 6.2 Lighthouse Audit
```bash
flutter build web
# Run Lighthouse in Chrome DevTools
```

Targets:
- Performance: >90
- Accessibility: >90
- PWA: All checks pass
- Best Practices: >90

### 6.3 Deploy
- [ ] Vercel / Netlify / Firebase Hosting
- [ ] Custom domain
- [ ] HTTPS (auto with hosting)

---

## Phase 7: Cleanup Checklist

- [ ] Delete `android/` directory
- [ ] Delete `ios/` directory  
- [ ] Delete `lib/FCM/` directory
- [ ] Delete `lib/webUI/` (old web helpers)
- [ ] Remove temp files (`temp_*.txt`)
- [ ] Update `.gitignore`
- [ ] Update `pubspec.yaml` dependencies
- [ ] Update `AGENTS.md`

---

## Estimated Effort

| Phase | Time | Complexity |
|-------|------|------------|
| Phase 1: Package Audit | 1-2 hours | Low |
| Phase 2: Code Refactor | 4-8 hours | Medium |
| Phase 3: PWA Optimization | 2-3 hours | Low |
| Phase 4: Responsive UI | 8-16 hours | High |
| Phase 5: Web Push | 4-6 hours | Medium |
| Phase 6: Testing | 2-4 hours | Low |
| Phase 7: Cleanup | 1-2 hours | Low |

**Total: ~3-5 days**

---

## Quick Wins After Migration

1. Faster build times (web-only)
2. No App Store approval delays
3. Instant rollbacks
4. ~40% smaller codebase
5. Cross-platform instantly (iOS, Android, Windows, Mac, Linux)