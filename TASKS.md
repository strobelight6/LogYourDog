# Log Your Dog — Build Tasks

Chunked by feature. Each task is scoped to be completable in a single Claude session.

---

## Feature 1: Firebase Setup

**[x] 1.1 — Add Firebase dependencies**
- Added `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage` to `pubspec.yaml`
- `firebase_messaging` deferred to Feature 7.3 — requires iOS push notification entitlement enabled in Xcode first
- Firebase initialized in `main.dart` via `FirebaseConfig.currentPlatform` (env-based, no hardcoded keys)
- Local testing via Firebase Emulator Suite — see CLAUDE.md for setup

**[x] 1.2 — Create Firestore data layer**
- Firestore collection structure defined in CLAUDE.md and as header comments in each model file
- `toFirestore()` / `fromFirestore()` added to `UserProfile`, `DogProfile`, `DogPost`
- Added `Follow` model (`lib/models/follow.dart`)
- Added `AppNotification` model with `NotificationType` enum (`lib/models/notification.dart`)

---

## Feature 2: Authentication & Onboarding

**[x] 2.1 — Auth screens**
- Create `login_screen.dart` — email/password sign-in form with Firebase Auth
- Create `signup_screen.dart` — email/password registration form
- Wire up `FirebaseAuth.signInWithEmailAndPassword` and `createUserWithEmailAndPassword`
- Show validation errors inline

**[x] 2.2 — Onboarding screen**
- Create `onboarding_screen.dart` — after sign-up, prompt for display name, profile photo, and location (all optional)
- Save initial `UserProfile` document to Firestore on completion

**[x] 2.3 — Auth gate**
- Wrap `main.dart` in an `AuthGate` widget that listens to `FirebaseAuth.authStateChanges()`
- Redirect unauthenticated users to login; authenticated users to home feed
- Create `AuthService` in `lib/services/auth_service.dart` with `signIn`, `signUp`, `signOut`

---

## Feature 3: Firebase-backed Services

**[x] 3.1 — Replace ProfileService with Firestore**
- Rewrite `profile_service.dart` to read/write `UserProfile` from Firestore `users` collection
- Remove all `SharedPreferences` usage
- Keep the same public API so existing screens don't break

**[x] 3.2 — Replace DogService with Firestore**
- Rewrite `dog_service.dart` to read/write `DogProfile` from Firestore `dogProfiles` collection
- Remove all `SharedPreferences` usage

**[x] 3.3 — Replace FeedService with Firestore**
- Rewrite `feed_service.dart` to read/write `DogPost` from Firestore `dogPosts` collection
- Query posts ordered by `createdAt` descending
- Remove all mock/seed data

---

## Feature 3.5: Firestore Security Rules

**[x] 3.5.1 — Write and deploy security rules**
- Create `firestore.rules` with deny-by-default baseline
- `users/{userId}`: read by any authenticated user; write only by owner (`request.auth.uid == userId`)
- `dogProfiles/{profileId}`: read by any authenticated user; write only by owner
- `dogPosts/{postId}`: read by any authenticated user; write only by author; delete only by author
- `dogPosts/{postId}/comments/{commentId}`: read by any authenticated user; write only by comment author
- `follows/{followId}`: read by any authenticated user; write only if `followerId == request.auth.uid`
- `notifications/{notificationId}`: read/write only by the recipient (`request.auth.uid == resource.data.userId`)
- Deploy via `firebase deploy --only firestore:rules`
- Verify rules against the emulator using the Firebase Rules Playground

---

## Feature 4: Follow System

**[x] 4.1 — Follow model + service**
- Add `Follow` model to `lib/models/follow.dart`
- Create `lib/services/follow_service.dart` with: `followUser`, `unfollowUser`, `isFollowing`, `getFollowers`, `getFollowing`
- Write to Firestore `follows` collection

**[x] 4.2 — Follow UI on profiles**
- Add follow/unfollow button to `profile_screen.dart` (hidden on own profile)
- Display follower count and following count on `profile_screen.dart`
- Wire counts to live Firestore queries

**[x] 4.3 — User search screen**
- Create `lib/screens/search_screen.dart`
- Search Firestore `users` by `displayNameLower` (case-insensitive prefix match)
- Show profile photo, display name, follower count, and follow button in results
- Add search tab to main navigation

**[x] 4.4 — Feed filtered to following**
- Update `feed_service.dart` to query only posts from users the current user follows
- Use Firestore `where('userId', whereIn: followingIds)` pattern with batching for >30 following

**4.5 — Suggested users on Search idle state**
- [ ] 4.5.1 — Add `ProfileService.getSuggestedUsers({int limit = 10})` — queries `users` ordered by `createdAt` desc, excludes current user
- [ ] 4.5.2 — Show suggested list as idle state in `search_screen.dart` under "People you might know" heading
- [ ] 4.5.3 — (Optional) Denormalize `followerCount` on `users` doc via `FieldValue.increment` in FollowService — eliminates N fan-out reads in search results (existing docs default to 0)

---

## Feature 5: Home Feed Polish

**[x] 5.1 — Real-time feed updates**
- Convert `home_feed_screen.dart` to use a Firestore `snapshots()` stream instead of a one-time fetch
- `FeedService.watchFeedPosts()` batches `whereIn` queries for >30 following and merges streams
- Removed refresh button — stream handles live updates automatically

**[x] 5.2 — Like functionality with Firestore**
- Update like/unlike to write `likedByUserIds` in Firestore atomically (`FieldValue.arrayUnion/arrayRemove`)
- Reflect like state and count in real time via the feed stream

**[x] 5.3 — Comments**
- Added `commentCount` field to `DogPost` (Firestore-backed, incremented atomically via `FieldValue.increment`)
- Added `toFirestore()` / `fromFirestore()` to `DogPostComment`
- `FeedService.watchComments(postId)` streams comments subcollection in real time
- `FeedService.addComment(postId, content)` writes to `dogPosts/{id}/comments` and increments `commentCount`
- `DogPostCard` converted to `StatefulWidget` with expandable comment thread (tap comment icon to toggle)

**5.4 — Discover feed for new/unfollowing users**
- [ ] 5.4.1 — Add `FeedService.getDiscoverPosts({int limit = 20})` — queries `dogPosts` globally ordered by `createdAt` desc (one-time fetch)
- [ ] 5.4.2 — In `home_feed_screen.dart`, detect empty stream and render a "Discover" list with a banner: "Follow users to see their posts here"
- [ ] 5.4.3 — Add inline Follow button on each discover card (via FollowService)
- [ ] 5.4.4 — Add "Find more users" button at bottom routing to Search tab

**5.5 — Post detail screen + tappable cards**
- [ ] 5.5.1 — Create `lib/screens/dog_post_detail_screen.dart` (full post + comments + comment input)
- [ ] 5.5.2 — Wrap `DogPostCard` in `InkWell` → routes to detail screen on tap (comment icon tap still expands inline — existing behavior kept)
- [ ] 5.5.3 — Make author avatar and display name tappable → ProfileScreen (guarded when userId == currentUserId)
- [ ] 5.5.4 — Update Feature 7.2 notifications routing to push post detail screen when notification type is `postLiked`

---

## Feature 6: Collections Screen (breed progress tracker)

**[ ] 6.1 — Extract shared breed/color constants**
- Extract `_commonBreeds` and `_commonColors` from `log_dog_screen.dart` and `add_dog_screen.dart` to `lib/constants/dog_data.dart`

**[ ] 6.2 — Rewrite `collections_screen.dart`**
- Fetch user's posts via `FeedService.getUserPosts(currentUserId)`
- Group by breed → `Map<String, List<DogPost>>`
- Compute progress ratio: encountered / total known breeds
- Two tabs: "By Breed" and "By Color"
- Each entry: breed name, count, `LinearProgressIndicator`
- Sort by count desc (rarest at bottom as aspirational targets)

**[ ] 6.3 — Wire milestone notification trigger**
- After post creation in `log_dog_screen.dart`, compute updated breed count
- Call `NotificationService.notifyMilestoneReached` at 25 / 50 / 100%
- Show `SnackBar` / `Dialog` as immediate celebration UI

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
- Enable Push Notifications capability in Xcode (Signing & Capabilities tab) before starting
- Add `firebase_messaging: ^15.1.3` to `pubspec.yaml`
- Integrate `firebase_messaging` — request permission, save FCM token to user's Firestore doc
- Handle foreground and background messages
- Wire `notifyNewFollower` and `notifyPostLiked` to send FCM via Cloud Function or direct API call

---

## Feature 8: Photo Handling

**[x] 8.1 — Image picker integration**
- `image_picker` package already added and wired in `log_dog_screen.dart` (gallery + camera)
- Profile photo selection wired in onboarding and profile edit screens
- **Known limitation**: `log_dog_screen.dart` previously stored the raw `image_picker` temp file path
  as `photoUrl` in Firestore. These paths (`/tmp/image_picker_*.jpg`) are short-lived simulator/device
  temp files — they are deleted by the OS and are meaningless to other users or on subsequent sessions.
  This caused `PathNotFoundException` errors in the feed. Fixed by setting `photoUrl: null` on post
  creation until Storage upload is implemented in 8.2.

**8.2 — Firebase Storage upload**
- Create `lib/services/storage_service.dart` with `uploadDogPhoto(file)` and `uploadProfilePhoto(file)`
- In `log_dog_screen.dart`: call `StorageService.uploadDogPhoto(_imageFile!)` before `createPost`;
  pass the returned download URL as `photoUrl` on the `DogPost`
- Same pattern for profile photos in onboarding and profile edit screens
- Store the returned HTTPS download URL (not local path) in the Firestore document

---

## Feature 9: Location

**9.1 — GPS tagging on log form**
- Add `geolocator` package
- In `log_dog_screen.dart`, add "Use my location" button that auto-fills a city/region string
- Location is opt-in; allow manual text entry as fallback

---

## Feature 10: Pre-launch Security

**10.1 — Firebase App Check**
- Enable App Check in the Firebase console (use DeviceCheck on iOS, Play Integrity on Android)
- Add `firebase_app_check` to `pubspec.yaml`
- Initialize App Check in `main.dart` before other Firebase services
- Use debug provider for emulator/simulator; production providers for release builds
- Enforce App Check in the Firebase console for Firestore and Storage (enforcement blocks requests without a valid attestation)
- Note: requires a signed production build to test end-to-end; do this step with a release candidate

---

## Feature 11: Dog Tagging Loop

**Dependencies:** Feature 8.2 (Storage) should land first so dog photos are meaningful. Feature 7.1 (NotificationService) must land first.

**[ ] 11.1 — Dog tag step in `log_dog_screen.dart`**
- Optional "Tag an existing dog" row → bottom sheet with `DogService.searchDogs()` results
- On select: display chip "Tagging: Buddy by @alex"
- On submit: write `taggedDogId` on DogPost, call `FieldValue.increment(1)` on dog doc directly (atomic — no read-then-write race)

**[ ] 11.2 — Schema update in `lib/models/notification.dart`**
- Add `dogLogged` to `NotificationType` enum
- Add optional `dogId` field to `AppNotification` with `toFirestore()` / `fromFirestore()` support
- Update Firestore security rules for the new field

**[ ] 11.3 — Wire notification after post creation**
- After post with `taggedDogId` is created, look up dog's ownerId → write `dogLogged` notification (skip if owner == current user)
- Add `NotificationService.notifyDogLogged(ownerId, actorName, dogId, postId)` in Feature 7.1 service

**[ ] 11.4 — Create `lib/screens/dog_detail_screen.dart`**
- Shows DogProfile fields (photo, breed, description, `timesLogged` count) and owner info
- Feed of all DogPosts where `taggedDogId == dog.id`
- Make dog cards on `profile_screen.dart` tappable (currently dead — no action on tap)

**[ ] 11.5 — Firestore rules: allow any authenticated user to increment `timesLogged`**
- Allow increment when creating a DogPost with a valid `taggedDogId`

---

## Feature 12: "Log Again" Quick-Relog

**Dependency:** Feature 5.5 (post detail) for the overflow menu surface.

**[ ] 12.1 — `LogDogScreen` accepts optional `DogPost? prefillFrom` param**
- Pre-populates name, breed, color, `taggedDogId` from it in `initState`

**[ ] 12.2 — Add "Log Again" option to DogPostCard overflow menu (own posts only)**
- Pushes `LogDogScreen` with `prefillFrom` set

**[ ] 12.3 — Wire callback: on successful relog, pop back to previous screen**

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
