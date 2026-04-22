# Prioritized Task List: Eyadati Web-Incompatibility Fixes

## 1. Refactor `lib/webUI/web_ui_helper.dart`
- **Goal:** Remove `dart:io` and use web-safe platform checks.
- **Layered Planning:**
  - **Research:** Analyze existing usage of `Platform` in `web_ui_helper.dart` to identify critical dependencies.
  - **Act:** Replace `dart:io` `Platform` with `kIsWeb` from `flutter/foundation.dart` and implement universal checks.
  - **Validate:** Run `flutter build web` to ensure no `dart:io` related build errors persist.

## 2. Refactor `lib/clinic/clinic_registration_provider.dart`
- **Goal:** Replace `dart:io` `File` with web-compatible `XFile` logic.
- **Layered Planning:**
  - **Research:** Examine how `File` is currently used for image/data handling in `clinic_registration_provider.dart`.
  - **Act:** Migrate the provider logic to support `XFile` (from `cross_file` or `image_picker`) and handle raw bytes for cross-platform compatibility.
  - **Validate:** Verify image upload/handling functionality in the simulator/browser.

## 3. Refactor `lib/clinic/clinic_edit_profile.dart`
- **Goal:** Resolve `dart:io` imports and filesystem dependencies.
- **Layered Planning:**
  - **Research:** Identify specific `dart:io` classes (e.g., `File`, `Directory`) and how they interact with UI/backend.
  - **Act:** Decouple filesystem-bound logic and replace with web-compatible abstractions (e.g., memory-based buffers or platform-agnostic file pickers).
  - **Validate:** Check for successful profile updates in both mobile and web build targets.

## 5. Audit UI and Responsive Layouts
- **Goal:** Resolve UI violations and responsiveness issues.
- **Layered Planning:**
  - **Research:** Audit `lib/webUI/clinic_web_ui.dart` for fixed-height `MediaQuery` usage and lack of scrolling for smaller desktop screens.
  - **Act:** Replace fixed height calculations with `LayoutBuilder` or scrollable containers to ensure UI fits on smaller screens. 
  - **Validate:** Test responsiveness by resizing browser window to various breakpoints.

## 6. Detect Potential Bugs in Web Navigation
- **Goal:** Ensure web-specific routing behaves predictably.
- **Layered Planning:**
  - **Research:** Analyze `ClinicWebUI`'s dependency on `showMaterialModalBottomSheet` for mobile-style menus. 
  - **Act:** Implement more desktop-appropriate navigation patterns (e.g., sidebars or persistent menus) if necessary for a better user experience.
  - **Validate:** Verify deep-linking/navigation state persists correctly across browser reloads.

