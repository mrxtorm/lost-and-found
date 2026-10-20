# Chapter 3 — Methodology and System Design

> The diagrams are written in **Mermaid**. They display as images on GitHub, in VS Code with a Mermaid extension, or at https://mermaid.live, where you can export them as PNG or SVG for Word. Every diagram was drawn from the actual source code (`lib/`) and from `firestore.rules`.

---

## 3.1 Software Development Methodology

> **Your input is needed.** I cannot tell from the code which methodology you followed. Name the method you actually used and describe what you did in each phase.

[[METHODOLOGY NAME, e.g., Agile (Scrum) / Iterative and Incremental / Prototyping / Waterfall]]

**Evidence that you can cite from the project.** The git history shows development work from **October 2 to October 18, 2026** in these commits:

| Date | Commit summary |
|---|---|
| 2026-10-02 | Initial commit |
| 2026-10-04 | Fixed Firestore rules |
| 2026-10-04 | Item matching (name keyword and category) on submit; "Check matches" in My Posts; possible-match notifications; notification linking |
| 2026-10-04 | Resend button for rejected claims |
| 2026-10-13 | User-interface improvements |
| 2026-10-17 | Backup before additional features |
| 2026-10-17 | Registration verification, user agreement, multiple photos, Lost items without a photo, notification badge, mark notifications as read, confetti animation, user feedback |
| 2026-10-18 | Backup: UI refinements across the screens, shared feedback widgets (`app_feedback.dart`), theme updates (commit `6b4124c`, the version documented here) |

**Figure 2. Development Methodology.** [[Insert a diagram of your chosen methodology.]]

**Template (replace with what actually happened):**

| Phase / Sprint | Dates | Activities | Output |
|---|---|---|---|
| [[Planning]] | [[ ]] | [[ ]] | [[ ]] |
| [[Analysis / Requirements]] | [[ ]] | [[ ]] | [[ ]] |
| [[Design]] | [[ ]] | [[ ]] | [[ ]] |
| [[Development: iteration 1]] | [[ ]] | [[ ]] | [[ ]] |
| [[Testing]] | [[ ]] | [[ ]] | [[ ]] |
| [[Deployment / Evaluation]] | [[ ]] | [[ ]] | [[ ]] |

---

## 3.2 Requirements-Gathering Methods *(conditional)*

> **Keep this section only if you actually gathered requirements** through interviews, surveys, observation or document review. Give the number of respondents, the dates and the instruments used. If you did not, delete the section and add one sentence to 3.3: *"The requirements were defined by the researchers based on the problem analysis and the review of related systems."*

[[DESCRIBE METHODS, RESPONDENTS AND DATES — or delete this section]]

---

## 3.3 System Requirements

Every requirement below is satisfied by the current source code unless it says otherwise.

### Functional Requirements

**Table 2. Functional Requirements**

| ID | Requirement | Status |
|---|---|---|
| FR-01 | The system shall let a user register with full name, email and password (password entered twice for confirmation). | Implemented |
| FR-02 | The system shall send an email-verification link after registration and allow the user to resend it. | Implemented |
| FR-03 | The system shall let a user log in, log out, and request a password-reset email. | Implemented |
| FR-04 | The system shall remember accounts previously used on the device (no passwords) for quick sign-in, and let the user remove them. | Implemented |
| FR-05 | The system shall require acceptance of the current Terms of Service version and record each acceptance. | Implemented |
| FR-06 | The system shall block access to the main app until the email is verified and the Terms are accepted. | Implemented |
| FR-07 | The system shall let a user report an item as Lost or Found with name, category, location, date, description and up to 5 photos. | Implemented |
| FR-08 | The system shall require at least one photo and a verification question for Found reports. Photos are optional for Lost reports. | Implemented |
| FR-09 | The system shall show possible matches of the opposite type before a report is submitted. | Implemented |
| FR-10 | The system shall display other users' posts and support search (name, category, location) and filters (type, category). | Implemented |
| FR-11 | The system shall show item details with all photos in a full-screen viewer. | Implemented |
| FR-12 | The system shall let a user submit one claim per Found item by answering the verification question, with optional additional details. | Implemented |
| FR-13 | The system shall let the finder approve or reject a claim, and let the claimant resend a rejected claim. | Implemented |
| FR-14 | When a claim is approved, the system shall record a completed return and delete the item, the claim, the conversation and its messages. | Implemented |
| FR-15 | The system shall provide private one-to-one messaging per post, with unread counts. | Implemented |
| FR-16 | The system shall create in-app notifications for claim events and possible matches, and let the user mark one or all as read. | Implemented |
| FR-17 | The system shall list the user's own posts, filter them, delete them, and check matches for each one. | Implemented |
| FR-18 | The system shall let both participants of a completed return submit one optional rating (1–5) and recommendation (up to 500 characters). | Implemented |
| FR-19 | The system shall save reports, deletions, claims, messages and read-status changes made offline, and sync them when online. | Implemented |
| FR-20 | The system shall let a user edit an existing post. | **Not implemented** (shows "will be implemented later") |
| FR-21 | The system shall let a user edit their profile and change their password inside the app. | **Not implemented** (shows "coming soon") |
| FR-22 | The system shall let a user report an inappropriate post, and support warnings and temporary posting bans. | **Planned** (rules only; no app screen or moderation component) |

### Non-Functional Requirements

**Table 3. Non-Functional Requirements**

| ID | Category | Requirement | How the system addresses it |
|---|---|---|---|
| NFR-01 | Security | Only verified users who have accepted the Terms can read or write protected data. | `hasAccess()` in `firestore.rules` checks the signed ID token and the acceptance record. |
| NFR-02 | Security | Users can change only data they own or are involved in. | Ownership and participant checks on every collection; deny by default. |
| NFR-03 | Privacy | Claim answers and chats are visible only to the two users involved and are deleted after a return. | Claim and conversation rules; cleanup in `ClaimService`. |
| NFR-04 | Privacy | No passwords are stored on the device. When an account logs out, its cached data is not shown to the next account. | `RememberedAccount` stores no secrets; `clearUserScopedCacheOnLogout`. |
| NFR-05 | Availability | The app remains usable without an internet connection. | Drift local database, offline queue, `SyncManager`. |
| NFR-06 | Reliability | Offline actions are never lost or duplicated during sync. | Pending flags, IDs generated on the device, idempotent message send, 30-second retry. |
| NFR-07 | Integrity | One user cannot create duplicate claims or duplicate feedback. | Deterministic document IDs plus create-only rules. |
| NFR-08 | Usability | Forms show clear errors, and the screens follow Material Design. | Field-level validation and scroll-to-error in the report form; `AppTheme`. |
| NFR-09 | Performance | [[Only if measured: state the target and the measured value]] | No performance measurement has been done yet. |
| NFR-10 | Portability | Runs on Android phones. | Flutter build for Android. |

---

## 3.4 System Architecture

LOFO uses a **layered, offline-first client architecture** with cloud services. It has **no custom backend server**. The application talks directly to Firebase and Cloudinary, and Firestore Security Rules enforce security on the server.

**Figure 3. System Architecture of LOFO**

```mermaid
flowchart TB
    subgraph Device["Android Device — LOFO App (Flutter)"]
        UI["Presentation Layer<br/>Screens and Widgets"]
        ST["State Layer<br/>Providers (ChangeNotifier)"]
        RP["Data Layer<br/>Repositories (offline-first)"]
        DB[("Local Database<br/>Drift / SQLite")]
        SV["Service Layer<br/>Auth, Item, Claim, Chat,<br/>Notification, Feedback, Terms,<br/>Matching, Cloudinary"]
        SM["SyncManager +<br/>ConnectivityService"]
        SP[("SharedPreferences<br/>remembered accounts,<br/>terms cache")]
        UI --> ST --> RP
        RP <--> DB
        RP --> SV
        SM --> RP
        UI -.-> SV
        SV -.-> SP
    end
    subgraph Cloud["Cloud Services"]
        FA["Firebase Authentication"]
        FS[("Cloud Firestore<br/>+ Security Rules")]
        CL[("Cloudinary<br/>image hosting")]
    end
    SV <--> FA
    SV <--> FS
    SV --> CL
```

**Description of the layers:**

1. **Presentation layer** (`lib/screens`, `lib/widgets`): the Flutter screens and reusable widgets.
2. **State layer** (`lib/providers`): the `AuthProvider`, `ItemProvider`, `ClaimProvider`, `ChatProvider` and `NotificationProvider` classes. They hold screen state such as filters and badge counts, and notify the UI when data changes.
3. **Data layer** (`lib/data/repositories`): the repositories. They write every change to the local database first and then try to send it to the cloud. They also listen to Firestore and copy server data into the local database.
4. **Local database** (`lib/data/local`): a Drift (SQLite) database. **The UI reads from this database**, so screens load even when the device is offline.
5. **Service layer** (`lib/services`): the classes that call Firebase Authentication, Cloud Firestore and the Cloudinary upload API. The pure-Dart matching algorithm also lives here.
6. **Sync layer** (`lib/data/sync`): `SyncManager` sends queued changes at start-up, whenever the connection returns, and every 30 seconds while work is still pending.
7. **Cloud**: Firebase Authentication (accounts), Cloud Firestore (shared data, protected by Security Rules) and Cloudinary (photos).

---

## 3.5 Use-Case Diagram

LOFO has **one human actor, the User**. A user acts as a *Finder* when they own a Found post, and as a *Claimant* when they claim someone else's Found post. The app has **no Administrator actor**. The external systems are shown as secondary actors.

**Figure 4. Use-Case Diagram**

```mermaid
flowchart LR
    U(("👤 User"))
    F(("👤 Finder<br/>(User who posted<br/>a Found item)"))
    C(("👤 Claimant<br/>(User claiming<br/>a Found item)"))
    F -. is a .-> U
    C -. is a .-> U

    subgraph LOFO["LOFO System"]
        UC1([Register])
        UC2([Verify Email])
        UC3([Log In / Log Out])
        UC4([Reset Password])
        UC5([Accept Terms of Service])
        UC6([Report Lost / Found Item])
        UC7([View Possible Matches])
        UC8([Browse, Search and Filter Items])
        UC9([View Item Details])
        UC10([Send / Read Messages])
        UC11([View and Mark Notifications])
        UC12([Manage My Posts / Delete Post])
        UC13([Submit / Resend Claim])
        UC14([Approve / Reject Claim])
        UC15([Give Post-Return Feedback])
    end

    U --- UC1 & UC2 & UC3 & UC4 & UC5 & UC6 & UC7 & UC8 & UC9 & UC10 & UC11 & UC12
    C --- UC13
    C --- UC15
    F --- UC14
    F --- UC15
    UC6 -. include .-> UC7

    FA[["Firebase Auth"]]
    FS[["Cloud Firestore"]]
    CL[["Cloudinary"]]
    UC1 & UC2 & UC3 & UC4 --- FA
    UC6 --- CL
    UC6 & UC13 & UC14 & UC10 --- FS
```

**Table 4. Use-Case Descriptions (main use cases)**

| Use case | Actor | Precondition | Main flow | Postcondition |
|---|---|---|---|---|
| Register | User | None | The user enters full name, email, password and confirmation → the account is created → a verification email is sent | The account exists but is unverified |
| Verify Email | User | Registered | The user opens the link in the email → taps "I've Verified My Email" → the app reloads the user and refreshes the ID token | Email verified |
| Accept Terms | User | Verified | The user reads the Terms (v1.0) → taps *I Accept* → an acceptance record is created | The user can enter the app |
| Report Item | User | Has access | The user fills in the form → the app shows possible matches → the user continues → the item is saved locally and synced | The item is visible to others after sync |
| Submit Claim | Claimant | Found item owned by another user | The claimant answers the verification question and adds details → submits | A Pending claim exists; a claim message and a notification go to the finder |
| Approve / Reject Claim | Finder | A Pending claim exists | In the conversation, the finder taps *Accept Claim* or *Reject* | Approve: completed return recorded, data deleted, claimant notified. Reject: claimant notified and can resend |
| Give Feedback | Finder / Claimant | A completed return exists | The user gives a rating of 1–5 and an optional recommendation | One feedback record per user per return |

---

## 3.6 Data-Flow Diagrams

**Figure 5. Context Diagram (Level 0)**

```mermaid
flowchart LR
    U[User]
    S((0<br/>LOFO<br/>System))
    FA[Firebase Authentication]
    CL[Cloudinary]
    U -- "registration and login data, reports, photos,<br/>claims, messages, decisions, feedback" --> S
    S -- "item feed, matches, claim status,<br/>messages, notifications" --> U
    S -- "credentials, verification and reset requests" --> FA
    FA -- "auth state, verified flag, ID token" --> S
    S -- "photo files" --> CL
    CL -- "secure image URLs" --> S
```

**Figure 6. Level-1 DFD**

```mermaid
flowchart TB
    U[User]
    FA[Firebase Auth]
    CL[Cloudinary]

    P1((1.0<br/>Manage Account<br/>and Access))
    P2((2.0<br/>Report and<br/>Browse Items))
    P3((3.0<br/>Match Items))
    P4((4.0<br/>Process Claims))
    P5((5.0<br/>Messaging))
    P6((6.0<br/>Notifications))
    P7((7.0<br/>Sync Data))

    D1[(D1 termsAcceptances)]
    D2[(D2 items)]
    D3[(D3 claims)]
    D4[(D4 conversations / messages)]
    D5[(D5 notifications)]
    D6[(D6 completedReturns / feedback)]
    D7[(D7 Local SQLite cache)]

    U -- credentials, ToS acceptance --> P1
    P1 <--> FA
    P1 --> D1
    U -- report details, photos --> P2
    P2 --> CL
    P2 --> D7
    P7 <--> D7
    P7 --> D2
    P7 --> D3
    P7 --> D4
    D2 --> P3
    P3 -- possible matches --> U
    P3 -- match alerts --> P6
    U -- claim answer / decision --> P4
    P4 --> D7
    P4 --> D6
    P4 -- delete resolved data --> D2 & D3 & D4
    P4 -- claim events --> P6
    U -- messages --> P5
    P5 --> D7
    D4 --> P5
    P6 --> D5
    D5 -- notifications --> U
    D2 -- item feed --> U
```

---

## 3.7 Entity-Relationship Diagram

Cloud Firestore is a **NoSQL document database**. It has no tables or foreign keys. The diagram below is a **logical ERD**: the "relationships" are ID fields stored inside documents (for example, `ownerId` holds a Firebase Auth user ID). **USER** represents the Firebase Authentication account. The app does **not** store a user-profile collection.

**Figure 7. Logical ERD**

```mermaid
erDiagram
    USER ||--o{ ITEM : "posts (ownerId)"
    USER ||--o{ CLAIM : "submits (claimantId)"
    ITEM ||--o{ CLAIM : "receives (itemId)"
    USER ||--o{ CLAIM : "decides as finder (ownerId)"
    ITEM ||--o{ CONVERSATION : "is discussed in (postId)"
    USER }o--o{ CONVERSATION : "participates (participantIds, exactly 2)"
    CONVERSATION ||--o{ MESSAGE : contains
    USER ||--o{ NOTIFICATION : "receives (recipientId)"
    USER ||--o{ TERMS_ACCEPTANCE : "accepts (userId)"
    CLAIM ||--o| COMPLETED_RETURN : "becomes when approved (same id)"
    COMPLETED_RETURN ||--o{ FEEDBACK : "has at most 2 (returnId)"

    USER {
        string uid PK "Firebase Auth"
        string displayName
        string email
        bool emailVerified
    }
    ITEM {
        string id PK "UUID v4"
        string title
        string description
        string category
        string location
        string date
        string status "Lost | Found"
        string imageUrl
        array imageUrls
        string username
        string ownerId FK
        string verificationQuestion "Found only"
        timestamp createdAt
    }
    CLAIM {
        string id PK "itemId_claimantId"
        string itemId FK
        string itemTitle
        string itemImageUrl
        string claimantId FK
        string claimantName
        string ownerId FK
        string answer
        string additionalDetails
        string status "Pending | Approved | Rejected"
        timestamp createdAt
    }
    CONVERSATION {
        string id PK "postId_uidA_uidB"
        string postId FK
        string itemName
        string itemImageUrl
        string itemType
        array participantIds
        map participantNames
        string lastMessage
        timestamp lastMessageTime
        map unreadCounts
    }
    MESSAGE {
        string id PK "UUID v4 or claim_itemId"
        string senderId FK
        string senderName
        string text "1-2000 chars"
        timestamp timestamp
        bool isRead
    }
    NOTIFICATION {
        string id PK "auto"
        string recipientId FK
        string type
        string title
        string message
        string relatedItemId
        string relatedClaimId
        bool isRead
        timestamp createdAt
    }
    TERMS_ACCEPTANCE {
        string id PK "uid_version"
        string userId FK
        string email
        string version
        timestamp acceptedAt
    }
    COMPLETED_RETURN {
        string id PK "itemId_claimantId"
        string itemId
        string itemTitle
        string ownerId FK
        string claimantId FK
        timestamp completedAt
    }
    FEEDBACK {
        string id PK "returnId_uid"
        string returnId FK
        string itemTitle
        string authorId FK
        string role "finder | claimant"
        string otherUserId
        int rating "1-5"
        string recommendation "max 500"
        timestamp createdAt
    }
```

> **Not shown:** the collections `reports` and `users` (with `bannedUntil`) exist **only in the Security Rules** for the planned moderation feature. The app never reads or writes them, except that the rules check `users/{uid}` when a user creates or updates an item.

---

## 3.8 Database Design

### 3.8.1 Cloud Firestore Data Dictionary

**Table 5. `items`**: Lost and Found posts. Document ID: UUID v4 generated on the device.

| Field | Type | Constraint / Rule | Description |
|---|---|---|---|
| title | string | Required in the form | Item name |
| description | string | Required | Item description |
| category | string | One of: Electronics, Wallet, ID, Keys, Books, Others | Category |
| location | string | One of: Library, Classroom, Laboratory, Cafeteria, Gymnasium, Main Building, Other | Where the item was lost or found |
| date | string | Date chosen in the form | Date lost or found (stored as text) |
| status | string | `Lost` or `Found` (`Pending` is a legacy value treated as Found) | Report type |
| imageUrl | string | May be empty for Lost items | First photo (kept for older posts) |
| imageUrls | array<string> | 0–5 URLs | All photo URLs (Cloudinary) |
| username | string | | Poster's display name |
| ownerId | string | Must equal the signed-in user (rules) | Poster's user ID |
| verificationQuestion | string / null | Required for Found | Question that the claimant must answer |
| createdAt | timestamp | | Creation time |

**Table 6. `claims`**: Document ID: `{itemId}_{claimantId}` (one claim per user per item).

| Field | Type | Constraint / Rule | Description |
|---|---|---|---|
| itemId | string | Item must exist and be Found | Claimed item |
| itemTitle, itemImageUrl | string | Cannot change after creation | Copy of item info for display |
| claimantId | string | Must equal the signed-in user | Claimant |
| claimantName | string | | Claimant's display name |
| ownerId | string | Must equal the item's owner; cannot be the claimant | Finder |
| answer | string | Claimant may change it only when resending | Answer to the verification question |
| additionalDetails | string | Same as above | Extra proof of ownership |
| status | string | `Pending`, `Approved`, `Rejected` | Claim state |
| createdAt | timestamp | Cannot change | Submission time |

**Table 7. `conversations`**: Document ID: `{postId}_{uidA}_{uidB}`, with the two user IDs sorted.

| Field | Type | Constraint / Rule | Description |
|---|---|---|---|
| postId | string | Cannot change | Related item |
| itemName, itemImageUrl, itemType | string | Cannot change | Item info for the chat header |
| participantIds | array<string> | Exactly 2 different users, including the creator | Participants |
| participantNames | map | | Display names by user ID |
| lastMessage | string | Updatable | Preview text |
| lastMessageTime | timestamp | Updatable | For sorting |
| unreadCounts | map<uid,int> | Updatable | Unread messages per participant |

**Table 8. `conversations/{id}/messages`**

| Field | Type | Constraint / Rule | Description |
|---|---|---|---|
| senderId | string | Must equal the signed-in user | Sender |
| senderName | string | | Sender's name |
| text | string | 1–2000 characters | Message body |
| timestamp | timestamp | Cannot change | Send time |
| isRead | bool | Created as false; only the recipient may set it to true | Read flag |

**Table 9. `notifications`**: Document ID: auto-generated by Firestore.

| Field | Type | Constraint / Rule | Description |
|---|---|---|---|
| recipientId | string | Only the recipient can read or delete it | Receiver |
| type | string | Clients may create: `match`, `category_match`, `claim_received`, `claim_approved`, `claim_rejected`, `claim_update`, `message` | Event type (the app currently creates `category_match` and the three `claim_*` events) |
| title, message | string | | Display text |
| relatedItemId, relatedClaimId | string / null | | Links used when the notification is tapped |
| isRead | bool | The only field that may be updated | Read flag |
| createdAt | timestamp | | Creation time |

**Table 10. `termsAcceptances`**: Document ID: `{uid}_{version}`. Create-only.

| Field | Type | Rule |
|---|---|---|
| userId | string | Must equal the signed-in user |
| email | string | Must equal the token's email (case-insensitive) |
| version | string | Must equal the current version (`1.0`) |
| acceptedAt | timestamp | Must equal the server time |

**Table 11. `completedReturns`**: Document ID: same as the claim ID. Create-only. Created by the finder while the claim is Approved.

| Field | Type | Description |
|---|---|---|
| itemId, itemTitle | string | Returned item |
| ownerId | string | Finder (must be the signed-in user) |
| claimantId | string | Claimant (must match the claim) |
| completedAt | timestamp | Server time |

**Table 12. `feedback`**: Document ID: `{returnId}_{uid}`. Create-only, so each user can give feedback only once per return.

| Field | Type | Rule |
|---|---|---|
| returnId | string | The completed return must exist |
| itemTitle | string | |
| authorId | string | Must equal the signed-in user |
| role | string | `finder` or `claimant`, checked against the completed return |
| otherUserId | string | Must be the other participant |
| rating | int | 1–5 |
| recommendation | string | Up to 500 characters |
| createdAt | timestamp | Server time |

**Tables 13–14. `reports` and `users`**: These are **rule-only, planned** collections. The rules describe `reports` with the fields itemId, reporterId, reason (spam / inappropriate / harassment / scam / other), details (up to 300 characters), status and createdAt, and `users/{uid}` with the field `bannedUntil`. **The current app does not use them.**

### 3.8.2 Local Database (Drift / SQLite)

**Table 15. Local tables**

| Table | Copies | Extra columns for offline sync |
|---|---|---|
| `items` | `items` | `synced`, `pendingCreate`, `pendingUpdate`, `pendingDelete`, `updatedAt`, `localImagePath`, `localImagePaths` (photos not yet uploaded), `imageUrls` (JSON) |
| `claims` | `claims` | `synced`, `pendingCreate`, `pendingUpdate`, `updatedAt` |
| `conversations` | `conversations` | `viewerId` (which account owns the cached row), `participantIdsJson`, `otherUserId`, `otherUserName`, `unreadCount`, `pendingMarkRead` |
| `messages` | `messages` | `conversationId`, `content` (message text), `synced`, `pendingCreate` |
| `notifications` | `notifications` | `pendingMarkRead`. Also stores device-only "Report Posted" notices. |

---

## 3.9 Class Diagram

The diagram is simplified. It shows the main classes and their relationships, and leaves out the screens and the generated Drift code.

**Figure 8. Class Diagram**

```mermaid
classDiagram
    direction LR
    class ItemModel {
      +String id
      +String title
      +String description
      +String category
      +String location
      +String date
      +String status
      +List~String~ imageUrls
      +String ownerId
      +String? verificationQuestion
      +bool isSyncPending
      +fromDoc() ItemModel
      +toMap() Map
    }
    class ClaimModel {
      +String id
      +String itemId
      +String claimantId
      +String ownerId
      +String answer
      +String additionalDetails
      +String status
    }
    class ConversationModel {
      +String id
      +String postId
      +List~String~ participantIds
      +String otherUserName
      +String lastMessage
      +int unreadCount
    }
    class MessageModel {
      +String id
      +String senderId
      +String text
      +DateTime timestamp
      +bool isRead
    }
    class NotificationModel {
      +String id
      +String recipientId
      +String type
      +String title
      +String message
      +bool isRead
    }
    class CompletedReturn {
      +String id
      +String ownerId
      +String claimantId
      +hasParticipant(uid) bool
    }

    class AuthService {
      +register(email, password, name)
      +login(email, password)
      +resetPassword(email)
      +sendEmailVerification()
      +reloadAndCheckVerified() bool
      +signOut()
    }
    class TermsService {
      +String currentVersion$
      +hasAcceptedCurrent(uid) bool
      +recordAcceptance()
    }
    class ItemService
    class ClaimService {
      +submitClaim(item, answer, details)
      +updateClaimStatus(claimId, status)
    }
    class ChatService {
      +getOrCreateConversation(...) String
      +sendMessage(conversationId, text)
      +sendMessageWithId(...)
      +markConversationRead(id)
    }
    class NotificationService {
      +createNotification(...)
      +notifyLostUsersForFoundItem(item)
      +markAllAsRead()
    }
    class FeedbackService {
      +recordCompletedReturn(...)
      +submit(return, rating, recommendation)
    }
    class ItemMatchingService {
      +findMatches(item, candidates)$ List~ItemMatch~
      +findMatchesForDraft(title, category, status, candidates)$ List~ItemMatch~
    }
    class CloudinaryService {
      +uploadImage(File) String
    }

    class AppDatabase
    class ItemRepository {
      +reportItem(...)
      +deleteItem(id)
      +pushPending(uid)
    }
    class ClaimRepository
    class ChatRepository
    class NotificationRepository
    class SyncManager {
      +start()
      +setCurrentUserId(uid)
      +syncNow()
    }
    class ConnectivityService

    class AuthProvider
    class ItemProvider
    class ClaimProvider
    class ChatProvider
    class NotificationProvider

    AuthProvider --> AuthService
    ItemProvider --> ItemRepository
    ClaimProvider --> ClaimRepository
    ChatProvider --> ChatRepository
    NotificationProvider --> NotificationRepository

    ItemRepository --> AppDatabase
    ClaimRepository --> AppDatabase
    ChatRepository --> AppDatabase
    NotificationRepository --> AppDatabase
    ItemRepository --> ItemService
    ItemRepository --> CloudinaryService
    ItemRepository --> NotificationService
    ItemRepository ..> ItemMatchingService
    ClaimRepository --> ClaimService
    ChatRepository --> ChatService
    ClaimService --> ChatService
    ClaimService --> NotificationService
    ClaimService --> FeedbackService
    NotificationService ..> ItemMatchingService
    ItemService --> CloudinaryService

    SyncManager --> ConnectivityService
    SyncManager --> ItemRepository
    SyncManager --> ClaimRepository
    SyncManager --> ChatRepository
    SyncManager --> NotificationRepository

    ItemRepository ..> ItemModel
    ClaimService ..> ClaimModel
    ChatService ..> ConversationModel
    ChatService ..> MessageModel
    NotificationService ..> NotificationModel
    FeedbackService ..> CompletedReturn
```

---

## 3.10 Activity and Sequence Diagrams

**Figure 9. Activity Diagram: Report an Item**

```mermaid
flowchart TD
    A([Start]) --> B[Open Report Item]
    B --> C[Choose Lost or Found]
    C --> D[Enter name, category, location,<br/>date, description; add photos ≤ 5]
    D --> E{Found?}
    E -- Yes --> F[Enter verification question]
    E -- No --> G
    F --> G{All required fields valid?<br/>Found also needs ≥ 1 photo}
    G -- No --> H[Highlight errors and<br/>scroll to the first one] --> D
    G -- Yes --> I[Find possible matches of the<br/>opposite type in the local cache]
    I --> J{Matches found?}
    J -- Yes --> K[Show Possible Matches screen]
    K --> L{User choice}
    L -- Go back and edit --> D
    L -- Continue posting --> M
    J -- No --> M[Save item locally<br/>pendingCreate = true]
    M --> N{Online?}
    N -- No --> O[Keep in queue; SyncManager<br/>retries on reconnect / every 30 s] --> N
    N -- Yes --> P[Upload photos to Cloudinary]
    P --> Q[Write item to Firestore]
    Q --> R[Mark local row synced]
    R --> S{Found item?}
    S -- Yes --> T[Notify owners of similar Lost<br/>items in the same category]
    S -- No --> U
    T --> U[Add local 'Report Posted' notification]
    U --> V([End])
```

**Figure 10. Sequence Diagram: Claim, Approval and Return**

```mermaid
sequenceDiagram
    autonumber
    actor C as Claimant
    actor F as Finder
    participant App as LOFO App
    participant FS as Cloud Firestore

    C->>App: Open Found item → Claim Item
    C->>App: Enter answer + details → Submit
    App->>App: Save claim locally (pendingCreate)
    App->>FS: Create claims/{itemId}_{claimantId} (status Pending)
    FS-->>App: Rules check: claimant ≠ owner, item is Found
    App->>FS: Get or create conversation {postId}_{uidA}_{uidB}
    App->>FS: Add message "Claim request submitted…"
    App->>FS: Create notification (claim_received) for the finder
    F->>App: Open notification → conversation with claim panel
    alt Finder rejects
        F->>App: Tap Reject
        App->>FS: Update claim status = Rejected
        App->>FS: Notification (claim_rejected) for the claimant
        C->>App: Resend Claim with new answer (optional)
    else Finder approves
        F->>App: Tap Accept Claim
        App->>FS: Notification (claim_approved) for the claimant
        App->>FS: Update claim status = Approved
        App->>FS: Create completedReturns/{claimId}
        App->>FS: Delete messages, conversation, item, claim
        App-->>F: Confetti + optional feedback sheet
        C->>App: Open "Claim Approved" notification
        App-->>C: Confetti + optional feedback sheet
        C->>App: Rating and recommendation
        App->>FS: Create feedback/{claimId}_{uid}
    end
```

**Figure 11. Sequence Diagram: Offline Queue and Sync**

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant UI as Screen
    participant R as Repository
    participant DB as Local DB (Drift)
    participant SM as SyncManager
    participant CS as ConnectivityService
    participant FS as Firestore / Cloudinary

    U->>UI: Create report / claim / message (offline)
    UI->>R: write(...)
    R->>DB: Insert row (pendingCreate = true)
    DB-->>UI: Stream update — shown immediately
    R-xFS: Immediate push fails (no network)
    Note over R,DB: Row stays pending
    CS-->>SM: Connectivity changed: online
    SM->>R: pushPending(currentUserId)
    R->>DB: Read pending rows for this user
    R->>FS: Upload photos, write documents (same IDs)
    FS-->>R: Success
    R->>DB: Mark row synced
    alt Push failed again
        SM->>SM: Schedule retry in 30 seconds
    end
    FS-->>R: Firestore listener: server snapshot
    R->>DB: Merge (rows with pending changes are not overwritten)
```

---

## 3.11 User-Interface Design

**Design approach.** The app uses Flutter Material components with one custom theme (`lib/theme/app_theme.dart`). The main screens are reached from a **bottom navigation bar with five tabs**: Home, Messages, My Posts, Notifications and Profile. The Notifications tab shows a badge with the unread count. The report form is divided into numbered steps. It shows errors next to the fields and scrolls to the first error.

**Figure 12. Screen-Flow Diagram**

```mermaid
flowchart TD
    SP[Splash Screen] -->|not signed in| LG[Login]
    SP -->|signed in| AG{Access Gate}
    LG --> RG[Register]
    LG --> FP[Forgot Password]
    LG -->|success| AG
    RG -->|account created| AG
    AG -->|email not verified| VE[Verify Email]
    VE -->|verified| AG
    AG -->|terms not accepted| TS[Terms of Service]
    TS -->|I Accept| AG
    TS -->|Decline| LG
    AG -->|allowed| MN[Main Navigation]

    MN --> H[Home]
    MN --> MS[Messages]
    MN --> MP[My Posts]
    MN --> NT[Notifications]
    MN --> PR[Profile]

    H --> RI[Report Item]
    RI --> DM[Possible Matches before posting]
    DM --> ID
    H --> ID[Item Details]
    ID --> CI[Claim Item]
    ID --> CV[Conversation]
    MS --> CV
    MP --> PM[Potential Matches] --> ID
    MP --> ID
    NT --> ID
    NT --> CV
    CV -->|approve| FB[Feedback Sheet]
    NT -->|claim approved| FB
    PR --> LG
```

[[INSERT WIREFRAMES OR DESIGN MOCK-UPS HERE, IF YOU MADE ANY. Otherwise the screenshots in 4.3 are enough.]]

---

## 3.12 Hardware and Software Requirements

**Table 16. Hardware Requirements**

| Purpose | Minimum / Used | Notes |
|---|---|---|
| End user | Android smartphone running [[minimum Android version — the build uses Flutter's default `minSdkVersion`; confirm with `flutter build apk` output or Android Studio]] | Camera or gallery for photos; internet connection for syncing |
| Development computer | [[CPU, RAM, storage of the computer you used]] | Windows 11 was used during development |
| Test device(s) | [[PHONE MODEL(S) AND ANDROID VERSION(S)]] | |

**Table 17. Software Requirements**

| Software | Version | Purpose |
|---|---|---|
| Android OS (end user) | [[ ]] | Runs the app |
| Flutter SDK | [[run `flutter --version`]] | App framework |
| Dart SDK | ^3.12.2 (from `pubspec.yaml`) | Programming language |
| Android Studio / IntelliJ IDE | [[version]] | IDE (the project contains `.idea` and `.iml` files) |
| Firebase CLI | [[version]] | Deploying rules and indexes; rules tests |
| Node.js | [[version]] | Running the Firestore rules tests |
| Java (JDK) | [[version]] | Needed by the Firestore emulator |

---

## 3.13 Development Tools and Technologies

**Table 18. Development Tools and Technologies**

| Tool / Library | Role in LOFO |
|---|---|
| **Flutter / Dart** | Cross-platform UI framework and language |
| **provider** | State management (ChangeNotifier providers) |
| **firebase_core, firebase_auth** | Firebase initialization; accounts, email verification, password reset |
| **cloud_firestore** | Cloud database, real-time listeners, transactions and batches |
| **Firestore Security Rules and Indexes** | Server-side access control; composite indexes for queries |
| **Cloudinary (REST API through `http`)** | Photo upload and hosting |
| **cached_network_image** | Caching of downloaded photos |
| **image_picker** | Picking photos from the camera or gallery |
| **drift, sqlite3, sqlite3_flutter_libs, path_provider, path** | Local SQLite database for offline-first storage |
| **connectivity_plus** | Detecting when the device goes online or offline |
| **shared_preferences** | Remembered accounts and cached Terms acceptance |
| **uuid** | Generating document IDs on the device |
| **build_runner, drift_dev** | Code generation for the Drift database |
| **flutter_test, flutter_lints** | Unit and widget tests; static analysis |
| **@firebase/rules-unit-testing + Firebase Emulator** | Automated tests of the Firestore Security Rules |
| **Git** | Version control |

> `firebase_storage` is listed in `pubspec.yaml` and `storage.rules` exists, but **the app does not use Firebase Storage**. Photos go to Cloudinary. You may remove the dependency, or mention it only as unused.
