# Chapter 4 — System Development, Results, and Discussion

> Every statement in this chapter describes the current source code. Test results are reported **only** where real evidence exists. Rows marked `[[ ]]` must be filled in with results from your own testing.

---

## 4.1 System Implementation

LOFO was built as a Flutter application for Android. The cloud services were configured as follows. **No keys or secrets are reproduced in this document.**

1. **Firebase project.** A Firebase project was created and linked to the Android app with the FlutterFire configuration (`firebase.json`, `lib/firebase_options.dart`, `android/app/google-services.json`). Only the Android platform is configured.
2. **Firebase Authentication.** The Email/Password sign-in method is used. The app also uses Firebase Authentication to send verification and password-reset emails.
3. **Cloud Firestore.** The database stores the shared collections described in Section 3.8. Security Rules (`firestore.rules`) and composite indexes (`firestore.indexes.json`) are deployed with the Firebase CLI.
4. **Cloudinary.** Photos are uploaded to Cloudinary with an *unsigned upload preset* over HTTPS (`lib/services/cloudinary_service.dart`). The returned secure URL is saved in the item document.
5. **Local database.** A Drift database (`lib/data/local/app_database.dart`) is created when the app starts. Its code is generated with `build_runner`.
6. **App start-up** (`lib/main.dart`). The app initializes Firebase, then creates the local database, the connectivity service, the four repositories and the `SyncManager`, starts the sync manager, and registers all objects with `MultiProvider`. The first screen is the Splash Screen.

**Project structure**

```
lib/
 ├─ main.dart                 App entry and dependency wiring
 ├─ firebase_options.dart     FlutterFire configuration (Android)
 ├─ models/                   Item, Claim, Conversation, Message, Notification, Feedback, RememberedAccount
 ├─ services/                 Firebase / Cloudinary access, matching algorithm, terms, feedback
 ├─ data/
 │   ├─ local/                Drift database, tables, connectivity service
 │   ├─ repositories/         Offline-first repositories
 │   └─ sync/                 SyncManager
 ├─ providers/                ChangeNotifier state
 ├─ screens/                  19 screens
 ├─ widgets/                  Reusable UI pieces (cards, feedback sheet, image viewer, celebration)
 └─ theme/                    App theme and colors
```

---

## 4.2 Description of System Modules

**Table 19. System Modules and Implementation Status**

| # | Module | Main files | Status |
|---|---|---|---|
| 1 | Authentication and Access Gate | `auth_service.dart`, `login/register/verify_email/forgot_password_screen.dart`, `access_gate.dart` | Implemented |
| 2 | Terms of Service Agreement | `terms_service.dart`, `terms_screen.dart` | Implemented |
| 3 | Item Reporting | `report_item_screen.dart`, `item_repository.dart`, `cloudinary_service.dart` | Implemented (editing a post is **not** implemented) |
| 4 | Item Matching | `item_matching_service.dart`, `draft_matches_screen.dart`, `potential_matches_screen.dart` | Implemented |
| 5 | Home Feed and Search | `home_screen.dart`, `item_provider.dart`, `item_details_screen.dart` | Implemented |
| 6 | Claims and Verification | `claim_item_screen.dart`, `claim_service.dart`, `claim_repository.dart`, `conversation_screen.dart` | Implemented |
| 7 | Messaging | `chat_service.dart`, `chat_repository.dart`, `messages_screen.dart`, `conversation_screen.dart` | Implemented |
| 8 | Notifications | `notification_service.dart`, `notification_repository.dart`, `notifications_screen.dart` | Implemented (in-app only) |
| 9 | My Posts | `my_posts_screen.dart` | Implemented |
| 10 | Post-Return Feedback | `feedback_service.dart`, `return_feedback_sheet.dart`, `celebration_overlay.dart` | Implemented |
| 11 | Offline Sync | `app_database.dart`, `sync_manager.dart`, `connectivity_service.dart` | Implemented |
| 12 | Profile | `profile_screen.dart` | **Partial:** only *About* and *Log Out* work; the other options show "coming soon" |
| 13 | Content Reporting and Moderation | `firestore.rules` only | **Planned:** no app screen and no moderation component |

### Module 1: Authentication and Access Gate
To register, a user enters a **full name, email, password and password confirmation**. Firebase Authentication creates the account, stores the name as the display name, and sends a verification email. On the **Verify Your Email** screen, the user can resend the link, confirm with *"I've Verified My Email"*, or switch to a different account. When the user confirms, the app reloads the account and **forces a refresh of the ID token**, so that the server rules see the verified status right away. The login screen also lists **accounts previously used on the device** (name, email and photo only, never a password), so a returning user can sign in quickly. The **Access Gate** runs after login, after registration and from the splash screen. It sends the user to *Verify Email*, then to *Terms*, and finally to the main app.

### Module 2: Terms of Service Agreement
The Terms (version 1.0, nine sections) appear after email verification. Choosing *I Accept* creates a `termsAcceptances/{uid}_1.0` record. Choosing *Decline* signs the user out. Each acceptance is also saved on the device, so a user who has already accepted can open the app while offline. If the version number is changed in **both** `TermsService.currentVersion` and `requiredTermsVersion()` in the rules, every user must accept the Terms again.

### Module 3: Item Reporting
The report form has numbered steps: type (Lost/Found), photos (up to 5), item name, category, location, date, description, and, for Found items only, a verification question with suggestion chips (for example, "What is inside it?"). When the user submits, the app first runs the matching module (Module 4). The report is then **saved to the local database immediately** with an ID generated on the device (UUID v4), so it appears on the screen right away. The app then tries to upload the photos and write the document to Firestore. If the device is offline, the report waits in a queue (Module 11).

### Module 4: Item Matching
Matching runs in three places:
1. **Before posting**: the *Possible Matches* screen lets the user go back and edit the report or continue posting.
2. **My Posts → Check Matches**: shows possible matches for one existing post.
3. **When a Found item reaches the server**: users who own an older Lost item in the **same category** with a similar name receive a "Possible Match Found" notification. Each user receives at most one notification, for their best-matching item.

The algorithm is explained in Section 4.5.

### Module 5: Home Feed and Search
The Home tab lists **other users' posts**, newest first. Users can search by text (the item name, category or location contains the search words) and filter by type (All/Lost/Found) and by one of six category cards. A *Clear filters* control resets the view, and the user can pull down to refresh. Item Details shows every photo, which can be opened in a full-screen viewer, and shows *Message* or *Claim* actions depending on the item type and the user's role.

### Module 6: Claims and Verification
A user can claim only a **Found** item that **another user** posted. The claimant answers the finder's verification question and may add details. The claim ID `{itemId}_{claimantId}` allows **one claim per user per item**, while different users can still claim the same item. Submitting a claim also (a) opens or reuses the conversation for that item, (b) posts a "Claim request submitted" message in it, and (c) notifies the finder. Inside the conversation, the finder sees a **private claim panel** with the claimant's answer and the buttons *Accept Claim* and *Reject*:
- **Reject**: the status becomes Rejected and the claimant is notified. The claimant may use **Resend Claim** with new answers.
- **Accept**: the claimant is notified, the claim is marked Approved, a `completedReturns` record is written, and then the **messages, the conversation, the item and the claim are deleted**. The finder sees a confetti animation followed by an optional feedback form.

The item's public Lost/Found status **never changes** while a claim is pending, so other users do not see that someone has claimed the item.

### Module 7: Messaging
Each conversation belongs to **one post and two users**. Its ID `{postId}_{uidA}_{uidB}` (with the two user IDs sorted) prevents duplicate chats. Sending a message is a Firestore **transaction** that adds the message, updates the conversation preview, and increases the other user's unread count. Messages must be 1–2000 characters long. The Messages tab lists conversations, newest first, and has a search box. A new conversation needs a connection. Messages in an existing conversation can be written offline and are sent later.

### Module 8: Notifications
The app creates the following notifications:

| Event | Type | Recipient |
|---|---|---|
| A claim is submitted or resent | `claim_received` | Finder |
| A claim is approved | `claim_approved` | Claimant |
| A claim is rejected | `claim_rejected` | Claimant |
| A similar Found item is posted | `category_match` | Owner of the Lost item |
| An offline report has synced | `report_posted` (stored on the device only) | Reporter |

Tapping a notification opens the related item or conversation, or, for an approved claim, the confetti animation and the feedback form. Users can mark one notification or all notifications as read. The bottom navigation shows an unread badge.

### Module 9: My Posts
Lists the user's own posts with the filters All, Lost, Found and Claimed, and shows a "sync pending" state for posts created offline. Each post has a menu with *Edit* (currently shows "will be implemented later") and *Delete* (with confirmation). Each post also has *Check Matches*.

> **Note:** The *Claimed* filter does not show anything at present, because approved items are deleted instead of being marked "Claimed".

### Module 10: Post-Return Feedback
After a return, each participant can give **one** rating (1–5 stars) and an optional recommendation (up to 500 characters). The feedback ID `{returnId}_{uid}` and the create-only rule prevent duplicate feedback. Feedback is optional, and only its author can read it.

### Module 11: Offline Sync
See Figure 11. Every local table has *pending* flags. `SyncManager` sends the current user's pending changes in this order: items → claims → messages and conversation read flags → notification read flags. It does this (a) at sign-in, (b) when the connection returns, and (c) every 30 seconds while work remains. Firestore listeners copy server data into the local database. **Rows with a pending local change are not overwritten** by server data. Rows deleted on the server are removed locally unless they still have a pending change. When a user logs out, the cached conversations, messages and notifications of that account are removed, but unsynced changes are kept.

---

## 4.3 User-Interface Presentation

> **Your input is needed.** Add actual screenshots (saved in `docs/documentation/screenshots/`). The captions and descriptions below match the real screens.

| Figure | Screen | Description | Screenshot |
|---|---|---|---|
| 13 | Splash | Shown for 3 seconds, then opens Login or the Access Gate | [[splash.png]] |
| 14 | Login | Email/password login, remembered accounts, Forgot Password, Register | [[login.png]] |
| 15 | Register | Full Name, University Email, Password, Confirm Password | [[register.png]] |
| 16 | Verify Email | Resend link, "I've Verified My Email", Use a different account | [[verify_email.png]] |
| 17 | Terms of Service | Nine sections; Decline / I Accept | [[terms.png]] |
| 18 | Home | Search bar, Lost/Found filter, category cards, item feed | [[home.png]] |
| 19 | Report Item | Step-by-step form with photos and verification question | [[report_item.png]] |
| 20 | Possible Matches (before posting) | Matches with shared keywords; edit or continue | [[draft_matches.png]] |
| 21 | Item Details | Photo gallery, details, Message / Claim | [[item_details.png]] |
| 22 | Claim Item | Verification question, answer, additional details | [[claim_item.png]] |
| 23 | Messages | Conversation list with unread counts and search | [[messages.png]] |
| 24 | Conversation + Claim Panel | Chat; Accept Claim / Reject (finder); Resend Claim (claimant) | [[conversation.png]] |
| 25 | Notifications | List, unread state, Mark all as read | [[notifications.png]] |
| 26 | My Posts | Filters, Edit/Delete menu, Check Matches | [[my_posts.png]] |
| 27 | Potential Matches | Matches for an existing post | [[potential_matches.png]] |
| 28 | Feedback Sheet | Star rating and recommendation after a return | [[feedback.png]] |
| 29 | Profile | Account info, About, Log Out | [[profile.png]] |

---

## 4.4 Database Implementation

### 4.4.1 Firestore Security Rules (summary)

All protected collections use one helper:

```javascript
function hasAccess() {
  return request.auth != null
    && request.auth.token.email_verified == true      // verified email
    && exists(/databases/$(database)/documents/termsAcceptances/
              $(request.auth.uid + '_' + requiredTermsVersion()));  // accepted ToS
}
```

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| items | Any user with access | Owner only (and not banned*) | Owner only; owner cannot change (not banned*) | Owner only |
| claims | Claimant or finder | Claimant; ID = itemId_uid; item exists and is Found; not own item | Finder: `status` only. Claimant: resubmit a Rejected claim | Finder, only when Approved |
| conversations | Participants | Exactly 2 distinct participants including the creator | Only `lastMessage`, `lastMessageTime`, `unreadCounts` | Participants |
| messages | Participants | Sender = self; 1–2000 chars; `isRead` = false | Recipient sets `isRead` from false to true only | Participants |
| notifications | Recipient | Allowed types only (no `moderation_*`) | Recipient; `isRead` only | Recipient |
| termsAcceptances | Owner | Self; current version; server time | ✘ | ✘ |
| completedReturns | Participants | Finder, while the claim is Approved | ✘ | ✘ |
| feedback | Author | Participant; rating 1–5; text ≤ 500 | ✘ | ✘ |
| everything else | ✘ | ✘ | ✘ | ✘ |

\* The posting-ban check reads `users/{uid}.bannedUntil`. Nothing in the current system writes this field (planned moderation).

### 4.4.2 Composite Indexes

**Table 20. Composite Indexes (`firestore.indexes.json`)**

| Collection | Fields |
|---|---|
| items | ownerId ↑, createdAt ↓ |
| claims | ownerId ↑, createdAt ↓ |
| notifications | recipientId ↑, createdAt ↓ |
| conversations | participantIds (array-contains), lastMessageTime ↓ |
| conversations | postId ↑, participantIds (array-contains) |

### 4.4.3 Deterministic Document IDs

| Document | ID format | Purpose |
|---|---|---|
| Claim | `{itemId}_{claimantId}` | One claim per user per item |
| Conversation | `{postId}_{sortedUidA}_{sortedUidB}` | One chat per post per pair of users |
| Terms acceptance | `{uid}_{version}` | One record per version |
| Completed return | same as the claim ID | Links feedback to the return |
| Feedback | `{returnId}_{uid}` | One feedback per participant |
| Item / Message | UUID v4 generated on the device | The same ID is kept offline and online, so syncing never creates duplicates |

---

## 4.5 Algorithms and Important Code

### 4.5.1 Item-Matching Algorithm (`ItemMatchingService`)

**Input:** a new or existing report (name, category, type) and a list of candidate items.
**Output:** up to 10 candidates (1000 when creating notifications), sorted by score.

**Steps:**

1. **Type filter.** Keep only candidates of the **opposite type** (Lost ↔ Found; the legacy value "Pending" counts as Found). Skip the user's own posts and the item itself.
2. **Keyword extraction.** Convert the name to lowercase, remove symbols, and split it into words. Then:
   - remove **stop words** (e.g., *a, the, my, lost, found, new, old,* sizes and **colors**);
   - remove **numbers only** (so "Room 13 key" does not match "iPhone 13");
   - remove a simple **plural ending** (*keys → key*);
   - replace each **synonym** with one common keyword (Table 21).
3. **Keyword requirement.** The two names must share **at least one keyword**.
4. **Accessory guard.** Both names must have the **same accessory words** (*charger, cable, adapter, case, cover, protector, strap, holder, pouch, sleeve, lanyard, stand, mount*). So "phone" does not match "phone charger". If the only shared word is an accessory word, the main objects must not conflict, so "phone charger" does not match "laptop charger".
5. **Name similarity** (`nameScore`):
   - identical normalized names → **1.00**
   - same keyword set, worded differently → **0.95**
   - one keyword set contains the other → **0.85**
   - otherwise the **Jaccard index** |A∩B| / |A∪B|, with a minimum of **0.40**
6. **Final score** = **0.7 × nameScore + 0.3 × (same category ? 1 : 0)**, kept between 0 and 1.
7. Sort by score in descending order and return the top results.

**Table 21. Synonym Groups**

| Common keyword | Words treated as the same |
|---|---|
| phone | mobile, cellphone, cell, smartphone, telephone, iphone, android |
| tablet | ipad, tab |
| laptop | macbook |
| earphone | earbud, headphone, headset, airpod |
| wallet | purse, billfold |
| key | keychain, keyring |
| bag | backpack, handbag, knapsack |
| bottle | tumbler, flask |
| glasses | eyeglass(es), spectacle(s) |

**Worked examples** (calculated from the code, not from user testing):

| Lost report | Found report | Result |
|---|---|---|
| "Black Mobile Phone" (Electronics) | "iPhone 13" (Electronics) | Keywords {phone} and {phone}, same set → 0.95. Score = 0.7×0.95 + 0.3 = **0.965** |
| "Leather Wallet" (Wallet) | "Wallet" (Wallet) | {leather, wallet} contains {wallet} → 0.85. Score = 0.595 + 0.3 = **0.895** |
| "Phone" (Electronics) | "Phone Charger" (Electronics) | Accessory words differ → **not matched** |
| "Room 13 Key" (Keys) | "iPhone 13" (Electronics) | No shared keyword (numbers removed) → **not matched** |

### 4.5.2 Offline Queue and Conflict Handling

- Every write goes to the **local database first**, with `pendingCreate`, `pendingUpdate` or `pendingDelete` set to true, and then the app attempts an immediate push.
- **Conflict rule:** when server data arrives, a local row that still has a pending change is **kept**, so local edits are never overwritten before they are uploaded. Other rows are replaced with the server version.
- **Duplicate prevention:** items and messages keep their device-generated IDs. `sendMessageWithId` checks inside a transaction whether the message already exists before writing it.
- **Privacy on shared devices:** an item that has not been synced yet is visible only to its author. When a user logs out, that account's synced private cache is cleared.

### 4.5.3 Return Completion and Cleanup (`ClaimService.updateClaimStatus`)

The order matters because of the Security Rules:
1. Notify the claimant while the claim still exists.
2. Set the claim to **Approved**. The delete rule allows deletion only of Approved claims.
3. Write `completedReturns/{claimId}`. The rule checks that the claim is Approved.
4. Delete all messages in batches of 450 (Firestore allows at most 500 operations per batch), then delete the conversation, the item and the claim in one final batch.

### 4.5.4 Sample Code

Short code excerpts are in **Appendix F**.

---

## 4.6 System Testing

The project contains these kinds of testing:

1. **Automated unit tests (Flutter).** `test/data/local/app_database_test.dart` runs the Drift database in memory and tests the offline behavior. `test/celebration_test.dart` is a widget test.
2. **Automated Security Rules tests.** `firestore_rules_test/rules.test.mjs` uses `@firebase/rules-unit-testing` with the Firestore Emulator. **These tests have not been run and recorded yet.** Run them with `npm test` inside `firestore_rules_test/` and paste the output into Table 22.
3. **Functional (manual) testing.** [[Describe how you tested the app by hand: who tested, on which devices, and on which dates.]]
4. **User evaluation.** [[Only if you did one. Otherwise state that none was done.]]

---

## 4.7 Test Cases and Results

### 4.7.1 Automated Test Results

**Table 22. Automated Test Results**

| Suite | Test | Result |
|---|---|---|
| Local DB: items | A newly reported item can be queried immediately | Passed |
| | Updating an item sets `pendingUpdate` without touching other fields | Passed |
| | Deleting an unsynced (`pendingCreate`) item removes it completely | Passed |
| | A synced item marked `pendingDelete` is hidden from visible queries | Passed |
| | `pendingItemOps` returns only rows with an outstanding change | Passed |
| Local DB: cross-account | A not-yet-synced item is visible only to its own author | Passed |
| | Once synced, the item becomes visible to everyone | Passed |
| Local DB: server sync | Server data overwrites a row with no pending local change | Passed |
| | Server data does not overwrite a row with a pending local edit | Passed |
| | A row removed from the server disappears locally once synced | Passed |
| | A row with a pending create or delete is not removed by a server sync | Passed |
| Local DB: messages | Re-syncing the same message ID does not create a duplicate | Passed |
| | A pending (unsynced) message is not overwritten by a server sync | Passed |
| | `markMessageSynced` clears the pending flag | Passed |
| Local DB: claims | A claim submitted offline can be queried by the item owner | Passed |
| | `markClaimSynced` clears the pending flag | Passed |
| Local DB: read status | Marking a notification read locally is optimistic and reversible | Passed |
| | Marking a conversation read locally sets the unread count to zero | Passed |
| Local DB: logout | Logging out clears that account's synced conversations and notifications | Passed |
| | Logging out never deletes an unsynced (pending) claim | Passed |
| Widget | Celebration animation shows from a popped route's navigator | Passed |
| **Total** | **21 tests** | **21 passed, 0 failed.** Run with `flutter test` on October 18, 2026, on the code in commit `6b4124c`. |
| Firestore rules | Access gate, items, claims, conversations, notifications, bans, users, termsAcceptances | [[NOT YET RUN — paste the results]] |

### 4.7.2 Functional Test Cases

**Table 23. Functional Test Cases.** The *Expected Result* column comes from the code. Fill in *Actual Result* and *Status* from your own testing. **Do not mark a test Passed unless you actually ran it.**

| TC | Requirement | Test steps | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| TC-01 | FR-01 | Register with an empty field | "Please fill in all fields." | [[ ]] | [[ ]] |
| TC-02 | FR-01 | Register with passwords that do not match | "Passwords do not match." | [[ ]] | [[ ]] |
| TC-03 | FR-01 | Register with an email that is already used | "This email is already registered." | [[ ]] | [[ ]] |
| TC-04 | FR-02, FR-06 | Register and then try to enter the app before verifying | The Verify Email screen is shown | [[ ]] | [[ ]] |
| TC-05 | FR-05 | Verify the email, then choose Decline on the Terms | The user is signed out and returned to Login | [[ ]] | [[ ]] |
| TC-06 | FR-05, FR-06 | Accept the Terms | The main app opens | [[ ]] | [[ ]] |
| TC-07 | FR-03 | Log in with a wrong password | "Invalid email or password." | [[ ]] | [[ ]] |
| TC-08 | FR-03 | Forgot Password with a valid email | A reset email is sent | [[ ]] | [[ ]] |
| TC-09 | FR-07, FR-08 | Submit a Found report with no photo | A photo error is shown; the form scrolls to the photo section | [[ ]] | [[ ]] |
| TC-10 | FR-08 | Submit a Found report with no verification question | A verification-question error is shown | [[ ]] | [[ ]] |
| TC-11 | FR-07 | Submit a Lost report with no photo | The post is created | [[ ]] | [[ ]] |
| TC-12 | FR-07 | Try to add a 6th photo | "You can add up to 5 photos." | [[ ]] | [[ ]] |
| TC-13 | FR-09 | Report Lost "Mobile Phone" while a Found "iPhone 13" exists | The Possible Matches screen lists it | [[ ]] | [[ ]] |
| TC-14 | FR-09 | Report Lost "Phone" while only a Found "Phone Charger" exists | No match is shown | [[ ]] | [[ ]] |
| TC-15 | FR-10 | Search "wallet"; filter Found; select category Keys | The list is filtered correctly | [[ ]] | [[ ]] |
| TC-16 | FR-12 | Claim a Found item and answer the question | "Request Submitted"; the finder receives a notification and a chat message | [[ ]] | [[ ]] |
| TC-17 | FR-12 | Try to claim your own item | Not allowed | [[ ]] | [[ ]] |
| TC-18 | FR-12 | Claim the same item a second time while the claim is Pending | "You already submitted a claim for this item." | [[ ]] | [[ ]] |
| TC-19 | FR-13 | The finder rejects the claim | The claimant is notified; the Resend Claim button is available | [[ ]] | [[ ]] |
| TC-20 | FR-13, FR-14 | The finder accepts the claim | Confetti and feedback form; the item, chat and claim disappear for both users | [[ ]] | [[ ]] |
| TC-21 | FR-18 | Submit feedback twice for the same return | The second attempt is blocked | [[ ]] | [[ ]] |
| TC-22 | FR-15 | Send a message | Appears for both users; the recipient's unread count increases | [[ ]] | [[ ]] |
| TC-23 | FR-16 | Post a Found item similar to another user's Lost item in the same category | The Lost owner receives "Possible Match Found" | [[ ]] | [[ ]] |
| TC-24 | FR-16 | Tap "Mark all as read" | The badge clears | [[ ]] | [[ ]] |
| TC-25 | FR-17 | Delete your own post | Confirmation, then the post is removed | [[ ]] | [[ ]] |
| TC-26 | FR-19 | Turn on airplane mode → report an item → turn airplane mode off | The post is shown as pending, then syncs; "Report Posted" notification | [[ ]] | [[ ]] |
| TC-27 | FR-19 | Send a message offline → reconnect | The message is delivered exactly once | [[ ]] | [[ ]] |
| TC-28 | NFR-04 | Log out of account A and log in as B on the same phone | B cannot see A's chats or notifications | [[ ]] | [[ ]] |
| TC-29 | FR-11 | Open a post that has several photos and tap a photo | All photos are viewable in the full-screen viewer | [[ ]] | [[ ]] |
| TC-30 | FR-04 | Log out, then reopen the Login screen | The previous account appears as a quick-pick tile and can be removed; no password is pre-filled | [[ ]] | [[ ]] |

---

## 4.8 Performance Evaluation *(conditional)*

> **No performance or usability data exists in the project.** Choose one option:
> - **(a)** If you conducted an evaluation (for example ISO/IEC 25010 or SUS), describe the instrument, the respondents (number and type), the dates, the scoring scale, and the results table with means and interpretation.
> - **(b)** If you did not, **delete this section** and add this to the Scope and Limitations: *"Formal performance and usability evaluation was not conducted in this study."*

[[ ]]

---

## 4.9 Security and Data-Privacy Measures

**Table 24. Security Measures**

| # | Measure | Where it is enforced |
|---|---|---|
| 1 | Email verification required | Firebase Auth ID token + `hasAccess()` rule; Verify Email screen |
| 2 | Terms of Service acceptance required and recorded | `termsAcceptances` (create-only) + `hasAccess()` |
| 3 | Only the owner can create, change or delete a post; ownership cannot be transferred | `items` rules |
| 4 | Claim answers are visible only to the claimant and the finder | `claims` read rules |
| 5 | Each party can change only specific claim fields | `affectedKeys().hasOnly(...)` in the rules |
| 6 | Chats are private to their two participants; message content cannot be edited | `conversations` and `messages` rules |
| 7 | Clients cannot fake moderation notices | Notification type allow-list |
| 8 | Audit records cannot be changed | Create-only `termsAcceptances`, `completedReturns`, `feedback` |
| 9 | Deny by default | `match /{document=**} { allow read, write: if false; }` |
| 10 | Data minimization after a return | Item, claim, chat and messages are deleted on approval |
| 11 | No passwords stored on the device | `RememberedAccount` stores only uid, email, name, photo URL and time |
| 12 | Cache separation on shared devices | `viewerId` column; cache cleared on logout; unsynced items visible only to their author |
| 13 | Encrypted transport | All Firebase and Cloudinary traffic uses HTTPS |

**Known risks** (honest limitations found during the code audit):
1. **Notification spoofing.** A verified user can create an allowed-type notification for any recipient. The rules do not check that a matching claim or item exists.
2. **Business logic runs on the client.** Match notifications and the return cleanup run on the user's phone. If the app is closed in the middle of a cleanup, some data may remain.
3. **Unsigned image uploads.** The Cloudinary upload preset is part of the app. Photo URLs are public to anyone who has the link, and photos are **not deleted** when a post is deleted.
4. **Chat permissions.** Any participant can delete any message in their conversation. The display names stored in a conversation are supplied by the client and are not checked.
5. **Personal data.** Names, emails (in Terms records), posts, claims and messages are stored in Firestore. [[If required: state compliance with RA 10173 (Data Privacy Act of 2012) and how consent is obtained — the in-app Terms, Section 8.]]

---

## 4.10 Discussion of Findings

> **DRAFT.** Update this section after you add your functional-test and evaluation results. The table currently cites only evidence that exists.

**Table 25. Objectives and Evidence**

| Specific objective (draft numbering, §1.3) | Evidence | Finding |
|---|---|---|
| 1. Reporting module | Module 3; TC-09 to TC-12 | Implemented. Test results: [[ ]] |
| 2. Searchable feed | Module 5; TC-15 | Implemented. Test results: [[ ]] |
| 3. Matching method | Module 4; §4.5.1 examples; TC-13, TC-14, TC-23 | Implemented. Limited to keyword matching of names. Test results: [[ ]] |
| 4. Verified claim process | Module 6; rules; TC-16 to TC-20 | Implemented. Test results: [[ ]] |
| 5. Messaging and notifications | Modules 7–8; TC-22 to TC-24 | Implemented (in-app only). Test results: [[ ]] |
| 6. Offline support | Module 11; **20 automated database tests passed**; TC-26 to TC-28 | Implemented. The automated evidence supports the offline logic. Device test results: [[ ]] |
| 7. Security | Rules; Table 24; rules test suite | Implemented. Rules tests: [[run and report]] |
| 8. Evaluation (if any) | §4.8 | [[ ]] |

**Discussion.** [[Write 2–4 paragraphs: what worked well, what problems you met during development (for example, Firestore permission errors when starting new chats, which led to the deterministic conversation IDs), how the results answer each research question, and how the limitations affect the results.]]
