# LOFO: Phase 3 Missing Information

I could not find these items in the source code, the Firebase configuration, or the git history.
Please type your answers directly under each question, or paste them in chat. If something does not exist (for example, you did not run a survey), write **"None"**. I will then leave out the matching section, as the approved outline says.

> Please do **not** include passwords, API keys, or respondents' personal data. Summaries are enough.

---

## A. Project Identity (Title Page, Approval Sheet)

1. **Approved project title** (exact wording): Campus Lost and Found
2. **App name to use in the document.** The code says "Campus Lost & Found". Should the document call it "LOFO", "Campus Lost & Found", or "LOFO: Campus Lost & Found"? :Campus Lost & Found
3. **Which campus or institution** is the app for (school, campus, college or department)? : BISU Candijay Campus
4. **Researchers' full names**, degree program, year and section: Mark Jeshmer B. Jaromahum, Feny Ann V. Cervantes, Jules J. Tuyogon, Jotham Aaron Puracan
5. **Adviser's name**, plus any panel or approval-sheet names: Jhoel Kennenth Gulle 
6. **Month and year of submission**, and the subject or course code: Put any I'll just edit it.

## B. Approved Research Content (Chapter 1)

7. **Statement of the Problem:** your approved general problem and specific questions, word for word. 
8. **General Objective and Specific Objectives:** your approved wording, word for word.
9. **Background facts:** how are lost items handled on your campus today (guard house, office logbook, Facebook group, word of mouth)? What is the source of each fact (an interview, an observation, or a document)?
10. **Approved Scope and Limitations**, if your adviser already approved any wording. Otherwise I will write them from the audit.
11. **Intended beneficiaries** for the Significance section (students, faculty, staff, a campus office, future researchers):

## C. Chapter 2 Sources

12. **Related literature and studies:** list every source you have already read or cited, with author, year, title, and journal or URL. I will only use these.
13. **Related systems or apps you reviewed** (name, plus the source where you got the information):
14. **Required citation style** (APA 7th edition, IEEE, or another style):

## D. Methodology (Chapter 3)

15. **Software development methodology you actually followed**, and what you did in each phase or sprint:
16. **Requirements-gathering methods actually used** (interviews, survey, observation, document review). Include the number of respondents and the dates:
17. **Conceptual framework model** your adviser prefers (IPO, or another model):

## E. Testing and Evaluation Evidence (Chapter 4)

18. **Manual or functional testing:** did you test the app by hand? Please give the test cases you ran and their actual results (pass or fail, with notes and dates).
19. **Test devices:** phone model(s) and Android version(s):
20. **Firestore rules tests** (`firestore_rules_test/`): have you run them? If yes, paste the result. If no, may I run them? Running them needs the Firebase CLI and Java installed, and it does not change your app or your live database.
21. **User evaluation or usability study** (for example ISO/IEC 25010 or the System Usability Scale): the instrument used, the number and type of respondents, the dates, and the summarized results (means or scores):
22. **Any performance measurements** (load times, sync times), if any:

## F. Appendices

23. **Project timeline:** the start and end dates of each phase, for the Gantt chart:
24. **Is a budget section required?** If yes, list any actual costs (device, internet, paid services):
25. **Letters, permissions, or consent forms** you used, if any:
26. **Researchers' profiles or CVs:** will you supply them?
27. **Screenshots:** please save them in `docs/documentation/screenshots/` with names such as `login.png` or `home.png`, or tell me where they are.

## G. Decisions on Findings from the Audit

28. **Moderation Worker.** The Firestore rules mention a server-side moderation Worker (content reports, posting bans). Does this exist outside this repository (for example as a deployed Cloud Function or Cloudflare Worker)? If not, I will describe it as **planned**.
29. **Terms vs. app.** The Terms of Service promise "reporting tools" and warnings or bans that the app does not have yet. Should the documentation describe these as **planned features**? I recommend yes.
30. **Version to document.** You have uncommitted changes in 25 files. Should I document the current working tree? I recommend that you commit it first so the documentation matches a fixed version.
31. **Output format:** Markdown only, or Markdown plus a final Word (.docx) file?
