# Chapter 2 — Review of Related Literature and Systems

> **Important.** This chapter must be built from sources that **you** have read and can cite. I have not added any author, study, statistic or system description, because inventing them would be academic dishonesty. Below you will find a template for each section and a short sample paragraph that shows the expected style. Replace every `[[ ... ]]` with real, cited content in [[CITATION STYLE, e.g., APA 7th]].

---

## 2.1 Related Literature

*Purpose: books, articles and reports that explain the concepts behind LOFO.*

Suggested topics (cover only those you have sources for):

| Topic | Why it relates to LOFO | Your source(s) |
|---|---|---|
| Lost-and-found management in schools and public places | Background of the problem | [[SOURCE]] |
| Mobile application use among students | Supports the choice of a mobile platform | [[SOURCE]] |
| Cross-platform mobile development (Flutter) | Chosen framework | [[SOURCE]] |
| Cloud / Backend-as-a-Service databases (Firebase) | Chosen backend | [[SOURCE]] |
| Offline-first / local-first applications | Explains the offline design | [[SOURCE]] |
| Text similarity and keyword matching (e.g., the Jaccard index) | Basis of the matching method | [[SOURCE]] |
| Ownership verification and trust in peer-to-peer exchanges | Supports the verification question | [[SOURCE]] |
| Data privacy (e.g., the Data Privacy Act of 2012, RA 10173, if your institution requires it) | Supports the privacy measures | [[SOURCE]] |

**Template paragraph:**
> According to [[Author (Year)]], [[key idea from the source in your own words]]. This relates to the present project because [[connection to a specific LOFO feature]].

[[WRITE 2.1 HERE]]

---

## 2.2 Related Studies

*Purpose: earlier theses, capstones or journal studies that built similar systems.*

For each study, record: **author and year, title, purpose, method or technology, main findings, and how LOFO is similar or different.**

| # | Author (Year) | Title | Technology / Method | Findings | Relation to LOFO |
|---|---|---|---|---|---|
| 1 | [[ ]] | [[ ]] | [[ ]] | [[ ]] | [[ ]] |
| 2 | [[ ]] | [[ ]] | [[ ]] | [[ ]] | [[ ]] |
| 3 | [[ ]] | [[ ]] | [[ ]] | [[ ]] | [[ ]] |

[[WRITE 2.2 HERE]]

---

## 2.3 Related Systems or Applications

*Purpose: existing apps, websites or manual processes that solve the same problem.*

Include only systems that you actually examined. For each one, state where your information came from (for example, an app-store page, the official website, or your own use of the app on [[date]]).

- **Current campus process.** [[e.g., the logbook at the security office — describe it from your observation or interview]]
- **Social-media groups.** [[only if your sources document this]]
- **[[System / App name]]** — [[short description and source]]
- **[[System / App name]]** — [[short description and source]]

---

## 2.4 Comparison of Existing Systems

**Table 1. Comparison of Existing Systems**

The **LOFO** column is filled in from the actual source code. Fill in the other columns only with information that you have verified. ✔ = present, ✘ = absent, ◐ = partial.

| Feature | [[System A]] | [[System B]] | [[Current campus process]] | **LOFO** |
|---|---|---|---|---|
| Mobile access | [[ ]] | [[ ]] | [[ ]] | ✔ (Android) |
| Report lost items | [[ ]] | [[ ]] | [[ ]] | ✔ |
| Report found items with photos | [[ ]] | [[ ]] | [[ ]] | ✔ (up to 5 photos) |
| Search and category filter | [[ ]] | [[ ]] | [[ ]] | ✔ |
| Automatic match suggestions | [[ ]] | [[ ]] | [[ ]] | ✔ (keyword-based) |
| Ownership verification before return | [[ ]] | [[ ]] | [[ ]] | ✔ (finder's verification question) |
| Private in-app messaging | [[ ]] | [[ ]] | [[ ]] | ✔ |
| In-app notifications | [[ ]] | [[ ]] | [[ ]] | ✔ |
| Push notifications | [[ ]] | [[ ]] | [[ ]] | ✘ |
| Works offline | [[ ]] | [[ ]] | [[ ]] | ✔ |
| Verified accounts only | [[ ]] | [[ ]] | [[ ]] | ✔ (email verification) |
| Admin / moderation tools | [[ ]] | [[ ]] | [[ ]] | ✘ (planned) |
| Image-based matching | [[ ]] | [[ ]] | [[ ]] | ✘ |

---

## 2.5 Synthesis

> Write this **after** sections 2.1–2.4 are complete. Use this structure:

1. **Common findings.** What the sources agree on. [[e.g., central reporting improves recovery — only if your sources say so]]
2. **Common features** of existing systems. [[from Table 1]]
3. **Common weaknesses** of existing systems. [[from Table 1 and your sources]]
4. **How LOFO builds on them.** LOFO keeps the useful features (central reporting, search, photos) and adds the features in §2.6.

[[WRITE 2.5 HERE]]

---

## 2.6 Research or System Gap

> **DRAFT.** Confirm each point against Table 1. Delete any point that a system you reviewed already provides.

Based on the systems that were reviewed, LOFO addresses the following gaps:

1. **Ownership verification.** [[If true per Table 1:]] Many existing channels do not give a structured way to confirm ownership before an item is handed over. In LOFO, the finder writes a verification question. The claimant's answer is visible only to the finder and the claimant, and the finder decides whether to approve the claim.
2. **Automatic matching.** In LOFO, users do not have to search manually. The system suggests possible matches between opposite report types (lost and found) before a report is submitted, and notifies owners of Lost items when a similar Found item is posted.
3. **Privacy of transactions.** Claims and conversations are private to the two users involved. They are deleted after a successful return.
4. **Reliability on weak connections.** The offline-first design lets users report and message even with an unstable connection.
5. **Accountability.** Only users with a verified email address who have accepted the Terms of Service can access the data.

---

## 2.7 Conceptual Framework

LOFO uses the **Input–Process–Output (IPO)** model. [[Change this if your adviser prefers another model.]] Every element in the model corresponds to an implemented part of the system.

**Figure 1. Conceptual Framework of LOFO**

```mermaid
flowchart LR
    subgraph I[INPUT]
        I1[User account data<br/>name, email, password]
        I2[Terms of Service acceptance]
        I3[Lost / Found reports<br/>name, category, location, date,<br/>description, photos,<br/>verification question]
        I4[Claim answers and details]
        I5[Chat messages]
        I6[Claim decisions<br/>approve / reject]
        I7[Feedback<br/>rating, recommendation]
    end
    subgraph P[PROCESS]
        P1[Registration, email verification<br/>and access gate]
        P2[Local storage and<br/>cloud synchronization]
        P3[Keyword-based<br/>item matching]
        P4[Claim verification<br/>workflow]
        P5[Messaging and<br/>notification generation]
        P6[Return completion<br/>and data cleanup]
    end
    subgraph O[OUTPUT]
        O1[Verified user accounts]
        O2[Searchable feed of<br/>lost and found items]
        O3[Possible-match suggestions<br/>and notifications]
        O4[Approved / rejected claims]
        O5[Completed returns and<br/>post-return feedback]
    end
    I --> P --> O
```

**Explanation.** The **inputs** are the data that users enter: account details, reports, claims, messages, decisions and feedback. The **process** shows how LOFO handles these inputs. It verifies users, stores and syncs data, matches lost and found reports, runs the claim-verification workflow, delivers messages and notifications, and cleans up data after a return. The **outputs** are the results that users see: verified accounts, a searchable item feed, match suggestions, claim decisions, and completed returns with optional feedback.
