# I-Crash: the app

How the Flutter app in `app/` works: who uses it, what every screen does, the main
flows, and how the code is organised. For setup, read the repository
[README](../README.md); for the backend, [FIREBASE.md](FIREBASE.md); for the visual
design, [DESIGN.md](DESIGN.md).

Updated 18 Oct 2026 (design v2, branch `DEV-Martim`).

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

**Profile menu** (both shells): language (Português / English), set or change the PIN,
lock now (only with a PIN), switch institution (only with more than one), the debug-only
shell switch, and sign out.

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
| **A1 Login** (`features/auth/login_screen.dart`) | E-mail and password through Firebase Auth. "Esqueci-me da palavra-passe" sends a password-reset e-mail. When a session is saved on the device, it also offers the PIN and cart login |
| **A2 PIN unlock** (`pin_unlock_screen.dart`) | Decision D3: the PIN **unlocks the session already saved on this device**, so it works offline and needs no server. Five wrong attempts drop the saved session and require the password. "Não é {nome}? Iniciar sessão" signs out. The PIN is stored as a salted SHA-256 hash, locally only |
| **A3 Cart login** (`cart_login_screen.dart`) | Decision D3: scanning a cart's QR (or typing the code printed under it) opens a session **limited to that cart**. NFC is shown but is a stub |
| **Institution picker** (`institution_picker_screen.dart`) | Lists the institutions where the user has an active membership. Skipped automatically when there's only one |

The flow lives in `ui/app/app_root_view_model.dart` (stages:
`starting → signedOut | locked | pin | cartLogin → pickingInstitution → ready`).

**Database model (18 Oct, D3 changed):** the institution issues each employee a
`userNumber`, password and PIN, which must be changed on first login. The PIN is checked by
the server, so it works on any cart tablet, not only the device with a saved session. A1
and A2 will change accordingly; the login method is still open (DATABASE.md DB3).

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

- The cart's **drawers**, each with its own state (worst slot wins) and counts.
- **Cart menu:** monthly check · search product (shows the drawer and position) · show
  the cart QR code · change state (manager+) · the cart's reports · **Modo de
  emergência** (if allowed).
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
- **Database model:** the panel's data is a SlotCC with its batches. "Earliest known
  expiry" is calculated from the batches not yet removed, and there's no minimum quantity
  (D10), so **low stock** and **missing** both become *Replenishment needed* (below max).
- **Tapping a slot** opens the side panel **over** the grid (it never shrinks the grid).
  The panel shows the product, quantity vs target, earliest known expiry, lots, and
  actions:
  - **Registar consumo:** lower the quantity (anyone with `recordConsumption`).
  - **Repor stock (A7):** add units with lot and expiry. Can be pre-filled by a GS1
    scan. Manager+ under the current rules.
  - **Atribuir / trocar produto:** a product can be in only **one slot per cart**.
  - **Reconciliar:** after a physical audit, confirm the real quantity and which lots
    are present.
  - **Corrigir:** fix a past event with a compensating event.
- Slot states (`SlotHealth`), most urgent first: **expired** → **missing** (0 units) →
  **expiring** (within the warning window, default 30 days) → **low stock** (below
  target or minimum) → **ok**; plus **free** (no product).

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

- Decision D6: sign with **name + PIN + date**. The signer confirms, enters their PIN,
  and the report becomes **read-only**.
- PDF export (`report_pdf.dart`). Reports and signatures are a **local stub** for now.
- **Database model:** the person who performs the check is the one who signs it (a
  separate signer is open, DB4). A signed report has `signedAt` and can't change.

### A10 Emergency mode
`features/emergency/`

- Proposal §9. In the final prototype it's kept as an idea, not a priority.
- Entered from the cart menu. The shell turns **red** so nobody stays in it by accident.
- **Consumption only:** every product of the cart is visible at once (the column count
  adapts so nothing scrolls); **tap = −1 unit**. "Desfazer último" records a
  compensating correction.
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
| **B3 Cart configuration** | `cart_config_*`, `drawer_form_dialog.dart` | Name, service, location, state, the **automatic state** switch (D7), **archive** (D15: never delete), drawers list and **add drawer** |
| **B4 Grid editor** | `grid_editor_*` | Drawer layout: resize rows/columns, select cells, **merge** (the selection must form a rectangle) and **split**, then save. Slot setup: product, target, minimum, expiry warning ("Aplicar à posição"), "Limpar posição". Handles **orphaned assignments** (a product whose slot disappeared): reassign or remove |
| **B5 Catalogue** | `catalog_*` | Products: name, presentation, **GTIN (unique)**, category (drug / material / fluid), expiry warning days. Filters by category, "used in N carts". **CSV import** by pasting `nome;apresentação;GTIN;categoria;aviso` |
| **B6 Templates** | `templates_*` | Capture a cart's structure and target quantities as a template; duplicate, rename, re-capture, delete; create a cart from it. Templates never carry stock, lots or history |
| **B7 Users & permissions** | `users_*` | Members with name, e-mail, role, status. **Invite** (name + e-mail + role): the account gets a random password nobody sees and a reset e-mail, so the person picks their own. Resend invite, change role, enable/disable (not yourself). Permission toggles per role (§2) |
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
- **Assignment** = one product in one slot of one cart. It holds `currentQuantity`
  (live stock), `targetQuantity`, optional `minimumQuantity` and `earliestKnownExpiry`.
- **Batches** (lots) hang under the assignment: lot number, expiry, optional quantity,
  GTIN, source (manual / GS1 scan / audit).
- **Usage events** are an append-only log: consumption, replenishment, correction,
  audit reconciliation.

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
| Auth, Institution (+ members), Cart, Drawer, Product, Inventory, Usage, Audit | Firestore / Firebase Auth |
| DeviceSession (remembered user, PIN), Report (+ check drafts, signatures), Emergency, Template, Shift, Permission, CartSettings (D7 switch) | **Local** (`data/local/`), one device only |

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
| `domain/` | Inventory rules, history summaries, CSV export |
| `services/` | GS1 Data Matrix parser, HID scanner, internal QR payload |
| `ui/` | Dashboard ViewModels, layout fit at three screen sizes |
| `fakes/` | In-memory repositories for tests |

Run with `flutter test` in `app/`.

---

## 8. Known issues

1. **Offline stock writes fail:** consumption, replenishment and correction use
   Firestore transactions, which need the server. They should become batched
   increments plus an immutable event, so they queue offline.
2. **Slot ids repeat across drawers** (`r{row}c{col}`), so an assignment's `slotId` is
   ambiguous between drawers. The assignment needs a `drawerId`. (In the relational model
   a slot's key includes its drawer and cart, so this can't happen there.)
3. **Rules vs permissions:** health professionals can't replenish under the current
   rules (only `currentQuantity` may change). The rules must follow the confirmed D2
   permission set.
4. **Local stubs** (reports, signatures, templates, shifts, permissions, emergencies,
   D7 switch) live on one device until they get Firestore implementations.
5. CSV export is a copy dialog (no file saver yet). CSV import is by paste. NFC is a stub.
6. iOS doesn't run yet.
