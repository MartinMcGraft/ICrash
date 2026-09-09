# I-CRASH V2 — IMPLEMENTATION SPECIFICATION

You are working on an existing Flutter application originally developed around 2023 called **I-Crash**.

I-Crash helps healthcare professionals manage emergency/crash carts, with particular focus on:

- fast daily stock management after emergency use;
- replenishment;
- expiry-date management;
- periodic/monthly verification;
- physical drawer representation;
- traceability and operational auditing.

This is not a greenfield rewrite.

Preserve useful functionality from the existing project, but you are explicitly authorized to refactor obsolete architecture and replace the legacy backend/database.

The current goal is a **professional prototype/demo** suitable for future validation with healthcare professionals, investors and potential clients.

The current infrastructure should remain free whenever possible.

The architecture must nevertheless be capable of evolving later into a commercial/subscription product without requiring a complete rewrite.

---

# 0. CRITICAL WORKING RULES

Do NOT attempt to implement everything in one pass.

Work phase by phase.

For every phase:

1. Inspect the existing implementation first.
2. Understand the affected architecture.
3. Implement only the current phase.
4. Run:
   - `flutter analyze`
   - relevant unit/widget/integration tests
   - relevant platform build
5. Launch/use the Android emulator `ICrash_API_36`.
6. Run the application in debug mode.
7. Navigate through every flow affected by the changes.
8. Interact with the feature.
9. Confirm visually and functionally that it works.
10. Inspect runtime/console errors.
11. Fix regressions before completing the phase.
12. Commit the stable phase to Git.
13. Update implementation/handoff documentation.

A successful compilation alone does NOT mean a phase is complete.

Whenever technically possible, validate actual behavior on the Android emulator.

For camera/scanner functionality that cannot be properly tested using a virtual camera, create testable scanner abstractions and mock GS1/Data Matrix inputs.

Real physical-camera validation must remain documented as a later test requirement.

Never claim iOS/macOS validation when developing from Windows.

---

# 1. TOKEN / CONTEXT EXHAUSTION RULE — MANDATORY

Do not continue coding until context/token exhaustion.

Continuously maintain:

- `docs/IMPLEMENTATION_STATUS.md`
- `docs/AI_HANDOFF.md`
- `docs/ARCHITECTURE.md`
- `docs/FIREBASE_MODEL.md`
- `docs/TEST_STATUS.md`
- `docs/OPEN_DECISIONS.md`

These files must be updated throughout development, not only at the very end.

If remaining context becomes low:

STOP CODING at a safe point.

Before stopping:

1. Leave the repository buildable whenever possible.
2. Complete the current logical operation.
3. Run relevant tests.
4. Commit completed stable work.
5. Do not mix incomplete broken work into the previous stable commit.
6. Update `docs/AI_HANDOFF.md`.

`AI_HANDOFF.md` must contain enough information for a new Codex or Claude Code instance to continue independently.

It must include:

- repository path;
- current branch;
- current commit hash;
- completed phases;
- current partially completed phase;
- exact files changed;
- architecture decisions;
- Firebase configuration status;
- Firestore collections already implemented;
- domain models already implemented;
- dependencies added/removed;
- migrations already performed;
- security rules status;
- tests already run;
- Android emulator tests already performed;
- known bugs;
- known platform limitations;
- open business decisions;
- pending Git changes;
- exact commands needed to continue;
- exact next implementation task;
- temporary workarounds;
- things that must NOT be redone.

At the end of the agent's response, also give the user a concise human-readable handoff summary.

---

# 2. GIT — PHASE 0

The real GitHub repository already exists and is PRIVATE.

The integration development branch must be:

`DEV-Pedro`

Never develop directly on `main`.

First inspect the local environment:

- `git status`
- `git remote -v`
- `git branch -a`
- `git log`
- `gh auth status` if GitHub CLI exists

The locally modernized project may currently not contain `.git`.

Do NOT blindly run `git init`.

The repository already exists remotely and its history must be preserved.

If necessary:

1. verify access to the private GitHub repository;
2. identify the correct remote;
3. identify its default/main branch;
4. clone/connect safely;
5. preserve the already-modernized local Flutter files;
6. compare them against the GitHub version;
7. create `DEV-Pedro`;
8. apply the modernization changes to that branch;
9. inspect the diff carefully;
10. commit only the modernization changes.

Suggested initial commit:

`chore: modernize Flutter project and dependencies`

Do not request GitHub passwords, PAT values, SSH private keys or credentials in source files.

If authentication is needed, request interactive authentication on the local machine.

---

# 3. CURRENT FLUTTER BASELINE

A previous modernization already produced approximately:

- Flutter 3.47.2
- Dart 3.13.2
- Android API 36 environment
- Android emulator `ICrash_API_36`
- modern Gradle/Android configuration
- modern Flutter dependencies
- `mobile_scanner 7.4.0`
- successful `flutter analyze`
- successful Flutter tests
- successful Android debug build
- successful Web build
- successful Windows release build

Do NOT restart the Flutter upgrade from scratch.

Inspect and preserve this updated state unless a concrete problem is identified.

---

# 4. LEGACY BACKEND

The old Django/HTTP backend and legacy relational database are obsolete.

Do NOT spend development time restoring them before testing the application.

There is no production information that needs to be migrated.

Legacy database records were test data.

Create the new Firebase environment from a clean state.

Firebase must be implemented before the first complete end-to-end walkthrough of the modernized application.

---

# 5. PRODUCT PURPOSE

I-Crash represents and manages physical emergency/crash carts.

The application must help nurses and other authorized healthcare professionals perform operational stock tasks with minimum interaction.

The two most important operational areas are:

## Daily management

Record material/medicine consumed after emergency use.

## Periodic/monthly management

Physically verify cart contents, quantities, lots and expiration dates.

The application must always prioritize actual clinical workflow.

Never design an interaction that assumes a nurse will stop patient care in order to scan or record inventory information.

---

# 6. NO PATIENT INFORMATION

I-Crash must NOT contain identifiable patient information.

Do not create:

- patient profiles;
- patient names;
- patient identifiers;
- diagnosis information;
- patient medical histories;
- links between stock consumption and individual patients.

Consumption history is inventory/operational information only.

---

# 7. FIREBASE — PHASE 1

Create/configure a NEW Firebase project.

The project should remain on the free/Spark plan during the prototype phase whenever possible.

Do not enable billing without explicit user authorization.

The Firebase project should ultimately allow three Google accounts to have Owner-level administration.

The user will perform authentication/account-owner steps manually when necessary.

Use initially:

- Firebase Authentication
- Cloud Firestore
- Firebase App Check where applicable
- Crashlytics where supported
- Firebase Local Emulator Suite

Do not make the first prototype dependent on:

- deployed Cloud Functions;
- Firebase Storage;
- paid infrastructure.

Product images are explicitly deferred.

Server-side notification automation can also be introduced later.

The architecture must nevertheless be designed so future transition to:

- Blaze;
- Cloud Functions;
- Firebase Storage;
- FCM backend automation;
- commercial/subscription infrastructure

does not require rewriting the domain/application layers.

---

# 8. FIREBASE ENVIRONMENTS

Configure:

## Local development

Flutter application connected to Firebase Emulator Suite.

At minimum:

- Authentication emulator
- Firestore emulator

## Demo/development cloud

Real Firebase development/demo project.

Integration tests must never accidentally modify live/demo data.

Document environment selection clearly.

---

# 9. FIREBASE DATABASE LOCATION

Before creating an irreversible real Firestore database location, verify the choice with the user.

For a European/multi-country prototype, prefer an appropriate European location unless there is a better technical reason.

Do not silently select an irreversible location.

---

# 10. APPLICATION ARCHITECTURE — PHASE 2

Do NOT scatter Firebase API calls throughout Flutter screens.

Use clear separation between:

- presentation/UI;
- application/use cases;
- domain;
- repositories;
- infrastructure;
- Firebase implementations;
- scanner implementations;
- reporting;
- notifications.

Typical interfaces may include:

- `AuthRepository`
- `InstitutionRepository`
- `CartRepository`
- `DrawerRepository`
- `InventoryRepository`
- `ProductRepository`
- `AuditRepository`
- `UsageRepository`
- `ScannerService`
- `ReportService`
- `NotificationService`

The business/domain layer must remain testable without Firebase.

Document architecture in:

`docs/ARCHITECTURE.md`

---

# 11. OFFLINE-FIRST

The application must remain usable when Internet connectivity is temporarily unavailable.

This is especially important for Android/iOS.

Recording medicine consumption must not fail merely because Wi-Fi is temporarily unavailable.

Use Firestore offline functionality where supported.

The application must be able to represent states such as:

- synchronized;
- synchronization pending;
- synchronization failed/conflicted.

Do not interrupt users unnecessarily with networking dialogs.

---

# 12. PLATFORM PRIORITY

Priority:

1. Android
2. iOS
3. Windows
4. macOS
5. Web

Maintain one Flutter codebase whenever practical.

Flutter Web should remain supported through the Flutter project.

Do not create another frontend framework at this stage.

Desktop UI must not merely stretch mobile screens.

Support appropriate responsive/adaptive layouts.

Windows Firebase support must remain behind abstractions because production support/limitations may evolve.

---

# 13. INTERNATIONALIZATION

The application must support:

- Portuguese — Portugal
- English

Never hard-code user-facing text where localization should be used.

Prepare the structure so additional languages can later be added easily.

---

# 14. AUTHENTICATION — WORKSTREAM A

Initial authentication:

- email + password

Architecture must allow future mechanisms such as:

- username + password;
- NFC employee/staff card;
- staff QR login;
- institutional identity systems;
- other providers.

Do not fake insecure NFC/QR authentication now.

---

# 15. ROLES

Support at least:

## Platform Super Admin

Maximum platform privileges.

Can create institutions and manage top-level institutional administration.

## Institution Admin

Administers assigned institutions.

Can manage:

- members;
- managers;
- carts;
- templates;
- products;
- permissions;
- configuration.

## Manager

Operational/configuration role.

Can manage assigned carts and users according to granted permissions.

May configure carts/drawers.

Whether Managers can modify the structural layout of an already-active drawer must remain configurable/open for validation.

## User

Normal operational healthcare user.

Only sees institutions/carts explicitly assigned.

---

# 16. MULTI-INSTITUTION

The platform must support multiple independent institutions.

A single user may belong to multiple institutions.

Membership and permissions are institution-scoped.

Access to Institution A must never grant access to Institution B.

Only a maximum-privilege platform administrator should initially create institutions.

---

# 17. CART ACCESS

Institution membership alone does not automatically grant access to every cart.

Managers/admins must be able to assign users to specific carts.

Current assumption:

One cart has one responsible user at a given time.

Design the model so this restriction can later support multiple responsible users without major redesign.

Add that question to healthcare-user validation.

---

# 18. FIRESTORE SECURITY RULES

Security must exist at database-rule level.

Do not depend only on hiding buttons.

Rules must enforce at least:

- authenticated access;
- institution membership;
- role restrictions;
- cart assignment;
- prevention of privilege escalation;
- cross-institution isolation;
- restrictions on destructive operations;
- audit-history protections.

Internal QR codes must never bypass authorization.

Create automated Firestore Rules tests.

---

# 19. DOMAIN STRUCTURE

The conceptual hierarchy remains:

Institution
→ Emergency Cart
→ Drawer
→ Slot
→ Assigned Product
→ Inventory

However, unlike the old application, do not store everything directly inside `Slot`.

Separate:

## Slot

Physical position/layout.

## Product

Reusable definition of a medicine/material.

## CartProductAssignment

Association of one product to one slot in one cart.

## Inventory / batches

Stock, lots and expiration information.

---

# 20. PRODUCT UNIQUENESS INSIDE A CART

The same medicine may exist in many different emergency carts.

However:

**Within one emergency cart, a given product may only exist in one slot.**

Example:

Hospital A:

Cart 1:
- Adrenaline → Drawer 1 / Slot 5

Cart 2:
- Adrenaline → Drawer 2 / Slot 3

Valid.

But inside Cart 1, Adrenaline must not simultaneously exist in Slot 5 and Slot 8.

Enforce this in domain logic/data design, not only UI.

---

# 21. PRODUCT MODEL

Keep useful existing visible information such as:

- product name;
- volume/weight;
- application/description.

Do not overcomplicate the clinical product catalogue at this prototype stage.

The technical model must nevertheless support GS1 identifiers such as GTIN for Data Matrix mapping.

The GTIN does not need to dominate the normal UI.

Product images are deferred.

---

# 22. SLOT STOCK MODEL

Each cart-product assignment should support:

- `currentQuantity`
- `targetQuantity` / max quantity
- optional future `minimumQuantity`
- `earliestKnownExpiry`
- operational status

IMPORTANT:

`currentQuantity` is the authoritative fast operational quantity used during daily consumption.

Do NOT derive daily current quantity exclusively by summing individually known batches.

The batch model and aggregate operational quantity have intentionally different responsibilities.

---

# 23. LOT/BATCH MODEL

The same medicine can have several different lots with different expiration dates.

Store lot information for inventory/audit purposes.

Example conceptual batch fields:

- `lotNumber`
- `productId`
- `cartId`
- `slotId`
- known quantity where established by replenishment/audit
- `expiryDate`
- GTIN if available
- createdAt
- updatedAt
- createdBy
- source:
  - manual
  - GS1 Data Matrix
  - periodic audit

Do not assume that lot quantities are always perfectly synchronized with daily consumption.

This is deliberate and reflects real emergency workflow.

---

# 24. CRITICAL DAILY STOCK RULE — DO NOT ASSUME A LOT

During an emergency, staff do NOT scan the medicine being consumed.

After one or multiple emergencies, a nurse may record:

"2 units of medicine X were used."

The system does NOT know which physical lot was actually removed.

Therefore:

NEVER automatically choose a lot.

NEVER assume FEFO.

NEVER assume FIFO.

NEVER decrement a specific batch merely because its expiry is earlier.

Daily consumption must:

1. identify cart/product/slot;
2. decrease only the aggregate `currentQuantity`;
3. create an immutable consumption event;
4. leave individual lot attribution unchanged;
5. preserve conservative expiry information.

This behavior is intentional.

---

# 25. CONSERVATIVE EXPIRY RULE

Suppose the system knows:

Lot A:
- expiry October 2026

Lot B:
- expiry December 2026

A nurse records one medicine used during daily management.

The app must NOT assume October's unit was used.

Therefore the slot's known nearest expiry remains:

October 2026

until a physical replenishment/audit establishes that the October lot is no longer present.

This may result in the application warning about an expiry that has actually already left the cart.

That is acceptable and intentional.

For an emergency-cart application:

A false-positive request to verify stock is safer than silently assuming an earlier-expiry medicine no longer exists.

---

# 26. NEW REPLENISHMENT EXPIRY

If the currently known nearest expiry is:

December 2026

and replenishment adds a product with:

October 2026

then:

`earliestKnownExpiry = October 2026`

immediately.

If replenishment adds:

January 2027

then the nearest known expiry remains December 2026.

Never replace/remove existing lots merely because a new lot is added.

---

# 27. MONTHLY AUDIT RECONCILIATION

The periodic/monthly verification is where physical reality is reconciled.

During this process:

- verify quantities;
- verify lots;
- verify expiry dates;
- confirm actual inventory;
- remove lots confirmed no longer present;
- add previously unknown lots;
- correct incorrect lot quantities where necessary.

After reconciliation, recompute:

- `currentQuantity`
- `earliestKnownExpiry`

from physically verified data.

Example:

Before audit:

Known expiry:
October 2026

Daily consumption happened, but no specific lot was attributed.

During audit, nurse confirms the October lot no longer exists.

Remaining stock expires:

December 2026

Then:

`earliestKnownExpiry = December 2026`

This is the correct moment to advance the known expiry.

---

# 28. DATA CONSISTENCY CONSEQUENCE

Do not design code that assumes:

`currentQuantity == sum(all known batch quantities)`

at every moment.

After daily emergency consumption this equality may temporarily not hold.

Instead distinguish conceptually:

## Operational aggregate

`currentQuantity`

Fast, immediately updated daily stock quantity.

## Known batch state

Inventory lot information last established through replenishment/audit.

## Reconciliation

Periodic audit brings operational aggregate and physically verified batch state back into agreement.

Document this explicitly in:

`docs/FIREBASE_MODEL.md`

and test it.

---

# 29. GS1 DATA MATRIX — CRITICAL TERMINOLOGY

Medicines use:

**GS1 Data Matrix**

They do NOT use the application's internal QR code.

Never call medicine scanning a QR scan.

The project has two completely different scanning domains:

## Internal I-Crash QR

Identifies:

- cart
- drawer
- optionally slot

## Medicine GS1 Data Matrix

Can provide medicine information such as:

- GTIN
- expiry
- lot

Keep these implementations and terminology separate.

---

# 30. DATA MATRIX REPLENISHMENT

Data Matrix scanning is useful primarily during replenishment/audit, not during emergencies.

Scanning remains OPTIONAL in the current prototype.

The user can:

- attempt scan;
- retry as many times as wanted;
- cancel;
- manually enter data.

Preferred replenishment flow:

1. open product/slot;
2. specify quantity being added;
3. optionally scan GS1 Data Matrix;
4. parse available data;
5. identify/validate product;
6. obtain lot;
7. obtain expiration;
8. allow correction/manual fallback;
9. update aggregate quantity;
10. store/update lot information;
11. recompute nearest known expiry conservatively;
12. create audit event.

Unknown GTINs must not be silently attached to a product.

Allow an authorized mapping/confirmation workflow.

---

# 31. GS1 FIELDS

Parser must support at least, when present:

- AI 01 — GTIN
- AI 17 — expiry date
- AI 10 — batch/lot number

Scanner recognition and GS1 parsing must remain separate layers.

Create parser tests independent of the physical camera.

---

# 32. SCANNER ABSTRACTION

Business logic must not depend directly on `MobileScanner`.

Create an abstraction capable of supporting:

- Android/iOS/macOS camera scanning;
- Web scanning where feasible;
- USB/Bluetooth HID scanners;
- keyboard-style scanner input;
- mock/debug scanning for tests.

This is especially important for Windows.

---

# 33. INTERNAL QR CODES

Internal I-Crash QR codes identify:

- cart;
- drawer;
- optionally slot.

Use opaque/stable IDs rather than relying solely on meaningful sequential database IDs.

A versioned internal payload is preferable.

Example conceptual form:

`icrash://v1/cart/<opaque-id>`

The UI still displays human-readable labels such as:

`Carro 2 / Gaveta 1 / Slot 1`

Scanning does NOT grant authorization.

Flow:

scan
→ resolve ID
→ authenticate
→ validate institution
→ validate cart permission
→ show data

Unauthorized users must receive access denied.

---

# 34. QR LABEL GENERATION

Authorized roles should be able to generate/export printable QR labels for internal I-Crash objects.

Do not save rendered QR images in Firestore unnecessarily.

Persist identifiers/data and generate QR graphics when needed.

---

# 35. DRAWER REPRESENTATION — WORKSTREAM B

The drawer UI must remain a clear virtual representation of the actual physical drawer.

Current slots are rectangular.

The user must clearly see:

- drawer dimensions;
- individual compartments;
- merged compartments;
- assigned products;
- relevant stock/expiry status.

How this geometry is persisted internally may change completely from the 2023 implementation.

Visual fidelity/usability takes priority over preserving the old database representation.

---

# 36. NEW DRAWER GRID MODEL

Do not preserve the old fragile adjacency-based merge system merely for compatibility.

For rectangular slots, use a clean geometry representation similar to:

- `row`
- `column`
- `rowSpan`
- `columnSpan`

or an equivalent robust model.

Editor concept:

1. define base drawer rows/columns;
2. display cells;
3. select cells;
4. merge valid rectangular area;
5. create one visual slot;
6. split slot when required.

Prevent:

- overlaps;
- invalid geometry;
- inaccessible cells;
- inconsistent layouts.

---

# 37. FUTURE IRREGULAR SHAPES

Do NOT implement L/T/non-rectangular slots now.

However, preserve enough schema flexibility so future support does not require rewriting the complete inventory system.

Add to healthcare-user questions:

"Existem compartimentos reais em formato L, T ou outro formato não retangular que necessitem de ser representados como um único compartimento na aplicação?"

---

# 38. DRAWER STRUCTURE CHANGES

Drawer structures can change over time.

Initially only Admin can modify an existing active drawer layout.

Keep Manager permission configurable for future decision.

Structure modifications must not destroy historical understanding.

Use layout versioning or equivalent snapshots.

Historical events must preserve enough information to show what the cart looked like when the event occurred.

---

# 39. TEMPLATES / DUPLICATION

Support:

- duplicate cart;
- duplicate drawer;
- reusable cart templates;
- reusable drawer templates.

Duplicating configuration must NOT duplicate:

- consumption history;
- audit history;
- operational event history.

Templates contain configuration, not historical stock operations.

---

# 40. CART STATUS

Support states such as:

- Operational
- Replenishment required
- Audit required
- Out of service

Derive status automatically where practical.

Avoid allowing arbitrary status that contradicts actual inventory state.

---

# 41. DAILY MANAGEMENT — WORKSTREAM E

Daily management must optimize speed.

Normal scenario:

One or several emergencies happen.

The nurse prioritizes patients and medicines.

No inventory interaction is required while treating patients.

After the emergency period, the professional opens I-Crash and records what was consumed.

The user can identify products by:

## Virtual drawer

Navigate visually and select a slot.

## Search/list

Search/select medicine name.

Because the same product may only appear once inside a specific cart, selecting the product uniquely identifies its slot.

---

# 42. MULTIPLE EMERGENCIES

Do NOT require:

- Start Session
- End Session
- New Emergency
- closing one emergency before opening another

There may be two or more emergencies consecutively.

For the current prototype, the professional can wait until the emergency activity has ended and record all consumed material together.

Example:

During two consecutive emergencies:

- 2 Adrenaline used
- 1 Atropine used
- 3 Syringes used

Afterwards, the user simply records those total quantities.

Do not pretend to know which exact emergency consumed which medicine.

Do not create artificial event grouping that was not actually entered by the healthcare professional.

Each stock adjustment still receives:

- timestamp;
- responsible user;
- cart;
- product;
- amount;
- audit metadata.

Future client requirements may introduce more detailed emergency grouping if needed.

---

# 43. DAILY QUANTITY INTERACTION

Interaction should be extremely fast.

Example:

Adrenalina

`[-] 2 [+]`

`Registar utilização`

or a more efficient equivalent validated through testing.

Daily saving must:

1. decrease `currentQuantity`;
2. never go below valid bounds without explicit correction handling;
3. NOT decrement any assumed lot;
4. NOT modify known lot expiry merely because stock decreased;
5. preserve `earliestKnownExpiry`;
6. create an immutable audit/usage event;
7. work offline;
8. give immediate visual feedback.

---

# 44. CORRECTIONS

Authorized users must have a safe correction mechanism.

Do not silently edit/delete the original consumption event.

Prefer compensating/correction events.

Example:

Original:
`-2 Adrenaline`

Correction:
`+1 Adrenaline — correction of event XYZ`

History remains traceable.

---

# 45. COMPLETE AUDIT LOG

Keep detailed audit information wherever operationally meaningful.

Examples:

- role changes;
- permissions;
- institution memberships;
- cart assignments;
- cart creation;
- drawer creation;
- layout changes;
- product assignments;
- quantity changes;
- consumption;
- replenishment;
- new lot;
- lot correction;
- expiry correction;
- monthly verification;
- checklist;
- status changes;
- templates;
- administrative actions.

Where applicable store:

- actor UID;
- event type;
- institution;
- cart;
- drawer;
- slot;
- product;
- amount;
- previous value;
- new value;
- local timestamp;
- synchronized/server timestamp;
- correction reference/reason.

Logs must not be casually editable by normal users.

---

# 46. PERIODIC / MONTHLY MANAGEMENT — WORKSTREAM F

Default expiry-warning horizon:

1 month.

Make it configurable per institution.

Periodic audit must physically verify the cart.

The user must verify every drawer before the cart audit can be considered completed.

The workflow should:

1. choose assigned cart;
2. display drawer list/status;
3. enter each drawer;
4. show its virtual layout;
5. highlight products needing review;
6. verify quantities;
7. verify known lots;
8. verify expiration dates;
9. add missing batches;
10. remove batches physically confirmed absent;
11. correct stock;
12. mark drawer verified;
13. require every drawer before completion;
14. reconcile aggregate quantity and batch state;
15. recompute `earliestKnownExpiry`;
16. log performer and completion time.

---

# 47. EXPIRY PRIORITY

Dashboard/audit UI should clearly indicate urgency.

Example categories:

- Expired
- ≤ 30 days
- 31–60 days
- > 60 days

The institution-configured expiry threshold controls the main warning behavior.

Never rely on color alone.

Use accessible text/icons.

---

# 48. IMPORTANT EXPIRY PHILOSOPHY

Expiry information must be conservative.

If the system cannot prove that an early-expiry lot was removed, continue warning about that expiry.

Do not infer physical lot removal from aggregate daily consumption.

The monthly/physical audit is responsible for establishing that a lot is gone.

This rule must be explicitly covered by unit tests.

---

# 49. DASHBOARD — WORKSTREAM G

After login:

1. select institution when necessary;
2. show alerts/dashboard;
3. allow navigation to assigned carts.

Dashboard should show relevant items such as:

- assigned carts;
- carts operational;
- replenishment required;
- audit overdue;
- products expired;
- products close to expiry;
- slots needing review;
- checklist warnings;
- recent relevant activity.

Provide fast access to cart through:

- list/search;
- internal QR scan.

Do not show unauthorized carts.

---

# 50. NOTIFICATIONS

Notifications are desirable.

During the current free prototype phase prioritize:

- in-app alerts;
- local device notifications where appropriate.

Potential notifications:

- approaching expiry;
- overdue audit;
- replenishment requirement;
- checklist reminders.

Keep a `NotificationService` abstraction so future subscription/commercial versions can introduce:

- FCM;
- trusted server-side scheduling;
- Cloud Functions;
- multi-device notifications.

Do not build an insecure client-side message sender.

---

# 51. REPORTING — WORKSTREAM H

Provide operational reports/history in the application.

Include:

- consumption by product;
- consumption by cart;
- consumption by period;
- replenishment history;
- expired/discarded stock where available;
- audit history;
- current stock;
- expiry state;
- activity/audit history;
- user activity according to permissions.

Since emergencies are not explicitly grouped in this prototype, do NOT invent per-emergency consumption reports.

The report can show usage events/time ranges.

Provide detailed popup/view and PDF export.

Generate PDF locally initially.

Prepare architecture for possible CSV/Excel later.

---

# 52. DAILY CHECKLIST

Support configurable daily/operational checklists.

Do not invent clinical procedures.

Checklist definitions must be configurable.

The purpose is to support readiness validation without encoding unverified hospital-specific policy.

---

# 53. UI/UX REDESIGN — WORKSTREAM D

The 2023 academic interface requires major modernization.

Remove normal-product dependence on old academic institution logos.

Create an I-Crash visual identity/logo.

Use modern Flutter/Material 3 patterns where appropriate.

Primary design goals:

1. speed;
2. clarity;
3. professional healthcare appearance;
4. accessibility;
5. minimum taps;
6. tablet usability;
7. responsive desktop usability.

Do not prioritize decorative effects over operational efficiency.

Create reusable:

- typography;
- spacing;
- buttons;
- cards;
- statuses;
- alerts;
- dialogs;
- forms;
- navigation;
- grid visuals;
- inventory controls.

Dark mode can be supported but must not block important workflows.

---

# 54. RESPONSIVE UI

Mobile/tablet:

- touch-first;
- large interaction targets;
- camera scanner;
- rapid stock actions.

Desktop/Web:

- side navigation where appropriate;
- greater information density;
- keyboard interaction;
- HID scanner support;
- administration screens.

Do not simply stretch mobile layouts.

---

# 55. FULL APPLICATION WALKTHROUGH

Do this only after the minimum Firebase replacement is functional enough for the application to operate.

Do not restore Django merely to perform the test.

On Android emulator `ICrash_API_36`:

Inspect every accessible screen and classify each feature:

- WORKING
- WORKING BUT NEEDS IMPROVEMENT
- BUG
- OBSOLETE
- NOT YET IMPLEMENTED

Record findings in:

`docs/TEST_STATUS.md`

Fix obvious bugs and regressions.

---

# 56. LIVE DEBUG — MANDATORY AFTER CHANGES

For each significant change:

1. `flutter analyze`
2. relevant automated tests
3. launch/use `ICrash_API_36`
4. `flutter run`
5. navigate to modified feature
6. actually interact with it
7. verify visual output
8. inspect logs/errors
9. test normal flow
10. test relevant invalid/edge flow
11. fix failures
12. update test documentation

A code review or successful build alone is not enough.

---

# 57. AUTOMATED TESTS

Expand testing using:

- unit tests;
- widget tests;
- repository tests;
- Firestore emulator tests;
- Firebase Rules tests;
- `integration_test`.

Critical scenarios:

- login;
- institution selection;
- cart permissions;
- drawer rendering;
- merge/split;
- consumption;
- replenishment;
- GS1 parsing;
- multiple lots;
- conservative expiry logic;
- monthly reconciliation;
- offline write;
- reconnect/sync;
- unauthorized QR scan;
- role restrictions.

---

# 58. CRITICAL INVENTORY TEST CASE

Create an explicit automated test:

Initial:

`currentQuantity = 5`

Known batches:

Lot A:
- expiry October

Lot B:
- expiry December

`earliestKnownExpiry = October`

Daily consumption:

`consume(1)`

Expected:

`currentQuantity = 4`

Lot A:
unchanged

Lot B:
unchanged

`earliestKnownExpiry = October`

Then monthly audit confirms Lot A absent.

Remaining physically verified inventory:
Lot B only.

Expected after reconciliation:

`currentQuantity = verified quantity`

`earliestKnownExpiry = December`

This rule must never regress into FEFO/FIFO assumptions.

---

# 59. SECOND CRITICAL INVENTORY TEST

Initial nearest expiry:

December 2026

Restock adds:

Lot C
expiry October 2026
quantity 3

Expected:

`currentQuantity += 3`

Lot C stored.

`earliestKnownExpiry = October 2026`

Daily consumption afterwards must NOT automatically decrement Lot C.

---

# 60. SECURITY TESTS

Explicitly test:

- unauthenticated access denied;
- Institution A user cannot access Institution B;
- user cannot upgrade their own role;
- unassigned user cannot access cart;
- physical QR scan does not bypass authorization;
- normal User cannot alter drawer structure;
- Manager permissions are enforced;
- normal User cannot rewrite audit history;
- queued offline operation must still satisfy security rules when synchronized.

---

# 61. DEVELOPMENT DEPENDENCY ORDER

Common prerequisites:

## Phase 0
Git and `DEV-Pedro`.

## Phase 1
Firebase project/configuration.

## Phase 2
Architecture, repository interfaces, Firestore model foundation, offline model, emulator and security foundation.

Do not start parallel feature work until these common foundations are stable.

---

# 62. PARALLEL WORKSTREAM — A

Branch:

`feature/auth-access`

Scope:

- Authentication
- users
- institutions
- memberships
- roles
- permissions
- cart assignments
- security rules

Depends on Phase 0–2.

---

# 63. PARALLEL WORKSTREAM — B

Branch:

`feature/drawer-layout`

Scope:

- carts
- drawers
- slots
- virtual drawer
- new rectangular geometry
- merge/split
- layout versioning
- templates
- duplication

Depends on Phase 0–2.

Can run in parallel with A/C/D.

---

# 64. PARALLEL WORKSTREAM — C

Branch:

`feature/inventory-gs1`

Scope:

- products
- cart product uniqueness
- aggregate current quantity
- batches/lots
- conservative expiry
- GS1 Data Matrix
- replenishment
- scanner abstraction
- periodic reconciliation domain rules

Depends on Phase 0–2.

Can run in parallel with A/B/D.

---

# 65. PARALLEL WORKSTREAM — D

Branch:

`feature/ui-i18n`

Scope:

- Material 3/design system
- I-Crash branding
- PT-PT
- English
- responsive navigation
- reusable UI components

Depends on Phase 0–2.

Must not independently rewrite domain behavior owned by other workstreams.

---

# 66. SECOND PARALLEL WAVE

After A+B+C are integrated:

## Workstream E
Daily stock consumption.

Depends on:
A+B+C.

## Workstream F
Periodic/monthly verification and expiry management.

Depends on:
A+B+C.

E and F can largely run in parallel.

---

# 67. THIRD PARALLEL WAVE

After E/F:

## Workstream G
Dashboard / alerts / notifications.

## Workstream H
Reports / PDF / history.

## Workstream I
Internal QR / HID / scanner extensions.

These can largely proceed in parallel.

---

# 68. FINAL WORKSTREAM

## Workstream J — QA / hardening / releases

Perform:

- full Android validation;
- Windows validation;
- Web validation;
- later iOS testing from macOS;
- later macOS testing;
- accessibility review;
- performance review;
- offline/reconnection validation;
- Firebase Rules/security review;
- release configuration;
- package/application identifiers;
- Android signing;
- environment separation.

Do not consider `com.example.*` or development signatures production-ready.

---

# 69. COMMERCIAL FUTURE

Current phase:

Professional prototype/demo.

Infrastructure preference:

Free whenever practical.

Future potential:

- investors;
- investment fund;
- healthcare customers;
- subscription model;
- paid Firebase/Google Cloud infrastructure.

Therefore:

Do NOT prematurely build a complex subscription/payment platform now.

But avoid architecture that assumes:

- exactly one institution forever;
- unlimited free infrastructure forever;
- no server-side processing ever;
- no paid plan ever.

Keep service/repository boundaries ready for future commercial infrastructure.

---

# 70. GIT COMMITS

After each stable phase/logical feature:

1. inspect diff;
2. ensure no secrets;
3. run automated tests;
4. perform relevant live emulator validation;
5. update documentation;
6. commit;
7. push only to intended development/feature branch.

Never push directly to `main`.

Suggested commits:

- `chore: modernize Flutter project and dependencies`
- `feat: add Firebase project foundation`
- `feat: add institution scoped authentication`
- `feat: add Firestore domain architecture`
- `feat: add drawer layout model`
- `feat: add inventory and batch model`
- `feat: add GS1 Data Matrix replenishment`
- `feat: add fast daily consumption`
- `feat: add periodic inventory reconciliation`
- `feat: add operational dashboard`
- `feat: add PDF reports`

---

# 71. SECRETS

Never commit:

- passwords;
- PATs;
- service-account private keys;
- SSH private keys;
- private API secrets.

Do not treat hiding IDs or UI controls as security.

Authorization belongs in:

- Firebase Authentication;
- Firestore Security Rules;
- domain/application checks;
- App Check where appropriate.

---

# 72. HEALTHCARE USER QUESTIONS

Maintain:

`docs/OPEN_DECISIONS.md`

Include at least:

1. Can a physical compartment have an L/T/non-rectangular shape?
2. Should Managers be allowed to change active drawer structures?
3. Can more than one healthcare professional simultaneously be responsible for one cart?
4. Is a minimum stock quantity useful in addition to current and target/max quantity?
5. Should GS1 Data Matrix scanning during replenishment eventually become mandatory?
6. Is the conservative lot strategy correct: daily consumption changes only aggregate quantity and lot reconciliation happens during physical audits?
7. How often should a complete physical cart audit occur?
8. Must every individual slot be explicitly confirmed, or is mandatory confirmation of every drawer sufficient?
9. Which checklist items are operationally required?
10. Which notifications are valuable without producing alert fatigue?
11. Which roles may correct historical inventory entries?
12. Which GS1 information should normal users actually see?
13. How often are carts duplicated from an identical configuration?
14. Are there institution-specific rules for expiry warning periods?
15. Is it useful in a future version to distinguish stock usage between individual consecutive emergencies, or is aggregate post-emergency recording preferable?
16. Should replenishment require confirmation that the scanned Data Matrix product matches the slot product?
17. How should partially known lots be displayed during the period between emergency consumption and the next physical reconciliation?

Do not invent clinical answers.

---

# 73. FUTURE FEATURES — DO NOT IMPLEMENT NOW

Document for future consideration:

- product images;
- Firebase Storage;
- mandatory Data Matrix replenishment;
- L/T/non-rectangular slot geometry;
- Cloud Functions;
- server-side FCM automation;
- NFC login;
- staff QR login;
- username/password login;
- institutional SSO;
- commercial subscriptions;
- billing;
- advanced analytics;
- advanced server infrastructure;
- deeper Windows production Firebase alternative if required;
- patient systems/integration.

Patient-identifiable data remains outside the intended I-Crash domain unless a completely separate future regulatory decision is made.

---

# 74. DEFINITION OF DONE

A feature is complete only when:

- architecture is coherent;
- data model is documented;
- permissions/security are enforced;
- localization is respected;
- automated tests pass;
- Android emulator test succeeds;
- UI behavior is visually verified;
- relevant offline behavior is checked;
- relevant error states are handled;
- logging exists where necessary;
- documentation is updated;
- Git commit exists;
- no secrets were introduced.

Do not optimize for number of lines/files changed.

Optimize for:

- healthcare-worker speed;
- reliability;
- maintainability;
- traceability;
- security;
- clear future evolution.

---

# 75. STARTING INSTRUCTION

START ONLY WITH:

## PHASE 0 — GIT / `DEV-Pedro`

Do not immediately start redesigning UI or implementing all Firebase functionality.

After Phase 0:

Proceed to Phase 1.

After Phase 1:

Proceed to Phase 2.

After Phase 2 is stable, prepare the repository so A/B/C/D can be distributed between independent programmers/AI coding agents.

Before any irreversible Firebase configuration action, especially database location selection, stop and ask the user when necessary.

After each phase report:

- phase completed;
- changes made;
- files changed;
- tests executed;
- live Android emulator validation;
- limitations;
- commit hash;
- next recommended phase.

If context is becoming low, follow the mandatory handoff procedure instead of continuing until context is lost.