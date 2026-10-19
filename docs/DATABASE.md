# I-Crash: database design

The relational database design for I-Crash, to be implemented and tested in PostgreSQL.

| Part | Content | Status |
|---|---|---|
| **1. Conceptual model** | Entity–relationship (ER) diagram: entities, attributes, relationships and cardinalities | **Finished** (18 Oct 2026), being validated |
| **2. Logical model** | Relational schema: tables, columns, types and sizes, NULL / NOT NULL, primary and foreign keys, constraints | **Defined** (18 Oct 2026). The PostgreSQL script with realistic data comes next |

**Diagrams:**
- Conceptual: [`ICrash_ERD_Conceptual.png`](ICrash_ERD_Conceptual.png). Part 1 explains it; if the two
  ever disagree, the diagram is the reference.
- Logical: [`ICrash_ERD_Logical.png`](ICrash_ERD_Logical.png), generated from the conceptual model by
  ERDplus (a beta feature). It's a reference only: where it's wrong, part 2 corrects it and lists the
  corrections (§2.5).

Background reasoning: `Claude outputs/ERD_Review_2026-10-18.md` (the review rounds that led to this model).

**Context.** I-Crash manages hospital crash carts: the emergency trolleys whose drawers hold
medicines and material that must always be complete and in date. Today a nurse checks each cart
on paper once a month. Each institution (hospital, clinic…) runs I-Crash on **its own local
server**, and nothing inside an institution is shared outside it. A user belongs to one
institution.

---

# Part 1: Conceptual model

## 1.1 How to read the diagram

| Symbol | Meaning |
|---|---|
| Rectangle | Entity |
| Double rectangle | **Weak entity**: it can only exist inside its parent, and is identified within that parent |
| Diamond | Relationship |
| Double diamond | **Identifying relationship**: the one that links a weak entity to its parent |
| Ellipse | Attribute |
| Dashed ellipse | **Derived** attribute: calculated from other data, not entered |
| <u>Underline</u> | **Unique**: no two rows share the value |
| Dashed underline | **Partially unique** (partial key): unique only within the parent of a weak entity. Drawer 1 exists in every cart, but only once per cart |
| (O) | **Optional**: may be empty. Attributes without (O) are mandatory |

**Cardinalities** use crow's-foot ends on each relationship line. The symbol closest to the
entity is the maximum, the other one the minimum: `|` = one, `O` = zero, crow's foot = many.
In this document they are written as **min..max**: `1..1` (exactly one), `0..1` (at most one),
`0..N` (any number, possibly none).

**Modelling conventions used throughout:**

- A property with **two possible values** (yes/no) is a **boolean attribute**, for example
  `isTemplate`. Booleans are always mandatory.
- A property with **three or more possible values** is a **lookup entity** (a small list of
  allowed values), for example **CartState**. This keeps the values in one place and lets new
  ones be added without changing the structure.
- A many-to-many relationship is drawn as an **associative entity** with two one-to-many
  relationships (SlotCC, UserTypePermission, CrashCartUser), so it can carry its own attributes.
- Each entity has an `id…` attribute, drawn as unique. Primary and foreign keys are decided in
  part 2.
- There are **no composite attributes** in this model.

**Summary of the model (22 entities, 29 relationships):**

| Area | Entities |
|---|---|
| Organisation | Institution, Department |
| Cart structure | CrashCart, CartState, Drawer, Slot |
| Stock | SlotCC, Batch, SlotState, ClinicalConsumable, Category |
| People and access | User, UserType, Permission, UserTypePermission, CrashCartUser |
| Reports | Report, ReportStatus, ReportItem, ResultItem |
| Logbook | History, HistoryType |

---

## 1.2 Entities and attributes

### Organisation

#### Institution
**What it is:** the hospital or clinic that uses I-Crash.
**Why it's here:** every cart, department and user belongs to an institution. Each server holds
only one institution, but keeping the entity scopes all the data to its hospital, holds the
hospital's settings, and allows a multi-site version later.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idInstitution` | Unique | Identifies the institution |
| `name` | | The institution's name, shown in the app and on reports |
| `expiryWarningDays` | | How many days before its expiry date an item counts as **expiring**. Hospitals may use different warning periods, so it's a setting per institution |

#### Department (weak, under Institution)
**What it is:** a service or ward inside the institution, e.g. Urgência, Cardiologia.
**Why it's here:** carts are placed in departments, and managers look at carts per department.
A department only exists inside its institution, so it's a weak entity.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idDepartment` | Partially unique | Identifies the department within its institution |
| `name` | | The department's name |
| `floor` | | The floor the department is on. A cart's floor is found through its department, so it isn't repeated on the cart |

### Cart structure

#### CrashCart
**What it is:** one physical crash cart, or a reusable cart layout (a **template**) when
`isTemplate` is true.
**Why it's here:** the cart is the central object of the system: everything that's checked,
used and replenished lives in a cart. Templates use the same entity because they have exactly
the same structure (drawers, slots, consumables); they just don't stand in a department.
CrashCart isn't weak: a template has no department.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idCrashCart` | Unique | Identifies the cart |
| `name` | | The name staff use, e.g. "Carro Urgência 1" |
| `location` | | Where the cart stands inside the department, e.g. "Sala de reanimação" |
| `qr_code` | | The content of the QR label stuck on the cart. Scanning it opens that cart in the app |
| `isTemplate` | Boolean | True if this row is a template layout rather than a real cart |
| `archived` | Boolean | True if the cart is retired. Carts are never deleted, because their history and reports must be kept |
| `autoState` | Boolean | True if the cart's state is updated automatically (expired or missing item → replenishment required; check overdue → audit required). False if staff set it by hand (decision D7) |

#### CartState (lookup)
**What it is:** the list of possible cart states: Operational, Replenishment required, Audit
required, Out of service.
**Why it's here:** the state has four values, so by the convention above it's a lookup entity.
It's what the carts list shows at a glance.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idCartState` | Unique | Identifies the state |
| `cartState` | Unique | The state's name. Unique so the same state can't be listed twice |

#### Drawer (weak, under CrashCart)
**What it is:** one physical drawer of a cart, shown in the app as a grid of cells.
**Why it's here:** nurses find items by drawer, and each drawer has its own layout. A drawer only
exists inside its cart, so it's a weak entity.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idDrawer` | Partially unique | Identifies the drawer within its cart |
| `number` | | The drawer's position in the cart (1 = top), as printed on the cart |
| `rows` | | Number of rows in the drawer's grid |
| `columns` | | Number of columns in the drawer's grid |

#### Slot (weak, under Drawer)
**What it is:** a compartment of a drawer: one grid cell, or several neighbouring cells merged
into one larger compartment.
**Why it's here:** a consumable is kept in a specific compartment, and the app draws the drawer
from its slots. A slot only exists inside its drawer, so it's a weak entity.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idSlot` | Partially unique | Identifies the slot within its drawer |
| `row` | | Row of the slot's top-left cell in the grid |
| `column` | | Column of the slot's top-left cell |
| `rowSpan` | | How many rows the slot covers (1 for a single cell) |
| `columnSpan` | | How many columns the slot covers |

The position label shown to nurses ("B3") isn't stored; it's calculated from `row` and `column`.

### Stock

#### SlotCC (associative entity: Slot ↔ ClinicalConsumable)
**What it is:** a clinical consumable placed in a slot, together with its stock in that slot.
**Why it's here:** a consumable can be in many carts, and a cart holds many consumables. SlotCC
is the link between a slot and the consumable it holds, and it's where the quantities live.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idSlotCC` | Unique | Identifies the placement |
| `maxNumberCC` | | The full quantity: how many units the slot should hold. Below this, the slot needs replenishing. There's no minimum stock (decision D10) |
| `currNumberCC` | | How many units are in the slot now. **Stored**, not derived: it's updated with every stock change recorded in History |
| `earliestExpirationDate` | **Derived** | The earliest expiry date among the slot's batches that haven't been removed. It drives the expiry warnings and the slot's colour in the grid |

#### Batch (weak, under SlotCC)
**What it is:** a group of units in one slot that share the same expiry date.
**Why it's here:** one slot can hold units with different expiry dates (e.g. 3 expiring in
December and 2 in March). A single date on SlotCC couldn't record that, and the nurse would have
to read every date again at each check. Nurses register the date and quantity when they stock a
slot (by scanner or by hand); each date becomes a batch. A batch only exists inside its slot
placement, so it's a weak entity.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idBatch` | Partially unique | Identifies the batch within its SlotCC |
| `expirationDate` | | The expiry date shared by the batch's units |
| `quantity` | | How many units with this date were put in the slot. Daily consumption doesn't lower it, because nobody records which unit was used; `currNumberCC` holds the real count |
| `lotNumber` | Optional | The manufacturer's lot code. Optional because many items have none, or it isn't read |
| `removedAt` | Optional | When the batch was confirmed gone (used up, discarded or not found). Empty while the batch is in the slot. Batches are never deleted, so the history stays complete |

#### SlotState (lookup)
**What it is:** the list of possible slot states: Valid/OK, Replenishment needed, Expiring,
Expired.
**Why it's here:** four values, so a lookup entity. It's what the grid shows on each slot. The
state that applies is worked out from `currNumberCC`, `maxNumberCC`, `earliestExpirationDate`,
the institution's `expiryWarningDays` and today's date.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idSlotState` | Unique | Identifies the state |
| `slotState` | Unique | The state's name |
| `priority` | | Decides which state is shown when a slot has two problems at once (e.g. expired *and* short): the worst one wins |

#### ClinicalConsumable
**What it is:** a catalogue item: a medicine or a piece of material, e.g. "Adrenalina 1 mg/ml,
ampola".
**Why it's here:** the same item is stocked in many carts, so its description is kept once in a
catalogue instead of in every slot.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idClinicalConsumable` | Unique | Identifies the item |
| `name` | | The item's name as staff know it |
| `description` | | Longer description: presentation, strength, notes |
| `weight` | Optional | Weight or dose per unit, when relevant (e.g. 1 mg) |
| `volume` | Optional | Volume per unit, when relevant (e.g. 10 ml) |
| `gtin` | Optional | The GS1 product code read from the item's Data Matrix or barcode, so scanning finds the item. Optional because not every item carries one |

#### Category (lookup)
**What it is:** the kind of item: Fármacos, Material, Fluidos…
**Why it's here:** used to group and filter the catalogue. More than two values, so a lookup
entity.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idCategory` | Unique | Identifies the category |
| `category` | Unique | The category's name |

### People and access

#### User
**What it is:** a person who uses I-Crash: a nurse, a manager, an administrator.
**Why it's here:** every action is recorded against the person who did it, reports are signed by
a person, and permissions depend on who is using the app. The institution creates each user's
credentials and hands them to the employee.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idUser` | Unique | Identifies the user |
| `userNumber` | Unique | The employee number (nº mecanográfico) the institution already uses. It's what the user types to log in |
| `name` | | Full name, shown on History and on signed reports |
| `email` | Optional | Contact email. Optional because not every employee has one the hospital wants to use |
| `passwordHash` | | The password, stored only as a secure hash, never in plain text |
| `pinHash` | | The short PIN used to unlock a cart tablet and to sign reports, stored as a hash. **Not unique**: two people may pick the same PIN, and identity comes from `userNumber` |
| `mustChangeCredentials` | Boolean | True when the user must set their own password and PIN at the next login: after the account is created, or after a reset |

#### UserType
**What it is:** a kind of user: Engineer Admin, Institution Manager, Health Professional (a
fourth type is still to be defined).
**Why it's here:** permissions are given per type of user, not per person.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idUserType` | Unique | Identifies the type |
| `type` | Unique | The type's name |

#### Permission
**What it is:** one action the system can allow or deny: record consumption, replenish, sign
reports, edit a cart's structure…
**Why it's here:** so the set of actions each user type may do can be configured instead of being
fixed in code.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idPermission` | Unique | Identifies the permission |
| `permission` | | The permission's short name |
| `description` | | What the permission allows, in plain words, for the administration screen |

#### UserTypePermission (associative entity: UserType ↔ Permission)
**What it is:** one permission granted to one user type.
**Why it's here:** a user type has many permissions and a permission belongs to many user types.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idUserTypePermission` | Unique | Identifies the grant |

#### CrashCartUser (associative entity: CrashCart ↔ User)
**What it is:** a person responsible for a cart.
**Why it's here:** carts have responsible professionals, a professional can be responsible for
several carts, and a cart can have several responsible people.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idCrashCartUser` | Unique | Identifies the assignment |

Shifts (one responsible person per cart per shift, decision D8) aren't modelled yet; see open
item DB5.

### Reports

#### Report
**What it is:** the document a person signs about a cart: a **monthly check**, or an **emergency
summary** of what was used during an emergency.
**Why it's here:** the monthly check is a formal, signed record (today a paper sheet). A report
groups the work done and fixes it with a signature.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idReport` | Unique | Identifies the report |
| `isEmergency` | Boolean | True for an emergency summary, false for a monthly check |
| `periodStart` | | When the check or the emergency started |
| `periodEnd` | Optional | When it finished. Empty while it's still in progress (a check may be paused and resumed) |
| `signedAt` | Optional | When the report was signed. Empty until it's signed; after that the report can't change |
| `notes` | Optional | Free comments by the person who did the check |

#### ReportStatus (lookup)
**What it is:** the stages of a report: In progress, Pending signature, Signed.
**Why it's here:** three values, so a lookup entity. Lets managers see unfinished and unsigned
reports.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idReportStatus` | Unique | Identifies the status |
| `reportStatus` | Unique | The status's name |

#### ReportItem
**What it is:** one batch that had to be dealt with during a monthly check.
**Why it's here:** a monthly check only looks at items that are **expired or expiring**;
everything else counts as valid (decision D4). When the check starts, the app creates one
ReportItem for each such batch. The list is the nurse's to-do list for the check, and records
what was done with each batch.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idReportItem` | Unique | Identifies the item |
| `handledAt` | Optional | When the nurse dealt with the item. Empty means not done yet, so the nurse can stop and resume later. The check can only be finished when every item has it |

Whether an item was *expired* or *expiring* isn't stored: it's worked out from the batch's
`expirationDate` and the report's `periodStart`.

#### ResultItem (lookup)
**What it is:** what was done with a checked batch: Replaced, Discarded (no stock), Kept, Not
found.
**Why it's here:** four values, so a lookup entity. It gives every check the same, comparable
outcomes.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idResultItem` | Unique | Identifies the result |
| `resultItem` | Unique | The result's name |

### Logbook

#### History
**What it is:** the logbook of stock changes: one row for every change in a slot's quantity.
**Why it's here:** traceability. Every use, replenishment, discard and correction must be
traceable to who did it, where and when. Rows are never edited or deleted; a mistake is fixed by
adding a correcting row.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idHistory` | Unique | Identifies the row |
| `amount` | | The change in quantity, with a sign: −2 for two units used, +5 for five added |
| `createdAt` | | When the change was recorded |
| `reason` | Optional | Free text explaining the change, e.g. why a correction was made |

Example of a row as the user sees it: *"18/10 14:32 · Enf. Ana Costa · Carro Urgência 1 ›
Gaveta 2 › A3 · Adrenalina · −2 (Consumo)"*.

#### HistoryType (lookup)
**What it is:** the kind of stock change: Consumption, Replenishment, Discard, Correction, Count.
**Why it's here:** five values, so a lookup entity. Used to filter the logbook and build reports.

| Attribute | Marking | What it is and why it exists |
|---|---|---|
| `idHistoryType` | Unique | Identifies the type |
| `historyType` | Unique | The type's name |

---

## 1.3 Relationships

Each relationship is listed with its name as drawn, its cardinality on each side, and what it
means in both directions. "A 1..1 : B 0..N" means each B is linked to exactly one A, and each A to
zero or more B.

### Organisation

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R1 | Institution — **Is composed by** — Department *(identifying)* | Institution 1..1 : Department 0..N | An institution has any number of departments; each department belongs to exactly one institution |
| R2 | Institution — **Belongs to** — User | Institution 1..1 : User 0..N | An institution has any number of users; each user belongs to exactly one institution. A person working in two hospitals has two accounts |
| R3 | Department — **Has a** — CrashCart | Department 0..1 : CrashCart 0..N | A department has any number of carts; a cart is in at most one department. Zero because templates aren't in any department |

### Cart structure

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R4 | CrashCart — **Created from** — CrashCart *(recursive)* | Template 0..1 : Copy 0..N | A cart may have been created from one template; a template may have been used to create any number of carts. Creating a cart copies the template's drawers, slots and consumables with their `maxNumberCC` once; later changes to the template don't affect the copies, and History is never copied |
| R5 | CartState — **Has a** — CrashCart | CartState 1..1 : CrashCart 0..N | Every cart is in exactly one state; a state applies to any number of carts |
| R6 | CrashCart — **Is composed by** — Drawer *(identifying)* | CrashCart 1..1 : Drawer 0..N | A cart has any number of drawers; each drawer belongs to exactly one cart |
| R7 | Drawer — **Is composed by** — Slot *(identifying)* | Drawer 1..1 : Slot 0..N | A drawer has any number of slots; each slot belongs to exactly one drawer |

### Stock

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R8 | Slot — **Relates** — SlotCC | Slot 1..1 : SlotCC 0..1 | A slot holds at most one consumable (it may be empty); each placement is in exactly one slot |
| R9 | ClinicalConsumable — **Relates** — SlotCC | ClinicalConsumable 1..1 : SlotCC 0..N | A catalogue item can be placed in any number of slots (in different carts); each placement is of exactly one item |
| R10 | SlotCC — **Has** — Batch *(identifying)* | SlotCC 1..1 : Batch 0..N | A placement has any number of batches (one per expiry date); each batch belongs to exactly one placement |
| R11 | SlotState — **Has a** — SlotCC | SlotState 1..1 : SlotCC 0..N | Each placement is in exactly one state at any moment; a state applies to any number of placements |
| R12 | Category — **Has a** — ClinicalConsumable | Category 1..1 : ClinicalConsumable 0..N | Each item is in exactly one category; a category groups any number of items |

### People and access

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R13 | UserType — **Is of a** — User | UserType 1..1 : User 0..N | Every user is of exactly one type; a type has any number of users |
| R14 | UserType — **Relates** — UserTypePermission | UserType 1..1 : UserTypePermission 0..N | A type has any number of granted permissions; each grant is for exactly one type |
| R15 | Permission — **Relates** — UserTypePermission | Permission 1..1 : UserTypePermission 0..N | A permission can be granted to any number of types; each grant is of exactly one permission |
| R16 | CrashCart — **Relates** — CrashCartUser | CrashCart 1..1 : CrashCartUser 0..N | A cart has any number of responsible people; each assignment is for exactly one cart |
| R17 | User — **Relates** — CrashCartUser | User 1..1 : CrashCartUser 0..N | A user can be responsible for any number of carts; each assignment is of exactly one user |

Together, R14 + R15 form the many-to-many link between UserType and Permission, and R16 + R17 the
many-to-many link between CrashCart and User.

### Reports

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R18 | CrashCart — **Which** — Report | CrashCart 1..1 : Report 0..N | Every report is about exactly one cart; a cart has any number of reports over time |
| R19 | User — **Performed and/or Signed by** — Report | User 1..1 : Report 0..N | Every report has exactly one responsible user, who performs the check and signs it; a user can have any number of reports. A separate signer (e.g. a manager) is open item DB4 |
| R20 | ReportStatus — **Has a** — Report | ReportStatus 1..1 : Report 0..N | Every report is in exactly one status; a status applies to any number of reports |
| R21 | Report — **Relates** — ReportItem | Report 1..1 : ReportItem 0..N | A report has any number of items to check; each item belongs to exactly one report. Only monthly checks have items |
| R22 | Batch — **Checks** — ReportItem | Batch 1..1 : ReportItem 0..N | Each report item is about exactly one batch; a batch can appear in any number of checks over time (e.g. "expiring" this month, "expired" next month). The slot, drawer, cart and consumable are all reached through the batch |
| R23 | ResultItem — **Result** — ReportItem | ResultItem 0..1 : ReportItem 0..N | An item has at most one result: none until the nurse handles it; a result can be given to any number of items |

### Logbook

| # | Relationship | Cardinality | Meaning |
|---|---|---|---|
| R24 | User — **Who** — History | User 1..1 : History 0..N | Every stock change was made by exactly one user; a user makes any number of changes |
| R25 | SlotCC — **What and where** — History | SlotCC 1..1 : History 0..N | Every stock change is to exactly one placement, which tells *what* item changed and *where* (slot, drawer, cart); a placement has any number of changes. History holds stock changes only; administrative changes are left to the security phase (DB12) |
| R26 | HistoryType — **Has a** — History | HistoryType 1..1 : History 0..N | Every change is of exactly one type; a type applies to any number of changes |
| R27 | Batch — **Affects** — History | Batch 0..1 : History 0..N | A change may concern one batch: a replenishment points to the batch it created or added to, a discard to the batch it removed from. Consumption rows have no batch, because nobody records which unit was used. A batch can be affected by any number of changes |
| R28 | Report — **Lists** — History | Report 0..1 : History 0..N | A change may have been made during a check or an emergency, and then belongs to that report; ordinary daily changes have no report. A report lists any number of changes |
| R29 | History — **Corrects** — History *(recursive)* | Corrected 0..1 : Correction 0..N | A correction row points to the one row it fixes; a row may be corrected by any number of later rows. The original row is never changed |

---

## 1.4 How Report and History work together

- **History is the logbook.** A row is written automatically for every stock change, by anyone,
  at any time.
- **A Report is the signed sheet** that today is done on paper.
  - **Monthly check:** the whole cart is checked in one go (breaks allowed). When the check
    starts, the app creates one ReportItem for each batch that is expired or expiring at that
    moment. **Everything else is valid by default and isn't checked.** The nurse handles each
    item (replace, discard, keep, or not found), which fills its `handledAt` and its result. Any
    replacement or discard made during the check is a History row linked to the report (R28).
    The check can only be finished when every item is handled; then it's signed.
  - **Emergency summary:** the consumption rows recorded during the emergency, linked to the
    report (R28), added up per consumable. That total is also the list of what to replenish.
- **Calculated, not stored:** whether a report item was expired or expiring; SlotCC
  `earliestExpirationDate`; the emergency summary lines; a check's progress (handled vs total
  items); the position label of a slot ("B3").

**Example, one slot over a month** (max 5): replenished with 3 units expiring Dec 2026 and 2
expiring Jun 2027 → two batches, `currNumberCC` = 5, earliest date Dec 2026. An emergency uses 2
units → History −2, `currNumberCC` = 3, batches unchanged (nobody knows which units were used), so
the slot keeps warning about December. The monthly check flags the December batch; the nurse finds
none of those units left → result "Not found", the batch gets `removedAt`, and the earliest date
becomes Jun 2027. Replenishing 2 units expiring Mar 2027 → a new batch and `currNumberCC` = 5.

---

## 1.5 Rules the diagram can't show

These constraints come from the business rules and will be enforced in part 2:

- A consumable appears in **only one slot per cart** (it may be in many carts).
- Slots stay inside their drawer's grid (counting rows and columns from 1:
  `row + rowSpan − 1 ≤ rows` and `column + columnSpan − 1 ≤ columns`) and don't overlap.
- `0 ≤ currNumberCC ≤ maxNumberCC`; a batch's `quantity` is greater than 0. "Needs
  replenishment" means `currNumberCC < maxNumberCC`; there is no minimum stock.
- After an emergency and until the next check, the total quantity of a slot's active batches may
  be **greater** than `currNumberCC`. This is intended: the app doesn't know which units were
  used, so it keeps warning about the earliest date until a check confirms it.
- During a check, a flagged batch whose units aren't in the slot gets the result "Not found" and
  a `removedAt`.
- Only carts with `isTemplate` = true can be the template side of "Created from". Every real cart
  (not a template) must have a department; templates have none.
- Report items exist only on monthly checks (`isEmergency` = false).
- A check can only be finished when every report item has `handledAt`.
- A signed report has `signedAt` and can no longer be changed.
- History rows are never edited or deleted. Batches and carts are never deleted either
  (`removedAt`, `archived`).
- PIN hashes are salted, so `pinHash` is never checked for uniqueness.

---

## 1.6 Open items

Also tracked in `docs/OPEN_DECISIONS.md` §2b. Open points found while building the logical model
(DB7–DB12) are in §2.6.

| # | Item | Status and notes |
|---|---|---|
| DB1 | Batch | **Decided (18 Oct): adopted** and drawn. Still to test the scenarios in PostgreSQL (part 2), and to confirm with ESEL how lots are handled after an emergency (clinical question 6) |
| DB2 | Catalogue per institution or shared (ClinicalConsumable and Category) | **Open.** Not drawn until decided. Pre-filling from a public list (e.g. INFARMED Infomed, medicines only) would be a one-way copy into the hospital's server |
| DB3 | Login method | **Open.** Institution-issued `userNumber` + password + PIN, changed on first login. Possibly the hospital's own login (Active Directory) later. Use a slow, salted hash and an attempt limit |
| DB4 | Separate signer (decision D6) | **Open.** Today one relationship (R19) covers both performing and signing |
| DB5 | Shifts on CrashCartUser (decision D8) | **Open.** Would add the day and the shift to the assignment |
| DB6 | Checking only flagged items | **Open.** Relies on recorded quantities being right. Ask ESEL whether procedure still requires a quick look at the rest |

---

# Part 2: Logical model

The relational schema for PostgreSQL, derived from the conceptual model in part 1.

**Diagram:** [`ICrash_ERD_Logical.png`](ICrash_ERD_Logical.png) (ERDplus, beta). The tables below
are the reference; §2.5 lists where they differ from the diagram and why.

## 2.1 How the conceptual model was translated

| Conceptual element | Becomes |
|---|---|
| Strong entity | A table, with its `id…` as **primary key (PK)** |
| Weak entity (Department, Drawer, Slot, Batch) | A table whose PK is its **partial key plus the PK of its parent**. Slot is under Drawer, which is under CrashCart, so Slot's PK has three columns |
| 1 : N relationship | A **foreign key (FK)** column on the N side, pointing to the PK of the 1 side. **NOT NULL** if the minimum on the 1 side is 1 (`1..1`); **NULL** if it's 0 (`0..1`) |
| 1 : 0..1 relationship (Slot — SlotCC) | An FK on the 0..1 side with a **UNIQUE** constraint, so a slot can't hold two consumables |
| Associative entity (SlotCC, UserTypePermission, CrashCartUser) | A table with its own PK and an FK to each side |
| Recursive relationship (Created from, Corrects) | An FK to the same table, with a new name so it doesn't clash with the PK |
| Unique attribute | A **UNIQUE** constraint |
| Optional attribute (O) | **NULL** allowed. Every other column is **NOT NULL** |
| Derived attribute (`earliestExpirationDate`) | Not stored; calculated in a **view** (§2.4) |
| Lookup entity | A small table filled with its fixed values when the database is created |

**Types and sizes used:**

| Type | Used for |
|---|---|
| `INTEGER`, **auto** | Every `id…` column a table generates itself. Auto = `GENERATED ALWAYS AS IDENTITY`: PostgreSQL numbers new rows 1, 2, 3… This also applies to the partial keys of weak tables; their PK stays composite, as the model says |
| `INTEGER` | Every FK column (same type as the PK it points to) |
| `SMALLINT` | Small counts and grid sizes (−32 768 to 32 767): quantities, drawer numbers, rows, columns, priorities, warning days |
| `VARCHAR(n)` | Text with a maximum length of *n* characters. Sizes are chosen per column, with room to spare |
| `CHAR(14)` | The GTIN, which always has exactly 14 digits |
| `BOOLEAN` | Yes/no attributes. Always NOT NULL, with a default |
| `DATE` | Expiry dates (day precision) |
| `TIMESTAMPTZ` | Moments in time (date + time + time zone), so summer/winter time changes don't confuse the order of events |

**How to read the tables below:** *Key* shows PK, FK (→ the table it points to) and UNIQUE. A key
made of several columns (composite) is written under **Constraints**, below each table, together
with the CHECK rules. CHECK = a condition the database rejects a row for breaking.

---

## 2.2 Tables

### Organisation

#### INSTITUTION
One row: the hospital or clinic this server belongs to.

| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idInstitution` | PK | INTEGER, auto | NOT NULL | |
| `name` | | VARCHAR(150) | NOT NULL | |
| `expiryWarningDays` | | SMALLINT | NOT NULL | Default 30. CHECK `> 0` |

#### DEPARTMENT
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idDepartment` | PK | INTEGER, auto | NOT NULL | Partial key |
| `idInstitution` | PK, FK → INSTITUTION | INTEGER | NOT NULL | R1 |
| `name` | | VARCHAR(100) | NOT NULL | |
| `floor` | | VARCHAR(20) | NOT NULL | Text, because floors are written like "-1", "R/C", "2.º" |

**Constraints:** PK (`idDepartment`, `idInstitution`).

### Cart structure

#### CRASHCART
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idCrashCart` | PK | INTEGER, auto | NOT NULL | |
| `qr_code` | | VARCHAR(255) | NOT NULL | The text in the cart's QR label (an `icrash://v1/…` link) |
| `name` | | VARCHAR(100) | NOT NULL | |
| `isTemplate` | | BOOLEAN | NOT NULL | Default false |
| `location` | | VARCHAR(150) | NOT NULL | |
| `archived` | | BOOLEAN | NOT NULL | Default false |
| `autoState` | | BOOLEAN | NOT NULL | Default true (the D7 rule is on) |
| `idDepartment` | FK → DEPARTMENT | INTEGER | NULL | R3. Empty for templates |
| `idInstitution` | FK → DEPARTMENT | INTEGER | NULL | R3. Second half of the department's key |
| `idCartState` | FK → CARTSTATE | INTEGER | NOT NULL | R5 |
| `idTemplate` | FK → CRASHCART | INTEGER | NULL | R4: the template this cart was created from. Named `idCrashCart` in the ERDplus diagram |

**Constraints:**
- FK (`idDepartment`, `idInstitution`) → DEPARTMENT, `MATCH FULL`: both columns filled or both empty.
- CHECK `isTemplate = (idDepartment IS NULL)`: real carts have a department, templates don't.
- CHECK `idTemplate <> idCrashCart`: a cart isn't its own template.

#### CARTSTATE
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idCartState` | PK | INTEGER, auto | NOT NULL | |
| `cartState` | UNIQUE | VARCHAR(50) | NOT NULL | Operational, Replenishment required, Audit required, Out of service |

#### DRAWER
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idDrawer` | PK | INTEGER, auto | NOT NULL | Partial key |
| `idCrashCart` | PK, FK → CRASHCART | INTEGER | NOT NULL | R6 |
| `number` | | SMALLINT | NOT NULL | CHECK `> 0` |
| `rows` | | SMALLINT | NOT NULL | CHECK `> 0` |
| `columns` | | SMALLINT | NOT NULL | CHECK `> 0` |

**Constraints:** PK (`idDrawer`, `idCrashCart`). UNIQUE (`idCrashCart`, `number`): two drawers of
one cart can't have the same number.

#### SLOT
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idSlot` | PK | INTEGER, auto | NOT NULL | Partial key |
| `idDrawer` | PK, FK → DRAWER | INTEGER | NOT NULL | R7 |
| `idCrashCart` | PK, FK → DRAWER | INTEGER | NOT NULL | R7 |
| `row` | | SMALLINT | NOT NULL | CHECK `≥ 1` |
| `column` | | SMALLINT | NOT NULL | CHECK `≥ 1` |
| `rowSpan` | | SMALLINT | NOT NULL | Default 1. CHECK `≥ 1` |
| `columnSpan` | | SMALLINT | NOT NULL | Default 1. CHECK `≥ 1` |

**Constraints:** PK (`idSlot`, `idDrawer`, `idCrashCart`). FK (`idDrawer`, `idCrashCart`) → DRAWER.
Fitting inside the drawer's grid and not overlapping other slots needs a trigger (§2.3).

### Stock

#### SLOTCC
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idSlotCC` | PK | INTEGER, auto | NOT NULL | |
| `maxNumberCC` | | SMALLINT | NOT NULL | CHECK `> 0` |
| `currNumberCC` | | SMALLINT | NOT NULL | Default 0. CHECK `0 ≤ currNumberCC ≤ maxNumberCC` |
| `idSlot` | FK → SLOT | INTEGER | NOT NULL | R8 |
| `idDrawer` | FK → SLOT | INTEGER | NOT NULL | R8 |
| `idCrashCart` | FK → SLOT | INTEGER | NOT NULL | R8. Also lets the database enforce "one consumable per cart" |
| `idClinicalConsumable` | FK → CLINICALCONSUMABLE | INTEGER | NOT NULL | R9 |
| `idSlotState` | FK → SLOTSTATE | INTEGER | NOT NULL | R11. Kept up to date by the server (§2.3) |

**Constraints:**
- FK (`idSlot`, `idDrawer`, `idCrashCart`) → SLOT.
- UNIQUE (`idSlot`, `idDrawer`, `idCrashCart`): a slot holds at most one consumable (R8 is 1 : 0..1).
- UNIQUE (`idCrashCart`, `idClinicalConsumable`): a consumable appears in only one slot per cart.
- `earliestExpirationDate` isn't a column: it's derived (view in §2.4).

#### BATCH
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idBatch` | PK | INTEGER, auto | NOT NULL | Partial key |
| `idSlotCC` | PK, FK → SLOTCC | INTEGER | NOT NULL | R10 |
| `expirationDate` | | DATE | NOT NULL | Items marked only with month and year are stored as the last day of that month (as GS1 does) |
| `quantity` | | SMALLINT | NOT NULL | CHECK `> 0` |
| `lotNumber` | | VARCHAR(20) | NULL | 20 = maximum length of a GS1 lot number |
| `removedAt` | | TIMESTAMPTZ | NULL | |

**Constraints:** PK (`idBatch`, `idSlotCC`). UNIQUE (`idSlotCC`, `expirationDate`) among batches
not removed (a partial unique index, `WHERE removedAt IS NULL`): a batch is *the* group of units with
one expiry date, so stocking more units with the same date adds to the existing batch.

#### SLOTSTATE
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idSlotState` | PK | INTEGER, auto | NOT NULL | |
| `slotState` | UNIQUE | VARCHAR(50) | NOT NULL | Valid/OK, Replenishment needed, Expiring, Expired |
| `priority` | | SMALLINT | NOT NULL | Higher = worse; the worst state wins |

#### CLINICALCONSUMABLE
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idClinicalConsumable` | PK | INTEGER, auto | NOT NULL | |
| `name` | | VARCHAR(150) | NOT NULL | |
| `weight` | | VARCHAR(30) | NULL | Value with its unit, e.g. "1 mg", "5000 UI". Text, because medicines use many units |
| `volume` | | VARCHAR(30) | NULL | Value with its unit, e.g. "10 ml" |
| `gtin` | | CHAR(14) | NULL | GTIN-14; shorter codes (EAN-13) are padded with leading zeros. CHECK digits only |
| `description` | | VARCHAR(500) | NOT NULL | |
| `idCategory` | FK → CATEGORY | INTEGER | NOT NULL | R12 |

#### CATEGORY
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idCategory` | PK | INTEGER, auto | NOT NULL | |
| `category` | UNIQUE | VARCHAR(50) | NOT NULL | Fármacos, Material, Fluidos… |

### People and access

#### USER
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idUser` | PK | INTEGER, auto | NOT NULL | |
| `userNumber` | UNIQUE | VARCHAR(20) | NOT NULL | Text, because employee numbers can have letters or leading zeros |
| `name` | | VARCHAR(150) | NOT NULL | |
| `email` | | VARCHAR(254) | NULL | 254 = maximum length of an email address |
| `pinHash` | | VARCHAR(255) | NOT NULL | The encoded hash (algorithm, salt and hash in one string). Not unique |
| `passwordHash` | | VARCHAR(255) | NOT NULL | Same format as `pinHash` |
| `mustChangeCredentials` | | BOOLEAN | NOT NULL | Default true: a new account must change its credentials |
| `idUserType` | FK → USERTYPE | INTEGER | NOT NULL | R13 |
| `idInstitution` | FK → INSTITUTION | INTEGER | NOT NULL | R2 |

#### USERTYPE
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idUserType` | PK | INTEGER, auto | NOT NULL | |
| `type` | UNIQUE | VARCHAR(50) | NOT NULL | Engineer Admin, Institution Manager, Health Professional |

#### PERMISSION
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idPermission` | PK | INTEGER, auto | NOT NULL | |
| `permission` | | VARCHAR(50) | NOT NULL | |
| `description` | | VARCHAR(255) | NOT NULL | |

#### USERTYPEPERMISSION
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idUserTypePermission` | PK | INTEGER, auto | NOT NULL | |
| `idUserType` | FK → USERTYPE | INTEGER | NOT NULL | R14 |
| `idPermission` | FK → PERMISSION | INTEGER | NOT NULL | R15 |

**Constraints:** UNIQUE (`idUserType`, `idPermission`): a permission is granted to a type only once.

#### CRASHCARTUSER
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idCrashCartUser` | PK | INTEGER, auto | NOT NULL | |
| `idCrashCart` | FK → CRASHCART | INTEGER | NOT NULL | R16 |
| `idUser` | FK → USER | INTEGER | NOT NULL | R17 |

**Constraints:** UNIQUE (`idCrashCart`, `idUser`): a person is assigned to a cart only once. To be
revisited if shifts are added (DB5).

### Reports

#### REPORT
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idReport` | PK | INTEGER, auto | NOT NULL | |
| `isEmergency` | | BOOLEAN | NOT NULL | Default false |
| `signedAt` | | TIMESTAMPTZ | NULL | |
| `periodStart` | | TIMESTAMPTZ | NOT NULL | |
| `periodEnd` | | TIMESTAMPTZ | NULL | |
| `notes` | | VARCHAR(1000) | NULL | |
| `idUser` | FK → USER | INTEGER | NOT NULL | R19 |
| `idReportStatus` | FK → REPORTSTATUS | INTEGER | NOT NULL | R20 |
| `idCrashCart` | FK → CRASHCART | INTEGER | NOT NULL | R18 |

**Constraints:** CHECK `periodEnd ≥ periodStart`. CHECK `signedAt IS NULL OR periodEnd IS NOT NULL`:
only a finished report can be signed.

#### REPORTSTATUS
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idReportStatus` | PK | INTEGER, auto | NOT NULL | |
| `reportStatus` | UNIQUE | VARCHAR(50) | NOT NULL | In progress, Pending signature, Signed |

#### REPORTITEM
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idReportItem` | PK | INTEGER, auto | NOT NULL | |
| `handledAt` | | TIMESTAMPTZ | NULL | |
| `idReport` | FK → REPORT | INTEGER | NOT NULL | R21 |
| `idResultItem` | FK → RESULTITEM | INTEGER | NULL | R23 |
| `idBatch` | FK → BATCH | INTEGER | NOT NULL | R22 |
| `idSlotCC` | FK → BATCH | INTEGER | NOT NULL | R22. Second half of the batch's key |

**Constraints:**
- FK (`idBatch`, `idSlotCC`) → BATCH.
- UNIQUE (`idReport`, `idBatch`, `idSlotCC`): a batch appears at most once in a check.
- CHECK `(handledAt IS NULL) = (idResultItem IS NULL)`: an item has a result exactly when it has
  been handled.

#### RESULTITEM
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idResultItem` | PK | INTEGER, auto | NOT NULL | |
| `resultItem` | UNIQUE | VARCHAR(50) | NOT NULL | Replaced, Discarded (no stock), Kept, Not found |

### Logbook

#### HISTORY
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idHistory` | PK | INTEGER, auto | NOT NULL | |
| `amount` | | SMALLINT | NOT NULL | Signed: −2, +5 |
| `createdAt` | | TIMESTAMPTZ | NOT NULL | Default: the current time |
| `reason` | | VARCHAR(500) | NULL | |
| `idReport` | FK → REPORT | INTEGER | NULL | R28 |
| `idUser` | FK → USER | INTEGER | NOT NULL | R24 |
| `idSlotCC` | FK → SLOTCC, and FK → BATCH | INTEGER | NOT NULL | R25, and second half of the batch's key for R27 |
| `idCorrectedHistory` | FK → HISTORY | INTEGER | NULL | R29: the row this one corrects. Named `idHistory` in the ERDplus diagram |
| `idHistoryType` | FK → HISTORYTYPE | INTEGER | NOT NULL | R26 |
| `idBatch` | FK → BATCH | INTEGER | NULL | R27 |

**Constraints:**
- FK (`idBatch`, `idSlotCC`) → BATCH, checked only when `idBatch` is filled. Because `idSlotCC` is
  shared with R25, a History row can only point to a batch of the same slot.
- CHECK `idCorrectedHistory <> idHistory`.

#### HISTORYTYPE
| Column | Key | Type (size) | Null | Notes |
|---|---|---|---|---|
| `idHistoryType` | PK | INTEGER, auto | NOT NULL | |
| `historyType` | UNIQUE | VARCHAR(50) | NOT NULL | Consumption, Replenishment, Discard, Correction, Count |

---

## 2.3 Rules that need triggers

These rules from §1.5 depend on other rows or other tables, so a CHECK can't express them:

| Rule | Where |
|---|---|
| A slot fits inside its drawer's grid (`row + rowSpan − 1 ≤ rows`, `column + columnSpan − 1 ≤ columns`) and doesn't overlap another slot of the same drawer | SLOT, on insert and update |
| `idTemplate` points to a cart with `isTemplate` = true | CRASHCART |
| Report items exist only on monthly checks (`isEmergency` = false) | REPORTITEM |
| A report can only be finished when every item has `handledAt`; a signed report can't change | REPORT |
| History rows are never updated or deleted; batches and carts are never deleted | HISTORY, BATCH, CRASHCART (or by not granting UPDATE/DELETE to the app's database user) |
| `currNumberCC` changes with every History row (`currNumberCC + amount`) | HISTORY, on insert |
| `idSlotState` is recalculated from the quantities and dates. It's stored, so it's recalculated when stock changes and once a day, because a batch can start expiring without anything being recorded | SLOTCC, plus a daily job |

## 2.4 Derived values (views)

Calculated when read, never stored:

| Value | How it's calculated |
|---|---|
| SlotCC `earliestExpirationDate` | `MIN(expirationDate)` of the slot's batches with `removedAt IS NULL` |
| Report item expired or expiring | Expired if the batch's `expirationDate` is before the report's `periodStart`, expiring otherwise |
| Check progress | Report items with `handledAt` vs all items of the report |
| Emergency summary | `SUM(amount)` per consumable of the History rows linked to the report |
| Slot label ("B3") | Letter from `row`, number from `column` |

## 2.5 Corrections to the ERDplus diagram

The ERDplus schema is a beta export. These are the places where the tables above differ from it:

| # | In the ERDplus diagram | Corrected to | Why |
|---|---|---|---|
| 1 | SLOT's PK is only `idSlot` | PK (`idSlot`, `idDrawer`, `idCrashCart`) | Slot is a weak entity: `idSlot` is only unique within its drawer, so the PK must include the drawer's PK |
| 2 | SLOTCC points to Slot with `idSlot` only | `idSlot`, `idDrawer`, `idCrashCart` | An FK must contain the whole PK it points to (follows from 1) |
| 3 | CRASHCART has two columns named `idCrashCart` (PK and the template FK) | The FK is `idTemplate` | A table can't have two columns with the same name |
| 4 | HISTORY has two columns named `idHistory` (PK and the correction FK) | The FK is `idCorrectedHistory` | Same reason |
| 5 | HISTORY has `idSlotCC` twice (R25, and inside the Batch FK) | One `idSlotCC`, used by both FKs | Same reason. Sharing it also guarantees the batch belongs to the same slot as the row |
| 6 | No UNIQUE on SLOTCC's slot columns | UNIQUE (`idSlot`, `idDrawer`, `idCrashCart`) | R8 is 1 : 0..1. Without it, a slot could hold two consumables |
| 7 | — | UNIQUE pairs on USERTYPEPERMISSION, CRASHCARTUSER and REPORTITEM; UNIQUE (`idCrashCart`, `idClinicalConsumable`) on SLOTCC; UNIQUE (`idCrashCart`, `number`) on DRAWER | Business rules the diagram doesn't show |

## 2.6 Open points in the logical model

To settle before the PostgreSQL script. Also tracked in `docs/OPEN_DECISIONS.md` §2b.

| # | Item | Notes |
|---|---|---|
| DB7 | Templates and mandatory columns | `qr_code` and `location` are NOT NULL, as in the conceptual model, but a template isn't a physical cart and has neither. Options: allow NULL only when `isTemplate` = true, or store a placeholder |
| DB8 | Uniqueness of `qr_code` and `permission` | Neither is marked unique. A scanned cart QR must identify exactly one cart, so `qr_code` should probably be UNIQUE. The same applies to a permission's name |
| DB9 | Slot state stored or calculated | SLOTCC stores `idSlotState`, so it must be recalculated whenever stock changes and once a day (§2.3). The alternative is to calculate it in a view, like `earliestExpirationDate`, which removes R11's FK |
| DB10 | `weight` and `volume` as text | Stored with their unit ("1 mg", "10 ml"), because medicines use many units. Numbers would need one fixed unit per column |
| DB11 | Deactivating users | USER has no active/disabled status (the Firebase version has one), and a user can't be deleted once History or a Report points to them. Something like an `active` boolean is needed to block people who leave |
| DB12 | Not modelled yet | A per-product expiry warning (the app has one; the model only has the institution's `expiryWarningDays`); drawer layout versions (`DOMAIN.md` §38); the administrative audit log of roles, permissions and layout changes (`DOMAIN.md` §45), left to the security phase |

## 2.7 Names in PostgreSQL

The names above match the diagrams. In the SQL script:
- PostgreSQL turns unquoted names to lowercase (`idCrashCart` becomes `idcrashcart`). The script
  will use **snake_case** (`id_crash_cart`, `curr_number_cc`) so names stay readable without quotes.
- `user` and `column` are reserved words in PostgreSQL. The script will name the USER table
  `app_user` and Slot's `column` column `col` (with `row` kept as is).
