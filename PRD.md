# Product Requirements Document

**Product:** Log Your Dog
**Platform:** Mobile (Flutter — iOS & Android)
**Date:** June 22, 2025
**Author:** Joe Strobel

---

## 1. Overview

**Log Your Dog** is a social, collectible dog-spotting app. Users spot dogs in the real world, log them with a name, breed, color, rating, and optional photo, then share those logs with their followers and fill out personal collections organized by breed, color, rating, and location.

**Core value props:**
- **Social:** Post your dog spots to a follower feed; like and comment on others'.
- **Collectible:** Every log fills a collection — catch all the breeds, colors, and ratings.

### Core Loop

1. Spot a dog in the world
2. Log it (name, breed, color, rating, optional photo)
3. Post appears in your followers' feeds
4. Your collections update — track progress toward completing a category
5. Follow friends to see their logs and compare collections

---

## 2. Goals & Objectives

- Provide a fun and engaging platform for dog lovers
- Let users log and track dogs they encounter in the world
- Encourage social interaction via a follower-based feed with likes and comments
- Implement a "collect them all" mechanic around dog attributes (breed, color, rating, location)
- Track the popularity of dogs based on how often they're logged

---

## 3. Core Features

### 3.1 Home Feed

The main feed displays posts from accounts the user follows, in reverse chronological order.

**Each post card displays:**
- Dog name, breed, color, location, rating (1–5 paws)
- Optional photo
- Like count and comment count
- Expandable comment thread below the post card
- Text input to add a comment

**Interactions:**
- Like/unlike a post
- Add a comment; view the full comment thread inline
- Tap a post to see full detail

**Follow system (asymmetric):**
- Users can follow anyone; following is not mutual (Twitter-style)
- Feed shows posts only from accounts you follow
- Follow/unfollow from profile pages and user search results
- Follower and following counts displayed on every profile

### 3.2 Logging a Dog

Users log a dog via a form that includes:
- Dog name
- Breed
- Color
- Location (auto-detected with permission, or user-provided)
- Rating (1–5 paws)
- Optional photo

**Dog tagging (nice-to-have, not core MVP):**
- The log form includes an optional "Tag a dog" field to link the log to an existing dog profile
- If not tagged, the log is standalone (no dog profile link)
- Tagged dogs have a "times logged" counter that increments
- Full tagging UX (search + select during log) is a future feature; see Section 6

### 3.3 Profile Page

- Displays profile photo, display name, location, bio
- Follower count and following count
- Lists dogs the user owns with full dog profile details (name, breed, color, photo, owner link, times logged)
- Shows the user's personal log history with filtering options

### 3.4 Collections

Collections are derived dynamically from a user's own logs — no separate data store required.

**Grouping dimensions:**
- **Breed** — e.g., "Golden Retrievers: 3 logged"
- **Color** — e.g., "Black dogs: 7 logged"
- **Rating tier** — Low (1–2 paws), Mid (3 paws), High (4–5 paws)
- **Location** — by city or region

**Progress tracking:**
- Each group shows "X of Y [bulldogs] logged" based on known entries in that category
- Dogs can appear in multiple collections simultaneously (a black labrador counts in both Color: Black and Breed: Labrador)
- Collections are per-user — based on that user's own logs, not their followers'

**Milestone badges:**
- 25%, 50%, and 100% completion of a category triggers a milestone badge
- Milestone achievement triggers an in-app notification (see 3.5)

### 3.5 Notifications

Users are notified when:
- Someone follows them
- A follower likes their post
- Their owned dog is tagged/logged by someone else
- A collection milestone is reached (25%, 50%, 100% of a category)

**Delivery:** Push notifications via Firebase Messaging; in-app notification list screen.

---

## 4. Authentication & Onboarding

- Email/password sign-up and sign-in via Firebase Auth
- On first launch, users optionally set a display name, profile photo, and location
- Guest browsing is out of scope for MVP — auth is required to use the app

---

## 5. User Discovery

- Users can search for others by username or display name
- Search results show profile photo, display name, and follower count
- Follow button available on search results and profile pages
- Follower/following counts shown on all profiles

---

## 6. Core User Journey

The primary flow for a new user:

1. **Sign up** — create account with email/password; optionally set display name and profile photo
2. **Log first dog** — fill out name, breed, color, rating, optional photo
3. **Post is shared** — appears in the feeds of anyone who follows the user
4. **Check Collections** — see breed and color progress fill in after first log
5. **Follow a friend** — find them via search; their logs now appear in the feed

---

## 7. Technical Requirements

### Platform & Framework

- Built with Flutter for cross-platform (iOS and Android) support
- State management: Provider, Riverpod, or Bloc

### Backend

Firebase is the committed backend for MVP:
- **Firestore** — real-time database for posts, profiles, follows, notifications
- **Firebase Auth** — email/password authentication
- **Firebase Storage** — dog photos
- **Firebase Messaging** — push notifications
- **Cloud Functions** — optional server-side logic (e.g., fan-out for feeds)

> Note: Current services use SharedPreferences for local storage — this is for development/demo only and will be replaced with Firestore.

### Core Packages

- `image_picker`, `cached_network_image` — photo handling
- `geolocator` or `location` — GPS tagging
- `firebase_messaging` — push notifications
- `cloud_firestore` — real-time feed updates

### Database Entities

**Users**
- `id`, `displayName`, `email`, `profilePhotoUrl`, `bio`, `location`, `createdAt`

**DogProfile**
- `id`, `ownerId`, `name`, `breed`, `color`, `photoUrls`, `timesLogged`, `createdAt`

**DogPost** (a log entry)
- `id`, `authorId`, `dogName`, `breed`, `color`, `location`, `rating`, `photoUrl`
- `taggedDogId` (optional — links to a DogProfile)
- `likedByUserIds`, `comments` (list of DogPostComment)
- `createdAt`

**DogPostComment**
- `id`, `postId`, `authorId`, `userProfilePicture`, `text`, `createdAt`

**Follow** (`lib/models/follow.dart`)
- `id: String`
- `followerId: String` — the user doing the following
- `followeeId: String` — the user being followed
- `createdAt: DateTime`

**AppNotification** (`lib/models/notification.dart`)
- `id: String`
- `recipientId: String`
- `type: NotificationType` — enum: `newFollower`, `postLiked`, `dogTagged`, `milestoneReached`
- `fromUserId: String?` — who triggered it
- `postId: String?` — related post, if applicable
- `dogId: String?` — related dog profile, if applicable
- `message: String` — human-readable text
- `isRead: bool`
- `createdAt: DateTime`

> Collections are derived dynamically by grouping a user's DogPost logs by `breed`, `color`, `rating`, or `location`. No separate collection model is needed for MVP.

---

## 8. Non-Functional Requirements

- **Performance:** Feed and collections load in <2s; smooth scrolling and image caching
- **Privacy:** Location tracking is opt-in and can be anonymized
- **Security:** Authentication required for all features; input sanitization; photo access controls
- **Responsiveness:** Adapts to different screen sizes (phones and tablets)
- **Testing:** Unit tests, widget tests, and integration tests using `flutter_test`

---

## 9. Out of Scope (MVP)

- In-app messaging
- Public dog map view
- Dog verification or moderation tooling
- AR-based dog detection
- Full dog tagging UX during log (search + select from existing profiles — nice-to-have)
- Guest/unauthenticated browsing

---

## 10. Success Metrics

- Daily active users (DAUs)
- Number of dog logs per week
- % of users who follow at least one other user
- Number of dog profile tags
- Collection milestone completions

---

## 11. Current Implementation Status

| Feature | Status |
|---|---|
| Home feed with like functionality | Built (mock data) |
| Log Dog form | Built |
| Profile screen | Built |
| Add Dog screen | Built |
| Data models: UserProfile, DogProfile, DogPost | Built |
| Services: FeedService, DogService, ProfileService | Built (local SharedPreferences) |
| Collections screen | UI shell only — no logic |
| Notifications screen | UI shell only — no logic |
| Auth / onboarding | Not started |
| Follow system | Not started |
| Firebase integration | Not started (placeholders exist in services) |
