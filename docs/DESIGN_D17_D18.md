# Design note: device setup (D17) and support access (D18)

**Status:** approved by Martim, 30 Oct 2026 (answers in §5). Phase 7 of the
30 Oct review, `docs/REVIEW_2026-10-30.md` §2.2 and §3). Everything here runs on the
Firebase prototype (Spark plan, no Cloud Functions); the local-server version replaces the
weak points listed in §4.

---

## 1. D17 — a tablet set up once, then PIN and cart login without a password

### 1.1 Data (Firestore)

| Path | Fields | Who writes |
|---|---|---|
| `institutions/{i}/devices/{deviceId}` | `name` ("Tablet Carro 3 · UCI"), `cartIds[]` (bound carts, ≥ 1), `authUid` (the device account), `registeredBy`, `registeredAt`, `revokedAt?` | Admin (or Super with a grant) |
| `institutions/{i}/memberships/{deviceAuthUid}` | `role: 'device'`, `status`, `deviceId`, `displayName` = device name | Admin, together with the device doc |
| `memberships/{uid}` (people) | new optional **`userNumber`** (nº mecanográfico), unique per institution (checked by the app) | Admin (B7) |

- The **device account** is an ordinary Firebase Auth user created the way B7 already
  creates people (isolated `FirebaseAuth` on a secondary app): e-mail
  `device-{deviceId}@{institutionId}.devices.icrash.invalid` and a long random password.
- The tablet keeps the device credentials locally (SharedPreferences under
  `icrash.local.device`; no secure storage package in the app yet — see §4).

### 1.2 Flow

1. **Configurar dispositivo** (link on A1, shown while the tablet isn't registered): an
   Admin signs in with their own e-mail + password; the app asks for the **device name** and
   the **carts it serves**; it creates the device account + membership + device doc, stores
   the credentials, signs the Admin out and signs the device in.
2. **Registered tablet, every start:** the app signs in silently as the device. A1 shows
   "Hospital de Teste · Tablet Carro 3 · UCI" and two buttons:
   - **Entrar com PIN** → "Nº mecanográfico ou e-mail" + PIN keypad;
   - **Entrar no carro** → scan the cart's QR → same identification + PIN (A3 today).
   No password field. The PIN is checked on the tablet against the member's hash (PBKDF2),
   which the device account may read.
3. The session then runs **as that person** (name, role, permissions, `actorUid`, report
   author/signer) while Firebase is signed in as the device. "Terminar sessão" goes back to
   the tablet's A1, not to an e-mail login. Inactivity (default 5 min) does the same.
4. **Personal devices** (laptop, a Manager's own phone) never register; they keep e-mail +
   password.
5. **Revogar** (Dashboard): sets `revokedAt` and disables the device membership; the next
   request fails and the tablet shows "Este dispositivo foi desativado" with the
   "Configurar dispositivo" link again. (A client can't delete the Firebase Auth account on
   Spark; IT can with an Admin SDK script, like `set_password.mjs`.)

### 1.3 Rules (emulator first, never deployed without Martim's OK)

- `isDevice(i)`: active membership with `role == 'device'` and its device doc not revoked.
- **Reads:** a device may read the institution doc, members (names, numbers, roles), the
  **PIN hashes** (`private/credentials`) of the institution's members, the catalogue, and
  everything under its **bound carts** (`cartIds`), nothing else.
- **Writes** on a bound cart follow the acting person: the same writes a Manager registered
  to that cart may do (stock, batches, cart status, usage events). Usage events from a
  device carry `actorUid` = the person; the rule checks that person is an **active member**
  who may access that cart (Admin, or registered via `responsibleUsers`). Assignment
  `updatedBy` follows the same value.
- Devices never write memberships, devices, credentials, structure or the catalogue.

### 1.4 Screens and tests

- A1: unregistered (today's form + "Configurar dispositivo") / registered (device header, two
  buttons, "Desativar neste tablet" only after an Admin PIN).
- New **A0 Configurar dispositivo** (2 steps: Admin sign-in → name + carts).
- New **A2b Identificação** (number/e-mail + keypad), shared by PIN and cart login.
- Dashboard **B7 → separador "Dispositivos"**: name, bound carts, registered by/at, state;
  rename, change carts, revoke.
- Tests: device ViewModels (setup, identify + PIN, wrong PIN ×5, revoked), layout tests for
  A0/A2b/B7-Dispositivos on both devices, rules tests (device reads only bound carts; writes
  need a valid `actorUid`; revoked device refused; device can't write memberships).

---

## 2. D18 — Super reaches an institution only while its Admin allows it

### 2.1 Data

| Path | Fields | Who writes |
|---|---|---|
| `institutions/{i}/support/current` | `grantId`, `reason`, `grantedBy`, `startsAt`, `endsAt`, `closedAt?` | Admin |
| `institutions/{i}/supportGrants/{grantId}` | same, kept as history | Admin |
| `institutions/{i}/supportLog/{id}` | `superUid`, `superEmail`, `grantId`, `at`, `action` (`enter` / `leave`) | Super (as self), create only |

### 2.2 Flow

1. Admin opens **Dashboard → Acesso do suporte** (new section, Admin only): reason (text,
   required), duration (**4 h / 24 h / 7 dias**; maximum to confirm), "Abrir acesso". While
   open: who, until when, "Fechar acesso agora", and the **access log** table.
2. Super signs in on the Dashboard (or tablet): the picker lists the institutions whose
   `support/current` is open, with "até às 18:00"; none → "Nenhum pedido de acesso aberto".
3. Entering writes a `supportLog` `enter` entry; a **banner** stays on every screen:
   "Acesso do suporte · Hospital de Teste · termina às 18:00". When the grant ends or is
   closed, the next request fails and the app returns Super to the picker.

### 2.3 Rules

- Super's power becomes conditional: `isInstitutionAdmin(i)` =
  Admin role **or** (`isPlatformSuperAdmin()` **and** `support/current` open:
  `!('closedAt' in data) && data.endsAt > request.time`).
- Super may read `institutions/{i}` (name) and `support/current` of any institution, to
  build the picker; nothing else without an open grant.
- `support/current`, `supportGrants`: Admin writes, Admin + Super read.
- `supportLog`: create by Super as self with an open grant; read by Admin; never updated or
  deleted.
- Super keeps creating institutions (`create: isPlatformSuperAdmin()`, unchanged).

---

## 3. Order of work

1. D18 first (smaller, mostly rules + one Dashboard section + picker + banner).
2. D17 (device account, identification, rules for devices, B7 Dispositivos).
3. `userNumber` in B7 (create user, edit) — needed by D17's identification.

Each step: emulator rules tests + Flutter tests, one commit.

## 4. Security limits of the Firebase prototype (written down, not hidden)

- **PIN hashes are readable by every registered tablet** of the institution. A 4-digit
  PIN can be brute-forced offline from a hash in seconds. The local server will check the
  PIN itself and never send hashes.
- **The Rules can't prove who typed the PIN:** a device could write with any member's
  `actorUid`. They only check that the member exists, is active and may use that cart.
- **Device credentials are stored in SharedPreferences**, not in the OS keychain. Adding
  `flutter_secure_storage` would fix it (new dependency, needs Martim's OK).
- **Reads by Super aren't logged by the server**, only the app's `enter`/`leave` entries;
  a modified client could skip them. The rules still refuse everything outside a grant.
- No Cloud Functions: grants end by time comparison in the rules, not by a job.

## 5. Martim's answers (30 Oct)

1. Support access: **4 h / 24 h / 7 dias**, 7 days at most.
2. Identification on a registered tablet: **nº mecanográfico or e-mail**, typed (no list of
   names on the tablet).
3. Every tablet is **bound to at least one cart** and reaches only those.
4. Inactivity timeout: 5 min (default, not asked).
5. `flutter_secure_storage` for the device credentials: yes, with the approval (D18 then D17).
