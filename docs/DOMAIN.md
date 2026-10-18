# I-Crash: domain rules

The rules that define what I-Crash is and how its data must behave, with the reasoning
behind them. They come from the original V2 specification (Sep 2026, `ICRASH_V2_SPECIFICATION.md`,
still in git history). Only the domain
content is kept here; the process instructions written for AI agents were dropped.

**Section numbers are the original ones.** Code comments that say *"spec section N"*
refer to **§N in this file**. Gaps in the numbering are sections that were only process
instructions (Git, phases, workstreams, testing routine) and were removed.

"**Today:**" notes say where the design v2 app (Oct 2026) differs from or hasn't yet
implemented a rule. Current decisions are in [OPEN_DECISIONS.md](OPEN_DECISIONS.md);
how the app implements all this is in [APP.md](APP.md) and [FIREBASE.md](FIREBASE.md).

Updated 15 Oct 2026.

---

## Product

### 5. Product purpose
I-Crash represents and manages **physical emergency (crash) carts**. It helps nurses and
other authorised health professionals do stock tasks with **minimum interaction**. The
two core areas:

- **Daily management:** record what was consumed after emergency use.
- **Periodic / monthly management:** physically verify cart contents, quantities, lots
  and expiry dates.

Real clinical workflow always comes first. **Never design an interaction that assumes a
nurse will stop patient care to scan or record inventory.**

### 6. No patient information
I-Crash must **not** contain identifiable patient information: no patient profiles,
names, identifiers, diagnoses or histories, and **no link between consumption and an
individual patient**. Consumption history is inventory and operational data only.

---

## Platform and infrastructure

### 7. Infrastructure constraints
- Stay on the **free Firebase plan (Spark)** during the prototype. No billing without
  explicit authorisation from the owners.
- Use Authentication, Cloud Firestore and the Local Emulator Suite.
- Don't depend on deployed Cloud Functions, Firebase Storage or paid infrastructure.
  Product images are deferred.
- Keep the domain and application layers independent of the infrastructure, so moving
  later to Blaze, Cloud Functions, Storage, FCM or a subscription product doesn't need a
  rewrite.

### 8–9. Environments and location
- Local development uses the emulators (at least Auth and Firestore). The cloud project
  is a separate demo/development environment, and tests must never modify its data.
- The Firestore location is irreversible. It was confirmed with the owners: `eur3`
  (Europe).

### 11. Offline first
- The app must stay usable without connectivity, especially on Android and iOS.
  **Recording consumption must not fail just because Wi-Fi is down.**
- Show the sync state (synced / pending / failed or conflicted) without interrupting
  users with network dialogs.

**Today:** consumption, replenishment and correction use Firestore transactions, which
fail offline. They need to change to batched increments plus an event (FIREBASE.md §8).

### 12. Platforms
One Flutter codebase for Android, iOS, Windows, macOS and web; no second frontend
framework. Desktop must not just stretch the phone UI.

**Today:** decision R1 splits the app into the **App** shell (Android/iOS) and the
**Dashboard** shell (web/desktop).

### 13. Languages
Portuguese (Portugal) and English. No hard-coded user-facing text. The structure must
allow more languages later.

### 14. Authentication
Start with e-mail and password. The architecture must allow other methods later (staff
NFC card, staff QR, institutional identity, other providers). **Don't fake insecure NFC
or QR authentication.**

**Today:** D3 adds a device-local PIN (unlocks a session already saved on the device) and
a cart-scoped session opened by scanning the cart QR. Neither replaces real
authentication.

---

## People and access

### 15. Roles
| Role | Can |
|---|---|
| **Platform Super Admin** | Everything; creates institutions |
| **Institution Admin** | Manages one institution: members, managers, carts, templates, products, permissions, configuration |
| **Manager** | Operational and configuration work on assigned carts and users, per granted permissions; may configure carts and drawers. Whether a Manager may change the layout of an **active** drawer stays open |
| **User** | Normal health professional; sees only the institutions and carts explicitly assigned |

**Today:** D2 renames these as Engineer Admin, Institution Manager and Health
Professional, with a fourth type to define, and gives the Health Professional more
actions. See OPEN_DECISIONS.md.

### 16. Multi-institution
- Several independent institutions; one user may belong to several.
- Membership and permissions are per institution.
- **Access to institution A never grants access to institution B.**
- Initially only a platform admin creates institutions.

### 17. Cart access
- Membership alone doesn't give access to every cart; managers assign users to specific
  carts.
- For now one cart has one responsible user at a time, but the model must allow several
  later without a redesign. This is clinical question 3.

**Today:** responsible users are a subcollection (one document per user). D8 shifts
assign one responsible person per cart per shift.

### 18. Security at database level
Security lives in the **Firestore rules**, not in hidden buttons. The rules must
enforce:
- authentication and institution membership;
- roles and cart assignment;
- no privilege escalation and cross-institution isolation;
- limits on destructive operations;
- protection of the audit history.

Internal QR codes never bypass authorisation. The rules have automated tests.

---

## Structure and products

### 19. Domain structure
**Institution → Cart → Drawer → Slot → Assigned product → Inventory.** Unlike the 2023
app, don't store everything inside the slot. Keep these separate:

| Concept | What it is |
|---|---|
| **Slot** | A physical position in the drawer's layout |
| **Product** | A reusable definition of a medicine or material |
| **CartProductAssignment** | One product in one slot of one cart |
| **Inventory / batches** | Stock, lots and expiry |

### 20. One slot per product per cart
The same medicine can be in many carts, but **within one cart a product occupies only
one slot**. For example, Adrenaline can be in Cart 1 / Drawer 1 / Slot 5 *and* in
Cart 2 / Drawer 2 / Slot 3, but not in two slots of Cart 1. Enforce this in the domain and
data, not only in the UI. It's also why choosing a product inside a cart identifies its
slot.

### 21. Product model
- Keep it simple: name, volume or weight, application or description.
- The model supports GS1 identifiers (**GTIN**) for Data Matrix mapping, but the GTIN
  needn't dominate the UI.
- Product images are deferred.

**Today:** products also have a category (drug, material, fluid) and an expiry-warning
override.

---

## Stock, lots and expiry (the critical part)

### 22. Slot stock model
Each assignment has `currentQuantity`, `targetQuantity` (max), an optional
`minimumQuantity`, `earliestKnownExpiry` and a status.

**`currentQuantity` is the authoritative, fast operational number** used in daily
consumption. Don't derive it by summing known batches: the aggregate and the batches
deliberately have different jobs.

### 23. Lots (batches)
- One medicine can have several lots with different expiry dates.
- A batch holds: lot number, product, cart and slot, a known quantity (when set by a
  replenishment or audit), expiry date, GTIN if available, timestamps, author, and
  source (manual / GS1 Data Matrix / periodic audit).
- Lot quantities are **not** always in sync with daily consumption. That's deliberate.

### 24. Daily consumption never assumes a lot
During an emergency, staff don't scan what they use. Afterwards a nurse records "2 units
of X were used", and the system can't know which physical lot was taken.

- **Never** choose a lot automatically. **Never** assume FEFO or FIFO. **Never**
  decrement a batch because it expires earlier.
- Daily consumption must:
  1. identify the cart, product and slot;
  2. lower only `currentQuantity`;
  3. create an immutable consumption event;
  4. leave lot attribution unchanged;
  5. keep the conservative expiry.

### 25. Conservative expiry
Known lots: A expires in October, B in December. One unit is consumed. The app must
**not** assume the October unit was used, so the nearest expiry **stays October** until
a replenishment or audit shows lot A is gone.

The app may then warn about an expiry that has already left the cart. That's accepted:
**a false alarm to check stock is safer than silently assuming an earlier-expiring
medicine is gone.**

### 26. Expiry on replenishment
- Nearest known expiry December, a lot expiring **October** is added → it becomes
  October **immediately**.
- A lot expiring January 2027 is added → it stays December.
- Adding a lot never removes or replaces existing lots.

### 27. Monthly audit reconciliation
The periodic check is where physical reality is reconciled. During it:
- verify quantities, lots and expiry dates;
- remove lots confirmed absent and add lots that weren't known;
- correct lot quantities.

Then **recompute `currentQuantity` and `earliestKnownExpiry` from what was physically
verified.** This is the right moment to move the expiry forward (e.g. lot A confirmed
gone → the expiry becomes December).

### 28. Consequence for the data
Don't write code that assumes `currentQuantity == sum(batch quantities)` at every
moment. It can differ after emergency consumption. There are three distinct ideas:

| Idea | What it is |
|---|---|
| **Operational aggregate** | `currentQuantity`: fast, updated immediately |
| **Known batch state** | Lots as last established by a replenishment or audit |
| **Reconciliation** | The audit that brings the two back into agreement |

### 47. Expiry urgency
Show urgency clearly, e.g. expired / ≤ 30 days / 31–60 days / > 60 days. The
institution's warning threshold drives the main warning. **Never rely on colour alone;**
use text and icons.

**Today:** slot states are expired, missing, expiring (within the window), low stock,
OK and free.

### 48. Expiry philosophy
Expiry information is conservative. If the system can't prove an early-expiring lot was
removed, it keeps warning. Physical lot removal is **never inferred** from aggregate
consumption; only the physical audit establishes it. This is covered by unit tests.

### 58. Critical test 1 (must never regress)
1. Start: `currentQuantity = 5`; lot A expires October, lot B December;
   `earliestKnownExpiry = October`.
2. `consume(1)` → `currentQuantity = 4`, lots A and B unchanged, expiry still
   **October**.
3. An audit confirms lot A absent and only lot B remains → `currentQuantity` = the
   verified quantity, expiry = **December**.

### 59. Critical test 2
1. Nearest expiry is December 2026.
2. Replenish lot C (October 2026, quantity 3) → `currentQuantity += 3`, lot C stored,
   expiry = **October 2026**.
3. A later daily consumption must **not** decrement lot C.

Both tests are in `app/test/domain/inventory_rules_test.dart`.

---

## Scanning and codes

### 29. Two separate scanning domains
**Medicines use GS1 Data Matrix**, not the app's QR. Never call medicine scanning a "QR
scan". Keep the two apart in code and wording:

| | Internal I-Crash QR | Medicine GS1 Data Matrix |
|---|---|---|
| Identifies | Cart, drawer, optionally slot | The medicine |
| Carries | An opaque id | GTIN, expiry, lot |

### 30. Data Matrix during replenishment
- Scanning is useful mainly for replenishment and audits, not during emergencies. It's
  **optional**: the user can retry, cancel or type the data.
- Flow:
  1. open the slot and enter the quantity;
  2. optionally scan;
  3. parse and identify or validate the product;
  4. take the lot and expiry, with manual correction allowed;
  5. update the aggregate and the lot;
  6. recompute the expiry conservatively;
  7. log the event.
- **An unknown GTIN is never silently attached to a product.** An authorised person
  confirms the mapping.

**Today:** D9 adds EAN-13 and Code 128 barcodes for products.

### 31. GS1 fields
The parser supports at least AI **01** (GTIN), AI **17** (expiry) and AI **10**
(batch/lot). Recognising the code and parsing it are separate layers, and the parser has
tests that don't need a camera.

### 32. Scanner abstraction
Business logic never depends on `MobileScanner` directly. The abstraction covers the
camera (Android/iOS/macOS), web where feasible, USB/Bluetooth HID and keyboard-style
scanners, and mock scanning for tests. This matters most for Windows.

### 33. Internal QR codes
- They identify a cart, drawer or slot with **opaque, stable ids** in a versioned
  payload, e.g. `icrash://v1/cart/<opaque-id>`. The UI shows readable labels
  ("Carro 2 / Gaveta 1 / Slot 1").
- **Scanning grants nothing.** The flow is: scan → resolve id → authenticate → check the
  institution → check cart permission → show. Anyone without access gets "access
  denied".

### 34. QR labels
Authorised roles can generate printable QR labels. Don't store QR images in Firestore:
store the ids and draw the QR when needed.

---

## Drawers, carts and templates

### 35. Drawer representation
The drawer screen is a faithful picture of the real drawer: its dimensions, compartments,
merged compartments, products and stock/expiry state. Visual fidelity matters more than
keeping the 2023 storage format.

### 36. Drawer grid model
- Rectangular slots are stored as `row`, `column`, `rowSpan`, `columnSpan`.
- The editor defines rows × columns, selects cells, **merges a valid rectangle** into one
  slot, and splits it back.
- Prevent overlaps, invalid geometry, unreachable cells and inconsistent layouts.

### 37. Irregular shapes (future)
Don't implement L, T or other non-rectangular slots now, but keep the schema flexible
enough to add them without rewriting the inventory (e.g. replace the span fields with a
list of cells). This is clinical question 1.

### 38. Drawer structure changes
- Layouts change over time. Initially only Admin may change the layout of an active
  drawer; keep Manager permission configurable.
- Changes must not destroy historical understanding. Use **layout versions or
  snapshots**, so history can show the cart as it was when an event happened.

**Today:** structure editing is in the Dashboard (B4, manager+). Carts have a
`layoutVersion` field, but no snapshots are stored yet. Orphaned assignments (slot
removed) are flagged for reassignment or removal.

### 39. Templates and duplication
- Support duplicating carts and drawers, and reusable cart and drawer templates.
- **Templates and duplicates copy configuration only, never consumption, audit or event
  history.**

**Today:** cart templates exist (B6, local stub). Drawer templates and "duplicate drawer"
don't.

### 40. Cart status
- States: **Operational**, **Replenishment required**, **Audit required**, **Out of
  service**.
- Derive the status automatically where practical, and don't allow a status that
  contradicts the actual inventory.

**Today:** D7 rule (switchable per cart):
- expired or missing → replenishment required;
- check older than 31 days → audit required (shown as "Verificação em atraso");
- otherwise → operational;
- out of service is always manual.

---

## Daily and periodic work

### 41. Daily management
Optimise for speed. Typical case: one or several emergencies happen and the nurse treats
the patient, with **no inventory interaction during care**. Afterwards they open I-Crash
and record what was consumed, finding products either by the **virtual drawer** or by
**search** (the product identifies its slot, §20).

### 42. Multiple emergencies
- **Don't** require "start session", "end session", "new emergency", or closing one
  emergency before the next.
- Consecutive emergencies can be recorded together afterwards as totals (e.g.
  2 Adrenaline, 1 Atropine, 3 Syringes).
- **Don't pretend to know which emergency used what**, and don't invent groupings the
  professional didn't enter.
- Each stock change still records the time, user, cart, product, amount and audit data.

**Today:** emergency mode (A10) groups the consumption recorded while it's open into a
summary report. It's an idea kept but **left out of the final prototype**, and it
mustn't contradict this section. See OPEN_DECISIONS.md §4.

### 43. Recording a daily quantity
Must be extremely fast, e.g. `Adrenalina [-] 2 [+]  Registar utilização`. Saving must:
1. lower `currentQuantity`, never below valid bounds without an explicit correction;
2. not decrement any assumed lot, and not change any lot's expiry;
3. keep `earliestKnownExpiry`;
4. create an immutable usage event;
5. **work offline**;
6. give immediate visual feedback.

### 44. Corrections
Authorised users can correct mistakes, but **the original event is never edited or
deleted**. A compensating event is added instead, e.g. original `−2 Adrenaline` →
correction `+1 Adrenaline, correcting event XYZ`.

### 45. Audit log
- **What to log**, wherever it matters operationally:
  - roles, permissions, memberships, cart assignments;
  - cart and drawer creation, layout changes, product assignments;
  - quantity changes, consumption, replenishment;
  - new lots, lot and expiry corrections;
  - monthly checks, checklists, status changes, templates, administrative actions.
- **Fields to store:** actor, event type, institution, cart, drawer, slot, product,
  amount, previous and new value, local and server timestamps, correction reference or
  reason.
- **Logs can't be edited** by normal users. In the rules, nobody can edit or delete them.

### 46. Periodic / monthly check
- Default expiry warning: **1 month**, configurable per institution.
- **Every drawer must be verified** before the check counts as complete.
- Flow:
  1. choose the cart and see its drawers and their state;
  2. enter each drawer and see its layout, with products needing review highlighted;
  3. verify quantities, lots and expiry dates;
  4. add missing lots, remove lots confirmed absent, correct stock;
  5. mark the drawer verified;
  6. when every drawer is done, reconcile (§27);
  7. record who did it and when.

**Today:** A8 (D4, half-confirmed) goes drawer by drawer and flags positions with
differences in the report. Lot-level reconciliation is done from the slot panel.

**Update 18 Oct (D4 decided):** the monthly check covers the whole cart in one go, but
only the items that are **expired or expiring** are checked; the rest is valid by default.
The "every drawer must be verified" rule above is replaced. The app still needs to change
(A8). See `docs/OPEN_DECISIONS.md` D4 and `docs/DATABASE.md` §1.4.

### 52. Daily checklist
Support configurable operational checklists, but **don't invent clinical procedures**:
the checklist items must be configurable. This is clinical question 9.

**Today:** not implemented.

---

## Overview, alerts and reports

### 49. Dashboard
After login (and choosing an institution when needed), show alerts and fast access to
the user's carts:
- assigned carts and their states (operational, replenishment required, audit overdue);
- expired and expiring products, and slots needing review;
- checklist warnings and recent activity.

Open a cart by list, search or internal QR. **Never show carts the user can't access.**

**Today:** cross-cart alerts are manager+ only, because of a Firestore rules limitation
(FIREBASE.md §6).

### 50. Notifications
- Desirable. During the free prototype phase, prioritise in-app alerts and local device
  notifications (expiry approaching, check overdue, replenishment needed, checklist
  reminders).
- Keep a `NotificationService` abstraction so FCM, server scheduling or Cloud Functions
  can come later.
- **Never build an insecure client-side message sender.**

### 51. Reports
- In-app reports and history:
  - consumption by product, by cart and by period;
  - replenishment history, expired or discarded stock where known;
  - audit and activity history, current stock and expiry state;
  - user activity per permissions.
- Detailed view and **PDF export**, generated locally; CSV/Excel can come later.
- Since emergencies aren't grouped, **don't invent per-emergency consumption reports**.

---

## Design principles (from the spec)

### 53–54. UI
- **Goals, in order:** speed, clarity, professional healthcare look, accessibility,
  minimum taps, tablet usability, responsive desktop.
- No academic institution logos; the app has its own identity.
- Reusable typography, spacing, buttons, cards, status, alerts, dialogs, forms,
  navigation, grid visuals and stock controls.
- **Touch devices:** large targets, a camera scanner, fast stock actions.
- **Desktop:** side navigation, denser information, keyboard and HID scanner support,
  administration.
- Don't stretch mobile layouts.

**Today:** this is realised by design v2. See [DESIGN.md](DESIGN.md).

---

## Security, future and limits

### 60. Security tests
Test explicitly:
- unauthenticated access is denied;
- institution A can't reach institution B;
- nobody can raise their own role;
- an unassigned user can't open a cart;
- a QR scan doesn't bypass authorisation;
- a normal user can't change drawer structure;
- manager permissions are enforced;
- nobody can rewrite the audit history;
- operations queued offline still have to satisfy the rules when they sync.

**Today:** in `firebase/firestore-tests/rules.test.mjs`.

### 69. Commercial future
- Today the product is a professional prototype on free infrastructure. It may later
  serve investors, healthcare customers and a subscription model.
- **Don't build subscriptions or payments now**, but don't assume one institution
  forever, free infrastructure forever, or no server-side processing ever.

### 71. Secrets
Never commit or generate service-account keys, keystores, signing passwords or `.env`
files. Real credentials are handled by the owners, outside the repository.

### 72. Healthcare questions
These moved to [OPEN_DECISIONS.md](OPEN_DECISIONS.md) §3. Don't invent clinical
answers.

### 73. Future features (not now)
- Product images and Firebase Storage.
- Mandatory Data Matrix replenishment.
- L/T/non-rectangular slots.
- Cloud Functions and server-side FCM.
- NFC, staff QR, username, and institutional SSO login.
- Subscriptions and billing.
- Advanced analytics and server infrastructure.
- A Windows-specific Firebase alternative if needed.
- Integration with patient systems.

**Patient-identifiable data stays outside I-Crash** unless a completely separate future
regulatory decision is made.
