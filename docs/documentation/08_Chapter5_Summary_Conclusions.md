# Chapter 5 — Summary, Conclusions, and Recommendations

> **DRAFT.** The conclusions must answer **your approved** objectives (§1.3) and must be supported by the evidence in Chapter 4. Where test or evaluation results are still missing, the conclusion is left conditional with `[[ ]]`.

---

## 5.1 Summary of the Project

This project developed **LOFO (Campus Lost & Found)**, an Android mobile application for [[CAMPUS NAME]] that helps users report, match, verify and return lost and found items. The application was built with Flutter and Dart. It uses Firebase Authentication for accounts, Cloud Firestore for shared data, Cloudinary for photos, and a local Drift (SQLite) database for offline use. Development followed the [[METHODOLOGY]] methodology from [[START DATE]] to [[END DATE]].

The completed system provides:
- registration with email verification, a recorded Terms of Service agreement, and an access gate enforced on the server;
- Lost and Found reporting with up to five photos and a finder-defined verification question;
- keyword-based match suggestions before posting, on demand, and through notifications;
- a private claim workflow in which the finder approves or rejects claims, and approved returns are recorded and their data removed;
- one-to-one messaging, in-app notifications and optional post-return feedback;
- offline-first storage with automatic synchronization.

Testing so far includes 21 automated tests, all of which passed (offline database logic and one widget test). [[ADD THE RESULTS OF THE RULES TESTS, FUNCTIONAL TESTS AND EVALUATION]].

---

## 5.2 Conclusions

> Write one conclusion per specific objective. Suggested wording is given below; keep only what your evidence supports.

1. **Reporting.** The researchers developed a reporting module that collects the essential details of lost and found items with photos. [[Supported by TC-09 to TC-12 results.]]
2. **Browsing.** The searchable and filterable feed lets users find relevant posts by name, category, location and type. [[TC-15]]
3. **Matching.** The keyword-based matching method, with synonym handling, an accessory guard and category weighting, suggested relevant opposite-type reports in the cases tested. [[TC-13, TC-14, TC-23]] Its accuracy is limited because it compares only item names.
4. **Verified claiming.** The verification-question workflow gives finders a structured way to confirm ownership before an item is returned. The Security Rules keep claim answers private to the two users. [[TC-16 to TC-20; rules tests]]
5. **Communication.** Private messaging and in-app notifications kept the claimant and the finder informed. [[TC-22 to TC-24]]
6. **Offline support.** The offline-first design keeps reports, claims and messages when there is no connection and syncs them later. Twenty automated database tests confirm the queueing, conflict and duplicate-prevention logic. [[TC-26 to TC-28]]
7. **Security.** Requiring a verified email and acceptance of the Terms, together with ownership-based Security Rules, limits data access to authorized users. [[Rules test results]]
8. [[Evaluation conclusion, only if §4.8 exists.]]

---

## 5.3 Recommendations

These recommendations come from limitations found in the actual system:

1. **Move sensitive logic to the server.** Use Firebase Cloud Functions to create notifications and to run the return cleanup. This prevents notification spoofing and incomplete cleanups (see §4.9).
2. **Tighten the Security Rules.** Validate that a notification refers to a real claim or item, and restrict message deletion to the message's sender.
3. **Delete photos from Cloudinary** when a post is deleted or a return is completed, and consider signed uploads.
4. **Add pagination** to the Home feed and to the queries for match notifications, so the app stays fast as the number of posts grows.
5. **Run the Firestore rules tests** automatically before every rules deployment.
6. **Conduct a formal user evaluation** (for example ISO/IEC 25010 or SUS) with real campus users. [[Remove if you already did this.]]
7. **Coordinate with [[CAMPUS OFFICE]]** so the app can complement the existing lost-and-found process. [[Only if relevant.]]

---

## 5.4 Proposed Future Enhancements

| Enhancement | Basis in the current system |
|---|---|
| Edit an existing post | The menu option exists; it currently shows "will be implemented later" |
| Profile management: edit name and photo, change password, notification settings, help and support | The options exist on the Profile screen; they currently show "coming soon" |
| Content reporting, warnings and temporary posting bans, with a moderation back end | Already modeled in the Security Rules and described in the Terms of Service |
| Administrator or campus-office dashboard | No admin role exists yet |
| Push notifications (Firebase Cloud Messaging), including new-message alerts | Notifications are currently in-app only |
| Smarter matching: descriptions, location and date proximity, image similarity, Filipino terms | The current matching uses English item names only |
| History and statistics of returns | Only minimal `completedReturns` records are kept |
| iOS release | Only Android is configured |
| Release preparation: a unique application ID, app signing, and a project README | The app still uses the default `com.example` ID and the template README |
