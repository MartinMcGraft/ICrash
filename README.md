# I-Crash

**Intelligence Crash-Cart Management System.** I-Crash helps hospital teams keep
emergency (crash) carts complete and in date. Today the monthly expiry check of a
crash cart is done on paper and takes a health professional about a morning; I-Crash
replaces it with a tablet app that knows every drawer, slot, product, lot and expiry
date in the cart, plus a web dashboard for the people who configure the carts.

Owners: **Martim Pinheiro Alves** and **Pedro Jorge**. The project started as their
ISEL bachelor's final project (LEIM, 2023, Django + Flutter) and is now being turned
into a product, with ESEL nursing professors as the first clients and testers.

> **New here, human or AI?** Read this file top to bottom first. It is the current
> source of truth (updated 15 Oct 2026). See [Documentation map](#documentation-map)
> for the other documents and where older records live.

---

## Repository layout

```
ICrash/
├── app/            The Flutter app (package `icrash_app`, shown on devices as "ICrash")
├── firebase/       Firebase backend config: Firestore rules, indexes, emulator config,
│                   rules tests and admin tools
├── docs/           APP, FIREBASE, DESIGN, DOMAIN rules, open decisions, release checklist
├── isel/           Archive of the 2023 ISEL bachelor's project (report, planning,
│                   analysis, the original Django server and the original app1 Flutter
│                   app, legacy code included). Kept for reference; not maintained.
├── _claude_checks/, Claude outputs/   Local scratch files from AI sessions; not part
│                   of the project and safe to ignore.
└── README.md       This file
```

| Folder | What lives there |
|---|---|
| `app/lib/main.dart` | Entry point: locks phones/tablets to landscape, starts Firebase, loads the saved language |
| `app/lib/src/` | All app code (see [Architecture](#app-architecture)) |
| `app/lib/l10n/` | Translations: `app_pt.arb` (template, PT-PT) and `app_en.arb` |
| `app/test/` | Unit, ViewModel and layout tests (81 tests, all passing on 15 Oct 2026) |
| `firebase/firebase.json`, `.firebaserc` | Emulator ports and Firebase project aliases |
| `firebase/firestore.rules`, `firestore.indexes.json` | Security rules and indexes (deployed to the cloud project) |
| `firebase/firestore-tests/` | Automated rules tests and emulator seed scripts (emulator only, never the cloud) |
| `firebase/tools/` | One-off admin scripts that target the **real** cloud project (Admin SDK) |

---

## Quick start

**Prerequisites:** Flutter (stable channel, Dart ≥ 3.13), Node.js, and the Firebase
CLI (`npm i -g firebase-tools`). Java is needed for the Firestore emulator.

```sh
# 1. Start the local backend (Auth + Firestore emulators, UI on http://127.0.0.1:4000)
cd firebase
firebase emulators:start --only auth,firestore --project demo-icrash-v2

# 2. In a second terminal, seed test data (emulator data is lost on every restart)
cd firebase/firestore-tests
npm install          # first time only
node seed_qa_run.mjs # 4 test accounts across every role, 2 institutions, edge cases

# 3. Run the app (debug builds talk to the emulator automatically)
cd app
flutter pub get
flutter run                    # pick Android / Chrome / macOS
flutter test                   # app tests
```

Test accounts created by `seed_qa_run.mjs` (emulator only; the password is in the
script): `enfermeira.teste@icrash.pt` (institutionAdmin), `gestor.teste@icrash.pt`
(manager), `utilizador.teste@icrash.pt` (user), `super.teste@icrash.pt` (platform
super admin, no institution).

Firestore rules tests (from `firebase/`):

```sh
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

### Build-time switches

| Flag | Values | Default |
|---|---|---|
| `--dart-define=ICRASH_BACKEND=` | `emulator` / `cloud` | debug → `emulator`, release → `cloud` |
| `--dart-define=ICRASH_SHELL=` | `app` / `dashboard` | Android/iOS → `app`, web/desktop → `dashboard` |

In debug builds the profile menu also has **"Ver como App / Ver como Dashboard"**,
so both shells can be tried on one computer.

### Platform status (15 Oct 2026)

| Platform | Status |
|---|---|
| Android | ✅ runs |
| Web | ✅ runs |
| iOS / iPadOS | ❌ not running yet (to investigate). Plugins use Swift Package Manager, so CocoaPods installs only the `Flutter` pod; that is expected. |
| macOS / Windows / Linux | Builds exist for the Dashboard shell; not recently validated |

---

## Firebase environments

| Alias (`firebase/.firebaserc`) | Project id | Used for |
|---|---|---|
| `default`, `local` | `demo-icrash-v2` | Local emulators only (a `demo-` project can never reach the cloud) |
| `development` | `i-crash-pt-2026` | The real cloud project. Rules and indexes are deployed; Auth + Firestore only, no billing, no Storage, no Cloud Functions |

App ids: Android/iOS `pt.icrash.app`, macOS `pt.icrash.app.macos`. FlutterFire config
is in `app/firebase.json` and `app/lib/firebase_options.dart`.

**Never commit secrets.** Service-account keys, keystores and `.env` files are
gitignored. `firebase/tools/provision_cloud_admins.mjs` needs a service-account key
passed on the command line; keep that key outside the repository.

Full setup (emulators, cloud access, deploying rules, first admins, a new project from
zero), the data model and the rules: **[docs/FIREBASE.md](docs/FIREBASE.md)**.

---

## App architecture

Summary below; every screen, flow and convention in detail:
**[docs/APP.md](docs/APP.md)**. Visual design and Figma: **[docs/DESIGN.md](docs/DESIGN.md)**.

One Flutter codebase, **two shells**, chosen by platform; the user's role decides what
is visible inside each:

- **App shell** (Android/iOS, landscape only, tablet-first): the nurse ↔ cart
  assistant. Monthly check by default, plus an **emergency mode** (red theme) entered
  from the cart menu. Must work offline and sync later.
- **Dashboard shell** (web, Windows, macOS, Linux): configuration and oversight for
  managers and admins (carts, drawer grids, catalogue, templates, users, shifts,
  reports).

The code under `app/lib/src/` follows **MVVM**:

| Layer | Folder | Responsibility |
|---|---|---|
| View | `ui/features/<feature>/*_screen.dart`, `ui/shells/` | Draws state and forwards user intents. No repository calls, no business rules |
| ViewModel | `ui/features/<feature>/*_view_model.dart` | Screen state, stream subscriptions, actions returning `ActionResult`. No `BuildContext` |
| Domain | `domain/` (`entities/`, `repositories/` interfaces, `use_cases/`, `reports/`, `inventory_rules.dart`, `inventory_health.dart`) | Entities, repository contracts, pure business rules |
| Data | `data/firebase/` (Firestore/Auth), `data/local/` (on-device stubs) | Implements the repository interfaces |
| Services | `services/` | Scanners (QR, GS1 Data Matrix, EAN-13, Code 128; camera or USB/HID reader), GS1 parser, sync status, reports |
| Common | `common/` | `AppServices` dependency injection (no DI package), environment, generated localisations |

Key conventions:

- Base classes in `ui/core/mvvm/view_model.dart`: `ViewModel` (`listen()`, `notify()`,
  `run()` → `ActionResult`) and `ViewModelBuilder`. One screen = one View + one ViewModel.
- `SessionController` / `SessionScope` (`ui/core/session/session.dart`) hold the
  signed-in user, role, permissions (`can(...)`), open emergencies and cart login.
- Design tokens in `ui/core/theme/tokens.dart` (`IcColors`, `IcSpace`, `IcText`, …)
  mirror the Figma "I-Crash Design v2" file. Fonts: IBM Plex Sans/Mono (bundled).
  Icons: `ui/core/icons/ic_icons.dart` (SVG paths, no icon package).
- **Layout rule:** phones (height < 500) may scroll vertically, never sideways; tablets
  and desktops never scroll. Use `FitList`, `FitDataTable`, `SlotGrid` and
  `OverlayPanelLayout`; `test/ui/layout_fit_test.dart` enforces it at 844×390,
  1280×800 and 1440×900.
- Translations: edit both ARB files, then run `flutter gen-l10n`. CSV/PDF exports stay
  in Portuguese on purpose.

### Screens (Figma ids)

| App shell | Dashboard shell |
|---|---|
| A1 Login · A2 PIN unlock · A3 Cart login (`features/auth`) | B1 Overview (`features/dashboard/overview_*`) |
| A4 Carts list · A12 offline (`features/carts`) | B2 Carts · B3 Cart configuration |
| A5 Cart + menu (`features/cart`) | B4 Drawer grid editor |
| A6 Drawer · A7 Replenish (`features/drawer`) | B5 Product catalogue |
| A8 Monthly check (`features/monthly_check`) | B6 Cart templates |
| A9 Report: sign, PDF (`features/reports`) | B7 Users & permissions |
| A10 Emergency mode (`features/emergency`) | B8 Shifts |
| A11 Scanner (`features/scanner`) | B9 Reports & history |

### Real backend vs on-device stubs

| Repository | Backed by |
|---|---|
| Auth, institutions/members, carts, drawers/slots, products, inventory, usage events, audit | **Firestore / Firebase Auth** |
| Device session (remembered user, PIN as salted SHA-256), reports & signatures, emergencies, templates, shifts, permissions, per-cart auto-status | **Local stubs** (`data/local/`, SharedPreferences). These live only on one device until they get a Firestore implementation; swapping one is a one-line change in `AppServices` |

### Roles

The code has `platformSuperAdmin`, `institutionAdmin`, `manager` and `user`
(`domain/entities/role.dart`). The product direction uses **Engineer Admin**,
**Institution Manager** and **Health Professional**, with a fourth type still
undecided. Mapping the two is open decision **D2**.

---

## Business rules: do not "simplify" these

These are deliberate clinical and traceability decisions. Code that contradicts one is
a bug, and the rule must not be changed to match the code:

1. **Consumption never picks a lot.** Daily use only lowers the slot's aggregate
   `currentQuantity`; it never touches batches or expiry.
2. **Earliest-known expiry is conservative.** Replenishing with an earlier expiry moves
   it earlier; a later expiry never moves it later. Only a physical audit
   (reconciliation) may recompute it from confirmed lots.
3. **Lot state is reconciled only during a physical audit.**
4. **Usage and audit events are immutable.** Mistakes are fixed with a compensating
   correction event, never by editing or deleting.
5. **One product per cart, many carts per product.** A product occupies at most one slot
   in a given cart.
6. **Medicines are scanned as GS1 Data Matrix; internal identification uses QR**
   (`icrash://v1/...`). An unknown GTIN is never silently linked to a product, and
   manual entry is always available.
7. **Scanning never bypasses permissions.**
8. **Concurrent emergencies never require separate sessions.**
9. **No identifiable patient data, anywhere.**
10. **Firestore Rules are the security boundary.** Institutions are fully isolated from
    each other. UI checks are convenience only.

Full reasoning, with examples: `docs/DOMAIN.md` (§20–28, §44–48, §58–59).

---

## History: what changed and why

| When | Who | Change |
|---|---|---|
| 2023 | Martim & Pedro | ISEL bachelor's project: Flutter app (`app1`) + Django REST + PostgreSQL. Archived in `isel/` |
| Sep 2026 | Pedro (AI-assisted) | **Modernisation** on branch `DEV-Pedro`: Flutter/Android toolchain updated, backend moved from Django to **Firebase** (Auth + Firestore, rules, emulator tests), new V2 screens under `lib/src/presentation/` (carts, drawers/slots, products, stock, GS1 scanning, history, CSV/PDF, PT/EN). Old screens kept reachable as "legacy". Its work logs (`IMPLEMENTATION_STATUS.md`, `AI_HANDOFF.md`, `TEST_STATUS.md`, `MODERNIZATION_2026.md`) are in git history on `DEV-Pedro` |
| 13 & 28 Sep 2026 | Martim (with Claude) | Code, UX and security audits of the September version (kept in the claude.ai "I-Crash" project; the 13 Sep one is also in git history) |
| Oct 2026 | Martim | **Design v2 rewrite** on branch `DEV-Martim`: new Figma design, MVVM structure under `lib/src/ui/`, App and Dashboard shells, monthly check, emergency mode, reports with signature, templates, shifts, users & permissions, the no-scroll layout rule. The pre-v2 `lib/src/presentation/` screens were deleted (still in git history) |
| 15 Oct 2026 | Martim | **Repository reorganised**: the app moved from `03_Implementacao/app1` to `app/` and was renamed **ICrash** on every platform. The legacy V1 code (`home_menu.dart`, `grids/`, `registration/`, `request_handler/`, `qr_code_reader/`, `updates/`, `teste/`) and its now-unused packages (`http`, `camera`, `image`, `google_mlkit_*`, `zxing_lib`) were removed from the app. The original app with its legacy code is kept in `isel/03_Implementacao/app1`, as Pedro asked. Firebase files moved into `firebase/`; the bachelor's material moved into `isel/` |

### Git branches (as of 15 Oct 2026)

- `main`: the 2023 bachelor's project only. Nothing from 2026 has been merged into it yet.
- `DEV-Martim` already contains `DEV-Pedro` up to pull request #1 (most of the September work).
- `DEV-Pedro`: the Firebase modernisation. Its last **5 commits are not in
  `DEV-Martim`**: Android release-signing wiring, 13 UX/logic fixes from go-live testing,
  a sign-out fix, and two production-only fixes. They were written against the old
  `presentation/` screens, so they must be ported by hand into the v2 code, not merged
  blindly.
- `DEV-Martim`: the design v2 rewrite. **The v2 code and the 15 Oct reorganisation are
  not committed yet.**
- Do not develop directly on `main`.

---

## Known issues and open items

1. **iOS doesn't run yet.**
2. **Offline stock writes:** consumption, replenishment and correction use Firestore
   transactions, which fail offline. They should become increments plus immutable
   events so they queue.
3. **Slot ids repeat across drawers** (`r{row}c{col}`), so an assignment's `slotId` is
   ambiguous; the assignment needs a `drawerId`.
4. **Rules:** health professionals may only change `currentQuantity`, so replenishment
   is limited to managers until D2 is decided.
5. **Local stubs** (reports, templates, shifts, permissions, emergencies) need Firestore
   implementations before multi-device use.
6. CSV export is a copy dialog (no file saver yet); CSV import works by pasting text;
   cart login by NFC is a stub.
7. **Release:** Android release signing and store accounts are human-only tasks; see
   `docs/RELEASE_CHECKLIST.md`.

Product decisions (D1–D15, with what is confirmed and what is still open) and the
clinical questions for the nurses are in `docs/OPEN_DECISIONS.md`.

---

## Documentation map

| File | Read it for |
|---|---|
| `README.md` (this file) | Orientation, setup, architecture summary, business rules, history |
| `docs/APP.md` | The app in detail: shells, roles and permissions, every screen (A1–A12, B1–B9), flows, code structure, MVVM rules, layout rule, how to add a screen |
| `docs/FIREBASE.md` | Backend: local emulators, cloud project, deploying rules, creating admins, a new project from zero, data model, security rules and their quirks, indexes, inventory rules |
| `docs/DESIGN.md` | Figma file and pages, design principles, colour/type/spacing tokens, components, state system, layout per screen size |
| `docs/OPEN_DECISIONS.md` | Decisions D1–D15 with their status, and the clinical questions; never answer those in code by guesswork |
| `docs/RELEASE_CHECKLIST.md` | What a real store release requires (signing, accounts) |
| `docs/DOMAIN.md` | The domain rules and why they exist (stock, lots, expiry, audits, roles, scanning, no patient data). Code comments "spec section N" refer to §N here |
| `isel/README.md` | Install guide of the 2023 Django + Flutter version |

Removed on 15 Oct 2026 because they described screens and folders that no longer
exist (recover any of them with `git log --all -- docs/<file>` and `git show`):
`ARCHITECTURE.md`, `MANUAL_UTILIZADOR.md`, `IMPLEMENTATION_STATUS.md`, `AI_HANDOFF.md`,
`TEST_STATUS.md`, `MODERNIZATION_2026.md`, `AUDIT_2026-09-13.md`, `FIREBASE_MODEL.md`
(now in `FIREBASE.md`) and `ICRASH_V2_SPECIFICATION.md` (its domain rules are now in
`DOMAIN.md`; the rest was instructions for AI agents). The two 28 Sep audits
and the generated test plan were never committed; the audits are kept in the
claude.ai project, and the test plan can be rebuilt with `isel/build_test_document.py`.

---

## Notes for AI assistants

If you are an AI helping Martim or Pedro:

1. **Read this README first**, then `docs/APP.md` (app), `docs/FIREBASE.md` (backend),
   `docs/DESIGN.md` (UI) or `docs/DOMAIN.md` (business rules), whichever the task
   touches, then the code. If the code and
   the docs disagree, say so; the code is what runs.
2. **To explain the app or the recent changes**, use [History](#history-what-changed-and-why),
   [Git branches](#git-branches-as-of-15-oct-2026) and `git log` / `git diff` on the
   relevant branch. The September work logs live in git history (see the
   Documentation map).
3. **Never change the [business rules](#business-rules-do-not-simplify-these)** to make
   code or tests pass. Report a contradiction instead.
4. **Never deploy** `firestore.rules` / `firestore.indexes.json` to `i-crash-pt-2026`,
   loosen the rules (even temporarily), or run `firebase/tools/` scripts without
   explicit confirmation from a human owner.
5. **Never generate, request or commit secrets** (service-account keys, keystores,
   signing passwords, `.env`).
6. Develop against the **emulator** (`demo-icrash-v2`), not the cloud project.
7. Don't push to `main`. Don't touch `isel/`; it is a frozen archive.
8. New screens follow the MVVM recipe: ViewModel extends `ViewModel`, View uses
   `ViewModelBuilder`, strings go in both ARB files, there is a ViewModel test using
   `buildTestServices` (`test/fakes/fake_repositories.dart`), and the screen respects
   the layout rule and is added to `layout_fit_test.dart`.
9. After changing code, run `flutter test` in `app/` (and the rules tests if
   `firestore.rules` changed).
