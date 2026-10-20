# LOFO (Campus Lost & Found): Phase 2 Documentation Outline

**Based on:** the Phase 1 Project Audit (approved) and `docs/Computer_Science_Documentation_Parts.pdf`, which I used as a guide only.
**Status legend:**
- **Include**: the section is needed and I can write it from the source code.
- **Include + your input**: the section is needed, but part of it must come from you.
- **Conditional**: include it only if the evidence exists.
- **Omit**: the section does not fit LOFO. The reason is given.

Throughout the document, every feature is labeled **Implemented**, **Partially implemented**, or **Planned / Unverified**, using the same labels as the audit.

---

## Preliminary Pages

| Section | Status | Why it is relevant to LOFO |
|---|---|---|
| Title Page | Include + your input | This page is required. I need your approved title, your names, the course, and the date. |
| Approval Sheet | Include + your input | This page is required by the institution. Please use your department's official template. I will leave a placeholder. |
| Acknowledgment | Include + your input | This page is personal, so you should write it. I can give you a short structure to follow. |
| Abstract | Include (written last) | It summarizes the problem, the method, the system, and the results. I will write it only after the results are confirmed. |
| Table of Contents, List of Tables, List of Figures | Include | The document will contain many tables (requirements, data dictionary, test cases) and diagrams. |

## Chapter 1: Introduction

| Section | Status | Why it is relevant |
|---|---|---|
| 1.1 Background of the Study | Include + your input | This section explains the lost-and-found problem on campus. Local facts must come from you, for example how lost items are handled now (a guard office? Facebook groups?). I will not invent statistics. |
| 1.2 Statement of the Problem | Include + your input | This section must be consistent with your approved research problems and objectives. |
| 1.3 Objectives: General and Specific | Include + your input | I will match each specific objective to an implemented module (reporting, matching, claim verification, messaging, notifications, offline use, security). Please give me your approved wording. |
| 1.4 Scope and Limitations | Include | This is important for LOFO. It covers Android only, one user type with no admin, in-app notifications only (no push), keyword-based matching, and the partial or planned features from the audit (post editing, profile settings, content reporting and bans). |
| 1.5 Significance of the Project | Include + your input | This section names who benefits: students, finders, and possibly the campus office. Please tell me your intended beneficiaries. |
| 1.6 Definition of Terms | Include | The project uses many technical terms, for example Firestore, Security Rules, offline-first, sync queue, verification question, claim, finder, claimant, Cloudinary, Drift/SQLite, and email verification. |

## Chapter 2: Review of Related Literature and Systems

| Section | Status | Why / note |
|---|---|---|
| 2.1 Related Literature | Include + your input | The guide requires this chapter, but **I cannot supply sources**. You must give me the books and articles you already cited, or approve the ones you find. I will only summarize sources that you provide. |
| 2.2 Related Studies | Include + your input | The same rule applies: you provide the studies (for example, earlier lost-and-found systems from theses or journals). |
| 2.3 Related Systems or Applications | Include + your input | This section is useful because LOFO competes with informal channels and other lost-and-found apps. You must name the systems you reviewed. |
| 2.4 Comparison of Existing Systems | Include + your input | This is a feature-comparison table. I can fill in LOFO's column from the code. The other columns need your verified information. |
| 2.5 Synthesis | Include | I will write it from 2.1–2.4 after you provide them. |
| 2.6 Research or System Gap | Include | I will connect the gap to features LOFO actually has: private verification-question claims, automatic match suggestions, in-app chat tied to a post, and offline use. |
| 2.7 Conceptual Framework | Include | I will use an Input–Process–Output (IPO) diagram based on the real modules, unless your adviser wants a different model. |

## Chapter 3: Methodology and System Design

| Section | Status | Why it is relevant |
|---|---|---|
| 3.1 Software Development Methodology | Include + your input | I need the method you actually used (for example Agile, Scrum, Iterative, Prototyping, or Waterfall). The git history shows short development cycles, but that alone does not prove a method. |
| 3.2 Requirements-Gathering Methods | Conditional | Include this only if you actually conducted interviews, surveys, or observation. If you did not, I will omit it and say that the requirements came from the team's analysis. |
| 3.3 System Requirements: Functional and Nonfunctional | Include | I can derive these directly from the code and rules, for example FR-01 Register, FR-07 Report item, FR-11 Claim, and NFRs for security, offline availability, usability, and privacy. |
| 3.4 System Architecture | Include | This shows the layered offline-first client: UI → Providers → Repositories → Drift and Firebase/Cloudinary, with the SyncManager. It is central to LOFO's design. |
| 3.5 Use-Case Diagram | Include | It has **one human actor (User)**, shown in the situational roles Finder and Claimant, plus external systems (Firebase Auth, Firestore, Cloudinary). **There is no Admin actor**, because none exists in the app. |
| 3.6 Data-Flow Diagram (Context + Level 1) | Include | It shows how item, claim, message, and notification data move between the user, the app, the local store, and the cloud stores. |
| 3.7 Entity-Relationship Diagram | Include (adapted) | Firestore is a NoSQL database, so I will present a **logical ERD** of the collections and their reference fields (ownerId, itemId, claimantId, participantIds). I will state clearly that these are document references, not SQL foreign keys. |
| 3.8 Database Design (Data Dictionary) | Include | This covers every Firestore collection and every Drift table, with field, type, constraint, and description, taken from the models and rules. |
| 3.9 Class Diagram | Include (simplified) | It covers the models, services, repositories, and providers, which shows the layered structure. I will leave out the generated Drift classes. |
| 3.10 Activity and Sequence Diagrams | Include | I will make three diagrams for LOFO's most important flows: **(a)** activity for reporting an item with the match check, **(b)** sequence for claim → approve → completed return → cleanup, and **(c)** sequence for offline queueing and sync. |
| 3.11 User-Interface Design | Include + your input | This covers the screen-flow (navigation) diagram, which I can derive from the code, and the design principles used. Screenshots or wireframes come from you. |
| 3.12 Hardware and Software Requirements | Include + your input | This lists development and end-user requirements. Please tell me the Android phone(s) and Android version(s) you actually tested on. |
| 3.13 Development Tools and Technologies | Include | This is known from `pubspec.yaml` and the configuration files. |

## Chapter 4: System Development, Results, and Discussion

| Section | Status | Why it is relevant |
|---|---|---|
| 4.1 System Implementation | Include | This describes how the system was built and configured: Firebase setup, rules and index deployment, and Cloudinary upload. **No secrets will be included.** |
| 4.2 Description of System Modules | Include | It covers 10 modules: Authentication & Access Gate, Terms Agreement, Item Reporting, Matching, Home/Search, Claims & Verification, Messaging, Notifications, My Posts, Post-Return Feedback, and Offline Sync. Each module is labeled with its implementation status. |
| 4.3 User-Interface Presentation | Include + your input | This needs actual screenshots from your device. I will write the caption and description for each screen. |
| 4.4 Database Implementation | Include | This covers the Firestore Security Rules (a summary plus key excerpts), the composite indexes, the deterministic document IDs, and the local Drift schema. |
| 4.5 Algorithms and Important Code | Include | This covers the **item-matching algorithm** (keywords, synonyms, accessory guard, 0.7/0.3 score), the **offline sync and conflict rule**, the **one-claim-per-user ID scheme**, and the **return cleanup**. These are real and worth explaining. |
| 4.6 System Testing | Include | This covers the testing approach: Flutter unit tests, Firestore rules emulator tests, and any manual or functional testing that you performed. |
| 4.7 Test Cases and Results | Include + your input | The automated results that exist are **21/21 Flutter tests passed (Oct 18, 2026)**. The rules tests must be run and recorded. Manual test results must come from your actual testing. I will not make up pass/fail results. |
| 4.8 Performance Evaluation | Conditional | Include this only if you have real data, for example an ISO/IEC 25010 or System Usability Scale (SUS) survey, or measured response times. **No performance or usability data exists in the project.** If you have none, I will omit this section with an explanation. |
| 4.9 Security and Data-Privacy Measures | Include | This is one of LOFO's strongest areas: the server-side access gate, ownership rules, private claims and chats, immutable audit records, data deletion after a return, and on-device privacy. I will also note the known risks from the audit. |
| 4.10 Discussion of Findings | Include | I will relate the results to each specific objective, using only the evidence that we have. |

## Chapter 5: Summary, Conclusions, and Recommendations

| Section | Status | Why it is relevant |
|---|---|---|
| 5.1 Summary of the Project | Include | This summarizes what was built. |
| 5.2 Conclusions | Include | Each conclusion answers one objective and must be supported by the evidence in Chapter 4. |
| 5.3 Recommendations | Include | These are based on real limitations, for example fixing notification spoofing, server-side logic (Cloud Functions), pagination, and deleting images from Cloudinary. |
| 5.4 Proposed Future Enhancements | Include | These come from the partial and planned features: post editing, profile management, content reporting and moderation, an admin dashboard, push notifications (FCM), iOS support, and better matching. |

## References

| Section | Status | Note |
|---|---|---|
| Books, Journal Articles, Websites | Include + your input | Only sources that you provide or approve will be listed. |
| Technical Documentation | Include | This means official documentation for the tools used: Flutter, Dart, Firebase Auth, Cloud Firestore, Security Rules, Drift, and Cloudinary. You must confirm the **citation style** (APA 7th edition?). |

## Appendices

| Appendix | Status | Reason |
|---|---|---|
| A. Project Timeline / Gantt Chart | Include + your input | The git history only covers Oct 2–17, 2026. I need your full schedule, including planning and testing. |
| B. Budget | Conditional | Include it only if your adviser requires it. The project appears to use free tiers (Firebase, Cloudinary), so a short cost table may be enough. |
| C. Survey or Interview Questions | Conditional | Include it only if you actually used a survey or interviews. |
| D. Requirements Specification | Omit as a separate appendix | Chapter 3.3 already covers the functional and nonfunctional requirements. A copy would only duplicate it. |
| E. Test Cases (full table) | Include | This holds the detailed test-case table that supports 4.7. |
| F. Sample Source Code | Include | It contains short, credential-free excerpts: the matching algorithm, the key Firestore rules, and the sync manager. |
| G. User Manual | Include | End users need step-by-step guides for registering, reporting, claiming, chatting, and approving a claim. |
| H. Installation and Deployment Guide | Include | This explains how to install the APK and how a developer sets up Firebase and Cloudinary, using placeholders instead of real keys. |
| I. Screenshots | Include + your input | These are your device screenshots, if you don't place them in 4.3 instead. |
| J. Letters and Permissions | Conditional | Include them only if you asked the campus or an office for permission, or conducted surveys. |
| K. Data-Privacy Consent Form | Conditional | Include it only if you collected data from respondents. The app's own Terms of Service (v1.0) can be attached as the in-app user agreement. |
| L. Researchers' Profiles / CV | Include + your input | Usually required. You must supply these. |

## Additional Technical Documents from the Guide

| Document | Decision | Reason |
|---|---|---|
| Software Requirements Specification (SRS) | Omit as a separate document | Chapter 3.3 covers it. A separate SRS would duplicate it. |
| Software Design Document | Omit as a separate document | Chapter 3 (sections 3.4–3.11) already covers the design. |
| Database Documentation | Merge into 3.8 and 4.4 | It is the same content. |
| API Documentation | **Omit** | LOFO has **no custom API or backend**. It calls Firebase SDKs and one Cloudinary upload endpoint, which are described in 4.1 and 4.4. |
| Source-Code Documentation | Short appendix (M) | This shows the folder and layer structure of `lib/`, which helps future maintainers. |
| Testing and Quality-Assurance Document | Merge into 4.6–4.7 and Appendix E | It is the same content. |
| Deployment and Installation Guide | Appendix H | Covered there. |
| System Administrator Manual | **Omit** | There is **no admin role or admin interface** in LOFO. Maintenance tasks are covered in Appendix N. |
| Maintenance and Troubleshooting Guide | Short appendix (N) | This is relevant: deploying rules and indexes, updating the Terms version in **both** `terms_service.dart` and `firestore.rules`, and fixing common errors such as PERMISSION_DENIED for unverified users or an offline sync that is stuck. |
| Version History and Change Log | Optional appendix (O) | Seven real commits exist, from Oct 2 to Oct 17, 2026. I would include it only if your adviser asks, because the commit messages are informal. |

---

## Diagrams Planned (all derived from the code)

1. Conceptual Framework (IPO)
2. System Architecture diagram
3. Use-Case diagram (User, plus external Firebase and Cloudinary systems)
4. Context DFD and Level-1 DFD
5. Logical ERD of the Firestore collections
6. Class diagram (models, services, repositories, providers)
7. Activity diagram: Report Item with match check
8. Sequence diagram: Claim, Approve, Return
9. Sequence diagram: Offline queue and sync
10. Screen-flow and navigation diagram (Splash → Login/Register → Verify → Terms → Home, Messages, My Posts, Notifications, Profile)

**Proposed format:** one Markdown file per chapter in `docs/documentation/`, with diagrams written as Mermaid (text-based, version-controlled, and easy to export as images). If your adviser needs a Word (.docx) file, I can also produce one at the end.

## Proposed File Layout

```
docs/documentation/
  00_Phase1_Project_Audit.md
  01_Phase2_Documentation_Outline.md
  02_Preliminary_Pages.md
  03_Chapter1_Introduction.md
  04_Chapter2_Related_Literature.md
  05_Chapter3_Methodology_and_Design.md
  06_Chapter4_Development_Results.md
  07_Chapter5_Summary_Conclusions.md
  08_References.md
  09_Appendices.md
  10_Validation_Report.md      (Phase 5)
```
