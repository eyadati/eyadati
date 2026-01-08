# Eyadati Flutter Project

## Project Overview

This is a Flutter project named "eyadati". Based on the dependencies and file structure, it appears to be a mobile application for managing appointments with clinics. 

**Key Technologies:**

*   **Frontend:** Flutter
*   **Backend:** Firebase (Authentication, Firestore, Cloud Messaging), Supabase
*   **State Management:** Provider
*   **Localization:** `easy_localization` (with translations for English, French, and Arabic)
*   **UI:** `google_fonts`, `flex_color_scheme`, `table_calendar`, and custom theming.

**Architecture:**

The project is structured into several feature directories:

*   `lib/Appointments`: Contains logic for booking and managing appointments.
*   `lib/clinic`: Handles clinic-specific features like managing appointments, profile editing, and registration.
*   `lib/user`: Manages user-related functionality, including appointments, profile editing, and registration.
*   `lib/FCM`: Contains Firebase Cloud Messaging helper functions and services.
*   `lib/Themes`: Defines the light and dark themes for the application.

## Building and Running

### Prerequisites

*   Flutter SDK: `^3.29.0`
*   Dart SDK: `^3.8.1`

### Key Commands

*   **Get dependencies:** 
    ```bash
    flutter pub get
    ```
*   **Run the app:** 
    ```bash
    flutter run
    ```
*   **Run tests:** 
    ```bash
    flutter test
    ```
*   **Build for Android:** 
    ```bash
    flutter build apk
    ```
*   **Build for iOS:** 
    ```bash
    flutter build ios
    ```

## Development Conventions

*   **State Management:** The project uses the `provider` package for state management.
*   **Theming:** Custom themes are defined in `lib/Themes/`, with separate files for light and dark modes. A `ThemeProvider` is likely used to apply these themes.
*   **Localization:** The `easy_localization` package is used for internationalization. Translation files are located in `assets/translations/`.
*   **Firebase:** The project is configured to use Firebase services. The `firebase_options.dart` file contains the necessary configuration.
*   **Supabase:** Supabase is also integrated into the project. The connection details are present in `lib/main.dart`.
*   **Assets:** All static assets like images and fonts are stored in the `assets/` directory and declared in `pubspec.yaml`.
*   **Code Style:** The project uses `flutter_lints` to enforce good coding practices. The linting rules are configured in `analysis_options.yaml`.
