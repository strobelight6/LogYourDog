# Log Your Dog — Build Tasks

Chunked by feature. Each task is scoped to be completable in a single Claude session.

---

## Feature 1: Firebase Setup

**1.1 — Add Firebase dependencies**
- Add `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging` to `pubspec.yaml`
- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) placeholders with setup instructions
- Initialize Firebase in `main.dart`

**1.2 — Create Firestore data layer**
- Define Firestore collection/document structure for: `users`, `dogProfiles`, `dogPosts`, `follows`, `notifications`
- Add `toFirestore()` / `fromFirestore()` serialization to all models (`UserProfile`, `DogProfile`, `DogPost`)
- Add missing models: `Follow` and `AppNotification`

---

## Feature 2: Authentication & Onboarding

**2.1 — Auth screens**
- Create `login_screen.dart` — email/password sign-in form with Firebase Auth
- Create `signup_screen.dart` — email/password registration form
- Wire up `FirebaseAuth.signInWithEmailAndPassword` and `createUserWithEmailAndPassword`
- Show validation errors inline

**2.2 — Onboarding screen**
- Create `onboarding_screen.dart` — after sign-up, prompt for display name, profile photo, and location (all optional)
- Save initial `UserProfile` document to Firestore on completion

**2.3 — Auth gate**
- Wrap `main.dart` in an `AuthGate` widget that listens to `FirebaseAuth.authStateChanges()`
- Redirect unauthenticated users to login; authenticated users to home feed
- Create `AuthService` in `lib/services/auth_service.dart` with `signIn`, `signUp`, `signOut`

---

## Feature 3: Firebase-backed Services

**3.1 — Replace ProfileService with Firestore**
- Rewrite `profile_service.dart` to read/write `UserProfile` from Firestore `users` collection
- Remove all `SharedPreferences` usage
- Keep the same public API so existing screens don't break

**3.2 — Replace DogService with Firestore**
- Rewrite `dog_service.dart` to read/write `DogProfile` from Firestore `dogProfiles` collection
- Remove all `SharedPreferences` usage

**3.3 — Replace FeedService with Firestore**
- Rewrite `feed_service.dart` to read/write `DogPost` from Firestore `dogPosts` collection
- Query posts ordered by `createdAt` descending
- Remove all mock/seed data

---

## Feature 4: Follow System

**4.1 — Follow model + service**
- Add `Follow` model to `lib/models/follow.dart`
- Create `lib/services/follow_service.dart` with: `followUser`, `unfollowUser`, `isFollowing`, `getFollowers`, `getFollowing`
- Write to Firestore `follows` collection

**4.2 — Follow UI on profiles**
- Add follow/unfollow button to `profile_screen.dart` (hidden on own profile)
- Display follower count and following count on `profile_screen.dart`
- Wire counts to live Firestore queries

**4.3 — User search screen**
- Create `lib/screens/search_screen.dart`
- Search Firestore `users` by `displayName`
- Show profile photo, display name, follower count, and follow button in results
- Add search tab to main navigation

**4.4 — Feed filtered to following**
- Update `feed_service.dart` to query only posts from users the current user follows
- Use Firestore `where('authorId', whereIn: followingIds)` pattern (handle >10 limit if needed)

---

## Feature 5: Home Feed Polish

**5.1 — Real-time feed updates**
- Convert `home_feed_screen.dart` to use a Firestore `snapshots()` stream instead of a one-time fetch
- Show a loading skeleton while initial data loads

**5.2 — Like functionality with Firestore**
- Update like/unlike to write `likedByUserIds` in Firestore atomically (`FieldValue.arrayUnion/arrayRemove`)
- Reflect like state and count in real time on `dog_post_card.dart`

**5.3 — Comments**
- Add inline comment thread to `dog_post_card.dart` (expandable)
- Write new comments to the `comments` array on the `DogPost` document
- Show comment author name and timestamp

---

## Feature 6: Collections Screen

**6.1 — Collections logic**
- In `collections_screen.dart`, fetch the current user's `DogPost` logs from Firestore
- Group logs by `breed`, `color`, and `rating tier` (Low/Mid/High)
- Display each group with count (e.g., "Golden Retrievers: 3 logged")

**6.2 — Progress tracking**
- For each breed/color group, compute % toward a known total (use a hardcoded list of common breeds/colors as the denominator)
- Show a progress bar per group
- Trigger in-app milestone badge display at 25%, 50%, 100%

---

## Feature 7: Notifications

**7.1 — Notification model + service**
- Add `AppNotification` model to `lib/models/notification.dart`
- Create `lib/services/notification_service.dart` — write notifications to Firestore `notifications` collection
- Add helper methods: `notifyNewFollower`, `notifyPostLiked`, `notifyMilestoneReached`

**7.2 — In-app notifications screen**
- Rewrite `notifications_screen.dart` to query Firestore for the current user's notifications
- Display each notification with type icon, message, and timestamp
- Mark notifications as read on tap

**7.3 — Push notifications**
- Integrate `firebase_messaging` — request permission, save FCM token to user's Firestore doc
- Handle foreground and background messages
- Wire `notifyNewFollower` and `notifyPostLiked` to send FCM via Cloud Function or direct API call

---

## Feature 8: Photo Handling

**8.1 — Image picker integration**
- Add `image_picker` package
- Wire photo selection in `log_dog_screen.dart` and `add_dog_screen.dart`
- Wire profile photo selection in onboarding and profile edit

**8.2 — Firebase Storage upload**
- Create `lib/services/storage_service.dart` with `uploadDogPhoto(file)` and `uploadProfilePhoto(file)`
- Upload on form submit; store returned URL in Firestore document

---

## Feature 9: Location

**9.1 — GPS tagging on log form**
- Add `geolocator` package
- In `log_dog_screen.dart`, add "Use my location" button that auto-fills a city/region string
- Location is opt-in; allow manual text entry as fallback

---

## Housekeeping

**H.1 — Navigation overhaul**
- Set up a `BottomNavigationBar` with tabs: Feed, Log, Collections, Notifications, Profile
- Replace any placeholder routing in `main.dart` with proper named routes or `go_router`

**H.2 — State management**
- Introduce a state management solution (Riverpod recommended per PRD)
- Wrap `main.dart` in `ProviderScope`
- Convert service calls in screens to use providers

**H.3 — Error handling & loading states**
- Add consistent loading indicators and error messages across all screens that fetch data

---

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Done
