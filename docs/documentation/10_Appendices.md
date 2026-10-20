# Appendices

> Appendices marked **conditional** should be kept only if the material exists. Appendix D (Requirements Specification) was **omitted on purpose** because Chapter 3.3 already covers it, as agreed in the outline.

---

## Appendix A — Project Timeline (Gantt Chart)

> **Your input is needed.** The git history shows development work only from **Oct 2 to Oct 18, 2026**. Replace the placeholder dates below with your real schedule.

```mermaid
gantt
    title LOFO Project Timeline
    dateFormat  YYYY-MM-DD
    section Planning
    Proposal and title approval     :a1, [[YYYY-MM-DD]], [[N]]d
    section Analysis and Design
    Requirements and design         :a2, [[YYYY-MM-DD]], [[N]]d
    section Development
    Core app (initial commit → matching) :d1, 2026-10-02, 3d
    UI improvements                 :d2, 2026-10-05, 9d
    Verification, ToS, photos, feedback :d3, 2026-10-14, 4d
    UI refinements (backup commit)  :d4, 2026-10-18, 1d
    section Testing
    Testing                         :t1, [[YYYY-MM-DD]], [[N]]d
    section Documentation
    Documentation                   :doc, [[YYYY-MM-DD]], [[N]]d
```

> The bars for 2026-10-05 to 2026-10-18 are an **estimate** based on commit dates. Correct them using your own records.

---

## Appendix B — Budget *(conditional)*

> Keep this appendix only if your adviser requires it. The project uses Firebase and Cloudinary. Whether you stayed within the free tiers must be confirmed from your own billing pages.

| Item | Quantity | Unit cost | Total |
|---|---|---|---|
| [[Development computer]] | | | |
| [[Test phone]] | | | |
| [[Internet]] | | | |
| Firebase (Auth, Firestore) | | [[free tier? confirm]] | |
| Cloudinary | | [[free tier? confirm]] | |
| **Total** | | | |

---

## Appendix C — Survey or Interview Questions *(conditional)*

[[Attach only if you used them.]]

---

## Appendix E — Test Cases

The full functional test-case table is **Table 23 in Section 4.7.2**, and the automated test results are in **Table 22**. Attach here any extra evidence, such as screenshots of test runs and the console output of `flutter test` and of the Firestore rules tests.

**Recorded output (October 18, 2026, `flutter test`):**
```
00:00 +21: All tests passed!
```

---

## Appendix F — Sample Source Code

The excerpts below are copied from the project. **No configuration values or keys are included.**

### F.1 Matching score (`lib/services/item_matching_service.dart`)

```dart
// 1) The item names must share at least one keyword.
final candidateTokens = _keywords(candidate.title);
final shared = draftTokens.intersection(candidateTokens);
if (shared.isEmpty) continue;

// 2) Accessory guard: "phone" must not match "phone charger".
final draftAccessories = draftTokens.intersection(_accessoryWords);
final candidateAccessories = candidateTokens.intersection(_accessoryWords);
if (draftAccessories.length != candidateAccessories.length ||
    !draftAccessories.containsAll(candidateAccessories)) {
  continue;
}

final sameCategory = draftCategory.isNotEmpty &&
    _normalize(candidate.category) == draftCategory;

final nameScore = _nameSimilarity(
  draftName, _normalize(candidate.title), draftTokens, candidateTokens);

// Name is the main signal; same category is a bonus.
final score = (0.7 * nameScore) + (sameCategory ? 0.3 : 0.0);
```

### F.2 Access gate in the Security Rules (`firestore.rules`)

```javascript
function isVerified() {
  return request.auth != null
    && request.auth.token.email_verified == true;
}

function hasAcceptedTerms() {
  return exists(
    /databases/$(database)/documents/termsAcceptances/$(
      request.auth.uid + '_' + requiredTermsVersion()
    )
  );
}

function hasAccess() {
  return isVerified() && hasAcceptedTerms();
}
```

### F.3 One claim per user per item (`firestore.rules`)

```javascript
allow create: if hasAccess()
  && claimId == request.resource.data.itemId + '_' + request.auth.uid
  && request.resource.data.claimantId == request.auth.uid
  && request.resource.data.ownerId != request.auth.uid
  && request.resource.data.status == 'Pending'
  && get(/databases/$(database)/documents/items/$(request.resource.data.itemId))
       .data.status in ['Found', 'Pending'];
```

### F.4 Sync pass (`lib/data/sync/sync_manager.dart`)

```dart
Future<void> syncNow() async {
  if (_isSyncing) return;
  final uid = _currentUserId;
  if (uid == null) return;

  _isSyncing = true;
  try {
    final online = await connectivity.checkNow();
    if (!online) return;

    await itemRepository.pushPending(uid);
    await claimRepository.pushPending(uid);
    await chatRepository.pushPending(uid);
    await notificationRepository.pushPending(uid);
  } catch (_) {
    // Swallowed - we'll retry on the next connectivity change / timer.
  } finally {
    _isSyncing = false;
    await _scheduleRetryIfNeeded();
  }
}
```

---

## Appendix G — User Manual

### G.1 Getting Started
1. **Install** the LOFO APK (see Appendix H) and open the app.
2. **Register.** On the Login screen, tap **Register**. Enter your Full Name, University Email, Password and Confirm Password, then tap **Create Account**.
3. **Verify your email.** Open the link sent to your inbox, return to the app, and tap **I've Verified My Email**. If you did not receive the email, use the resend option.
4. **Accept the Terms.** Read the Terms of Service and tap **I Accept**. Tapping **Decline** signs you out.
5. **Logging in later.** Your account appears on the Login screen for quick selection. Tap **Forgot Password?** to receive a reset email.

### G.2 Reporting an Item
1. On **Home**, tap the report button.
2. Choose **Lost** or **Found**.
3. Add photos (up to 5). Photos are **required for Found** items.
4. Enter the item name, then choose the category and the location, set the date, and write a description.
5. **Found items:** write a **verification question** that only the real owner can answer (for example, "What is the lock-screen wallpaper?").
6. Submit. If similar posts exist, LOFO shows **Possible Matches**. Open them to check, or continue posting.
7. If you are offline, your post is saved and sent automatically when you reconnect. You will receive a **Report Posted** notification.

### G.3 Finding Items
- Use the **search bar** (item name, category or location), the **Lost/Found** filter, and the **category cards**. Tap **Clear filters** to reset.
- Tap a post to see all photos and details. Tap a photo to view it full screen.

### G.4 Claiming a Found Item (Owner)
1. Open the Found post and tap **Claim**.
2. Answer the verification question and add helpful details (for example, where and when you lost it). Submit.
3. Follow the conversation in **Messages**. You will be notified when the finder approves or rejects your claim.
4. If your claim is rejected, you may tap **Resend Claim** and give better details.

### G.5 Handling Claims (Finder)
1. Open the **Claim Request Received** notification, or open the conversation in **Messages**.
2. Read the claimant's answer in the claim panel.
3. Tap **Accept Claim** if the answer proves ownership, or **Reject** if it does not.
4. After you accept, arrange the hand-over with the claimant. The post, the claim and the chat are then removed for privacy.

### G.6 Messages, Notifications, My Posts, Feedback
- **Messages:** your chats, newest first. Unread chats show a count.
- **Notifications:** tap one to open the related item or chat. Use **Mark all as read** to clear the badge.
- **My Posts:** filter your posts, delete one (⋮ → Delete), or tap **Check Matches**.
- **Feedback:** after a completed return, rate the experience from 1 to 5 stars and leave an optional recommendation. Feedback can be submitted only once.

### G.7 Logging Out
Open **Profile** → **Log Out** → confirm.

---

## Appendix H — Installation and Deployment Guide

### H.1 Installing the App (end user)
1. Copy the APK file to the Android phone: [[how you distribute it]].
2. Allow installation from this source when Android asks.
3. Open the APK and tap **Install**.

### H.2 Developer Setup
> Values in `<ANGLE_BRACKETS>` are placeholders. **Never commit or publish real keys.**

1. Install the Flutter SDK, Android Studio (with the Android SDK), Git, Node.js, Java (JDK) and the Firebase CLI.
2. Get the source code and install the dependencies:
   ```bash
   flutter pub get
   ```
3. Generate the Drift database code (only needed after the tables change):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Firebase:**
   - Create a Firebase project and enable **Authentication → Email/Password** and **Cloud Firestore**.
   - Connect the Android app (for example with `flutterfire configure`). This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
   - Deploy the rules and indexes:
     ```bash
     firebase deploy --only firestore:rules,firestore:indexes
     ```
5. **Cloudinary:** create an *unsigned upload preset* and put `<CLOUD_NAME>` and `<UPLOAD_PRESET>` into `lib/services/cloudinary_service.dart`.
6. Run the app on a device or emulator:
   ```bash
   flutter run
   ```
7. Build a release APK:
   ```bash
   flutter build apk --release
   ```
   > Before a real release, change the default application ID `com.example.lost_and_found_app` and set up app signing.

### H.3 Running the Tests
```bash
flutter test
```
Firestore rules tests (requires Java and the Firebase CLI):
```bash
cd firestore_rules_test
npm install
npm test
```

---

## Appendix I — Screenshots

[[Insert the screenshots from `docs/documentation/screenshots/`, or refer to Section 4.3.]]

---

## Appendix J — Letters and Permissions *(conditional)*

[[Attach only if applicable.]]

## Appendix K — Data-Privacy Consent Form *(conditional)*

[[Attach only if you collected data from respondents.]] The in-app **Terms of Service and User Agreement v1.0** (`lib/services/terms_service.dart`) can be attached as the user agreement that app users accept.

## Appendix L — Researchers' Profiles

[[Name, photo, contact (optional), education, skills, and role in the project, for each researcher.]]

---

## Appendix M — Source-Code Structure

| Folder | Contents |
|---|---|
| `lib/models` | Data classes and Firestore mapping |
| `lib/services` | Firebase, Cloudinary and Terms access; matching algorithm; feedback |
| `lib/data/local` | Drift database, table definitions, connectivity service |
| `lib/data/repositories` | Offline-first repositories (items, claims, chat, notifications) |
| `lib/data/sync` | `SyncManager` |
| `lib/providers` | State management for the screens |
| `lib/screens` | 19 screens |
| `lib/widgets` | Reusable widgets |
| `lib/theme` | Colors and theme |
| `test/` | Flutter unit and widget tests |
| `firestore_rules_test/` | Firestore Security Rules tests (Node.js, emulator) |
| `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json` | Firebase configuration (`storage.rules` is currently unused) |

---

## Appendix N — Maintenance and Troubleshooting Guide

| Task / Problem | What to do |
|---|---|
| Change the Terms of Service text | Edit `TermsService.sections`. If users must accept again, change **both** `TermsService.currentVersion` and `requiredTermsVersion()` in `firestore.rules`, then deploy the rules. |
| Change Firestore rules or indexes | Edit the file, run the rules tests, then run `firebase deploy --only firestore:rules,firestore:indexes`. |
| "PERMISSION_DENIED" right after verifying the email | The ID token is refreshed automatically on "I've Verified My Email". If the error remains, log out and log in again. |
| A new query fails with a "requires an index" error | Add the index from the error link to `firestore.indexes.json` and deploy it. |
| A post stays "pending" | Check the internet connection. The app retries every 30 seconds while online and immediately when the connection returns. |
| Photo upload fails | Check the Cloudinary upload preset (unsigned) and the network connection. Photos larger than Cloudinary's limit may be rejected. |
| Database tables changed | Re-run `build_runner` and plan a Drift schema migration. |
| Add matching synonyms | Edit `_synonyms` in `item_matching_service.dart` (keys must be lowercase and singular). |

---

## Appendix O — Version History *(optional)*

| Date | Version / Commit | Changes |
|---|---|---|
| 2026-10-02 | Initial commit | Project created |
| 2026-10-04 | Rules fix | Firestore rules corrected |
| 2026-10-04 | Matching | Name/category matching on submit, Check Matches, match notifications, notification linking |
| 2026-10-04 | Resend claim | Resend button for rejected claims |
| 2026-10-13 | UI | User-interface improvements |
| 2026-10-17 | Backup | Snapshot before new features |
| 2026-10-17 | Features | Registration verification, user agreement, multiple photos, Lost posts without a photo, notification badge, mark notifications as read, celebration animation, user feedback |
| 2026-10-18 | Backup (`6b4124c`) | UI refinements, shared feedback widgets, theme updates — **the version documented** |
