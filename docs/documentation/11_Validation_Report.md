# Phase 5 — Validation Report

**Date:** October 18, 2026
**Version documented:** commit `6b4124c` ("Backup", Oct 18, 2026). The app code has not changed since the audit.
**Files checked:** `03`–`10` in `docs/documentation/`

---

## 1. Consistency Checks Performed

| # | Check | Result |
|---|---|---|
| 1 | The feature list agrees across the Scope (§1.4), the FRs (§3.3), the modules (§4.2), the user manual (App. G) and Chapter 5 | ✔ Consistent. Partial and planned items (post editing, profile settings, reporting and moderation, push notifications) are labeled the same way everywhere. |
| 2 | Every FR marked Implemented has at least one test case | ✔ After the fix. TC-29 (FR-11) and TC-30 (FR-04) were added during validation. FR-20 to FR-22 have no test cases because they are not implemented. |
| 3 | Objectives (§1.3) ↔ modules (§4.2) ↔ evidence (Table 25) ↔ conclusions (§5.2) | ✔ The same 7 (+1 optional) objectives are used in all four places. |
| 4 | ERD (Fig. 7) ↔ data dictionary (Tables 5–15) ↔ `lib/models` ↔ `firestore.rules` | ✔ The field names and ID formats agree. Rule-only collections (`reports`, `users`) are marked planned in both places. |
| 5 | Document IDs (§4.4.3) ↔ code | ✔ Items and messages use UUID v4 generated on the device (repositories). Claims, conversations, terms acceptances, completed returns and feedback use the deterministic IDs stated. *The audit was corrected during this phase: it first said items use an auto ID.* |
| 6 | Use cases ↔ roles | ✔ One human actor (User, acting as Finder or Claimant). There is no Admin actor anywhere in the document. |
| 7 | Screen-flow diagram (Fig. 12) ↔ `lib/screens` | ✔ All 19 screen files are represented. The tab order is Home, Messages, My Posts, Notifications, Profile. *The audit was corrected earlier.* |
| 8 | Notification types in the text ↔ code | ✔ Only `claim_received`, `claim_approved`, `claim_rejected`, `category_match` and the device-only `report_posted` are described as created by the app. |
| 9 | Test results | ✔ Only the real `flutter test` run (21/21 passed) is reported as a result. All manual test cases, the rules tests and the evaluation are left blank. |
| 10 | Credentials | ✔ No API keys, Cloudinary values, Firebase config values or passwords appear in any documentation file. The code excerpts in Appendix F contain none. |
| 11 | Invented sources or data | ✔ None. Chapter 2, the references, the background facts, the survey data and the dates are placeholders. |
| 12 | Commit history (§3.1, App. A, App. O) ↔ `git log` | ✔ Corrected during validation: the resend-claim commit is dated **Oct 4** (not Oct 17), and the Oct 18 backup commit was added. |
| 13 | Class-diagram syntax | ✔ One Mermaid syntax issue was fixed (`currentVersion`). |

---

## 2. Unresolved Issues (need your action)

### A. Information only you can provide (placeholders `[[ ... ]]`)

| File | Placeholders | Main items |
|---|---|---|
| 03_Preliminary_Pages | 27 | Title, names, adviser, institution, acknowledgment, abstract results |
| 04_Chapter1 | 18 | Campus background with sources, approved problems and objectives, beneficiaries |
| 05_Chapter2 | 85 | **All literature, studies and related systems**, plus the comparison-table columns |
| 06_Chapter3 | 41 | Methodology and phases, requirements gathering, hardware specs, tool versions |
| 07_Chapter4 | 92 | **Manual test results (TC-01 to TC-30)**, rules-test output, screenshots, evaluation, discussion |
| 08_Chapter5 | 17 | Conclusions that depend on test results |
| 09_References | 6 | Your sources; citation style |
| 10_Appendices | 19 | Gantt dates, budget, consent forms, CVs |

### B. Evidence still missing
1. **Firestore rules tests have not been run.** Run `npm test` in `firestore_rules_test/` (this needs Java and the Firebase CLI) and paste the output into Table 22.
2. **No manual functional testing** has been recorded. Fill in Table 23 with real results only.
3. **No usability or performance evaluation** exists. Keep §4.8 only if you conduct one. Otherwise delete it and add the limitation sentence given there.
4. **No screenshots** yet. Save them in `docs/documentation/screenshots/`.

### C. Decisions I made because the questionnaire was not answered (please confirm)
1. **App name.** The document uses **"LOFO (Campus Lost & Found)"**. The app itself never displays "LOFO". Change the name in the document, or rename the app, so that they match.
2. **Moderation and reporting** are described as **planned**, because no moderation code exists in the repository.
3. **Format.** The documents are in Markdown with Mermaid diagrams. A Word file can be produced after the placeholders are filled in.
4. **Suggested title, problems and objectives** are marked **DRAFT**. They must be replaced with the wording your adviser approved.

### D. Mismatches between the app and the documentation that only a code change can fix
These are documented honestly as limitations. Fix them in the app only if you want the documentation to say something different.
1. The Terms of Service (sections 6–7) promise **reporting tools and bans** that the app does not have.
2. The **"Claimed"** filter in My Posts can never show any items.
3. `firebase_storage` and `storage.rules` are **unused**, because photos go to Cloudinary.
4. The **Edit** post and **Profile** options are placeholders.

### E. Formatting and rendering notes
1. The **Gantt chart in Appendix A will not render** until the `[[ ]]` dates are replaced with real dates.
2. The Mermaid diagrams were checked by reading them but were **not rendered**. Paste each one into https://mermaid.live to export PNG or SVG files for Word.
3. The file numbering differs slightly from the Phase 2 outline: `02` is now the Phase 3 questionnaire, so the chapters start at `03`. The content follows the approved outline.
