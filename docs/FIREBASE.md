# I-Crash: Firebase backend

Everything about the backend: what exists, how to run it locally, how to work with the
cloud project, how to set one up from zero, the data model and the security rules.
This document replaces `FIREBASE_MODEL.md`.

Updated 29 Oct 2026 (database decisions of 28 Oct: no overfill, drawer numbers and slot
documents, `drawerId`, batches never deleted, the `usedAt` structure lock, admin-set PIN and
password). Files live in [`firebase/`](../firebase); app-side code is in
`app/lib/src/data/firebase/`.

> **New direction (18 Oct 2026):** each institution is to run I-Crash on **its own local
> server**, with a relational (PostgreSQL) database designed in [DATABASE.md](DATABASE.md).
> Whether Firebase stays, and in what role, is decided in the security/hosting phase. Until
> then this document describes the backend the app **runs on today**. How each Firestore
> collection maps to the relational model, and what differs, is in §10.

---

## 1. What we use

| Product | Used | Notes |
|---|---|---|
| **Authentication** | Yes | E-mail and password only |
| **Cloud Firestore** | Yes | Native mode, location `eur3` (Europe, multi-region). The location can never be changed |
| Storage, Cloud Functions, Hosting | **No** | The project is on the free **Spark** plan; no billing is authorised. Anything that needs Functions (server-side PIN, signed-report service, invites by e-mail link) needs the Blaze plan first |

| Environment | Project id | `.firebaserc` alias | Used by |
|---|---|---|---|
| Local emulators | `demo-icrash-v2` | `default`, `local` | Debug builds (automatic). A `demo-` project can't reach the cloud even by mistake |
| Cloud | `i-crash-pt-2026` | `development` | Release builds (automatic), or debug with `--dart-define=ICRASH_BACKEND=cloud` |

The rules and indexes in `firebase/` are **deployed to `i-crash-pt-2026`** (last
deployed 9 Sep 2026).

### Files

```
firebase/
├── .firebaserc              project aliases (above)
├── firebase.json            emulator ports; points at the rules and indexes files
├── firestore.rules          security rules (§6)
├── firestore.indexes.json   composite indexes (§7)
├── firestore-tests/         rules tests + emulator seed scripts (never touch the cloud)
│   ├── rules.test.mjs
│   └── seed_qa_run.mjs      wipes the emulator, then 5 users, 2 institutions, 3 carts
└── tools/
    └── provision_cloud_admins.mjs   creates the first admins in the REAL project
```

App side: `app/firebase.json` and `app/lib/firebase_options.dart` (FlutterFire config)
and `app/android/app/google-services.json`. These contain public client identifiers, not
secrets.

There is **no `GoogleService-Info.plist`** for iOS or macOS: those platforms take their
config only from `firebase_options.dart`. Worth checking when the iOS build is fixed.

---

## 2. Local development (every developer)

### Prerequisites
- **Node.js** (LTS) and the Firebase CLI: `npm install -g firebase-tools`
- **Java** (a recent JDK; the Firestore emulator runs on it)
- Flutter, for the app (see the README)

No Firebase login is needed for the emulators: the `demo-` project id works offline.

### Run
```sh
# Terminal 1: emulators (Auth :9099, Firestore :8081, UI http://127.0.0.1:4000)
cd firebase
firebase emulators:start --only auth,firestore --project demo-icrash-v2

# Terminal 2: test data (emulator data is wiped on every restart, so re-seed each time)
cd firebase/firestore-tests
npm install            # first time only
node seed_qa_run.mjs   # or: npm run seed

# Terminal 3: the app (debug → emulator automatically)
cd app
flutter run
```

`seed_qa_run.mjs` (also `npm run seed`) creates these accounts (2 Nov 2026):

| Account | E-mail | Type | PIN | Nº mecanográfico |
|---|---|---|---|---|
| super | `super.teste@icrash.pt` | **Super** (I-Crash team): no membership, a `platformAdmins` marker; picks Hospital A or B (both have a 7-day support window open) | `0001` | — |
| adminA | `admin.teste@icrash.ia.pt` | **Admin** of Hospital A (its IT): users, carts, catalogue… | `1000` | A100 |
| adminB | `admin.teste@icrash.ib.pt` | **Admin** of Hospital B | `2000` | B200 |
| userA | `user.teste@icrash.ia.pt` | **Manager** in Hospital A (health professional), registered to Carro de Urgência A1 only | `1001` | A101 |
| userB | `user.teste@icrash.ib.pt` | **Manager** in Hospital B, registered to Carro de Urgência B1 only | `2001` | B201 |

Password for every account: **`icrash-teste-123`**. Carts: Hospital A has **A1** (userA)
and **A2** (nobody registered, so only adminA sees it); Hospital B has **B1** (userB). Each
cart has 2 drawers of 2 × 2 (drawer 1 named "Via aérea e circulação", drawer 2 unnamed). A1
and B1 hold an OK placement, one expiring in 12 days, one expired 10 days ago and one below
target; A2 is all OK. Expiry dates are relative to the day the seed runs. **The seed wipes
the emulator first** (every Auth account and Firestore document, tablets included).

### How the app finds the emulator
`app/lib/src/common/app_environment.dart` and
`app/lib/src/data/firebase/firebase_bootstrap.dart`:

- **Host:** the Android emulator reaches your computer at `10.0.2.2`; everything else
  uses `127.0.0.1`. This is automatic.
- **Separate named app:** emulator mode starts a **separate named `FirebaseApp`** with
  the `demo-icrash-v2` project id. Two reasons:
  - Android/iOS/macOS auto-start the default app with the real project's config, so
    re-initialising `[DEFAULT]` crashes (`duplicate-app`).
  - The emulator evaluates rules per project id, and collection-group queries fail if
    the id doesn't match.
- **Don't simplify this back to one default app.** Both bugs come back.

### Rules tests
Run them before **any** change to `firestore.rules` is deployed:
```sh
cd firebase
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```
They cover:
- unauthenticated access and cross-institution isolation;
- cart access for assigned, unassigned and manager users;
- what a normal user may write;
- drawer structure;
- no self-escalation;
- immutable history;
- the `memberIndex` and cross-cart `assignments` queries.

---

## 3. The cloud project (`i-crash-pt-2026`)

**Access:**
- Ask an owner (Martim or Pedro) to add you in Firebase Console › Project settings ›
  Users and permissions.
- Then run `firebase login`.
- From `firebase/`, the alias `--project development` targets the cloud.

### Deploying rules and indexes
Only after the rules tests pass and **an owner has agreed**:
```sh
cd firebase
firebase deploy --only firestore:rules,firestore:indexes --project development
```
- Never deploy permissive "temporary" rules to bootstrap data. Use the Admin SDK tool
  below.
- The emulator ignores indexes; the cloud needs them, so a query that works locally can
  fail in the cloud until its index is deployed.

### Creating the first administrators
The rules make `platformAdmins` unwritable from any client, and only a platform admin can
create an institution. That chicken-and-egg is deliberate: the first admin has to be
created with the **Admin SDK**, which bypasses the rules.

1. In Firebase Console › Authentication, **create the user accounts** (e-mail and
   password).
2. Console › Project settings › Service accounts › **Generate new private key**. Save it
   **outside the repository**, and delete it when you're done: it grants full access.
3. Run:
   ```sh
   cd firebase/tools
   npm install
   ICRASH_ADMIN_EMAILS="a@example.com,b@example.com" node provision_cloud_admins.mjs ~/keys/i-crash-key.json
   ```
   - The script refuses keys from any other project.
   - It writes `platformAdmins/{uid}`, the institution `icrash-hq`, and an
     `institutionAdmin` membership plus `memberIndex` for each user, then reads them back
     to verify.
   - Safe to re-run.

Everything else (members, carts, products) is then created from inside the app.

4. **PINs for the first administrators.** Nobody can set their own PIN, not even an
   admin (DB3), and these first admins have no other admin to do it. Set it with the same
   key, only with a project owner's explicit OK:
   ```sh
   node set_password.mjs --cloud ~/keys/i-crash-key.json --email a@example.com --pin 1234 --institution icrash-hq
   ```
   After that, each administrator sets the others' PINs in B7.

### Release builds
A release build talks to the cloud by default. Never point a release build at the
emulator. Signing and store steps are in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).

---

## 4. Setting up a new Firebase project from zero

Only needed for a new environment (e.g. a separate production project, or a client's own
instance).

1. **Create the project** in the Firebase Console. Keep it on Spark unless billing is
   approved.
2. **Firestore:** create the database in **Native mode**. Pick the location carefully
   (`eur3` for Portugal and the EU); it can't be changed later.
3. **Authentication:** enable the **Email/Password** provider.
4. **Register the apps** with FlutterFire, from `app/`:
   ```sh
   dart pub global activate flutterfire_cli
   flutterfire configure --project <new-project-id>
   ```
   - This regenerates `lib/firebase_options.dart`, `android/app/google-services.json`
     and `app/firebase.json` (and can add iOS/macOS `GoogleService-Info.plist` files).
   - Bundle ids: Android/iOS `pt.icrash.app`, macOS `pt.icrash.app.macos`.
5. **Point the tooling at it:**
   - add an alias in `firebase/.firebaserc`;
   - change `EXPECTED_PROJECT_ID` in `firebase/tools/provision_cloud_admins.mjs`;
   - update the project id named in this document and the README.
6. **Deploy** the rules and indexes (§3) to the new project.
7. **Provision** the first admins (§3). Change `INSTITUTION_ID` / `INSTITUTION` in the
   script if the first institution isn't I-Crash's own.
8. **Check:** sign in from a release build, or from a debug build with
   `--dart-define=ICRASH_BACKEND=cloud`.

---

## 5. Data model

### Collections

Everything an institution owns sits under `institutions/{institutionId}`. The
institution is the **tenancy root**, and every rule checks it.

```
platformAdmins/{uid}                         marker: platform super admin (Engineer Admin)

institutions/{institutionId}                 name, expiryWarningDays, createdBy
  memberships/{uid}                          uid, role, status, displayName, email, service
    private/credentials                      pinHash (DB3; see §9)
  memberIndex/{uid}                          uid, status  (copy for the "my institutions" query)
  products/{productId}                       name, unitDescription, description, gtin,
                                             category, expiryWarningDays
  carts/{cartId}                             name, status, service, location, archived,
                                             layoutVersion, templateId, responsibleUserIds[]
    responsibleUsers/{uid}                   who may access the cart (non-managers)
    drawers/{drawerId}                       number, name?, rows, columns, usedAt?
      slots/{slotId}                         row, column, rowSpan, columnSpan, label?, usedAt?
    assignments/{assignmentId}               institutionId, cartId, drawerId, slotId, productId,
                                             currentQuantity, targetQuantity,
                                             earliestKnownExpiry?, usedAt?, updatedAt/By
      batches/{batchId}                      expiryDate, quantity, lotNumber?, gtin?,
                                             source (manual | gs1DataMatrix | periodicAudit),
                                             removedAt?, createdBy
  usageEvents/{eventId}      IMMUTABLE       type (consumption | replenishment | correction |
                                             auditReconciliation), cartId, assignmentId,
                                             productId, amount (signed), actorUid,
                                             correctsEventId?, reason?, batchId?, serverTimestamp
  auditEvents/{eventId}      IMMUTABLE       type, actorUid, cartId?, drawerId?, slotId?,
                                             productId?, previousValue, newValue,
                                             correctionRef?, metadata
```

- **Paths:** all of them are defined once in `app/lib/src/data/firebase/firestore_paths.dart`.
- **Entities:** the Dart versions are in `app/lib/src/domain/entities/`.
- **New in design v2 (Oct 2026):** cart `service`, `location` and `archived`; membership
  `displayName`, `email` and `service`; product `category` and `expiryWarningDays`.
- **Changed 29 Oct 2026 (database decisions of 28 Oct):**
  - Drawers have a **`number`** (unique in the cart, checked by the app) and an
    optional **`name`** (D20, 30 Oct: 1–50 characters, checked by the rules; no field when
    there's none; a used drawer may be renamed). A drawer is created **together with its slot documents** (one per cell, or a
    template's layout), in one batch.
  - Slot **rows and columns stay 0-based in Firestore** (`r0c0` is the top-left cell).
    DATABASE.md counts from 1; add 1 when the data moves to PostgreSQL.
  - Assignments store **`drawerId`**: slot ids repeat in every drawer, so a slot is only
    unambiguous with its drawer. `minimumQuantity` (D10) and the stale `status` are no
    longer written; old documents may still have them and they're ignored.
  - Batches are **never deleted** (DB1): a batch confirmed gone gets `removedAt`. The
    lot number is optional (P9); a new batch needs `quantity > 0` and `expiryDate`.
  - Events: corrections may carry a `reason` (≤ 500 characters); replenishments store
    the `batchId` they created. `localTimestamp` is declared but never written.
  - GTINs are stored padded to **14 digits** (P16); lookups also match older unpadded
    values.
- **Firestore-only helper field `usedAt`** (no column in DATABASE.md): the first History
  event of a placement (consumption, replenishment, correction or reconciliation) sets
  `usedAt` on the placement, its slot and its drawer, in the same transaction as the
  event. The rules can't query `usageEvents`, so this marker is what lets them refuse to
  delete or reshape a used structure (P1/P2). In the relational model the same rule comes
  from the foreign keys and the trigger in DATABASE.md §2.3. Placements used before
  29 Oct 2026 have no marker; the app also reads the cart's history
  (`UsageRepository.watchUsedAssignmentIds`), so the UI blocks them anyway.
- **Values:**
  - Roles (D16, done 30 Oct): `institutionAdmin` (**Admin**) and `manager` (**Manager**);
    **Super** is a `platformAdmins/{uid}` marker. A stored `user` membership reads as
    `manager` (app and rules). **`device`** (D17, done 31 Oct): a registered tablet's own
    account.
  - **Registered tablets (D17):** `institutions/{i}/devices/{deviceId}` (`name`, `cartIds[]`,
    `authUid`, `registeredBy`, `registeredByName`, `registeredAt`, `revokedAt?`); the tablet's
    membership (`role: 'device'`, `deviceId`, `displayName` = name) and its entries in each
    bound cart's `responsibleUsers` + `responsibleUserIds`, written in one batch by the Admin.
    The account is created like a B7 user (isolated Auth), e-mail
    `device-{id}@{institutionId}.devices.icrash.invalid`, 32-character random password.
    Rules: `isDevice(i)`; a tablet may read the PIN hashes of its institution; a usage event
    from a tablet carries the person as `actorUid`, who must be an active non-device member who
    is the Admin or registered to the cart (`actorMayUseCart`); `devices/*` is written by the
    Admin only and read by the Admin or the tablet itself; revoking sets `revokedAt`, disables
    the membership and unregisters it from its carts. A client can't delete the Auth account
    (Spark); IT can with the Admin SDK. Security limits: `DESIGN_D17_D18.md` §4.
  - Memberships may carry **`userNumber`** (nº mecanográfico, D17), unique per institution
    (checked by the app).
  - **Support access (D18, done 30 Oct):** `institutions/{i}/support/current` (`grantId`,
    `reason`, `grantedBy`, `grantedByName`, `startsAt`, `endsAt`, `closedAt?`, `closedBy?`)
    is the window in force; `supportGrants/{grantId}` keeps every window;
    Super's own PIN hash is `platformAdmins/{uid}.pinHash` (readable by Super only; set by
    I-Crash, e.g. the seed); `supportLog/{id}`
    (`superUid`, `superEmail`, `grantId`, `action` enter/leave, `at`) is what Super did.
  - Membership status: `active`, `invited`, `disabled`.
  - Cart status: `operational`, `replenishmentRequired`, `auditRequired`,
    `outOfService`.

### Fields that are copies on purpose
Firestore rules can only check what a query filters on, so a few values are stored twice.
**Whoever writes one must write the other, in the same `WriteBatch`:**

| Copy | Of | Why |
|---|---|---|
| `memberIndex/{uid}` | `memberships/{uid}` (uid, status) | The "which institutions am I in" collection-group query (§6) |
| `carts.responsibleUserIds[]` | the `responsibleUsers` subcollection | A normal user lists their carts with `array-contains` |
| `assignments.institutionId`, `.cartId` | the document path | The cross-cart alerts collection-group query. Set at creation and never changeable |

The app already does this in `FirestoreInstitutionRepository` (members) and
`FirestoreCartRepository` (responsible users).

### Not in Firestore yet (local stubs on the device)
Reports and signatures, monthly-check drafts, emergency sessions, cart templates,
shifts, permission toggles, the per-cart automatic-state switch, and the saved device
session with its cached copy of the PIN hash (the PIN itself is set in Firestore, §9).
They live in SharedPreferences (`app/lib/src/data/local/`, keys prefixed
`icrash.local.`).

The proposed Firestore shape for them (`reports/…/signatures`, `shifts`, `templates`,
`checks/…`, a `users/{uid}` profile, and so on) is in the conceptual data model of
14 Oct 2026 (claude.ai project "I-Crash", `database-model-2026-10-14.md`). Moving a stub
to Firestore means adding the collection, its rules and tests, and swapping the
implementation in `AppServices`.

**Superseded for the relational version:** the model of 18 Oct in
[DATABASE.md](DATABASE.md) covers these too (reports, report items and signing; templates;
permissions; the automatic-state switch; a server-checked PIN). See §10.

---

## 6. Security rules

`firestore.rules` is **deny by default**: every collection is closed unless a rule opens
it.

| Helper | Meaning |
|---|---|
| `isMember(i)` | Signed in, with an `active` membership in institution `i` |
| `isManagerOrAbove(i)` | Role `manager` or `institutionAdmin` in `i`, or a platform admin |
| `isInstitutionAdmin(i)` | Role `institutionAdmin` in `i`, or a platform admin |
| `canAccessCart(i, c)` | Manager+, or a `responsibleUsers/{uid}` document on the cart |

| Collection | Read | Write |
|---|---|---|
| `platformAdmins/{uid}` | Only your own document | **Nobody** (Admin SDK only) |
| `institutions/{i}` | Members; Super gets and lists every institution (name only matters: to find open windows) | Create: platform admin. Update: institution admin (name, expiry warning only). Delete: nobody |
| `memberships/{uid}` | Members | Institution admin, **never your own document** (no self-escalation or self-reactivation) |
| `memberships/{uid}/private/credentials` | That user (active) and the institution's own Admin (**never Super**, D18) | The institution's own Admin, **never for yourself**, only a `pbkdf2-sha256$…` hash. Delete: nobody |
| `memberIndex/{uid}` | Only your own entry | Institution admin |
| `products` | Members | Admin (D16) |
| `carts/{c}` | Get: `canAccessCart` (Admin, or a Manager registered to the cart). List: Admin/Super unfiltered; a Manager must filter `responsibleUserIds array-contains <uid>` | Create: Admin. Update: Admin; a registered Manager **only `status`** (`updateCartStatus`). **Delete: nobody** (archive instead) |
| `responsibleUsers` | `canAccessCart` | Admin (P18) |
| `drawers` | `canAccessCart` | Create/update: Admin. **Delete: nobody.** A used drawer keeps `rows`, `columns` and `number` (a used drawer that never had a number may get one, Q8); it may be renamed (D20). Anyone who can access the cart may set `usedAt` once |
| `slots` | `canAccessCart` | Create/update: Admin; a used slot keeps `row`, `column` and spans. **Delete: Admin, only while unused.** Anyone who can access the cart may set `usedAt` once |
| `assignments` | `canAccessCart` | Admin. A registered Manager may change **only** `currentQuantity`, `earliestKnownExpiry`, `updatedAt`, `updatedBy` and `usedAt` (consumption, replenishment, monthly check). Always `0 ≤ currentQuantity ≤ targetQuantity` and `targetQuantity > 0` (P5); an old overfilled placement may still be lowered. A used placement keeps `slotId`, `drawerId` and `productId`. **Delete: Admin, only while unused.** `institutionId`/`cartId` must match the path and never change |
| `batches` | `canAccessCart` | Create: whoever may access the cart, with `quantity > 0`, `expiryDate` and no `removedAt`. Update: **only** setting `removedAt` (+ `updatedAt`), once; it can't be cleared, not even by an Admin (P21). **Delete: nobody** (DB1) |
| `usedAt` (drawers, slots, assignments) | — | May only go from absent to the request time; never changes or disappears afterwards |
| `support/current` (D18) | The institution's own Admin; any Super (to list open windows) | The institution's own Admin only (never Super): open with a reason (1–500) and `endsAt` ≤ now + 7 days; close by adding only `closedAt` (= request time) and `closedBy`. **Delete: nobody** |
| `supportGrants` (D18) | Own Admin; Super | Create: own Admin; update: only `closedAt`/`closedBy`, once. **Delete: nobody** |
| `supportLog` (D18) | Own Admin; Super | Create: Super, as itself, **only inside an open window**, action `enter`/`leave`. **Update and delete: nobody** |
| `usageEvents` | Members | Create only, as yourself, for a cart you can access; `reason` optional, ≤ 500 characters. **Update and delete: nobody, not even admins** |
| `auditEvents` | Manager+ | Create only, as yourself. **Update and delete: nobody** |
| Collection group `assignments` | Manager+ only (cross-cart alerts) | — |

### Rules quirks (confirmed against the emulator; don't "clean them up")
1. **`memberIndex` exists** because a collection-group query needs a `{path=**}` rule,
   and putting one on `memberships` broke the nested rule in the emulator.
   - Inside a `list` rule, the path wildcard right after `{path=**}` can't be used.
     Read `resource.data.uid` instead (that's why the documents store their own `uid`).
2. **A `list` rule may only read `resource.data` fields the query filters on.**
   - That's why the cross-cart `assignments` query is **Admin/Super only** (D16; a Manager reads their carts one by one): checking the
     user's cart would need `cartId`, which the query doesn't filter on, and the whole
     query fails.
   - A normal user still sees their own carts' assignments through the per-cart query.
3. **`carts` splits `get` and `list`** for the same reason. A normal user's cart list
   must use exactly the `responsibleUserIds array-contains` shape.

### Rules that conflict with the product direction
- Health professionals are meant to replenish, reconcile and change consumables (D2),
  but the rules let them change only `currentQuantity`.
- When D2's permission set is final, update the assignment and batch rules and their
  tests together.

---

## 7. Indexes

| Index | Backs |
|---|---|
| Collection group `memberIndex`: `uid` ↑, `status` ↑ | `InstitutionRepository.watchMyInstitutions` |
| Collection `usageEvents`: `assignmentId` ↑, `serverTimestamp` ↓ | `UsageRepository.watchEventsForAssignment` |
| Field override `assignments.institutionId` (collection and collection group) | The cross-cart alerts query |

When you add a query with several filters or an order on another field, add its index
here and deploy it. The cloud returns an error with a link that creates the index; copy
the result into `firestore.indexes.json` so it's versioned.

---

## 8. Inventory rules (how stock data must change)

Enforced in `app/lib/src/domain/inventory_rules.dart`, tested in
`app/test/domain/inventory_rules_test.dart`. These are clinical decisions (reasoning in
[DOMAIN.md](DOMAIN.md) §22–28). Don't change them to fit code.

| Operation | Changes | Never |
|---|---|---|
| **Consumption** | Lowers `currentQuantity`; appends a `consumption` event | Never touches batches or `earliestKnownExpiry`; never guesses which lot (no FIFO/FEFO); never below 0 |
| **Replenishment** | Raises `currentQuantity` up to the target; adds a batch (lot optional); moves `earliestKnownExpiry` **earlier** if the new batch expires sooner; the event stores `batchId` | Never moves the expiry later; never above the target (P5) |
| **Reconciliation** (after a physical audit) | One transaction: sets the confirmed quantity, recomputes the expiry from the confirmed batches, marks the other batches `removedAt`, appends the event | The only operation allowed to do this; never deletes a batch |
| **Correction** | Appends a compensating event with `correctsEventId` and an optional `reason`; stays within `0 … target` | Never edits or deletes the original event |

Every one of these sets the `usedAt` marker on the placement, slot and drawer the first
time (§5).

`currentQuantity` is allowed to differ from the sum of the lots between an emergency and
the next audit.

**Known issue:** consumption, replenishment and correction currently use
`runTransaction`, which **fails offline**. The planned fix:
- write them as a `WriteBatch` with `FieldValue.increment` plus the immutable event, so
  they queue offline;
- decide the conflict policy when two devices edit the same slot (D14).

---

## 9. Authentication details

**DB3 (28 Oct): the administration sets credentials; users can't change their own.**
Implemented 29 Oct 2026 as an interim under Firebase:

- **Sign-in:** e-mail and password (unchanged; each institution's login method is
  defined last). There is **no password-reset e-mail** and no "forgot password" in A1.
- **Creating a member (B7 "Criar utilizador"):** the administrator types the person's
  password (at least 8 characters) and PIN. The app creates the Auth account with that
  password on a **throwaway secondary `FirebaseApp`** (`createIsolatedAccountCreationAuth`;
  creating a user signs in as that user on whichever app runs it, and this keeps the admin
  signed in), then writes `memberships` + `memberIndex` + `private/credentials` in one
  batch. The member is created `active`; the administrator hands over both credentials.
- **PIN:** a salted, slow hash, `pbkdf2-sha256$<iterations>$<salt>$<hash>`
  (PBKDF2-HMAC-SHA256, 16-byte salt, 32-byte key; `app/lib/src/services/pin_hasher.dart`
  with package `cryptography`; the Node scripts use `crypto.pbkdf2Sync`,
  `firebase/firestore-tests/pin_hash.mjs`). It's stored in
  `memberships/{uid}/private/credentials`, not on the membership, because every member can
  read memberships. Only institution admins write it (never their own); only that user and
  admins read it. After each online sign-in the device copies the hash
  (`AppRootViewModel._refreshPin`) and checks A2 unlock and A9 signing against it,
  offline too; five wrong tries still drop the saved session. An administrator changes a
  PIN in B7 ("Definir novo PIN"); it takes effect on a tablet at the next online sign-in
  there. The iteration count travels with each hash, so `PinHasher.defaultIterations`
  (60 000) can be tuned to about 0.2 s on a cart tablet without invalidating PINs.
- **⚠ Prototype measure.** The user's device can read their own PIN hash, and a 4-digit
  PIN has only 10 000 values: anyone who gets the hash can brute-force it offline, slow
  hash or not. This is acceptable only for the prototype. The real check moves to the
  institution's server (DATABASE.md USER `pinHash`), which never hands out the hash and
  limits attempts.
- **Resetting another user's password:** on the Spark plan a client can't change
  **another** user's Firebase password (that needs the Admin SDK, i.e. Cloud Functions,
  which need billing). So B7's "Redefinir palavra-passe" only tells the administrator to
  ask technical support, and IT runs `firebase/tools/set_password.mjs` (Admin SDK) on
  their own computer:
  ```sh
  cd firebase/tools && npm install
  # emulator (default):
  node set_password.mjs --email user.teste@icrash.ia.pt --password 'nova-palavra-1' --pin 4321 --institution hospital-a
  # cloud, only with a project owner's explicit OK and a key kept outside the repo:
  node set_password.mjs --cloud ~/keys/i-crash-key.json --email … --password …
  ```
- **⚠ Users can still change their own password through the SDK.** The app offers no
  way to, but Firebase Auth lets any signed-in user call `updatePassword` on their own
  account from a modified client, and on Spark this can't be blocked. Under the
  institution's own login (DATABASE.md) only the administration can change credentials.
- **First administrators:** see §3 "Creating the first administrators" (their PIN is set
  with `set_password.mjs`).

---

## 10. Mapping to the relational model (DATABASE.md)

How the Firestore data model (§5) corresponds to the PostgreSQL design for the local-server
version. Table names are those of DATABASE.md part 2.

| Firestore | Relational table | Differences |
|---|---|---|
| `platformAdmins/{uid}` | USER with UserType "Engineer Admin" | No separate marker. Each server holds one institution |
| `institutions/{i}` | INSTITUTION | One row per server. `createdBy` isn't kept |
| `memberships/{uid}`, `memberIndex/{uid}` | USER (`idInstitution`, `idUserType`) | **A user belongs to one institution** (two hospitals = two accounts), so `memberIndex` isn't needed. Login is by `userNumber`, not e-mail (`email` is optional). Membership `status` (active / invited / disabled) has no equivalent yet (DB11). Membership `service` isn't kept |
| Roles (`Role`) and permission toggles (local stub) | USERTYPE, PERMISSION, USERTYPEPERMISSION | Permissions per user type are data |
| `products/{p}` | CLINICALCONSUMABLE + CATEGORY | `unitDescription` → `weight` / `volume`. `category` is a lookup table. The per-product `expiryWarningDays` isn't modelled (DB12) |
| `carts/{c}` | CRASHCART + CARTSTATE | `status` → CARTSTATE. `service` → DEPARTMENT (with `floor`). `templateId` → `idCrashCartTemplate`. `layoutVersion` isn't modelled (DB12). The auto-state switch (local stub) → `autoState` |
| `carts/{c}/responsibleUsers`, `responsibleUserIds[]` | CRASHCARTUSER | One table instead of a subcollection plus a copied array. Shifts (local stub) aren't modelled yet (DB5) |
| `drawers/{d}` | DRAWER | `number` → `number` (UNIQUE per cart there; checked by the app here). `name` → `name` (optional, D20). `usedAt` isn't a column: a used drawer is one whose slots History points to |
| `slots/{s}` | SLOT | Rows and columns are **0-based here, 1-based there: add 1 at migration**. `label` isn't stored (calculated). The key includes the drawer and cart, so slot ids no longer clash between drawers. `usedAt` isn't a column |
| `assignments/{a}` | SLOTCC + SLOTSTATE | `currentQuantity` → `currNumberCC`, `targetQuantity` → `maxNumberCC` (`0 ≤ curr ≤ max`, enforced here too). `drawerId` + `slotId` → (`idSlot`, `idDrawer`). `minimumQuantity` is gone (D10). `earliestKnownExpiry` → `earliestExpirationDate`, **derived** from the batches. Slot state is computed by the app (DB9 storage open). `usedAt` isn't a column (the FKs + §2.3 trigger do its job). The copied `institutionId`/`cartId` aren't needed |
| `assignments/{a}/batches/{b}` | BATCH | `expiryDate` → `expirationDate` (month-only dates = last day, P11), `quantity` (> 0), `lotNumber` optional, `removedAt` (never deleted) — all as in the design. Not yet one batch per expiry date: same-date batches aren't merged (P10 open). `gtin`, `source` and `createdBy` aren't stored on the batch there; who created it is on the History row |
| `usageEvents/{e}` | HISTORY + HISTORYTYPE | `type` → HISTORYTYPE (Consumption, Replenishment, Discard, Correction, Count; Discard/Count wait on P7). `correctsEventId` → `idHistoryCorrection`. `actorUid` → `idUser`. `reason` → `reason`. `batchId` → `idBatch` (replenishments). One `createdAt` instead of local and server timestamps. The report link (R28) isn't written yet |
| `memberships/{uid}/private/credentials` | USER `pinHash` | Same encoded-hash idea. There the server checks the PIN and never returns the hash |
| `auditEvents/{e}` | — | The administrative log isn't modelled; left to the security phase (DB12) |
| Reports, signatures, check drafts (local stubs) | REPORT, REPORTSTATUS, REPORTITEM, RESULTITEM | A monthly check lists only expired and expiring batches (D4). The signer is the user who performed the check (DB4) |
| Emergency sessions (local stub) | REPORT with `isEmergency` = true | The consumption rows recorded during it point to the report |
| Cart templates (local stub) | CRASHCART with `isTemplate` = true | Same tables as a real cart |
| Device session and PIN (local stub) | USER `pinHash`, `passwordHash` | Checked by the server, not the device |
| Firestore Rules (§6) | — | Security on the local server (database privileges, triggers, API) is designed in the security phase |

---

## 11. Migrating existing data in `i-crash-pt-2026` (not done)

The 29 Oct 2026 changes were made **without migrating** the cloud project; the app reads
old documents tolerantly. A migration (Admin SDK script, run only with a project owner's
OK) would need:

| What | Why | Until then |
|---|---|---|
| **Drawer `number`** for every drawer | P17; UNIQUE per cart | The app shows the creation-order position. A manager can set it in B3 ("Alterar número"), even on a used drawer that never had one |
| Drawer `name` | D20 (30 Oct) reverses P17's "no name" | Old names stored before P17 are shown again; check and fix them in B3 ("Editar gaveta") |
| **`drawerId`** on every assignment | Slot ids repeat across drawers | The app puts the placement in the first drawer (in number order) with that slot id |
| **Slot documents** for drawers whose layout was never edited | Every drawer has slots | The app draws one slot per cell; saving the grid in B4 creates them |
| **`usedAt`** on assignments, slots and drawers that already have usage events | Lets the rules block deleting/reshaping them | The app's history query blocks it in the UI; the rules don't |
| **PIN hashes** (`private/credentials`) for every member | DB3 | **Existing users have no PIN** until an administrator sets one in B7 (or IT with `set_password.mjs`): they sign in with the password only, can't unlock with a PIN and can't sign reports |
| PINs for the platform admins and the first institution admins | Nobody sets their own | `set_password.mjs --cloud …` |
| GTINs padded to 14 digits | P16 | Lookups match both forms |
| Overfilled assignments (`currentQuantity > targetQuantity`), if any | P5 | They can still be lowered; a manager raises the target or records a correction |
| Remove `minimumQuantity` and `status` from assignments | D10, stale field | Ignored |
| Batches: `removedAt: null`, `quantity` where missing | DB1 | Missing `removedAt` counts as active |
| Local data on each tablet (reports, templates) | Templates now store drawer numbers, no minimum | Old templates are read with their drawers numbered by position |

