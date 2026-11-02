# I-Crash: the app

How the Flutter app in `app/` works: who uses it, what every screen does, the main
flows, and how the code is organised. For setup, read the repository
[README](../README.md); for the backend, [FIREBASE.md](FIREBASE.md); for the visual
design, [DESIGN.md](DESIGN.md).

Updated 29 Oct 2026 (design v2, branch `DEV-Martim`; aligned with the database decisions
of 28 Oct: no minimum stock, no overfill, drawer numbers, batches never deleted, structure
fixed once used, templates archived, credentials set by the administration).

**30 Oct 2026 review:** Martim's device review and decisions **D16–D22** are in
[REVIEW_2026-10-30.md](REVIEW_2026-10-30.md). Sections below marked **"Target (30 Oct)"**
describe what the code must become; until it's done, the rest of the section is what runs.

This describes the app **as it runs today, on Firebase**. The relational database designed
on 18 Oct for the local-server version is in [DATABASE.md](DATABASE.md); where it changes
how a screen should work, a "Database model" note says so.

---

## 1. One codebase, two shells

The same Flutter app runs everywhere. The **platform** chooses the shell; the user's
**role and permissions** decide what is visible inside it (decision R1/D1).

| Shell | Platforms | For | Layout |
|---|---|---|---|
| **App** | Android, iOS, iPadOS (phone and tablet) | Managers (health professionals) at the cart: monthly checks, replenishing; Admin and Super to test | Landscape only. Navy side rail (96 px on tablet, 72 px on phone) |
| **Dashboard** | Web, Windows, macOS, Linux | Admins (institution IT) and Super (I-Crash team): configuration, catalogue, users, devices, shifts, reports; Managers may use it for their carts | 240 px navy sidebar |

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
| Ler código (scan) | Catálogo: Admin |
| Perfil (profile menu, bottom) | Modelos (templates): Admin |
| | Utilizadores (users): Admin |
| | ~~Turnos (shifts)~~: hidden, D8 set aside (2 Nov) |
| | Relatórios (reports) |
| | Histórico (history) |
| | Acesso do suporte: the institution's own Admin (D18) |

Sections the user can't use are **hidden**, not shown disabled. Each section keeps its
own navigation stack (`SectionNavigator`), so switching sections doesn't lose your place.

**Profile menu** (RV-15, 30 Oct): who is signed in, the line "Para alterar as suas
credenciais, contacte a administração." (DB3: there's no "set/change PIN"), **Bloquear
agora** (only with a PIN) and **Terminar sessão**. Also:
- the **language** switch only in the **Dashboard** (in the App it's on A1);
- "Mudar de instituição" only for **Super** (D16, D18) with more than one institution;
- "Ver como App / Dashboard" only in debug builds.

---

## 2. Users and permissions

### User types (D16, decided 30 Oct)

| Type | Who | Scope | Uses | Code role |
|---|---|---|---|---|
| **Super** | I-Crash team IT staff | App problems, updates, helping the institution's IT. Several institutions, **one at a time and only while that institution has granted support access** (D18) | Dashboard, tablet and phone | `platformSuperAdmin` (a `platformAdmins/{uid}` document, not a membership) |
| **Admin** | The institution's IT staff | Everything in **one** institution: all carts, users, devices, catalogue, templates, settings. No other institution | Dashboard; tablet or phone to test | `institutionAdmin` |
| **Manager** | A health professional | Full access to the **carts they're registered to** (`responsibleUsers`), nothing else | Tablet or phone; may use the Dashboard | `manager` |

The **`user` role is dropped** (existing `user` memberships become `manager`). Structure editing
(drawers, grid, catalogue, templates) stays Dashboard work and Admin-only by default (R7); B7
toggles can grant it to Managers. Support access rules: REVIEW_2026-10-30.md §2.2.

**In the code (done 30 Oct):** `Role` has `platformSuperAdmin`, `institutionAdmin` and
`manager`; a stored `user` reads as `manager`. Session helpers: `isInstitutionAdmin`
(Admin/Super: structure, catalogue, templates, users, shifts, every cart),
`canConsume`, `canReplenish`, `canChangeCartState`, `canMonthlyCheck` (cart actions, B7
toggles), `canEditStructure` (= Admin). A Manager's carts and "all assignments" are read per
registered cart (`firestore_access.dart`). There's no institution picker for Admins and
Managers; an old account with several institutions opens the first by name.

**Database model:** user types and their permissions are tables (UserType, Permission,
UserTypePermission), so the B7 toggles become shared data instead of a local stub. A user
belongs to one institution, so the institution picker isn't needed on a local server.

### Permission toggles (B7)

`AppPermission` (`domain/entities/app_permission.dart`) holds the switches shown in **B7
Users & permissions**. Since D16 only the **Manager's** cart actions are listed
(`managerPermissions`): `viewCarts`, `recordConsumption`, `replenish`, `monthlyCheck`,
`signReports`, `emergencyMode`, `changeCartState`, all on by default. An Admin has every
permission. Structure (`editDrawers`) and users/shifts aren't toggles: they stay the Admin's,
as in the Firestore Rules. The toggles are stored **locally on the device** for now (a stub),
so they shape what the UI offers; the Rules are the real enforcement.

Session helpers (`ui/core/session/session.dart`): `isInstitutionAdmin`, `can(permission)`,
`canConsume`, `canReplenish`, `canChangeCartState`, `canEditStructure`, `canUseEmergency`,
`canMonthlyCheck`.

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

**Registered tablets (D17, done 31 Oct):** A2/A3 used to work only after the user signed in
with e-mail + password on that device, because Firebase Auth needs a signed-in account and a
PIN isn't one (no Cloud Functions on Spark). Now (stages `deviceSetup`, `deviceHome`,
`deviceIdentify`, `deviceRevoked`; screens in `ui/features/device/`):

1. I-Crash delivers the tablet with the app installed.
2. **"Configurar dispositivo"** (once per device): an Admin, or Super with an open grant,
   signs in, names the device and optionally binds carts. The app creates a **device
   account** (a `device` membership of the institution) and keeps its credentials on the
   device; the Admin's session ends.
3. On a registered device, A1 offers **"Desbloquear com PIN"** (user number or e-mail +
   PIN) and **"Entrar no carro"** (scan the cart's QR, then PIN). Nobody types a password.
4. Personal devices (laptop, a Manager's phone) keep e-mail + password.
5. Admins list and revoke devices in the Dashboard.

How it works in the code:
- **A0 Configurar dispositivo** (link on A1, App shell on a tablet only): an Admin signs in;
  `DeviceSetupViewModel` asks for the name and the carts (≥ 1), calls
  `DeviceRepository.registerDevice`, saves `DeviceCredentials` in `DeviceCredentialStore`
  (`flutter_secure_storage` on Android/iOS; `LocalStore` elsewhere) and the root signs the
  Admin out and the tablet in.
- **Every start:** `AppRootViewModel` loads the credentials, signs the tablet in and reads its
  `devices/{id}` document (carts, name, `revokedAt`). A1 becomes `DeviceHomeScreen`.
- **A2b Identificação** (`DeviceSignInViewModel`): nº mecanográfico or e-mail
  (`Membership.matches`) + PIN, checked against the PIN hash with `PinHasher`. One message for
  an unknown person and a wrong PIN; 5 failures go back to A1.
- **Session:** `SessionController` runs as the person (`user`, `membership`, `actorUid`) while
  Firebase is signed in as the tablet; `allowedCartIds` = the tablet's carts the person is
  registered to (all of them for an Admin), `deviceName` set, so `isInstitutionAdmin` and
  `canEditStructure` are false (the rules give the tablet a Manager's writes on its carts).
  A3 accepts only the tablet's carts and the person must be on that cart.
- **Terminar sessão** and **5 min without a touch** (`AppRootViewModel.deviceIdleTimeout`)
  return to the tablet's A1; the tablet stays signed in. "Remover registo deste tablet" needs
  an Admin's PIN and only clears the tablet's own sign-in (revoking is done in B7).
- **B7 › Dispositivos:** name, carts, registered by/at, state; "Alterar nome e carros",
  "Revogar". Tablet accounts are left out of the people lists and shifts.
- B7 "Criar utilizador" takes an optional **nº mecanográfico** (unique; code `numberTaken`).

The **institution picker** is shown **only to Super** (RV-1, RV-2, done 30 Oct): it lists the
institutions whose Admin opened a **support window** (D18), with the reason and end time.
Entering writes "Entrou" to the institution's access log, and an amber **banner** stays on
every screen ("Acesso do suporte · Hospital X · termina às 18:00", `SupportBannerFrame`).
When the time is up or the Admin closes the window, Super goes back to the list with a
message. Inside, Super works as an Admin but never reads or sets PIN hashes. Rules changes and the prototype's security limits:
REVIEW_2026-10-30.md §3.2.

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
  (e.g. "1 expirado · 2 em falta" or "Tudo conforme") and the last monthly check.
- Filters: all, needs attention. Search by name. ("Os meus", the carts someone is on shift
  for, is hidden while shifts are set aside: D8, `kShiftsEnabled`.)
- **A12** is the same screen while offline: a notice plus the sync indicator; cached data
  stays readable.

### A5 Cart
`features/cart/cart_screen.dart`

- The cart's **drawers**, shown as **"Gaveta N"** in number order, each with its own state
  (worst slot wins). Each row: number badge, "Gaveta N", the grid line on one line (long
  form when it fits, else short; none on phones), and the **state and arrow at the right
  end** (RV-13, RV-22). The drawer's optional **name** (D20) replaces "Gaveta N" when it
  has one; page titles (A6, B4, A8) read "Gaveta 2 · Via aérea".
- **Cart menu** (same on phones and tablets, D21; scrolls on phones): monthly check ·
  search product (shows "Gaveta N · posição B3") · change state (manager+) · **Relatórios do
  carro**, which switches to the **Relatórios** section filtered by this cart (the rail
  highlights it; back returns to the cart, RV-12). (The shift's responsible person, in
  the header or here on phones, is hidden while shifts are set aside: D8.)
- The cart's QR isn't shown in the App any more (RV-21): it's printed from **B3**.
- The **Modo de emergência** button is **hidden** for now (P12; `kEmergencyModeEnabled` in
  `cart_screen.dart`); A10's code is kept.
- While a cart screen is open (`CartPresence`), the App's scanner reads only consumables
  (RV-26).
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
  no overfill): Repor stock is offered only up to the target (PT/EN messages; the rules
  enforce it too).
- **Database model:** the panel's data is a SlotCC with its batches. "Earliest known
  expiry" is calculated from the batches not yet removed.
- **Tapping a slot** opens the side panel **over** the grid (it never shrinks the grid).
  The panel shows the product, quantity vs target, earliest known expiry, lots, and
  actions:
  - **Registar consumo:** lower the quantity (anyone with `recordConsumption`). The panel
    closes after a successful consumption (RV-23).
  - **Repor stock (A7):** add units with an **expiry date** (required), a quantity > 0
    and an **optional lot** (P9). Can be pre-filled by a GS1 scan; month-only GS1 dates
    become the **last day of the month** (P11). The event records the batch it created.
    Manager+ under the current rules. Same-date batches aren't merged yet (P10 open).
  - **Atribuir / trocar produto:** a product can be in only **one slot per cart**, and a
    slot holds one product. The initial quantity can't exceed the target. Once the slot
    has History, **"Trocar produto" is refused** (P1: a used slot keeps its product).
  - **No "Corrigir" and no "Reconciliar"** (removed 30 Oct, D23/P15): a report is edited
    until it's signed and never changes afterwards. Old correction events still show in
    B9. The repository methods stay for A10's "Desfazer último" (hidden with emergency
    mode).
  - Phones show the same actions as tablets (D21); the panel scrolls if needed.
- Slot states (`SlotHealth`), one per slot, the highest priority wins (DB9). The order
  lives in one table, `slotStatePriority` in `domain/inventory_health.dart` (values to be
  fixed with P4): **expired** → **missing** (0 units) → **expiring** (within the warning
  window, default 30 days) → **low stock** (below target, not empty) → **ok**; plus
  **free** (no product).

### A8 Monthly check ("Gestão mensal")
`features/monthly_check/`, rules in `domain/monthly_check.dart`

Rebuilt on 30 Oct 2026 (D4, D22, D23; REVIEW_2026-10-30.md §5.5).

- The check covers the **whole cart** but lists only the lots that are **expired** or
  **expiring** (within the product's warning days, else the institution's); everything else
  counts as valid (D4). A slot without batch records uses its earliest known expiry.
- **One drawer per step** (only drawers with something to handle), with a progress bar.
  Each row shows the state on the left (Expirado / A expirar, lot, expiry) and **"Por
  resolver"** or the chosen outcome on the right. No "Marcar restantes" (RV-16, RV-17).
- Tapping a row asks for its **outcome**. The outcomes per state live in one table,
  `checkOutcomes` (to confirm with ESEL):
  - expired → **Substituído** or **Retirado sem reposição** (an expired lot can't be kept);
  - expiring → **Mantido** or **Substituído**.
- **Substituído** asks for the units, a **new expiry** (later than the old one, not past) and
  an optional lot, and **updates the stock at once**: the old lot is marked removed and the
  new one added in its place (reconciliation + replenishment); the quantity stays the same.
  **Retirado sem reposição** lowers the stock. Both lock the answer (a signed report never
  changes, P15). **Mantido** changes no stock and can be cleared.
- **Autosave:** every answer, the step and the note are saved on the device at once (the
  draft, format `version: 2`). **Back** (header or system) goes to the previous drawer;
  from the first one it leaves. The cart menu then offers **"Retomar verificação"**
  (RV-18). Answered lots that left the stock are kept in the draft.
- **Concluir** is enabled once every lot has an outcome; it creates the report, clears the
  draft and opens **A9**. With nothing to handle, the screen says so and "Concluir" creates
  an empty report to sign.
- Not decided yet: whether procedure still requires a quick look at the rest (DB6), and how
  a lot used in an emergency is known (P8 follow-up). Database: REPORT, REPORTITEM and
  RESULTITEM (DATABASE.md §1.4) still have to be reworked for D23.

### A9 Report: view and sign
`features/reports/report_screen.dart`, list in `reports_list_screen.dart`

- Decision D6: sign with **name + PIN + date**. The signer confirms, enters their PIN
  (the one the administration set), and the report becomes **read-only**.
- **Only the person who performed the check signs it** (DB4): anyone else sees "Só quem
  fez a verificação pode assinar" instead of the PIN field.
- A monthly report lists **"Lotes tratados (N)"**, each as "Consumível (Gaveta 1 · Via aérea ·
  A1) — expirado, Lote L1, expira a … → Substituído · 2 unidades · nova validade …".
  Reports made before 30 Oct keep their "Problemas encontrados" lines.
- An unsigned report **survives back**: it's created when the check ends and listed in
  "Por assinar". Leaving one you still have to sign asks **"Assinar agora / Sair"** (RV-19,
  RV-20). The **Relatórios** rail item and "Relatórios do carro (N)" show how many of your
  reports wait for your signature. The PIN field has 16 px below it on every size (RV-25).
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
- **Inside a cart** (a cart-limited session, or a cart open in Carrinhos) only consumables
  can be read: the mode tabs are hidden and a cart code shows "Dentro de um carro só pode
  ler consumíveis." (RV-26).
- The **scan sheet** used by A6/A7 and B5 has "Cancelar" and **"Inserir manualmente"**,
  which swaps the camera for a field to type the GTIN or GS1 text (RV-24).
- Error messages: unreadable, unknown product, not a cart, other institution, not in any
  cart.

---

## 5. Dashboard shell screens

| Screen | File(s) in `features/dashboard/` | What it does |
|---|---|---|
| **B1 Overview** | `overview_*` | Metrics: operational carts, needing replenishment, expiring within 30 days (and in how many carts), overdue checks, emergencies this month. "Carrinhos que precisam de atenção" list and recent activity (stock events + reports). PDF of the overview |
| **B2 Carts** | `dashboard_carts_*`, `cart_form_dialog.dart` | Table of every cart: state, service, location, drawers (the "responsible now" column is hidden with shifts, D8). Filters and search. **New cart**, from scratch or **from a template** |
| **B3 Cart configuration** | `cart_config_*`, `drawer_form_dialog.dart` | Name, service, location, state, the **automatic state** switch (D7), **archive** (D15: never delete). **"Código QR"** opens the cart code dialog to print it (RV-21). Drawer **name** (optional, D20, up to 50 characters) in "Adicionar gaveta", in a "Nome" column and in **Editar gaveta** (number only while Q8 allows it; the name always). Drawers table: **Nº** ("Gaveta N"), size, positions, with product. **Add drawer** asks for its **number** (default: lowest free; unique in the cart) and size, and creates one slot per cell. **Alterar número** only while the drawer has no History, or if it never had a number (Q8) |
| **B4 Grid editor** | `grid_editor_*` | Drawer layout: resize rows/columns, select cells, **merge** (the selection must form a rectangle) and **split**, then save. Slot setup: product, target, expiry warning ("Aplicar à posição"), "Limpar posição". A target below the current stock is refused. **Once the drawer has History** (P1/P2) the layout is locked (steppers, merge, split disabled; a warning replaces the hint), used slots keep their product and can't be cleared; targets can still change. **Orphaned assignments** (old data): reassign, or remove only when unused (Q7) |
| **B5 Catalogue** | `catalog_*` | Products: name, presentation, **GTIN (unique)**, category (drug / material / fluid), expiry warning days. Filters by category, "used in N carts". **CSV import** by pasting `nome;apresentação;GTIN;categoria;aviso` |
| **B6 Templates** | `templates_*` | Capture a cart's structure and target quantities as a template; duplicate, rename, re-capture; create a cart from it. Templates never carry stock, lots or history. **Archived, never deleted** (P3): tabs "Ativos / Arquivados", "Arquivar modelo" and "Restaurar"; archived templates aren't offered for new carts but can still be edited (local stub) |
| **B7 Users & permissions** | `users_*` | Members with name, e-mail, role, status. **Criar utilizador** (DB3): name, e-mail, role, **password** (min. 8) and **PIN** (4 digits), each typed twice; the administrator hands them over. Per member: change role, enable/disable, **Definir novo PIN**, **Redefinir palavra-passe** (shows "peça ao suporte técnico": the app can't change another user's Firebase password; IT uses `firebase/tools/set_password.mjs`). Never on yourself. Permission toggles per role (§2) |
| **B8 Shifts** | `shifts_*` | **Hidden (2 Nov): shifts are set aside, idea kept** (D8, `kShiftsEnabled` in `ui/core/feature_flags.dart`); the code below is kept. Decision D8: **one responsible health professional per cart per shift**. Week view by cart or by person. Shifts: morning 08–16, afternoon 16–24, night 00–08. "Copiar semana anterior" fills empty slots |
| **B9 Reports & history** | `reports_history_*` | Tabs for reports and events. Filter by cart and month. Totals (consumed, replenished, checks, emergencies, pending signatures), most consumed products, per-cart summary. Event rows show when, where (cart › drawer › position), what and who. CSV export (currently a copy dialog). Reads the latest N events and says when it hits the cap |
| **Acesso do suporte** (D18) | `support_access_*` | The institution's **own Admin** only (not Super). Closed: reason (required, ≤ 500), duration **4 h / 24 h / 7 dias**, "Abrir acesso". Open: until when, reason, who opened it, "Fechar acesso agora". Right: the **access log** (when, who, Entrou/Saiu). Rules: DESIGN_D17_D18.md §2 |

The App screens (A5, A6, A8…) also open inside the Dashboard when a manager drills into
a cart.

---

## 6. Inventory model in one page

The full reasoning is in [DOMAIN.md](DOMAIN.md) (§19–28) and [FIREBASE.md](FIREBASE.md) §8.
In short:

- **Institution → Cart → Drawer → Slot.** A slot is a rectangle of grid cells (it can
  span rows and columns).
- **Drawer** has a **number** (unique in its cart), an optional **name** (D20) and a grid;
  its slots are created with it. **Assignment** = one product in one slot (`drawerId` + `slotId`) of one cart.
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

### Phone vs tablet (D21, 30 Oct)

A phone may change **how** things are shown (shorter labels, smaller buttons, vertical
scrolling, a "Mais ações" menu), never **what** the user can do. Today some actions are hidden
on phones behind `if (!compact)` (A5 change state and reports, A6 Trocar produto); phase 2
(30 Oct) showed them again. Only information may be hidden on phones (e.g. the A5 grid line,
the A6 lot line). The full list and the reason for each is in REVIEW_2026-10-30.md §4.

### Layout rule (no sideways scrolling, ever)

| Form factor (`formFactorOf`) | Rule |
|---|---|
| Phone (height < 500 px) | May scroll **vertically** |
| Tablet (up to 1360 px wide) | **Nothing scrolls** |
| Desktop (wider) | **Nothing scrolls** |

- **Use these widgets:** `SlotGrid` (fits the space, shrinks the cell content),
  `OverlayPanelLayout` (App A6/A7: the side panel slides over the grid),
  `SidePanelLayout` (Dashboard B4: the panel sits beside the grid, which shrinks
  into the rest, so no position is covered while editing; D26), and `FitList` /
  `FitDataTable` (pages of exactly the height available, with a "1–10 de 212 ‹ ›"
  pager instead of scrolling).
- **Enforced by:** `test/ui/layout_fit_test.dart`, which renders screens at 844×390,
  1280×800 and 1440×900 with heavy data and fails on overflow or a forbidden scroll.
- **Real devices** (30 Oct): the same test renders A1, A4, A5, A6, A8 and A9 as an
  **iPhone 16** (852×393, insets 59 px left/right, 21 px bottom) and an **iPad mini**
  (1133×744, 24 top, 20 bottom), inside `AppShellFrame` (the App rail + safe area, shared
  with `AppShell`). It also fails when a button label is cut with "…".
- **Safe area:** the rail is `appRailWidth` = 72/96 px **plus the left inset**; content
  stays out of the notch and the home indicator.
- **Side panels on phones:** use `PanelColumn` (scrolls on phones, `Spacer` becomes a
  gap). Pick long/short labels with `textFits` instead of letting text wrap or cut.

### Localisation
- PT-PT is the default and the template (`lib/l10n/app_pt.arb`), and English is the
  second language. After editing either file, run `flutter gen-l10n`; the output goes to
  `lib/src/common/l10n/`.
- Use ICU plurals for counts.
- **Terminology (D19, done 30 Oct):** never "Produto" in the UI, the PDFs or the CSV. Short form **Consumível**
  (EN "Consumable"); long form **Consumível clínico** (EN "Clinical consumable") for titles.
  Code names (`Product`) don't change.
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
6. iOS ran in debug against the emulator for the 30 Oct review; the cloud project's
   `GoogleService-Info.plist` is still missing.
7. **Uniqueness the rules can't check:** a drawer number per cart, one product per slot
   and one slot per product are checked by the app with queries (two devices could race).
   The database enforces them with UNIQUE constraints later.
8. **PIN under Firebase is a prototype measure:** see FIREBASE.md §9. The PBKDF2
   iteration count (`PinHasher.defaultIterations`) still has to be measured on a cart
   tablet (aim: about 0.2 s per check).
