# LOFO (Campus Lost & Found) — Phase 1 Project Audit

**Audit date:** October 18, 2026
**Source audited:** the current working tree on `main`, including the uncommitted changes to the screens and widgets and the untracked `lib/widgets/app_feedback.dart`
**Scope:** `lib/`, `test/`, `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, `pubspec.yaml`, `firestore_rules_test/`, Android/iOS configuration, and git history
**Reference guide:** `docs/Computer_Science_Documentation_Parts.pdf`. It was used to decide what to look for, not as a checklist.

> This audit does not include any credentials. Firebase configuration values and Cloudinary upload settings exist in the source code but are left out on purpose.

---

## 1. Purpose of the Application

The app is called **"Campus Lost & Found"** in the code (`MaterialApp.title`, Terms of Service, About dialog). "LOFO" does not appear anywhere in the source code. The Terms of Service (`lib/services/terms_service.dart`) state its purpose:

> It helps members of the campus community report lost items, report found items, and return items to their rightful owners.

The app is a Flutter mobile client backed by Firebase. Users post Lost or Found items, the app suggests possible matches, users claim Found items by answering a verification question set by the finder, and the two users talk through in-app messaging until the item is returned.

## 2. User Roles

The app has **one account type**: a registered user whose email is verified and who has accepted the current Terms of Service. There is **no administrator role, admin screen, or admin dashboard** in the app.

Inside a single transaction, the same user can act in different situational roles:

| Situational role | What the code allows |
|---|---|
| **Reporter / post owner** | Creates Lost or Found posts, deletes their own posts, and views matches for their posts. |
| **Finder** (owner of a Found post) | Sets a verification question, receives claims, and approves or rejects them. Approving completes the return. |
| **Claimant** | Submits one claim per Found item, answers the verification question, and can resend the claim after a rejection. |
| **Lost-item reporter** | Receives a "Possible Match Found" notification when a similar Found item is posted. |
| **Return participant** | Gives optional feedback (finder or claimant) after a return is completed. |

**External "moderation Worker" (unverified):** the Firestore rules mention a server-side "moderation Worker" that writes `users/{uid}.bannedUntil`, changes report statuses, and creates `moderation_*` notifications. **No code for this worker exists in the repository.** It should not be documented as a system actor unless you can show that it exists.

## 3. Feature Inventory

### 3.1 Implemented (present in the code and reachable from the UI)

| # | Feature | Evidence (files) |
|---|---|---|
| F1 | Registration with name, email and password (Firebase Authentication) | `register_screen.dart`, `auth_service.dart` |
| F2 | Email verification: verification screen, resend link, re-check status, ID-token refresh | `verify_email_screen.dart`, `auth_service.dart` |
| F3 | Login, forgot password (reset email), logout with confirmation | `login_screen.dart`, `forgot_password_screen.dart`, `profile_screen.dart` |
| F4 | "Remembered accounts" quick-pick on the login screen. Stores only uid, email, name, photo URL and last sign-in time on the device. **No passwords are stored.** | `remembered_account.dart`, `remembered_accounts_service.dart` |
| F5 | Terms of Service / User Agreement, version 1.0. Acceptance is recorded in Firestore and cached on the device for offline start-up. | `terms_service.dart`, `terms_screen.dart` |
| F6 | Access gate: users enter the app only after verifying their email **and** accepting the Terms. This is also enforced by the server rules. | `access_gate.dart`, `firestore.rules` (`hasAccess()`) |
| F7 | Report an item as Lost or Found: item name, category (Electronics, Wallet, ID, Keys, Books, Others), location (Library, Classroom, Laboratory, Cafeteria, Gymnasium, Main Building, Other), date, description, and up to 5 photos. Photos are **required for Found** and **optional for Lost**. A **verification question is required for Found** items. | `report_item_screen.dart` |
| F8 | Possible-match check before a report is submitted. The user can continue posting or go back and edit. | `draft_matches_screen.dart`, `item_matching_service.dart` |
| F9 | Home feed of other users' posts: search by name, category or location; filter by Lost/Found and by category; pull-to-refresh | `home_screen.dart`, `item_provider.dart` |
| F10 | Item details with a multi-photo, full-screen image viewer | `item_details_screen.dart`, `full_screen_image_viewer.dart` |
| F11 | Claim a Found item: answer the verification question and add details. One claim per user per item, enforced by the deterministic id `itemId_claimantId`. A rejected claim can be resent. | `claim_item_screen.dart`, `claim_service.dart` |
| F12 | Finder approves or rejects a claim. On approval the app writes a `completedReturns` record, then **deletes the item, the claim, the conversation and all messages**. | `claim_service.dart` (`updateClaimStatus`, `_deleteResolvedData`) |
| F13 | One-to-one messaging per post. Conversation ids are deterministic, messages are at most 2,000 characters, unread counts are tracked per user, and the claim panel appears inside the chat. | `chat_service.dart`, `conversation_screen.dart`, `messages_screen.dart` |
| F14 | In-app notifications: claim received, resent, approved and rejected; "Possible Match Found" for Lost reporters; a device-only "Report Posted" notice after an offline report syncs. Also mark as read, mark all as read, and an unread badge. | `notification_service.dart`, `notifications_screen.dart`, `main_navigation_screen.dart` |
| F15 | My Posts: list, filter, delete with confirmation, "Check Matches" for each post | `my_posts_screen.dart`, `potential_matches_screen.dart` |
| F16 | Optional post-return feedback: a 1–5 rating plus a recommendation of up to 500 characters, once per participant | `return_feedback_sheet.dart`, `feedback_service.dart` |
| F17 | Offline-first data layer: local SQLite (Drift) cache, offline queue for item create/update/delete, claims, messages and mark-as-read, and automatic sync when the connection returns (with a 30-second retry). The cache is scoped per account and cleared on logout. | `lib/data/**` |
| F18 | Celebration (confetti) animation after a successful action | `celebration_overlay.dart` |

### 3.2 Partially implemented or not exposed in the UI

| Item | Finding |
|---|---|
| **Edit a post** | `ItemProvider.updateItem` and the repository and service code exist, but **no screen calls them**. Users cannot edit a post from the UI. |
| **Profile options** | "Edit Profile", "Personal Information", "Change Password", "Notification Settings" and "Help & Support" all show a **"coming soon"** message. Only "About" and "Log Out" work. |
| **"Claimed" filter in My Posts** | The filter option exists, but no code ever sets an item's status to `Claimed`, because approved items are deleted. The filter will always be empty. |
| **Notification types `match`, `claim_update`, `message`** | They are defined and allowed by the rules but **never created** by the code. New chat messages raise the conversation unread count only; they do not create a notification. |
| **Item status `Pending`** | A legacy value that the code treats as "Found". New posts use only `Lost` or `Found`. |

### 3.3 Planned or unverified (only in rules, tests or text, not in the app)

| Item | Finding |
|---|---|
| **Content reporting (flagging posts)** | The `reports` collection rules allow the reasons spam, inappropriate, harassment, scam and other, and Terms section 6 mentions "reporting tools provided in the app". **There is no UI or service code to submit a report.** |
| **Warnings, suspensions and posting bans** | The rules check `users/{uid}.bannedUntil` before item create and update, and the Terms describe warnings and bans. **Nothing in the repository writes these fields.** This depends on the external moderation Worker, which is not in the repository. |
| **Push notifications (FCM)** | **Not implemented.** Notifications appear only in the app. |
| **Firebase Storage** | `storage.rules` and the `firebase_storage` dependency exist, but **no Dart file imports Firebase Storage**. Images are uploaded to **Cloudinary**. |
| **iOS and web builds** | `firebase_options.dart` is configured **only for Android**. Other platforms throw "not configured". |

## 4. Architecture

The app uses a layered, offline-first client architecture. There is no custom backend server.

```
Screens & Widgets (lib/screens, lib/widgets)
        │  read/watch state
        ▼
Providers — ChangeNotifier via `provider` (lib/providers)
        │
        ▼
Repositories — offline-first (lib/data/repositories)
   ├── Local: Drift/SQLite AppDatabase (lib/data/local)   ← UI reads from here
   └── Remote: Services (lib/services)
          ├── Firebase Authentication
          ├── Cloud Firestore (protected by firestore.rules)
          └── Cloudinary REST image upload (HTTP)
SyncManager + ConnectivityService (lib/data/sync, lib/data/local)
   └── push queued changes when back online; Firestore listeners pull server data
```

- **Startup order:** `main.dart` → Firebase init → AppDatabase / ConnectivityService / repositories / SyncManager → `SplashScreen` → `AccessGate` → `MainNavigationScreen` (bottom tabs: Home, Messages, My Posts, Notifications, Profile).
- **Business logic runs on the client.** This includes matching, notification creation and the cleanup after a return. Firestore Security Rules are the only server-side enforcement.

## 5. Technologies

| Layer | Technology (from `pubspec.yaml` and the config files) |
|---|---|
| Language / framework | Dart (SDK ^3.12.2), Flutter (Material Design) |
| State management | `provider` |
| Authentication | Firebase Authentication (email/password, email verification, password reset) |
| Cloud database | Cloud Firestore, with Security Rules and composite indexes |
| Image hosting | Cloudinary (unsigned upload over the REST API using `http`); images displayed with `cached_network_image` |
| Local database | Drift (`drift`, `sqlite3`, `sqlite3_flutter_libs`), `path_provider` |
| Device services | `image_picker`, `connectivity_plus`, `shared_preferences`, `uuid` |
| Dev / testing | `flutter_test`, `flutter_lints`, `build_runner`, `drift_dev`; Node.js with `@firebase/rules-unit-testing` and the Firebase Emulator for the rules tests |
| Target platform | Android. The application id is still the default `com.example.lost_and_found_app`. |

## 6. Database Structure

### 6.1 Cloud Firestore collections (based on the models, services and rules)

| Collection | Document ID | Fields | Written by |
|---|---|---|---|
| `items` | UUID v4 generated on the device (offline-first) | title, description, category, location, date (string), status (Lost/Found), imageUrl, imageUrls[], username, ownerId, verificationQuestion (Found only), createdAt | The post owner |
| `claims` | `{itemId}_{claimantId}` | itemId, itemTitle, itemImageUrl, claimantId, claimantName, ownerId, answer, additionalDetails, status (Pending/Approved/Rejected), createdAt | The claimant creates it; the finder changes its status |
| `conversations` | `{postId}_{uidA}_{uidB}` (sorted) | postId, itemName, itemImageUrl, itemType, participantIds[2], participantNames{}, lastMessage, lastMessageTime, unreadCounts{} | Participants |
| `conversations/{id}/messages` | UUID v4 generated on the device, or `claim_{itemId}…` for claim messages | senderId, senderName, text (1–2000 chars), timestamp, isRead | Participants |
| `notifications` | auto id | recipientId, type, title, message, relatedItemId, relatedClaimId, isRead, createdAt | Created by another user's action (client-side) |
| `termsAcceptances` | `{uid}_{version}` | userId, email, version, acceptedAt | The user; create-only |
| `completedReturns` | `{itemId}_{claimantId}` | itemId, itemTitle, ownerId, claimantId, completedAt | The finder, at approval; immutable |
| `feedback` | `{returnId}_{uid}` | returnId, itemTitle, authorId, role (finder/claimant), otherUserId, rating (1–5), recommendation (≤500), createdAt | A participant; create-only |
| `reports` *(rules only)* | `{itemId}_{reporterUid}` | itemId, reporterId, reason, details (≤300), status, createdAt | **No app code** |
| `users` *(rules only)* | uid | bannedUntil, offenseCount (from comments) | **Server only; no app code** |

- **There is no `users` profile collection written by the app.** Names come from the Firebase Auth `displayName` and are copied into items, claims and conversations.
- **Indexes** (`firestore.indexes.json`): items (ownerId, createdAt↓); claims (ownerId, createdAt↓); notifications (recipientId, createdAt↓); conversations (participantIds array-contains, lastMessageTime↓) and (postId, participantIds).

### 6.2 Local Drift (SQLite) tables

These are the tables `items`, `claims`, `conversations`, `messages` and `notifications`. They copy the Firestore fields and add sync flags: `synced`, `pendingCreate`, `pendingUpdate`, `pendingDelete`, `pendingMarkRead`, `updatedAt`, plus `localImagePath(s)` for offline photos and `viewerId` to separate accounts.

## 7. Security and Data-Privacy Measures (implemented)

1. **Server-side access gate.** All protected data requires `email_verified == true` in the signed ID token **and** an acceptance record for Terms version 1.0.
2. **Ownership rules.** Only the owner can create, update or delete an item, and ownership cannot be transferred.
3. **Private claims.** Only the claimant and the finder can read a claim. The finder can change only `status`. The claimant can change only the answers and the status, and only when resubmitting a rejected claim. The claim id prevents duplicate claims. Users cannot claim their own items. Only Found items can be claimed.
4. **Private chats.** Conversations must have exactly two distinct participants, only participants can read them, and the item metadata cannot be changed. Messages must come from the authenticated sender, be 1–2000 characters long, and can be marked read only by the recipient.
5. **Notifications.** Only the recipient can read or delete a notification, and the only field that can be updated is `isRead`. Moderation notification types cannot be created by clients.
6. **Immutable audit records.** Terms acceptances, completed returns and feedback cannot be updated or deleted.
7. **Default deny** for every other path.
8. **Data minimization after a return.** The item, claim answers, conversation and messages are deleted when a claim is approved.
9. **On-device privacy.** No passwords are stored. The cached data of the previous account is cleared on logout, and unsynced offline items are visible only to the user who created them.

## 8. Testing Evidence Found

| Test suite | What it covers | Status |
|---|---|---|
| `test/data/local/app_database_test.dart` (20 tests) | Offline insert/update/delete, cross-account visibility, server-merge conflict handling, message de-duplication, offline claims, offline mark-as-read, logout cache clearing | **Passed.** I ran `flutter test` on Oct 18, 2026: 21/21 passed. |
| `test/celebration_test.dart` (1 test) | Celebration overlay widget | **Passed** (in the same run) |
| `firestore_rules_test/rules.test.mjs` (about 16 cases) | Access gate, item ownership, claims, chats, notifications, bans, users, termsAcceptances | **Not run by me.** It needs the Firebase Emulator. I could find no saved results. |

**Not found:** UI/integration tests for the screens, tests for the matching algorithm, performance tests, and any user-acceptance testing, survey or evaluation data. **You will need to provide these if your documentation must report them.**

## 9. Known Limitations and Risks (from the code)

1. **Notifications can be spoofed.** Any verified user can create a notification of an allowed type for any `recipientId`. The rules do not link the notification to a real claim or item.
2. **Client-side business logic.** Match notifications and the cleanup after a return run on the user's device. If the app closes partway through, the cleanup may be incomplete.
3. **No pagination.** The Home feed and the match notifications read the whole `items` collection (or a whole category), so the app may slow down as the data grows.
4. **The matching method is simple:** English keywords, a hand-made synonym list, a crude plural remover, and a Jaccard-style score (70% name, 30% same category). It does not compare images or descriptions, and it does not use location or date.
5. **Images stay on Cloudinary.** Deleting a post or completing a return does not delete its images. The unsigned upload setting is embedded in the client app.
6. **No transaction history after a return.** Only the minimal `completedReturns` record remains, so the app cannot show return statistics.
7. **Moderation is incomplete** (see §3.3). The Terms promise reporting tools and bans that the app does not provide.
8. **Profile management is unfinished** (see §3.2). Users cannot change their name or password inside the app (password reset works through the login screen).
9. **Chat permissions.** Any participant can delete any message in a conversation. The participant names are supplied by the client and are not checked.
10. **The item date is stored as a string**, not as a timestamp.
11. **The app is not ready for release:** Android only, the default `com.example` application id, and the default Flutter README.
12. **Version documented.** *Update (Oct 18, 2026):* the changes that were uncommitted at audit time were committed as `6b4124c` ("Backup"). All documentation describes that commit.
