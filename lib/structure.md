# Application Structure: User and Clinic Flows

This document outlines the core user and clinic flows within the Eyadati application, detailing the paths, functionality, and key components involved.

---

## I. Clinic Flow

The clinic flow focuses on managing clinic operations, appointments, and profile settings.

### 1. Clinic Registration

*   **Journey:**
    *   A new clinic owner signs up for an account.
    *   They provide initial clinic details (name, specialty, contact, working hours).
    *   They are automatically enrolled in a one-month free trial.
*   **Key Widgets/Pages:**
    *   `ClinicRegisterUi` (in `lib/clinic/clinicRegisterUi.dart`) - Handles the UI for registration.
    *   `ClinicRegisterUi_widgets` (in `lib/clinic/clinicRegisterUi_widgets.dart`) - Reusable widgets for the registration form.
*   **Key Functions/Classes:**
    *   `Clinicauth.clinicAccount` (in `lib/clinic/clinicAuth.dart`)
        *   Creates a new Firebase user with email and password.
    *   `ClinicFirestore.addClinic` (in `lib/clinic/clinic_firestore.dart`)
        *   Creates a new document in the `clinics` Firestore collection.
        *   Sets `firstMonthFreeTrial: true`, `freeTrialEnded: false`, `subscriptionStartDate`, `subscriptionEndDate` (calculated), `paused: false`, and other clinic details.
*   **Data Interactions:**
    *   **Firebase Authentication:** New user creation.
    *   **Firestore:** Creation of clinic profile document in `clinics` collection.

### 2. Clinic Login

*   **Journey:**
    *   An existing clinic owner logs into their account.
*   **Key Widgets/Pages:**
    *   Login dialog triggered from an initial screen (e.g., `flow.dart` or a dedicated login page).
*   **Key Functions/Classes:**
    *   `Clinicauth.clinicLoginIn` (in `lib/clinic/clinicAuth.dart`)
        *   Authenticates the user with Firebase.
        *   Navigates to `Clinichome` upon successful login.
*   **Data Interactions:**
    *   **Firebase Authentication:** User sign-in.

### 3. Clinic Home & Navigation (FloatingBottomNavBar)

*   **Journey:**
    *   After logging in, the clinic owner lands on the main dashboard with a floating bottom navigation bar.
    *   The app checks for subscription status and paused status.
    *   If paused or subscription ended, an overlay prevents interaction.
*   **Key Widgets/Pages:**
    *   `FloatingBottomNavBar` (in `lib/NavBarUi/ClinicNavBar.dart`)
        *   Manages the main screens for the clinic.
        *   Uses `StreamBuilder` to listen to clinic's Firestore document.
        *   Displays an overlay (`_buildOverlayMessage`) if `paused` is true or `subscriptionEndDate` is in the past.
    *   `ManagementScreen` (child of `FloatingBottomNavBar`)
    *   `ClinicAppointments` (in `lib/clinic/clinic_appointments.dart` - child of `FloatingBottomNavBar`)
    *   `Clinicsettings` (in `lib/clinic/clinicSettingsPage.dart` - child of `FloatingBottomNavBar`)
*   **Key Functions/Classes:**
    *   `CliniNavBarProvider` (in `lib/NavBarUi/ClinicNavBar.dart`)
        *   Manages the selected tab state.
*   **Data Interactions:**
    *   **Firestore:** Real-time listening to the clinic's document for `paused` and `subscriptionEndDate`.

### 4. Appointment Management

*   **Journey:**
    *   Clinic owner views, approves, declines, or cancels appointments.
*   **Key Widgets/Pages:**
    *   `ClinicAppointments` (in `lib/clinic/clinic_appointments.dart`)
    *   `AppoitmentsManagment` (in `lib/NavBarUi/AppoitmentsManagment.dart`) - Likely handles the UI for managing appointments.
*   **Key Functions/Classes:**
    *   `ClinicFirestore.cancelAppointment` (in `lib/clinic/clinic_firestore.dart`)
        *   Deletes appointments from both `clinics` and `users` collections.
    *   Logic for approving/declining appointments (likely within `ClinicAppointments` or a related provider).
*   **Data Interactions:**
    *   **Firestore:** Reading, adding, updating, and deleting appointments in `clinics/{clinicId}/appointments` and `users/{userId}/appointments` collections.

### 5. Clinic Profile Editing

*   **Journey:**
    *   Clinic owner updates their clinic's information (contact, address, working hours, avatar).
*   **Key Widgets/Pages:**
    *   `ClinicEditProfilePage` (in `lib/clinic/clinicEditeProfile.dart`)
*   **Key Functions/Classes:**
    *   `ClinicEditProfileProvider` (in `lib/clinic/clinicEditeProfile.dart`)
        *   Fetches existing clinic data (`_loadClinicData`).
        *   Handles image picking (`pickImage`) and uploading to Supabase Storage (`_uploadImage`).
        *   Updates clinic data in Firestore (`saveProfile`).
    *   `ClinicFirestore.updateClinic` (in `lib/clinic/clinic_firestore.dart`)
        *   Updates the clinic document in Firestore, including the `paused` status.
*   **Data Interactions:**
    *   **Firestore:** Reading and updating clinic profile document.
    *   **Supabase Storage:** Storing clinic avatar images.

### 6. Clinic Settings

*   **Journey:**
    *   Clinic owner accesses various settings, including subscription options and pausing their clinic.
*   **Key Widgets/Pages:**
    *   `Clinicsettings` (in `lib/clinic/clinicSettingsPage.dart`)
    *   `SubscribeScreen` (in `lib/chargili/paiment.dart`) - Accessed from settings for subscription.
*   **Key Functions/Classes:**
    *   `ClinicFirestore.updateClinic` (to update `paused` status).
    *   `SubscribeScreen._startSubscription` (in `lib/chargili/paiment.dart`)
        *   Invokes Supabase function `create-chargily-checkout` to initiate payment.
*   **Data Interactions:**
    *   **Firestore:** Updating `paused` status.
    *   **Supabase Functions:** `create-chargily-checkout` for payment initiation.
    *   **Chargily Pay:** Payment processing.

### 7. Subscription & Payment

*   **Journey:**
    *   Clinic owner manages their subscription, initiated from `Clinicsettings`.
    *   They choose a plan (number of doctors) and proceed to payment via Chargily.
    *   Payment status is communicated back to the app.
*   **Key Widgets/Pages:**
    *   `SubscribeScreen` (in `lib/chargili/paiment.dart`)
    *   `ChargilyCheckoutScreen` (in `lib/chargili/paiment.dart`) - Web view for Chargily payment.
*   **Key Functions/Classes:**
    *   `SubscribeScreen._calculatePrice` (calculates subscription cost).
    *   `SubscribeScreen._startSubscription` (initiates checkout).
    *   Supabase Edge Function `chargily-webhook` (in `supabase/functions/chargily-webhook/index.ts`)
        *   Receives payment notifications from Chargily.
        *   Verifies webhook signature.
        *   Updates clinic document in Firestore (subscription status, `staff` count).
        *   Triggers FCM notification to the clinic app about payment status.
*   **Data Interactions:**
    *   **Supabase Functions:** Orchestrates payment flow.
    *   **Chargily Pay:** Handles actual payment.
    *   **Firestore:** Updates subscription details, `staff` count.
    *   **Firebase Cloud Messaging (FCM):** Sends payment status notifications to the app.

---

## II. User Flow

The user flow focuses on finding clinics, booking appointments, and managing personal profiles.

### 1. User Registration

*   **Journey:**
    *   A new user signs up for an account.
    *   They provide basic personal details.
*   **Key Widgets/Pages:**
    *   (Assumed dedicated user registration UI, similar to clinic registration, but not explicitly identified in the provided file list).
*   **Key Functions/Classes:**
    *   Firebase Authentication `createUserWithEmailAndPassword`.
    *   (Assumed corresponding Firestore add user function).
*   **Data Interactions:**
    *   **Firebase Authentication:** New user creation.
    *   **Firestore:** Creation of user profile document in `users` collection.

### 2. User Login

*   **Journey:**
    *   An existing user logs into their account.
*   **Key Widgets/Pages:**
    *   Login dialog or page.
*   **Key Functions/Classes:**
    *   Firebase Authentication `signInWithEmailAndPassword`.
    *   `decidePage` (in `lib/flow.dart`) - Determines the initial page based on user role (clinic or regular user).
*   **Data Interactions:**
    *   **Firebase Authentication:** User sign-in.

### 3. User Home & Navigation (UserNavBar)

*   **Journey:**
    *   After logging in, the user lands on their main dashboard with a bottom navigation bar to browse clinics, view appointments, etc.
*   **Key Widgets/Pages:**
    *   `UserNavBar` (in `lib/NavBarUi/UserNavBar.dart`) - Assumed to exist for user navigation.
    *   (Other specific screens for browsing clinics, user profile, etc.)
*   **Key Functions/Classes:**
    *   (Assumed corresponding `UserNavBarProvider`.)
*   **Data Interactions:**
    *   **Firestore:** Reading clinic listings, user profile.

### 4. Booking Appointments

*   **Journey:**
    *   User searches for clinics, views clinic details, available slots, and books an appointment.
*   **Key Widgets/Pages:**
    *   `clinicsList.dart` (in `lib/Appointments/clinicsList.dart`) - Lists available clinics.
    *   `slotsUi.dart` (in `lib/Appointments/slotsUi.dart`) - Displays available appointment slots.
*   **Key Functions/Classes:**
    *   `booking_logic.dart` (in `lib/Appointments/booking_logic.dart`) - Contains the core logic for appointment booking.
    *   `Appointments/utils.dart` - Likely contains utility functions for appointment related operations.
*   **Data Interactions:**
    *   **Firestore:** Reading clinic data, available slots. Creating new appointment documents in both `clinics` and `users` collections.

### 5. Viewing Appointments

*   **Journey:**
    *   User views their upcoming and past appointments.
*   **Key Widgets/Pages:**
    *   `user_appointments.dart` (in `lib/user/user_appointments.dart`)
*   **Key Functions/Classes:**
    *   (Assumed Firestore queries to fetch user-specific appointments.)
*   **Data Interactions:**
    *   **Firestore:** Reading appointments from `users/{userId}/appointments`.

### 6. User Profile Editing

*   **Journey:**
    *   User updates their personal profile information.
*   **Key Widgets/Pages:**
    *   (Assumed dedicated user profile editing UI, similar to clinic editing.)
*   **Key Functions/Classes:**
    *   (Assumed user profile provider and Firestore update functions.)
*   **Data Interactions:**
    *   **Firestore:** Reading and updating user profile document.

---

**General Considerations:**

*   **State Management:** `provider` package is used throughout the application for state management.
*   **Theming:** Custom themes (light/dark mode) are defined in `lib/Themes/` and managed by `ThemeProvider`.
*   **Localization:** `easy_localization` is used for internationalization, with translations in `assets/translations/`.
*   **Error Handling:** `try-catch` blocks are used, and `ScaffoldMessenger` often displays error messages. `debugPrint` is used for logging.
*   **Network Connectivity:** `NetworkHelper.checkInternetConnectivity` is used to verify internet access before performing network operations.
