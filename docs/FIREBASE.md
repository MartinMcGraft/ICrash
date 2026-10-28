# I-Crash: Firebase backend

Everything about the backend: what exists, how to run it locally, how to work with the
cloud project, how to set one up from zero, the data model and the security rules.
This document replaces `FIREBASE_MODEL.md`.

Updated 18 Oct 2026. Files live in [`firebase/`](../firebase); app-side code is in
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
│   ├── seed_emulator.mjs    small fixture: 1 admin, 1 cart
│   └── seed_qa_run.mjs      full fixture: 4 users (every role), 2 institutions, edge cases
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
node seed_qa_run.mjs   # or: npm run seed  (the smaller seed_emulator.mjs)

# Terminal 3: the app (debug → emulator automatically)
cd app
flutter run
```

`seed_qa_run.mjs` creates these accounts (the shared emulator-only password is in the
script):

| E-mail | Role |
|---|---|
| `enfermeira.teste@icrash.pt` | institutionAdmin |
| `gestor.teste@icrash.pt` | manager |
| `utilizador.teste@icrash.pt` | user |
| `super.teste@icrash.pt` | platform super admin, no institution |

It also creates two institutions: one with two carts and crafted expiry, lot and
minimum-stock cases, and one bare one for isolation tests.

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
  memberIndex/{uid}                          uid, status  (copy for the "my institutions" query)
  products/{productId}                       name, unitDescription, description, gtin,
                                             category, expiryWarningDays
  carts/{cartId}                             name, status, service, location, archived,
                                             layoutVersion, templateId, responsibleUserIds[]
    responsibleUsers/{uid}                   who may access the cart (non-managers)
    drawers/{drawerId}                       name, rows, columns
      slots/{slotId}                         row, column, rowSpan, columnSpan, label
    assignments/{assignmentId}               institutionId, cartId, slotId, productId,
                                             currentQuantity, targetQuantity, minimumQuantity?,
                                             earliestKnownExpiry?, status, updatedAt/By
      batches/{batchId}                      lotNumber, expiryDate, quantity?, gtin?,
                                             source (manual | gs1DataMatrix | periodicAudit), createdBy
  usageEvents/{eventId}      IMMUTABLE       type (consumption | replenishment | correction |
                                             auditReconciliation), cartId, assignmentId,
                                             productId, amount (signed), actorUid,
                                             correctsEventId?, localTimestamp, serverTimestamp
  auditEvents/{eventId}      IMMUTABLE       type, actorUid, cartId?, drawerId?, slotId?,
                                             productId?, previousValue, newValue,
                                             correctionRef?, metadata
```

- **Paths:** all of them are defined once in `app/lib/src/data/firebase/firestore_paths.dart`.
- **Entities:** the Dart versions are in `app/lib/src/domain/entities/`.
- **New in design v2 (Oct 2026):** cart `service`, `location` and `archived`; membership
  `displayName`, `email` and `service`; product `category` and `expiryWarningDays`.
- **Values:**
  - Roles: `platformSuperAdmin`, `institutionAdmin`, `manager`, `user`.
  - Membership status: `active`, `invited`, `disabled`.
  - Cart status: `operational`, `replenishmentRequired`, `auditRequired`,
    `outOfService`.
  - Assignment status: `ok`, `replenishmentRequired`, `expiringSoon`, `expired`.

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
shifts, permission toggles, the per-cart automatic-state switch, and the device session
and PIN. They live in SharedPreferences (`app/lib/src/data/local/`, keys prefixed
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
| `institutions/{i}` | Members | Create: platform admin. Update: institution admin (name, expiry warning only). Delete: nobody |
| `memberships/{uid}` | Members | Institution admin, **never your own document** (no self-escalation or self-reactivation) |
| `memberIndex/{uid}` | Only your own entry | Institution admin |
| `products` | Members | Manager+ |
| `carts/{c}` | Get: `canAccessCart`. List: manager+ unfiltered; others must filter `responsibleUserIds array-contains <uid>` | Create/update: manager+. **Delete: nobody** (archive instead) |
| `responsibleUsers`, `drawers`, `slots`, `batches` | `canAccessCart` | Manager+ |
| `assignments` | `canAccessCart` | Manager+. An assigned non-manager may change **only** `currentQuantity`, `updatedAt` and `updatedBy`. `institutionId`/`cartId` must match the path and never change |
| `usageEvents` | Members | Create only, as yourself, for a cart you can access. **Update and delete: nobody, not even admins** |
| `auditEvents` | Manager+ | Create only, as yourself. **Update and delete: nobody** |
| Collection group `assignments` | Manager+ only (cross-cart alerts) | — |

### Rules quirks (confirmed against the emulator; don't "clean them up")
1. **`memberIndex` exists** because a collection-group query needs a `{path=**}` rule,
   and putting one on `memberships` broke the nested rule in the emulator.
   - Inside a `list` rule, the path wildcard right after `{path=**}` can't be used.
     Read `resource.data.uid` instead (that's why the documents store their own `uid`).
2. **A `list` rule may only read `resource.data` fields the query filters on.**
   - That's why the cross-cart `assignments` query is **manager+ only**: checking the
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
| **Consumption** | Lowers `currentQuantity`; appends a `consumption` event | Never touches batches or `earliestKnownExpiry`; never guesses which lot (no FIFO/FEFO) |
| **Replenishment** | Raises `currentQuantity`; adds a batch; moves `earliestKnownExpiry` **earlier** if the new lot expires sooner | Never moves the expiry later |
| **Reconciliation** (after a physical audit) | Replaces the batch set with the confirmed lots; recomputes quantity and expiry from them | The only operation allowed to do this |
| **Correction** | Appends a compensating event with `correctsEventId` | Never edits or deletes the original event |

`currentQuantity` is allowed to differ from the sum of the lots between an emergency and
the next audit.

**Known issue:** consumption, replenishment and correction currently use
`runTransaction`, which **fails offline**. The planned fix:
- write them as a `WriteBatch` with `FieldValue.increment` plus the immutable event, so
  they queue offline;
- decide the conflict policy when two devices edit the same slot (D14).

---

## 9. Authentication details

- **Sign-in:** e-mail and password. Password reset uses Firebase's reset e-mail.
- **Inviting a member (B7):** the app creates the Auth account on a **throwaway
  secondary `FirebaseApp`** (`createIsolatedAccountCreationAuth`). Creating a user signs
  in as that user on whichever app runs it, and this keeps the admin signed in. It uses a
  random password nobody sees, writes `memberships` + `memberIndex` in one batch, and
  sends the reset e-mail so the person chooses their own password. Replace this with a
  Cloud Function if billing is ever enabled.
- **PIN:** local only (salted SHA-256 in SharedPreferences). It unlocks the session
  already saved on the device; Firebase isn't involved.
- **Changed direction (18 Oct, D3):** in the relational model the institution issues each
  employee a `userNumber`, password and PIN, and the server checks the PIN, so it works on
  any cart tablet. Only the administration can change or reset credentials (DB3, 28 Oct).

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
| `drawers/{d}` | DRAWER | `name` → `number` |
| `slots/{s}` | SLOT | `label` isn't stored (calculated). The key includes the drawer and cart, so slot ids no longer clash between drawers (APP.md known issue 2) |
| `assignments/{a}` | SLOTCC + SLOTSTATE | `currentQuantity` → `currNumberCC`, `targetQuantity` → `maxNumberCC`. `minimumQuantity` is dropped (D10). `earliestKnownExpiry` → `earliestExpirationDate`, **derived** from the batches. `status` → SLOTSTATE. The copied `institutionId`/`cartId` aren't needed |
| `assignments/{a}/batches/{b}` | BATCH | One batch per **expiry date** in the slot. `lotNumber` optional; `removedAt` added (batches are never deleted). `gtin`, `source` and `createdBy` aren't stored on the batch; who created it is on the History row |
| `usageEvents/{e}` | HISTORY + HISTORYTYPE | `type` → HISTORYTYPE (Consumption, Replenishment, Discard, Correction, Count). `correctsEventId` → `idHistoryCorrection`. `actorUid` → `idUser`. One `createdAt` instead of local and server timestamps. Adds the batch affected and the report the row belongs to |
| `auditEvents/{e}` | — | The administrative log isn't modelled; left to the security phase (DB12) |
| Reports, signatures, check drafts (local stubs) | REPORT, REPORTSTATUS, REPORTITEM, RESULTITEM | A monthly check lists only expired and expiring batches (D4). The signer is the user who performed the check (DB4) |
| Emergency sessions (local stub) | REPORT with `isEmergency` = true | The consumption rows recorded during it point to the report |
| Cart templates (local stub) | CRASHCART with `isTemplate` = true | Same tables as a real cart |
| Device session and PIN (local stub) | USER `pinHash`, `passwordHash` | Checked by the server, not the device |
| Firestore Rules (§6) | — | Security on the local server (database privileges, triggers, API) is designed in the security phase |
