# Firebase model

Status: Phase 2 collection model and Firestore Rules implemented and tested against the local emulator. `firestore.rules` and `firestore.indexes.json` are now deployed to `i-crash-pt-2026` (2026-09-09), matching this document exactly. No application data exists there yet — the very first `institutions`/`platformAdmins` doc cannot be written by any client under these rules (by design; see "Why `memberIndex` exists" below and the note on provisioning `platformAdmins`), so seeding cloud sample data needs a Firebase Admin SDK service-account key, not a temporary rules relaxation.

Authentication and Cloud Firestore are the only Firebase products in use. Local Auth/Firestore emulators are configured separately from the `i-crash-pt-2026` cloud project — see "Environments" below. No billing, Storage or deployed Functions exist.

## Collection layout

```
platformAdmins/{uid}                                        marker doc; platform-wide super admin
institutions/{institutionId}
  memberships/{uid}                                          role + status, one per member (canonical)
  memberIndex/{uid}                                          {uid, status} pointer, denormalized from
                                                               memberships — see "Firestore Rules" below
  products/{productId}                                       institution-scoped catalogue
  carts/{cartId}
    responsibleUsers/{uid}                                   explicit cart access grant
    drawers/{drawerId}
      slots/{slotId}                                         row/column/rowSpan/columnSpan
    assignments/{assignmentId}                                CartProductAssignment: slotId, productId,
                                                               currentQuantity, targetQuantity,
                                                               minimumQuantity?, earliestKnownExpiry?, status
      batches/{batchId}                                       lotNumber, quantity?, expiryDate, gtin?,
                                                               source, createdBy
  usageEvents/{eventId}                                       immutable: consumption/replenishment/
                                                               correction/auditReconciliation
  auditEvents/{eventId}                                       immutable: generic admin/structural trail
```

Institution is the tenancy root: every other collection is nested under `institutions/{institutionId}`, and every Firestore Rule keys off that id. A user's role lives in exactly one place per institution — `memberships/{uid}` — never duplicated elsewhere, so there is one place to check for both application code and Rules.

`carts/{cartId}/responsibleUsers/{uid}` is a doc-per-uid collection rather than an array field on the cart, precisely so a future move to multiple simultaneous responsible users (spec section 17, open decision #3) needs no schema change — only relaxing who may add additional documents.

Dart entities mirroring this layout live in `03_Implementacao/app1/lib/src/domain/entities/`; Firestore reads/writes happen only in `03_Implementacao/app1/lib/src/data/firebase/`.

## The aggregate/batch split (spec sections 22-28, 58-59)

`currentQuantity` on a `CartProductAssignment` is the authoritative, immediately-updated operational stock number. `earliestKnownExpiry` is the conservative nearest known expiry across every batch ever recorded that has not been physically confirmed absent.

Rules, enforced in `lib/src/domain/inventory_rules.dart` and covered by `test/domain/inventory_rules_test.dart`:

- **Daily consumption** (`InventoryRepository.recordConsumption`) only ever decrements `currentQuantity` and appends an immutable `usageEvents` doc. It never reads, selects, or decrements a `Batch`, and never touches `earliestKnownExpiry`. No FEFO/FIFO inference exists anywhere in this path.
- **Replenishment** (`recordReplenishment`) increments `currentQuantity`, stores a new `Batch`, and updates `earliestKnownExpiry` only if the new batch expires *sooner* than the current value — it can only move earlier, never later, and never removes an existing batch's influence.
- **Reconciliation** (`reconcileAfterAudit`) is the only operation that may replace the batch set, and it recomputes both `currentQuantity` and `earliestKnownExpiry` strictly from the physically confirmed batches passed in.
- **Correction** (`recordCorrection`) appends a compensating `usageEvents` doc referencing the event it corrects; the original event is never edited or deleted.

Do not assume `currentQuantity == sum(batch quantities)` holds at all times — it is intentionally allowed to disagree between an emergency and the next physical audit (spec section 28).

## Firestore Rules (`firestore.rules`)

Deny-by-default; every collection is opened explicitly:

- `isMember(institutionId)` — signed in, has a `memberships/{uid}` doc with `status == 'active'`.
- `isManagerOrAbove(institutionId)` — role `manager`/`institutionAdmin`, or a `platformAdmins/{uid}` doc exists.
- `canAccessCart(institutionId, cartId)` — manager+ (sees every cart) or an explicit `responsibleUsers/{uid}` doc (spec section 17).
- A member can never write their own `memberships` doc (no self-escalation, no self-reactivation).
- On an `assignments` doc, an assigned non-manager user may change only `currentQuantity`/`updatedAt`/`updatedBy` — every structural field (`targetQuantity`, `slotId`, `productId`, `status`) stays manager+ only.
- `usageEvents`/`auditEvents` are create-only for members; `update`/`delete` are always `false`, including for institution admins.
- Only a `platformAdmins` doc holder may `create` an `institutions` doc.

### Why `memberIndex` exists (a Firestore Rules/emulator quirk)

`InstitutionRepository.watchMyInstitutions` needs to answer "which institutions do I belong to" with a single `collectionGroup('memberIndex').where('uid', '==', myUid).where('status', '==', 'active')` query, so the app never has to know institution ids up front. Firestore only authorizes a `collectionGroup()` query against a rule declared with a `{path=**}` wildcard — a nested `institutions/{id} { match /memberships/{uid} {...} }` rule, no matter how it's written, is never considered by a collection-group query, only by direct/subcollection access.

That alone would suggest just adding a `{path=**}/memberships/{uid}` rule. Two things confirmed empirically (against firebase-tools 15.29.0's Firestore emulator) make that the wrong move:

1. A collection-group (`{path=**}`) rule and a nested exact-path rule on the **same literal collection name** cause the emulator's `list`-validation to fail even for requests that would only ever hit one of them ("Null value error"/"Variable ... is not bound in path template" — it appears to try to statically prove *every* rule that could structurally match the collection name, including nested ones whose path variables aren't resolvable in that generic context).
2. Within a rule governing a `list`/`collectionGroup` request, referencing the wildcard segment captured immediately after `{path=**}` (here, `{uid}`) in the condition — even a trivial `uid == uid` — fails the same way. Reading the equivalent value from the document body instead (`resource.data.uid`) works correctly.

So `memberIndex` is a separate, purpose-built collection: a lightweight `{uid, status}` pointer written whenever a `memberships` doc is created/disabled, existing only so this one collection-group query has a rule it can safely satisfy (self-uid read via `resource.data.uid`; admin-only `create`/`update`/`delete`, which — being single-document operations, not `list` — can safely use `path[1]` for the institutionId). `memberships` itself keeps its original nested-only rule, untouched. **Nothing currently keeps `memberIndex` in sync automatically** — there is no membership-creation flow in the app yet; `firestore-tests/seed_emulator.mjs` writes both documents by hand. Whoever builds the membership-management screen (workstream A) must write both documents (ideally as one atomic `WriteBatch`) whenever a membership is created, disabled, or re-enabled.

### Why the cross-cart alerts query is manager+ only (another Firestore Rules quirk)

The dashboard's cross-cart alerts (spec section 49: expiring/expired products and stock below its minimum, across every cart in an institution) need `InventoryRepository.watchAllAssignments`, a `collectionGroup('assignments').where('institutionId', isEqualTo: institutionId)` query. Every `assignments` document carries a denormalized `institutionId` (and `cartId`) field, written once at creation and never changed afterward (enforced in `firestore.rules`), exactly like `memberIndex`'s `uid`/`status` fields — for the same reason: the query needs *something* to filter on that the rule can also read.

Two things confirmed empirically (again against firebase-tools' Firestore emulator) shaped the final rule:

1. A `{path=**}/assignments/{assignmentId}` collection-group rule and the pre-existing nested `carts/{cartId}/assignments/{assignmentId}` rule can coexist safely — unlike the `memberIndex` situation, this did **not** break here (both were exercised together with no evaluation errors once the issue below was fixed).
2. **A `list`/collection-group rule can only safely reference `resource.data` fields the query itself filters on.** The first version of this rule reused `canAccessCart(institutionId, cartId)` — the same function every other cart-scoped rule in this file uses — reading both `resource.data.institutionId` and `resource.data.cartId`. The query only filters on `institutionId`. For a user who should be *denied* a given candidate document (i.e. `isAssignedToCart` needed to evaluate to `false` using `cartId`), Firestore threw `Property cartId is undefined on object` and failed the **entire query**, not just that one document — confirmed with a throwaway probe script (since deleted) that isolated the exact same failure down to a *trivial* `resource.data.cartId == resource.data.cartId` rule, with no function calls at all. Firestore's `list` rule validation appears to require every `resource.data` field a rule touches to also appear in the query's own filter set, so it can reason about the rule without inspecting arbitrary documents; `cartId` isn't such a field here.

The fix: this collection-group rule is `isManagerOrAbove(resource.data.institutionId)` only — it touches only the one field the query filters on, and does not attempt an `isAssignedToCart` check at all. **Consequence: cross-cart alerts are manager+ only.** A normal (non-manager) user still reads their own responsible carts' assignments in full through the ordinary nested `watchAssignments` per-cart query (governed by the original, unchanged `canAccessCart(institutionId, cartId)` rule using path-captured variables, which — being evaluated per fixed-depth document, not as a `list`-with-mismatched-filter — works exactly as it always has); they simply don't get the aggregate cross-cart view. This is a real, deliberate scope decision, not an oversight — revisit only if a normal user's aggregate view becomes a real product requirement, and expect to need a denormalized array field (e.g. `responsibleUids` with `array-contains`) rather than another `resource.data` equality check, which this exploration shows does not extend safely beyond the query's own filters.

Automated tests: `firestore-tests/rules.test.mjs` (Node's built-in test runner + `@firebase/rules-unit-testing`), covering unauthenticated access, cross-institution isolation, unassigned-cart access, write-field scoping, self-escalation, audit-history immutability (spec section 60), the `memberIndex` collection-group query, and the `assignments` collection-group query specifically. Run with:

```
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

`platformAdmins` currently has no writer (no Cloud Function exists yet — Phase 1 explicitly has none); the first platform super admin must be provisioned manually via the Firebase console/Admin SDK against the emulator or, later, the real project.

Composite indexes (`firestore.indexes.json`): a `COLLECTION_GROUP` index on `memberIndex` (`uid`, `status`) backs `InstitutionRepository.watchMyInstitutions`, and a `COLLECTION` index on `usageEvents` (`assignmentId`, `serverTimestamp desc`) backs `UsageRepository.watchEventsForAssignment`. The emulator does not enforce these; they matter once Rules/queries run against the real `i-crash-pt-2026` project.

## Environments

- **Local emulator** (`demo-icrash-v2`, from `.firebaserc`): Auth on `127.0.0.1:9099`, Firestore on `127.0.0.1:8081`, UI on `127.0.0.1:4000`. `AppEnvironment`/`bootstrapFirebase` (see `docs/ARCHITECTURE.md` for why this needs its own named `FirebaseApp` and matching demo project id) point the Flutter app here by default in debug builds.
- **Cloud demo/development** (`i-crash-pt-2026`, from `.firebaserc`'s `development` alias): Standard/Native Firestore in `eur3`, Spark plan, e-mail/password Authentication enabled, `firestore.rules`/`firestore.indexes.json` deployed (2026-09-09), no users or application data yet. Only reached from a debug build via `--dart-define=ICRASH_BACKEND=cloud`, or automatically from a release build.

Real Firestore location (`eur3`) was already confirmed with the user in Phase 1; it is immutable and is not revisited here.
