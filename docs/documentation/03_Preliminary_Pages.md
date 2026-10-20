# Preliminary Pages

> **How to use this draft.** Text inside `[[ ... ]]` is a placeholder that you need to fill in or check. Text marked **DRAFT** is suggested wording. Ask your adviser to approve it before submission. Nothing in this document comes from a survey, an interview or a source that you have not provided.

---

## Title Page

<div align="center">

**[[APPROVED PROJECT TITLE]]**

*Suggested working title (DRAFT): "LOFO: A Mobile Lost-and-Found Application with Item Matching, Verified Claiming, and Offline Support for [[CAMPUS NAME]]"*

A Capstone Project / Thesis
Presented to the Faculty of the
[[COLLEGE / DEPARTMENT]]
[[INSTITUTION NAME AND CAMPUS]]

In Partial Fulfillment
of the Requirements for the Degree
[[DEGREE PROGRAM, e.g., Bachelor of Science in Computer Science]]

by

[[RESEARCHER 1 FULL NAME]]
[[RESEARCHER 2 FULL NAME]]
[[RESEARCHER 3 FULL NAME]]

[[MONTH YEAR]]

</div>

---

## Approval Sheet

> Use your department's **official approval-sheet template**. The text below is only a placeholder.

This capstone project entitled **"[[APPROVED PROJECT TITLE]]"**, prepared and submitted by **[[RESEARCHERS' NAMES]]**, in partial fulfillment of the requirements for the degree **[[DEGREE PROGRAM]]**, has been examined and is recommended for acceptance and approval.

| | |
|---|---|
| [[ADVISER NAME]] — Adviser | Date: ________ |
| [[PANEL MEMBER 1]] — Panel Member | Date: ________ |
| [[PANEL MEMBER 2]] — Panel Member | Date: ________ |
| [[PANEL CHAIR]] — Chairperson | Date: ________ |

Accepted and approved in partial fulfillment of the requirements for the degree [[DEGREE PROGRAM]].

[[DEAN / PROGRAM CHAIR NAME]] — [[Title]]  Date: ________

---

## Acknowledgment

> **You should write this section yourself.** A common structure is:
> 1. Thank God or a higher power, if appropriate for your institution.
> 2. Thank your adviser, [[ADVISER NAME]], for guidance.
> 3. Thank your panel members for their comments.
> 4. Thank the campus offices or people who helped, for example [[OFFICE / PERSON]].
> 5. Thank the respondents or testers, if any.
> 6. Thank your family and friends.

[[WRITE ACKNOWLEDGMENT HERE]]

---

## Abstract

> **DRAFT. Finalize this after Chapter 4 is complete.** The results sentence is left as a placeholder because no evaluation data has been provided.

Lost items on a campus are usually reported through informal channels, so owners and finders have difficulty finding each other. [[ADD ONE SENTENCE OF CAMPUS-SPECIFIC BACKGROUND WITH A SOURCE]]. This project developed **LOFO (Campus Lost & Found)**, an Android mobile application built with Flutter and Firebase. Students can report lost and found items with photos, search and filter posts, and receive suggestions of possible matches. A keyword-based matching method with synonym handling and category weighting produces these suggestions. Owners claim found items by answering a private verification question set by the finder. The finder then approves or rejects the claim through an in-app conversation. The system also provides in-app notifications, optional feedback after a return, and an offline-first local database that saves reports, claims and messages while the device has no connection and syncs them when it reconnects. Access to protected data requires a verified email address and acceptance of the Terms of Service, and Firestore Security Rules enforce this on the server. The project followed the [[DEVELOPMENT METHODOLOGY]] methodology. Automated unit tests of the local database and the user interface passed (21 of 21). [[ADD RESULTS OF FUNCTIONAL TESTING AND USER EVALUATION, IF ANY]]. [[ADD ONE-SENTENCE CONCLUSION]].

**Keywords:** lost and found, mobile application, Flutter, Firebase, item matching, offline-first

---

## Table of Contents

> Generate this automatically when you move the text to Word (References → Table of Contents).

- Title Page
- Approval Sheet
- Acknowledgment
- Abstract
- Table of Contents
- List of Tables
- List of Figures
- **Chapter 1 — Introduction**
  - 1.1 Background of the Study
  - 1.2 Statement of the Problem
  - 1.3 Objectives of the Project
  - 1.4 Scope and Limitations
  - 1.5 Significance of the Project
  - 1.6 Definition of Terms
- **Chapter 2 — Review of Related Literature and Systems**
  - 2.1 Related Literature
  - 2.2 Related Studies
  - 2.3 Related Systems or Applications
  - 2.4 Comparison of Existing Systems
  - 2.5 Synthesis
  - 2.6 Research or System Gap
  - 2.7 Conceptual Framework
- **Chapter 3 — Methodology and System Design**
  - 3.1 Software Development Methodology
  - 3.2 Requirements-Gathering Methods (conditional)
  - 3.3 System Requirements
  - 3.4 System Architecture
  - 3.5 Use-Case Diagram
  - 3.6 Data-Flow Diagrams
  - 3.7 Entity-Relationship Diagram
  - 3.8 Database Design
  - 3.9 Class Diagram
  - 3.10 Activity and Sequence Diagrams
  - 3.11 User-Interface Design
  - 3.12 Hardware and Software Requirements
  - 3.13 Development Tools and Technologies
- **Chapter 4 — System Development, Results, and Discussion**
  - 4.1 System Implementation
  - 4.2 Description of System Modules
  - 4.3 User-Interface Presentation
  - 4.4 Database Implementation
  - 4.5 Algorithms and Important Code
  - 4.6 System Testing
  - 4.7 Test Cases and Results
  - 4.8 Performance Evaluation (conditional)
  - 4.9 Security and Data-Privacy Measures
  - 4.10 Discussion of Findings
- **Chapter 5 — Summary, Conclusions, and Recommendations**
- References
- Appendices A–O

---

## List of Tables

| Table | Title | Location |
|---|---|---|
| 1 | Comparison of Existing Systems | 2.4 |
| 2 | Functional Requirements | 3.3 |
| 3 | Non-Functional Requirements | 3.3 |
| 4 | Use-Case Descriptions | 3.5 |
| 5–14 | Data Dictionary: Firestore collections | 3.8 |
| 15 | Local (Drift/SQLite) Tables | 3.8 |
| 16 | Hardware Requirements | 3.12 |
| 17 | Software Requirements | 3.12 |
| 18 | Development Tools and Technologies | 3.13 |
| 19 | System Modules and Implementation Status | 4.2 |
| 20 | Composite Indexes | 4.4 |
| 21 | Synonym Groups Used by the Matcher | 4.5 |
| 22 | Automated Test Results | 4.7 |
| 23 | Functional Test Cases | 4.7 / Appendix E |
| 24 | Security Measures and Enforcement Point | 4.9 |
| 25 | Objectives vs. Evidence | 4.10 |

## List of Figures

| Figure | Title | Location |
|---|---|---|
| 1 | Conceptual Framework (Input–Process–Output) | 2.7 |
| 2 | Development Methodology Diagram | 3.1 |
| 3 | System Architecture | 3.4 |
| 4 | Use-Case Diagram | 3.5 |
| 5 | Context Diagram (DFD Level 0) | 3.6 |
| 6 | DFD Level 1 | 3.6 |
| 7 | Logical Entity-Relationship Diagram | 3.7 |
| 8 | Class Diagram | 3.9 |
| 9 | Activity Diagram: Report an Item | 3.10 |
| 10 | Sequence Diagram: Claim, Approval, and Return | 3.10 |
| 11 | Sequence Diagram: Offline Queue and Sync | 3.10 |
| 12 | Screen-Flow Diagram | 3.11 |
| 13+ | User-Interface Screenshots | 4.3 |
