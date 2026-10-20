# Chapter 1 — Introduction

> Text inside `[[ ... ]]` needs your input. Sections marked **DRAFT** contain suggested wording. **Replace it with the wording your adviser approved.** No statistics or campus facts were invented. Every fact you add must have a source.

---

## 1.1 Background of the Study

Losing personal belongings is a common problem in schools and universities. Students and staff move between classrooms, laboratories, the library, the cafeteria and the gymnasium every day, and small items such as phones, wallets, identification cards, keys and books are easily left behind. When an item is lost, the owner and the person who finds it usually have no direct way to contact each other.

[[DESCRIBE THE CURRENT PROCESS ON YOUR CAMPUS. For example: "At [[CAMPUS]], found items are usually surrendered to [[OFFICE]] and recorded in a logbook," or "Students post about lost items in Facebook groups." State the source of each fact (interview, observation, or document) and cite it.]]

These informal methods have weaknesses. [[STATE ONLY WEAKNESSES THAT YOU OBSERVED OR THAT YOUR SOURCES DOCUMENTED. For example: posts are buried in busy social-media feeds, a logbook can only be checked in person, and there is no reliable way to prove ownership before an item is handed over.]]

Mobile devices are widely used by students, so a dedicated mobile application can give the campus a single, organized place to report lost and found items. This project developed **LOFO (Campus Lost & Found)**, an Android application built with Flutter and Google Firebase. In LOFO, users post lost or found items with photos, receive suggestions of possible matches, claim found items by answering a private verification question set by the finder, and talk to each other inside the app until the item is returned. The application also works when the internet connection is weak or unavailable: reports, claims and messages are saved on the phone first and sent to the cloud when the connection returns.

---

## 1.2 Statement of the Problem

> **DRAFT. Replace this with your approved wording.**

**General Problem:**
[[APPROVED GENERAL PROBLEM]]
*Suggested:* How can a mobile application help members of [[CAMPUS NAME]] report, match, verify and return lost and found items more efficiently and securely?

**Specific Problems:**
[[APPROVED SPECIFIC PROBLEMS]]
*Suggested (each one corresponds to a feature that actually exists):*

1. How can lost and found items be reported and viewed in one central place that is accessible from a mobile phone?
2. How can the system help users find possible matches between lost items and found items?
3. How can a finder confirm that a claimant is the real owner before returning an item?
4. How can owners and finders communicate privately and receive timely updates about their reports and claims?
5. How can the application stay usable when the internet connection is unstable?
6. How can user accounts and personal data be protected from unauthorized access?

---

## 1.3 Objectives of the Project

> **DRAFT. Replace this with your approved wording.** Each suggested objective lists the module in Chapter 4 that satisfies it, so that the objectives and the system agree.

### General Objective

[[APPROVED GENERAL OBJECTIVE]]
*Suggested:* To develop LOFO, an Android mobile application that helps members of [[CAMPUS NAME]] report, match, verify and return lost and found items.

### Specific Objectives

[[APPROVED SPECIFIC OBJECTIVES]]
*Suggested:*

1. To develop a reporting module that lets users post lost or found items with item name, category, location, date, description and up to five photos. *(Module: Item Reporting)*
2. To provide a searchable and filterable feed of lost and found items. *(Module: Home / Search)*
3. To implement a keyword-based matching method that suggests possible matches between lost and found reports before and after posting. *(Module: Item Matching)*
4. To implement a claim process in which the claimant answers a finder-defined verification question and the finder approves or rejects the claim. *(Module: Claims and Verification)*
5. To provide private one-to-one messaging and in-app notifications for claims and possible matches. *(Modules: Messaging; Notifications)*
6. To support offline use by saving reports, claims and messages locally and syncing them automatically when the device reconnects. *(Module: Offline Sync)*
7. To secure the system through email verification, Terms of Service acceptance and server-side Firestore Security Rules. *(Module: Authentication and Access Gate)*
8. [[OPTIONAL — only if you performed an evaluation:]] To evaluate the application in terms of [[functionality / usability / ...]] using [[instrument]].

---

## 1.4 Scope and Limitations

### Scope

The project covers an Android mobile application for the community of [[CAMPUS NAME]]. It includes the following features, all of which are **implemented** in the current version:

1. **Account management.** Users register with full name, email and password. They must verify their email before they can use the app. The app also provides login, password reset by email, logout, and a list of accounts previously used on the device for quick sign-in (no passwords are saved).
2. **Terms of Service.** Users must accept the Terms of Service and User Agreement (version 1.0) before entering the app. Each acceptance is recorded.
3. **Item reporting.** Users post Lost or Found items with name, one of six categories (Electronics, Wallet, ID, Keys, Books, Others), one of seven locations (Library, Classroom, Laboratory, Cafeteria, Gymnasium, Main Building, Other), date, description and up to five photos. Photos are required for Found items and optional for Lost items. Found items also require a verification question.
4. **Item matching.** Before a report is submitted, the app shows possible matches of the opposite type. Users can also check matches for their existing posts. When a Found item is posted, users who previously posted a similar Lost item in the same category receive a "Possible Match Found" notification.
5. **Browsing.** The Home feed shows other users' posts. Users can search by name, category or location, and filter by type (Lost/Found) and by category.
6. **Claiming.** A user may submit one claim for each Found item by answering the verification question. The finder approves or rejects the claim. A rejected claim can be sent again. When a claim is approved, the item, the claim, the conversation and its messages are deleted, and a minimal record of the completed return is kept.
7. **Messaging.** Users chat one-to-one about a specific post, and the app counts unread messages.
8. **Notifications.** Users receive in-app notifications when a claim is received, resent, approved or rejected, when a possible match is found, and when an offline report has finished posting. Users can mark notifications as read.
9. **My Posts.** Users view, filter and delete their own posts, and can check matches for each post.
10. **Post-return feedback.** After a return, the finder and the claimant can each give an optional 1–5 rating and a short recommendation.
11. **Offline support.** The app saves data in a local database. Reports, deletions, claims, messages and "mark as read" actions made offline are sent automatically when the device reconnects.

### Limitations

1. **Platform.** The app is configured and built for **Android only**. iOS and web are not configured.
2. **User roles.** There is **only one user type**. The app has no administrator account, admin dashboard or campus-office interface.
3. **Notifications** appear **only inside the app**. Push notifications (for example, Firebase Cloud Messaging) are not implemented, and new chat messages raise an unread count but do not create a notification.
4. **Matching** compares item **names** using English keywords and a fixed list of synonyms, with a bonus for the same category. It does not compare photos, descriptions, locations or dates.
5. **Editing posts** is not available. The Edit option in My Posts shows "will be implemented later".
6. **Profile settings** (Edit Profile, Personal Information, Change Password, Notification Settings, Help & Support) show a "coming soon" message. Users can reset a forgotten password from the login screen.
7. **Content reporting and moderation.** Firestore rules for reporting posts and for temporary posting bans exist, and the Terms of Service describe them. However, the app has **no screen for reporting posts** and **no moderation component** in this project. These are **planned features**.
8. **New conversations** need an internet connection. Messages in an existing conversation can be sent while offline.
9. **History after a return.** After a claim is approved, the item, the claim and the conversation are permanently deleted for privacy. Only a minimal completed-return record remains, so the app does not keep a full history of returns.
10. The app helps users **find each other**. It **does not handle the physical hand-over** of items. Users arrange the meeting themselves.

---

## 1.5 Significance of the Project

> **DRAFT. Adjust the beneficiaries to match your approved list.** [[CONFIRM BENEFICIARIES]]

- **Students and other campus members who lose items** get one place to report their losses. They are notified automatically when a similar found item is posted.
- **Finders** have a simple way to post found items and can confirm ownership through a private verification question before returning an item.
- **[[CAMPUS OFFICE, e.g., Office of Student Affairs / Security Office]]** *(only if they are a real beneficiary)* could use the app's records and approach to support or reduce its manual lost-and-found work.
- **Future researchers** can use this project as a reference for offline-first mobile applications, client-side matching, and data protection with Firebase Security Rules.
- **The researchers** gained practical experience in mobile development, cloud databases, security rules and software testing.

---

## 1.6 Definition of Terms

Terms are defined as they are used in this project.

| Term | Definition |
|---|---|
| **Access Gate** | The part of LOFO that decides whether a signed-in user may enter the main app. Entry requires a verified email and acceptance of the current Terms of Service. |
| **Claim** | A request by a user to recover a Found item. It includes the user's answer to the verification question and optional details. Its status is Pending, Approved or Rejected. |
| **Claimant** | The user who submits a claim for a Found item. |
| **Cloud Firestore** | Google Firebase's cloud NoSQL database. LOFO stores its shared data there as documents grouped into collections. |
| **Cloudinary** | A cloud image-hosting service. LOFO uploads item photos to it. |
| **Completed Return** | A minimal record saved when a finder approves a claim. It proves that a return took place and allows both users to leave feedback. |
| **Drift** | A Dart library for working with an SQLite database on the phone. LOFO uses it for its local database. |
| **Email Verification** | Confirming that a user owns their email address by clicking a link sent to it. |
| **Finder** | The user who posted a Found item. The finder sets the verification question and decides on claims. |
| **Firebase Authentication** | The Firebase service that manages user accounts, logins, email verification and password resets. |
| **Firestore Security Rules** | Server-side rules that decide which user may read or write each document in Cloud Firestore. |
| **Flutter** | Google's framework for building mobile apps from a single Dart codebase. |
| **Item Matching** | The process of finding possible pairs between Lost and Found reports by comparing keywords in item names, with a bonus for the same category. |
| **Lost Report / Found Report** | A post describing an item that the user lost, or an item that the user found. |
| **Offline-first** | A design in which the app reads from and writes to a local database first and syncs with the cloud when a connection is available. |
| **Provider** | A Flutter state-management package. LOFO uses it to share data between screens. |
| **Sync (Synchronization)** | Sending locally saved changes to the cloud and receiving the latest cloud data. |
| **Terms of Service (ToS)** | The user agreement that users must accept before using LOFO. The current version is 1.0. |
| **Verification Question** | A question written by the finder that only the real owner should be able to answer, for example "What is the lock-screen wallpaper?" |
| [[ADD ANY TERMS YOUR ADVISER REQUIRES]] | |
