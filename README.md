# MUHAFIZ – Zindagiyon Ka Tahaffuz

**Package name:** `muhafiz_1` · **Platform:** [Flutter](https://flutter.dev/) (Dart SDK `>=3.3.0 <4.0.0`)

A mobile emergency-response application focused on **SOS-style alerts**, **location-aware reporting**, **Firebase-backed user and emergency data**, and **situational tools** (maps, disaster context, Bluetooth proximity awareness, and an offline help guide). The app targets **Karachi, Pakistan** for several map and risk APIs, with much of the UI offering **English / Urdu** labels via a small localization helper.

---

## Overview

MUHAFIZ lets signed-in users:

- Trigger **emergency flow** from the home screen: **tap** opens full reporting; **long-press** can create a **quick Firestore emergency** (`IMMEDIATE SOS`) using the user profile and last known location when available.
- **Report emergencies** with **GPS address**, **optional photo / video / voice proof**, local **siren + vibration** patterns, and upload media to **Firebase Storage** while writing structured data to **Cloud Firestore**.
- Browse **volunteer “live” alerts** (Firestore `emergencies` stream) when **Volunteer Mode** is enabled on the home screen.
- Use **OpenStreetMap-based maps** (via `flutter_map`) and **public HTTP APIs** (weather, earthquakes, air quality, marine, Overpass) for **disaster context**—**no map API key** is required for OSM; listed third-party APIs are used as **public endpoints** in code (see [Tech stack](#tech-stack)).
- Use **BLE scanning** and **Firebase-synchronized** proximity alerting (see Bluetooth feature), with **audio + vibration** buzzer behavior for incoming alerts.

Authentication is **email/password** (Firebase Auth). The app entrypoint initializes **Firebase** and enables **Firestore offline persistence** for cached reads.

**AI / LLM usage:** The codebase does **not** integrate third-party large language models. The `VerificationBot` feature is a **fixed questionnaire** in Dart (rule-based), not an external AI service.

---

## Features


| Area                      | What exists                                                                                                                                                                                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Account**               | Login, sign-up, forgot password; splash routes to **home** or **login** based on `FirebaseAuth` session.                                                                                                                                                                       |
| **Home**                  | Large **SOS** control (tap vs long-press), **light/dark** theme toggle, **English / اردو** toggle, **Volunteer Mode** with **nearby / live** `emergencies` list, **Madgar Portal** card, **quick actions** (Offline Guide, Disaster Analysis, Emergency Map, BT Alerts).       |
| **Emergency report**      | Category selection, **geolocation** + reverse geocoding, description, **image / video** picks, **voice recording** (`record` + `path_provider`), **siren cycles** + vibration, **relative alert status** flow, **“other” emergency** screen, **VerificationBot** Q&A (non-AI). |
| **Profile**               | User fields (name, phone, blood group, volunteer flag, guardian contact, profile photo) synced with **Firestore** / **Storage**. **Report misuse** entry.                                                                                                                      |
| **Permissions**           | Dedicated **permissions** UI (part of bottom navigation on home).                                                                                                                                                                                                              |
| **Maps & location**       | **Karachi emergency map** with `flutter_map`, static POIs, and **Overpass**-based data; **location** screen after login (see auth flow). **Scientific Disaster Analysis** screen with **illustrative / demo** values in UI.                                                    |
| **Pre-disaster analysis** | `DisasterPredictionScreen` loads **Open-Meteo** weather, **USGS** earthquakes, **Open-Meteo air quality**, and **marine** data, then **sorts risk indicators** in-app.                                                                                                         |
| **Offline**               | **Offline guide** (static content).                                                                                                                                                                                                                                            |
| **Bluetooth**             | **BLE scan** + **Firestore**-driven **proximity alerts**; **EmergencyBuzzerService** (asset `siren.mp3` + vibration).                                                                                                                                                          |
| **Integrations**          | **Firebase** (Auth, Firestore, Storage), `**flutter_sms`** helper, `**url_launcher**`, `**workmanager**` initialization (see [Status](#current-progress--status)).                                                                                                             |


Some screens and widgets under `lib/features/maps/` (for example the **command centre** map wrapper) are **present in the codebase** but are **not registered** in `AppRoutes` and are **not** reachable from the current `HomeScreen` navigation paths.

---

## Tech stack

- **Framework:** Flutter / Dart
- **State / UI:** `provider`, Material 3 theming (`lib/core/theme/app_theme.dart`)
- **Backend:** Firebase  
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`  
  - Configuration via `lib/firebase_options.dart` (FlutterFire-style generated options) and platform-specific Firebase setup (e.g. Android `google-services` as present in the project).
- **Maps:** `flutter_map` + `latlong2` (OSM; no key required for the tile usage in app code)
- **Location:** `geolocator`, `geocoding`
- **Networking / APIs (public HTTP, as used in services):**  
  - Open-Meteo (weather, air quality)  
  - USGS earthquake feed  
  - Overpass API (OpenStreetMap queries)  
  - Additional marine endpoint(s) as implemented in `lib/services/marine_service.dart`
- **Device / hardware:** `permission_handler`, `screen_brightness`, `audioplayers`, `vibration`, `flutter_blue_plus`, `connectivity_plus`, `image_picker`, `record`, `path_provider`, `shared_preferences`, `workmanager`, `url_launcher`, `flutter_sms`, `http`, `intl`

---

## Architecture / project structure

Feature-first layout under `lib/features/`, with shared **core** and **services** layers:

```text
lib/
├── main.dart                 # Firebase init, Firestore persistence, Workmanager init (unawaited)
├── firebase_options.dart     # Generated Firebase options
├── core/                     # App shell: routes, theme, localization helper
│   ├── app_routes.dart       # Named routes (splash, auth, home, maps, etc.)
│   ├── app_setup.dart        # MaterialApp + Provider
│   ├── theme/
│   └── localization/
├── features/                 # Feature modules (screens, flows)
│   ├── authentication/
│   ├── home/                 # Home, SOS, report, profile, permissions, etc.
│   ├── maps/                 # Location, Karachi map, disaster analysis, command centre (code present)
│   ├── disaster/             # Disaster prediction / analysis UI
│   ├── bluetooth/
│   ├── offline/
│   ├── alerts/
│   └── feature_template/     # Template for new features (see below)
└── services/                 # Shared services (Firebase init helper, settings, HTTP-based APIs, BLE, etc.)
```

### Adding a new feature (existing convention)

The repo includes a **feature template** under `lib/features/feature_template/`:

1. Copy `lib/features/feature_template/` to `lib/features/<your_feature>/`.
2. Rename types from `FeatureTemplate...` to your names.
3. Export from your feature barrel file.
4. Register routes in `lib/core/app_setup.dart` and, if using named routes, add constants in `lib/core/app_routes.dart`.

---

## Installation and setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable), compatible with Dart `>=3.3.0 <4.0.0`
- For mobile builds: **Android Studio** (Android SDK) and/or **Xcode** (iOS, macOS only)
- A **Firebase project** with **Authentication** (email/password), **Cloud Firestore**, and **Firebase Storage** enabled, matching the security rules you intend to use in production

### Clone and fetch packages

```bash
cd muhafiz_app-main
flutter pub get
```

### Firebase configuration

The app calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in `lib/main.dart`. In a fresh checkout you typically:

1. Create a Firebase project in the [Firebase console](https://console.firebase.google.com/).
2. Register Android/iOS apps and download the platform config files (for Android, `google-services.json` in `android/app/` as required by the FlutterFire / Gradle setup).
3. Regenerate `lib/firebase_options.dart` using **FlutterFire CLI** (`flutterfire configure`) so keys and app IDs match your project.

> **Note:** Do not commit private keys or secrets you do not intend to be public. Treat `firebase_options.dart` and `google-services.json` like environment-specific configuration.

### Run the app

```bash
# List devices
flutter devices

# Run on a connected phone/emulator
flutter run
```

Debug APK example:

```bash
flutter build apk --debug
```

Output (default): `build/app/outputs/flutter-apk/app-debug.apk`

---

## Environment variables

There is **no** `flutter_dotenv` / `.env` integration in this repository. Configuration is done via **Firebase options files** and platform Firebase setup—not via a `.env` file.

---

## Usage (end-user flow)

1. **Launch** the app → **Splash** → **Login** (or **Home** if already signed in).
2. **Home:** Use **SOS** (tap to open the report flow, long-press for a quick `emergencies` document where profile/location data exists).
3. **Report:** Pick type, confirm location, add description and optional media, and submit (Firestore/Storage as implemented in `report_emergency_screen.dart`).
4. **Volunteer Mode:** Enable on home to see a **streamed list** of recent `emergencies` documents.
5. **Maps / analysis:** Use quick actions for **Offline Guide**, **Pre-disaster analysis** (public APIs), **Karachi map**, and **Bluetooth alerts** (requires Bluetooth permissions and supported hardware).

---

## Current progress / status

- **Core flows** (auth, home, report, profile, multiple supporting screens) are **implemented in Dart** and the project **analyzes cleanly** with `flutter analyze` when dependencies resolve.
- **Firestore collections** used in code include at least: `users`, `emergencies` (verify security rules and indexes in Firebase for your deployment).
- `**BackgroundSyncService`** uses **Workmanager**; the **background callback** in `lib/services/background_sync_service.dart` is largely a **placeholder** (returns success; comments describe intended offline sync). Treat background sync as **incomplete** until fleshed out.
- `**ConnectivityService`** exists under `lib/services/connectivity_service.dart` but is **not wired** into `main.dart` as a `Provider` in the current tree—**connectivity_plus** is available as a dependency.
- **Tests:** `test/` includes **widget tests** for `SettingsProvider` (not full E2E coverage of emergency flows).
- **Disaster “Scientific” analysis** UI uses **fixed demo numbers** in the widget (not live sensor I/O from the device).

---

## Team


| Name             | Role                   | Contact                                                     |
| ---------------- | ---------------------- | ----------------------------------------------------------- |
| *Ramiz Siddiqui* | *Team Lead & QA Engr.* | *[siddiramiz@gmail.com](mailto:siddiramiz@gmail.com)*       |
| *Wardha Khalid*  | *Full-Stack Developer* | *[khalidwardha1@gmail.com](mailto:khalidwardha1@gmail.com)* |
| *Maheen Fatima*  | *Full-Stack Developer* | *[Maheence123@gmail.com](mailto:Maheence123@gmail.com)*     |


---

## Links


| Resource                 | URL                                                                                                                                                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Repository (example)** | [https://github.com/wardha-netizen/muhafiz_app](https://github.com/wardha-netizen/muhafiz_app)                                                                                                                               |
| **Live demo / store**    | __                                                                                                                                                                                                                           |
| **Figma Design**         | *[https://www.figma.com/prototye](https://www.figma.com/proto/l6Us17ksKZF4lRKlJqAiLv/Untitled?node-id=1-3413&p=f&t=ScRLGvcmVOB10Ygq-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1&starting-point-node-id=1%3A3341)* |
| **Jira**                 | *[Jira-Kanban Board](https://khalidwardha1.atlassian.net/jira/software/projects/MUH/boards/34?atlOrigin=eyJpIjoiODJjNDE5ODcwZDFkNGUwNjg2MDcyMWY2N2E2ZjcxOTUiLCJwIjoiaiJ9)*                                                   |


---

## Future improvements (grounded in the codebase)

- **Wire or remove** unused navigation: e.g. ensure `muhafiz_command_centre_screen.dart` is reachable if it is part of the product, or document it as internal-only.
- **Complete** `BackgroundSyncService` / Workmanager path: local queue for reports when offline, then Firestore upload when online (currently stubbed).
- **Integrate** `ConnectivityService` (or remove) for consistent offline UX and messaging.
- **Hardening:** Firestore/Storage **security rules**, **App Check**, rate limits, and **location privacy** copy; validate **indexes** for `emergencies` queries (`orderBy` + filters).
- **Testing:** integration tests for SOS/report paths, and golden tests for critical UI.
- **iOS / desktop:** platform folders exist; confirm Firebase config and permissions for each target you ship.

---

## License / legal

*Copyright (c) 2026 MUHAFIZ Team.* 

*This README does not substitute for emergency services—always use official local emergency numbers when in danger.*


