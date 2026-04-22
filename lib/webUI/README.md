# Web & PWA Optimization Tasks

This folder contains UI components and helpers specifically designed for larger screens (Desktops, Laptops, and Tablets) and PWA-specific enhancements.

## 1. Responsive UI Implementation
*   **WebUIHelper:** Created a helper class to detect large screens (>900px) and mobile devices.
*   **Split-Screen Clinic Dashboard:**
    *   Left Side: Interactive Heatmap (Calendar) to visualize daily appointment load.
    *   Right Side: Real-time Online Appointments list.
    *   **Manual Appointments:** Migrated from a list view to a **GridView** for better space utilization on desktops.
*   **Split-Screen Patient Dashboard:**
    *   40% Width: Smart Search sidebar with City and Specialty filters.
    *   60% Width: Appointment tracking list.
    *   **Empty State:** Search results are hidden until the user confirms their filter selection to prevent heavy initial loads.
*   **Form Constraints:** Login and Registration pages are constrained to a mobile-like width (500px) to maintain a professional look, while main dashboards use the full screen width.

## 2. PWA & Web Enhancements
*   **Icon Update:** Updated all web and PWA icons using the high-quality `Eyadati_logo.png`.
*   **PWA Boot Fix:** Fixed the "stuck on loading" issue by adding a JavaScript bridge in `index.html` and correcting `manifest.json` paths for GitHub Pages subfolder hosting.
*   **Prominent Install Prompt:** Replaced the default browser install bar with a custom, high-visibility popup at the bottom of the screen.
*   **Desktop Scrolling:** Enabled mouse-wheel and stylus scrolling across the entire application.
*   **Font Readability:** Increased font weight globally on web for better readability on high-resolution monitors.

## 3. Feature-to-Device Tying
*   **Phone Calls:** The "Call" button is now only visible on actual mobile devices.
*   **Slidable Removal:** Removed `Slidable` widgets on the web version, replacing them with standard `ListTile` trailing actions for a more natural desktop feel.
*   **Calendar Integration:** Removed "Add to Calendar" on web (due to browser permission complexities) and replaced it with a prompt for users to take a photo/screenshot as proof of appointment.

## 4. General Improvements
*   **Language Update:** Changed "No Show" terminology to "Cancelled" across all translations (AR, FR, EN) and code logic to be more user-friendly.

## Packages Used
*   `pwa_install`: Used for handling the custom installation prompt logic.
*   `url_launcher`: Used for phone calls (conditionally) and maps.
*   `table_calendar`: Optimized for split-screen display.
*   `provider`: Used for cross-component state management in the new split layouts.
