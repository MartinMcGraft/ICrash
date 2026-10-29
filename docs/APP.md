# I-Crash: the app

How the Flutter app in `app/` works: who uses it, what every screen does, the main
flows, and how the code is organised. For setup, read the repository
[README](../README.md); for the backend, [FIREBASE.md](FIREBASE.md); for the visual
design, [DESIGN.md](DESIGN.md).

Updated 29 Oct 2026 (design v2, branch `DEV-Martim`; aligned with the database decisions
of 28 Oct: no minimum stock, no overfill, drawer numbers, batches never deleted, structure
fixed once used, templates archived, credentials set by the administration).

This describes the app **as it runs today, on Firebase**. The relational database designed
on 18 Oct for the local-server version is in [DATABASE.md](DATABASE.md); where it changes
how a screen should work, a "Database model" note says so.

---

## 1. One codebase, two shells

The same Flutter app runs everywhere. The **platform** chooses the shell; the user's
**role and permissions** decide what is visible inside it (decision R1/D1).

| Shell | Platforms | For | Layout |
|---|---|---|---|
| **App** | Android, iOS, iPadOS (phone and tablet) | Health professionals at the cart: monthly checks, replenishing, emergencies | Landscape only. Navy side rail (96 px on tablet, 72 px on phone) |
| **Dashboard** | Web, Windows, macOS, Linux | Managers and admins: configuration, catalogue, users, shifts, reports | 240 px navy sidebar |

- Override for testing: `flutter run --dart-define=ICRASH_SHELL=app` (or `dashboard`).
- In **debug builds** the profile menu has "Ver como App / Ver como Dashboard" to switch
  shells at runtime.
- Phones and tablets are locked to landscape in `main.dart`; desktop and web windows
  are left alone.

### Navigation

| App rail | Dashboard sidebar (hidden items depend on role) |
|---|---|
| Carrinhos (carts) | Visão geral (overview) |
| Relatórios (reports) | Carrinhos (carts) |
| Ler código (scan) | Catálogo: manager+ |
| Perfil (profile menu, bottom) | Modelos (templates): manager+ |
| | Utilizadores (users): institution admin+ |
| | Turnos (shifts): manager+ |
| | Relatórios (reports) |
| | Histórico (history) |

Sections the user can't use are **hidden**, not shown disabled. Each section keeps its
own navigation stack (`SectionNavigator`), so switching sections doesn't lose your place.

**Profile menu** (both shells): language (Português / English), lock now (only with a
PIN), switch institution (only with more than one), the debug-only shell switch, and sign
out. There is no "set/change PIN" any more (DB3): a line says "Para alterar as suas
credenciais, contacte a administração." 

---

## 2. Users and permissions

### Roles in the code

| Code role (`Role`) | Product name (D2) | Scope |
|---|---|---|
| `platformSuperAdmin` | Engineer Admin | Every institution. Granted by a `platformAdmins/{uid}` document, not a membership |
| `institutionAdmin` | Institution Manager | Everything in one institution, including users |
| `manager` | Institution Manager (without user management) | Configuration and stock in one institution |
| `user` | Health Professional | The carts they're responsible for |

"Manager+" in this document means `manager`, `institutionAdmin` or `platformSuperAdmin`.

**Database model:** user types and their permissions are tables (UserType, Permission,
UserTypePermission), so the B7 toggles become shared data instead of a local stub. A user
belongs to one institution, so the institution picker isn't needed on a local server.

### Permission toggles (B7)

`AppPermission` (`domain/entities/app_permission.dart`) holds the fine-grained switches
shown in **B7 Users & permissions**:

`viewCarts`, `recordConsumption`, `replenish`, `monthlyCheck`, `signReports`,
`emergencyMode`, `changeCartState`, `editDrawers`, `manageUsersAndShifts`.

- **Defaults:** a Health Professional (`user`) gets view carts, record consumption,
  replenish, monthly check, sign reports and emergency mode. Manager+ roles get all.
- An institution admin can change the toggles per role in B7. They're stored **locally
  on the device** for now (a stub), so they shape what the UI offers.
- **Firestore Rules are the real enforcement** and are role-based. For example, the
  rules let a `user` change only `currentQuantity`, so in practice **replenishing,
  assigning products and changing cart state need manager+** even if the toggle is on.
  `SessionController` combines both: `canReplenish = isManager && can(replenish)`.

Session helpers (`ui/core/session/session.dart`): `isManager`, `isInstitutionAdmin`,
`can(permission)`, `canConsume`, `canReplenish`, `canChangeCartState`,
`canEditStructure`, `canUseEmergency`, `canMonthlyCheck`.

---

## 3. Signing in (A1–A3)

```
start ─▶ saved session on this device?
          ├─ no  ─▶ A1 Login (e-mail + password)
          └─ yes ─▶ A1 with "Desbloquear com PIN" / "Entrar no carro" ─▶ A2 PIN  or  A3 Cart login
                                         │
                                         ▼
                 one institution? ─▶ open it   │   several ─▶ institution picker
                                         ▼
                              App shell or Dashboard shell
```

| Screen | What it does |
|---|---|
| **A1 Login** (`features/auth/login_screen.dart`) | E-mail and password through Firebase Auth. No "forgot password" (DB3): a note says to contact the administration. When a session is saved on the device, it also offers the PIN and cart login |
| **A2 PIN unlock** (`pin_unlock_screen.dart`) | Unlocks the session already saved on this device, offline. The PIN is **set by an administrator in B7** (DB3), stored as a salted PBKDF2 hash in the membership's `private/credentials` document; the device copies the hash after each online sign-in and checks the PIN against it. Five wrong attempts drop the saved session and require the password. "Não é {nome}? Iniciar sessão" signs out. A user with no PIN set can only sign in with the password |
| **A3 Cart login** (`cart_login_screen.dart`) | Decision D3: scanning a cart's QR (or typing the code printed under it) opens a session **limited to that cart**. NFC is shown but is a stub |
| **Institution picker** (`institution_picker_screen.dart`) | Lists the institutions where the user has an active membership. Skipped automatically when there's only one |

The flow lives in `ui/app/app_root_view_model.dart` (stages:
`starting → signedOut | locked | pin | cartLogin → pickingInstitution → ready`).

**Credentials (DB3, done 29 Oct):** only the administration sets or resets a user's
password and PIN (B7); users can't change their own, and the app offers no way to.
**Interim, under Firebase:** the PIN hash is readable by its user so the device can check
it offline, and a 4-digit PIN can be brute-forced from it (FIREBASE.md §9). In the
relational model the institution issues `userNumber` + password + PIN and its server checks
the PIN; the login method itself (e-mail today) is chosen per institution, last.

---

## 4. App shell screens

### A4 Carts list (+ A12 offline)
`features/carts/carts_screen.dart`

- One **card per cart**: name, service and location, a **state chip**, one alert line
  (e.g. "1 expirado · 2 em falta" or "Tudo conforme"), last monthly check, and who is
  responsible on the current shift.
- Filters: all, needs attention, mine. Search by name.
- **A12** is the same screen while offline: a notice plus the sync indicator; cached data
  stays readable.

### A5 Cart
`features/cart/cart_screen.dart`

- The cart's **drawers**, shown as **"Gaveta N"** in number order (P17: drawers have a
  number and no name), each with its own state (worst slot wins) and counts.
- **Cart menu:** monthly check · search product (shows "Gaveta N · posição B3") · show
  the cart QR code · change state (manager+) · the cart's reports. The **Modo de
  emergência** button is **hidden** for now (P12; `kEmergencyModeEnabled` in
  `cart_screen.dart`); A10's code is kept.
- **Automatic state (D7)**, when switched on for the cart in B3:
  - expired or missing product → **Reposição necessária**;
  - last monthly check older than **31 days** → **Verificação em atraso**
    (`auditRequired`);
  - otherwise → **Operacional**;
  - **Fora de serviço** is always manual and never overridden.

  The rule is `suggestedCartStatus` in `domain/inventory_health.dart`. A manager's
  client writes the change.

### A6 Drawer + A7 Replenish
`features/drawer/drawer_screen.dart`

- The drawer's **slot grid** (`SlotGrid`). Each cell shows the product's short name,
  quantity, and a status badge when it isn't OK. Free slots look different from
  "assigned, 0 units".
- There's **no minimum quantity** (D10). Stock always stays within **0 … target** (P5:
  no overfill): Repor stock is offered only up to the target, and a correction or
  reconciliation can't go above it or below 0 (PT/EN messages; the rules enforce it too).
- **Database model:** the panel's data is a SlotCC with its batches. "Earliest known
  expiry" is calculated from the batches not yet removed.
- **Tapping a slot** opens the side panel **over** the grid (it never shrinks the grid).
  The panel shows the product, quantity vs target, earliest known expiry, lots, and
  actions:
  - **Registar consumo:** lower the quantity (anyone with `recordConsumption`).
  - **Repor stock (A7):** add units with an **expiry date** (required), a quantity > 0
    and an **optional lot** (P9). Can be pre-filled by a GS1 scan; month-only GS1 dates
    become the **last day of the month** (P11). The event records the batch it created.
    Manager+ under the current rules. Same-date batches aren't merged yet (P10 open).
  - **Atribuir / trocar produto:** a product can be in only **one slot per cart**, and a
    slot holds one product. The initial quantity can't exceed the target. Once the slot
    has History, **"Trocar produto" is refused** (P1: a used slot keeps its product).
  - **Reconciliar:** after a physical audit, confirm the real quantity and which batches
    are present; the others are **marked removed** (`removedAt`), never deleted (DB1).
    Quantity, batches and event are written together.
  - **Corrigir:** fix a past event with a compensating event, with an **optional
    reason** (shown in B9 and the CSV).
- Slot states (`SlotHealth`), one per slot, the highest priority wins (DB9). The order
  lives in one table, `slotStatePriority` in `domain/inventory_health.dart` (values to be
  fixed with P4): **expired** → **missing** (0 units) → **expiring** (within the warning
  window, default 30 days) → **low stock** (below target, not empty) → **ok**; plus
  **free** (no product).

### A8 Monthly check
`features/monthly_check/`

- Decision D4 (half-confirmed): go **drawer by drawer**. Tap each position: unchecked →
  verified, or → problem (positions that already show an issue start as problem).
  Long-press clears. "Marcar restantes" verifies the rest of the drawer.
- Notes per check. **"Guardar e sair"** saves a draft to continue later.
- **Terminar** creates a monthly-check report (positions with differences are flagged)
  and opens **A9** to sign it.
- **To change (D4 decided, 18 Oct):** the check covers the whole cart in one go, but lists
  only the batches that are **expired or expiring**; everything else counts as valid. The
  nurse handles each one (replaced, discarded, kept, not found), can pause and resume, and
  can finish only when all are handled. Database: REPORT, REPORTITEM and RESULTITEM
  (DATABASE.md §1.4).

### A9 Report: view and sign
`features/reports/report_screen.dart`, list in `reports_list_screen.dart`

- Decision D6: sign with **name + PIN + date**. The signer confirms, enters their PIN
  (the one the administration set), and the report becomes **read-only**.
- **Only the person who performed the check signs it** (DB4): anyone else sees "Só quem
  fez a verificação pode assinar" instead of the PIN field.
- PDF export (`report_pdf.dart`). Reports and signatures are a **local stub** for now.

### A10 Emergency mode
`features/emergency/`

- Proposal §9. In the final prototype it's kept as an idea, not a priority.
- **Set aside (28 Oct, P12):** there's no emergency mode for now, and its rules aren't
  being defined. The screen below is what the code does today.
- **Entry point hidden** (29 Oct): the cart menu doesn't offer it while
  `kEmergencyModeEnabled` is false. The code is kept as it was.
- The shell turns **red** so nobody stays in it by accident.
- **Consumption only:** every product of the cart is visible at once (the column count
  adapts so nothing scrolls); **tap = −1 unit**. "Desfazer último" records a
  compensating correction of **that exact event** (its id is kept on the line).
- **Ending it** sets the cart to *Reposição necessária* (when the role may) and creates
  an emergency summary report.
- Writes that fail offline are counted and kept in the local log and summary (see
  known issue 1 in §8).

### A11 Scanner
`features/scanner/scanner_screen.dart`

- Camera or USB/HID reader, with torch and **manual entry**.
- **Product mode:** GS1 Data Matrix, EAN-13 and Code 128. It finds the product by GTIN
  and where it sits; "Repor este produto" opens the drawer with Replenish pre-filled
  (lot and expiry from the GS1 code). An unknown GTIN is never linked silently.
- **Cart mode:** the cart's internal QR (`icrash://v1/...`) opens that cart. A code from
  another institution is rejected.
- Error messages: unreadable, unknown product, not a cart, other institution, not in any
  cart.

---

## 5. Dashboard shell screens

| Screen | File(s) in `features/dashboard/` | What it does |
|---|---|---|
| **B1 Overview** | `overview_*` | Metrics: operational carts, needing replenishment, expiring within 30 days (and in how many carts), overdue checks, emergencies this month. "Carrinhos que precisam de atenção" list and recent activity (stock events + reports). PDF of the overview |
| **B2 Carts** | `dashboard_carts_*`, `cart_form_dialog.dart` | Table of every cart: state, service, location, drawers, responsible now. Filters and search. **New cart**, from scratch or **from a template** |
| **B3 Cart configuration** | `cart_config_*`, `drawer_form_dialog.dart` | Name, service, location, state, the **automatic state** switch (D7), **archive** (D15: never delete). Drawers table: **Nº** ("Gaveta N"), size, positions, with product. **Add drawer** asks for its **number** (default: lowest free; unique in the cart) and size, and creates one slot per cell. **Alterar número** only while the drawer has no History, or if it never had a number (Q8) |
| **B4 Grid editor** | `grid_editor_*` | Drawer layout: resize rows/columns, select cells, **merge** (the selection must form a rectangle) and **split**, then save. Slot setup: product, target, expiry warning ("Aplicar à posição"), "Limpar posição". A target below the current stock is refused. **Once the drawer has History** (P1/P2) the layout is locked (steppers, merge, split disabled; a warning replaces the hint), used slots keep their product and can't be cleared; targets can still change. **Orphaned assignments** (old data): reassign, or remove only when unused (Q7) |
| **B5 Catalogue** | `catalog_*` | Products: name, presentation, **GTIN (unique)**, category (drug / material / fluid), expiry warning days. Filters by category, "used in N carts". **CSV import** by pasting `nome;apresentação;GTIN;categoria;aviso` |
| **B6 Templates** | `templates_*` | Capture a cart's structure and target quantities as a template; duplicate, rename, re-capture; create a cart from it. Templates never carry stock, lots or history. **Archived, never deleted** (P3): tabs "Ativos / Arquivados", "Arquivar modelo" and "Restaurar"; archived templates aren't offered for new carts but can still be edited (local stub) |
| **B7 Users & permissions** | `users_*` | Members with name, e-mail, role, status. **Criar utilizador** (DB3): name, e-mail, role, **password** (min. 8) and **PIN** (4 digits), each typed twice; the administrator hands them over. Per member: change role, enable/disable, **Definir novo PIN**, **Redefinir palavra-passe** (shows "peça ao suporte técnico": the app can't change another user's Firebase password; IT uses `firebase/tools/set_password.mjs`). Never on yourself. Permission toggles per role (§2) |
| **B8 Shifts** | `shifts_*` | Decision D8: **one responsible health professional per cart per shift**. Week view by cart or by person. Shifts: morning 08–16, afternoon 16–24, night 00–08. "Copiar semana anterior" fills empty slots |
| **B9 Reports & history** | `reports_history_*` | Tabs for reports and events. Filter by cart and month. Totals (consumed, replenished, checks, emergencies, pending signatures), most consumed products, per-cart summary. Event rows show when, where (cart › drawer › position), what and who. CSV export (currently a copy dialog). Reads the latest N events and says when it hits the cap |

The App screens (A5, A6, A8…) also open inside the Dashboard when a manager drills into
a cart.

---

## 6. Inventory model in one page

The full reasoning is in [DOMAIN.md](DOMAIN.md) (§19–28) and [FIREBASE.md](FIREBASE.md) §8.
In short:

- **Institution → Cart → Drawer → Slot.** A slot is a rectangle of grid cells (it can
  span rows and columns).
- **Drawer** has a **number** (unique in its cart) and a grid; its slots are created
  with it. **Assignment** = one product in one slot (`drawerId` + `slotId`) of one cart.
  It holds `currentQuantity` (live stock, always `0 ≤ current ≤ target`),
  `targetQuantity` and `earliestKnownExpiry`. No minimum (D10).
- **Batches** hang under the assignment: expiry, quantity, optional lot number, GTIN,
  source (manual / GS1 scan / audit), and `removedAt` once confirmed gone (never deleted).
- **Usage events** are an append-only log: consumption, replenishment (with the batch it
  created), correction (with an optional reason), audit reconciliation.
- **Structure lock (P1/P2):** the first event of a placement marks it, its slot and its
  drawer with `usedAt`; from then on they can't be deleted or reshaped.

**In the relational model** ([DATABASE.md](DATABASE.md)) the same ideas have these names:
assignment → **SlotCC** (`currNumberCC`, `maxNumberCC`; no minimum), batches → **Batch**
(one per expiry date, `lotNumber` optional, `removedAt` instead of deleting),
`earliestKnownExpiry` → `earliestExpirationDate` (**derived** from the batches not
removed), usage events → **History**. The rules below are unchanged. FIREBASE.md §10 maps
every collection to its table.

Rules (pure functions in `domain/inventory_rules.dart`, tested in
`test/domain/inventory_rules_test.dart`):

1. Consumption only lowers `currentQuantity`. It never picks a lot and never changes the
   expiry.
2. Replenishing adds a batch; `earliestKnownExpiry` can only move **earlier**.
3. Only reconciliation after a physical audit may replace the batches and recompute
   quantity and expiry.
4. Corrections are new events that point at the event they fix.
5. `currentQuantity` may differ from the sum of the lots between an emergency and the
   next audit. That's intended.

---

## 7. Code structure

```
app/lib/
├── main.dart                 landscape lock, Firebase bootstrap, locale, MaterialApp
├── firebase_options.dart     FlutterFire config (cloud project)
├── l10n/                     app_pt.arb (template), app_en.arb
└── src/
    ├── common/               AppServices (DI), AppEnvironment, LocaleScope,
    │                         RepositoryFailure, generated l10n/
    ├── domain/
    │   ├── entities/         Cart, CartDrawer, Slot, CartProductAssignment, Batch,
    │   │                     Product, UsageEvent, AuditEvent, Membership, Role,
    │   │                     AppPermission, Shift, CartTemplate, CartReport,
    │   │                     EmergencySession, …
    │   ├── repositories/     interfaces only
    │   ├── use_cases/        cart_templates.dart
    │   ├── reports/          history summaries, CSV export
    │   ├── inventory_rules.dart    stock/expiry rules (pure)
    │   └── inventory_health.dart   slot/drawer/cart health, D7 auto-state
    ├── data/
    │   ├── firebase/         Firestore + Auth repositories, paths, codec, bootstrap
    │   └── local/            SharedPreferences stubs (prefix "icrash.local.")
    ├── services/             scanners (camera, HID), GS1 parser, internal QR payload,
    │                         sync status, notifications, report service
    └── ui/
        ├── app/              AppRoot + its ViewModel (auth/lock/institution flow)
        ├── shells/           AppShell, DashboardShell, profile menu, navigation
        ├── core/             mvvm/, session/, theme/, icons/, widgets/,
        │                     cart_live_data.dart, format.dart, labels.dart
        └── features/         one folder per area: auth, carts, cart, drawer,
                              monthly_check, reports, emergency, scanner, dashboard
```

### MVVM rules

| Layer | May | Must not |
|---|---|---|
| **View** (`*_screen.dart`) | Build widgets from ViewModel state; forward taps; show results with `showResult` | Call repositories; contain business rules |
| **ViewModel** (`*_view_model.dart`, extends `ViewModel`) | Subscribe with `listen()`, expose getters, run actions with `run()` → `ActionResult` | Use `BuildContext` or Material widgets |
| **Domain** | Pure Dart: entities, interfaces, rules | Import Flutter or Firebase |
| **Data** | Implement repository interfaces | Leak Firestore types upward |

- **Errors:** a ViewModel throws `ActionError('code')` inside `run()`. A
  `RepositoryFailure` (offline, permission, not found…) becomes a failed `ActionResult`.
  The View maps codes to localised text.
- **Dependency injection:** `AppServices` + `AppServicesScope`, no package. Tests build
  `AppServices.withRepositories(...)` with fakes via `buildTestServices`
  (`test/fakes/fake_repositories.dart`).
- **Shared live data:** `CartLiveData` streams one cart's drawers, slots, assignments
  and products. A5, A6, A8, A10, B3 and B4 reuse it.
- **Firestore vs local stubs:** a feature is wired to Firestore or to a local stub by one
  line in `AppServices`.

| Repository | Implementation today |
|---|---|
| Auth, Institution (+ members), Cart, Drawer, Product, Inventory, Usage, Audit, Credential (PIN hash, DB3) | Firestore / Firebase Auth |
| DeviceSession (remembered user, cached PIN hash), Report (+ check drafts, signatures), Emergency, Template, Shift, Permission, CartSettings (D7 switch) | **Local** (`data/local/`), one device only |

- **Business-rule codes:** rules in `domain/inventory_rules.dart` throw
  `StockRuleViolation(code)`; repositories pass them on as `RepositoryFailure(code:)`;
  `run()` turns either into `ActionResult.code`, and `showResult` shows the shared PT/EN
  text from `actionCodeText` (`ui/core/widgets/dialogs.dart`): `exceedsTarget`,
  `belowZero`, `targetBelowCurrent`, `invalidTarget`, `slotTaken`, `slotInUse`,
  `drawerInUse`, `drawerNumberTaken`, `quantityRequired`.

### Layout rule (no sideways scrolling, ever)

| Form factor (`formFactorOf`) | Rule |
|---|---|
| Phone (height < 500 px) | May scroll **vertically** |
| Tablet (up to 1360 px wide) | **Nothing scrolls** |
| Desktop (wider) | **Nothing scrolls** |

- **Use these widgets:** `SlotGrid` (fits the space, shrinks the cell content),
  `OverlayPanelLayout` (the side panel slides over the grid), and `FitList` /
  `FitDataTable` (pages of exactly the height available, with a "1–10 de 212 ‹ ›"
  pager instead of scrolling).
- **Enforced by:** `test/ui/layout_fit_test.dart`, which renders screens at 844×390,
  1280×800 and 1440×900 with heavy data and fails on overflow or a forbidden scroll.

### Localisation
- PT-PT is the default and the template (`lib/l10n/app_pt.arb`), and English is the
  second language. After editing either file, run `flutter gen-l10n`; the output goes to
  `lib/src/common/l10n/`.
- Use ICU plurals for counts.
- CSV/PDF exports stay in Portuguese whatever the UI language.

### Adding a screen
1. `<name>_view_model.dart` extends `ViewModel`. Subscribe in the constructor with
   `listen(...)`. Expose getters and actions that return `run(...)`.
2. `<name>_screen.dart` uses
   `ViewModelBuilder<XViewModel>(create: (services) => XViewModel(services, SessionScope.read(context)), builder: …)`
   and only `ui/core` widgets and tokens (no hard-coded colours or sizes).
3. Add the strings to **both** ARB files, then run `flutter gen-l10n`.
4. Add a ViewModel test with `buildTestServices(...)` (examples in
   `test/ui/dashboard_view_models_test.dart`).
5. Follow the layout rule and add the screen to `layout_fit_test.dart`.

### Tests (`app/test/`)
| Folder | Covers |
|---|---|
| `domain/` | Inventory rules (stock bounds, slot-state priority), history summaries, CSV export |
| `services/` | GS1 Data Matrix parser, HID scanner, internal QR payload, PIN hasher |
| `data/` | Local device session (cached PIN hash) |
| `ui/` | ViewModels (dashboard, A6 drawer, A9 report, app root), layout fit at three screen sizes |
| `fakes/` | In-memory repositories for tests |

Run with `flutter test` in `app/`.

---

## 8. Known issues

1. **Offline stock writes fail:** consumption, replenishment and correction use
   Firestore transactions, which need the server. They should become batched
   increments plus an immutable event, so they queue offline.
2. **Old placements without `drawerId`** (created before 29 Oct 2026): slot ids repeat
   across drawers, so the app puts such a placement in the first drawer, in number
   order, that has its slot id. New placements store `drawerId`. A migration would add it
   (see FIREBASE.md §11).
3. **Rules vs permissions:** health professionals can't replenish under the current
   rules (only `currentQuantity` may change). The rules must follow the confirmed D2
   permission set.
4. **Local stubs** (reports, signatures, templates, shifts, permissions, emergencies,
   D7 switch) live on one device until they get Firestore implementations.
5. CSV export is a copy dialog (no file saver yet). CSV import is by paste. NFC is a stub.
6. iOS doesn't run yet.
7. **Uniqueness the rules can't check:** a drawer number per cart, one product per slot
   and one slot per product are checked by the app with queries (two devices could race).
   The database enforces them with UNIQUE constraints later.
8. **PIN under Firebase is a prototype measure:** see FIREBASE.md §9. The PBKDF2
   iteration count (`PinHasher.defaultIterations`) still has to be measured on a cart
   tablet (aim: about 0.2 s per check).
