# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Lint
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter build ios        # Build iOS
flutter build apk        # Build Android
```

## Local development with Firebase Emulator

```bash
# 1. One-time setup
cp firebase.json.example firebase.json
cp .firebaserc.example .firebaserc
cp .vscode/launch.json.example .vscode/launch.json
npm install -g firebase-tools
firebase emulators:start

# 2. Run the app against the local emulator
flutter run --dart-define=USE_EMULATOR=true
```

The emulator UI is at http://localhost:4000 (Firestore, Auth, Storage).

## Firebase config and secrets

- **Emulator mode** (`USE_EMULATOR=true`): no real credentials needed. Placeholder values are used automatically in `lib/firebase_config.dart`.
- **Production**: Firebase values are injected via `--dart-define` flags — never hardcoded. See `.vscode/launch.json.example` for the full list of flags. Copy it to `.vscode/launch.json` (gitignored) and fill in real values from the Firebase console.
- `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` are all gitignored. For production iOS/Android builds, run `flutterfire configure` to generate `firebase_options.dart`, then swap `FirebaseConfig.currentPlatform` in `main.dart` for `DefaultFirebaseOptions.currentPlatform`.

## Firestore collection structure

| Collection | Document ID | Notes |
|---|---|---|
| `users` | Firebase Auth uid | `UserProfile` |
| `dogProfiles` | auto-id | `DogProfile` |
| `dogPosts` | auto-id | `DogPost`; comments in subcollection `dogPosts/{id}/comments` |
| `follows` | `{followerId}_{followingId}` | `Follow` |
| `notifications` | auto-id | `AppNotification` |

## Architecture

**Log Your Dog** is a Flutter social app where users log dogs they encounter, rate them, and follow other users.

### Navigation

`lib/main.dart` hosts `MainNavigationScreen` — a 5-tab `BottomNavigationBar`:
1. **Feed** (`home_feed_screen.dart`) — reverse-chronological dog post feed
2. **Collections** (`collections_screen.dart`) — logs grouped by breed/color with progress tracking
3. **Log Dog** (`log_dog_screen.dart`) — form to log an encountered dog; calls `_navigateToFeed` on submit
4. **Notifications** (`notifications_screen.dart`)
5. **Profile** (`profile_screen.dart`)

### Data Layer Pattern

Services use a **singleton + repository** pattern. Each service (except `ProfileService`) defines an abstract interface with `Local*` and `Cloud*` implementations:

- `LocalFeedRepository` / `CloudFeedRepository` → `FeedService.instance`
- `LocalDogRepository` / `CloudDogRepository` → `DogService.instance`
- `ProfileService.instance` — simpler, no repository abstraction yet

All local repositories persist via `SharedPreferences` with JSON serialization. The cloud stubs are placeholders for Firebase migration (see `TASKS.md`). Switch to cloud by calling `FeedService.initializeWithCloud()` / `DogService.initializeWithCloud()` before first use.

### Models

All models in `lib/models/` implement `toJson()` / `fromJson()`, `toFirestore()` / `fromFirestore()`, and `copyWith()`:
- `UserProfile` — current user; has `defaultProfile` static
- `DogProfile` — a registered dog with `ownerId`, tracks `timesLogged`
- `DogPost` — a logged encounter; `likedByUserIds`, 1–5 paw `rating`; comments stored in Firestore subcollection
- `Follow` — follow relationship; doc ID is `{followerId}_{followingId}`
- `AppNotification` — in-app notification with `NotificationType` enum

### Firebase Migration Roadmap

`TASKS.md` tracks the full roadmap. Next steps:
- Feature 2: Auth screens + `AuthGate` in `main.dart`
- Feature 3: Replace `SharedPreferences` services with Firestore implementations
- Features 4–9: Follow system, real-time feed, notifications, storage, location

State management: Riverpod is the planned solution (not yet introduced). When adding it, wrap `main.dart` in `ProviderScope`.
