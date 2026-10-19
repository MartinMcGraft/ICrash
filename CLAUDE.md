# I-Crash: notes for Claude Code

Hospital crash-cart app by Martim and Pedro. One Flutter codebase (`app/`, MVVM) with two shells: the App (Android/iOS, landscape) and the Dashboard (web/desktop).

## Read first
- `README.md`, especially "Business rules: do not simplify these" and "Notes for AI assistants". Its rules apply here too.
- Then the doc for the task: `docs/APP.md` (screens, roles, architecture), `docs/DOMAIN.md` (business rules), `docs/DESIGN.md` (Figma + tokens), `docs/DATABASE.md` (new DB design), `docs/FIREBASE.md`, `docs/OPEN_DECISIONS.md`.
- Martim keeps a longer handoff in the claude.ai project "I-Crash" (`claude/HANDOFF.md`). If you can't reach it, ask him to attach it.

## Commands (from `app/`)
- Flutter is at `~/flutter/bin/flutter` (3.47.4).
- `flutter pub get` · `flutter gen-l10n` (after editing ARB files; needs a full restart) · `flutter analyze` · `flutter test`
- Run: `flutter run -d macos --dart-define=ICRASH_SHELL=dashboard` (or `=app`). Debug builds use the Firebase emulator.
- Emulator, from `firebase/`: `firebase emulators:start --only auth,firestore --project demo-icrash-v2`, then `node firestore-tests/seed_qa_run.mjs` (re-seed after every restart).

## Rules
- Never touch `isel/` (frozen 2023 archive). Never push to `main`.
- `DEV-Pedro` commits are ported by hand into `DEV-Martim`, never merged blindly.
- Never deploy rules/indexes to `i-crash-pt-2026` or run `firebase/tools/` scripts without Martim's explicit OK. Never create or commit secrets.
- Layout rule: phones (height < 500) scroll vertically only; tablet and desktop never scroll (shrink grids, page lists with `FitList`/`FitDataTable`/`Pager`, the slot panel slides over the grid). Every new screen is added to `test/ui/layout_fit_test.dart`.
- Use the tokens in `ui/core/theme/tokens.dart`; never hard-code colours or sizes. Strings go in both `app_pt.arb` and `app_en.arb`.
- New screens follow the MVVM recipe in the README (ViewModel + test with `buildTestServices`).
- Re-read the current Figma frames (file `SN7TkBRDszbTFs8oR1uhPR`) before implementing a screen; the design changes.
- The database design in `docs/DATABASE.md` is not implemented yet. Don't reshape domain entities to match it unless asked.
- After changing code, run `flutter analyze` and `flutter test`.
- Show results, not running commentary. Ask before expensive or irreversible changes.
