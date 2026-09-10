# Release checklist

Documentation only — this file records what a real release requires and why,
but performs none of it. Real signing keys, keystores, and Apple/Google
account credentials must never be generated, requested, or handled by an AI
assistant in this environment; every item below that needs one is marked
**human action required** and is something Pedro (or whoever owns the
relevant developer account) must do directly, outside any assistant session.

Written for workstream J / spec section 68, as step 9 of the post-spec batch
started 2026-09-10 (see `docs/AI_HANDOFF.md`).

## What's already correct (Phase 1, unchanged since)

- **Package identifiers** are already set correctly on every platform, and do
  not need to change before release:
  - Android: `applicationId`/`namespace` = `pt.icrash.app` (`android/app/build.gradle`).
  - iOS: `PRODUCT_BUNDLE_IDENTIFIER` = `pt.icrash.app` (`ios/Runner.xcodeproj/project.pbxproj`).
  - macOS: `PRODUCT_BUNDLE_IDENTIFIER` = `pt.icrash.app.macos` (`macos/Runner/Configs/AppInfo.xcconfig`).
- **Environment separation already works correctly** and needs no changes —
  see `docs/ARCHITECTURE.md`'s "Environment selection" section: debug builds
  default to the local Firebase emulator, release builds default to the real
  cloud project (`i-crash-pt-2026`), and either can be forced with
  `--dart-define=ICRASH_BACKEND=emulator|cloud`. **A release build must never
  accidentally point at the emulator** — always build release with the
  default (no override) or an explicit `--dart-define=ICRASH_BACKEND=cloud`,
  never test a release build against `10.0.2.2`/`127.0.0.1`.
- `firestore.rules`/`firestore.indexes.json` are already deployed to
  `i-crash-pt-2026` and match the repo's copy exactly (see `docs/AI_HANDOFF.md`,
  "Firebase configuration status"). Any future change to either file needs
  explicit user confirmation before redeploying — this was already true and
  doesn't change for a release.

## Android release signing — not yet done

**Currently**: `android/app/build.gradle`'s `release` build type signs with
`signingConfigs.debug` — a build tagged `release` today is not actually
suitable for distribution; it's signed with the same throwaway debug key
every Flutter project ships with, and Google Play will reject an upload
signed that way (and even if it didn't, anyone could re-sign a malicious
update with the same public debug key).

**Required before shipping to Google Play or handing out a real release
APK**, in order:

1. **Human action required**: generate an upload keystore
   (`keytool -genkey -v -keystore <path>.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`)
   and store it somewhere durable and backed up *outside this repository* —
   losing it means losing the ability to publish updates to an existing Play
   Store listing under the same app identity.
2. **Human action required**: create `android/key.properties` (already
   `.gitignore`d by the standard Flutter template — verify this before
   creating it) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
   Never commit this file or the `.jks` itself.
3. Once both exist, `android/app/build.gradle` needs a `signingConfigs.release`
   block reading from `key.properties`, and the `release` build type's
   `signingConfig` changed from `signingConfigs.debug` to
   `signingConfigs.release` — this is a small, mechanical code change an
   assistant *can* make once the keystore/properties file exist, but there is
   nothing to wire up until step 1-2 are done by a human.
4. Google Play uses **Play App Signing** by default for new apps (Google
   holds the final signing key; the upload keystore from step 1 only signs
   the upload artifact) — decide whether to opt in when creating the Play
   Console listing (recommended: yes, it's the modern default and lets Google
   recover a lost upload key).

## iOS/macOS signing — not yet done, and cannot be validated from this environment

- **Human action required**: an active Apple Developer Program membership,
  an App ID matching `pt.icrash.app` (iOS) / `pt.icrash.app.macos` (macOS)
  registered in the Apple Developer portal, and provisioning
  profiles/signing certificates configured in Xcode.
- This entire area is unverifiable from Windows — consistent with every
  other iOS/macOS limitation already documented throughout this project
  (`docs/AI_HANDOFF.md`'s "Known platform limitations"). Whoever has access
  to a Mac must set this up and do a real device/TestFlight build.

## Windows — no store signing required for direct distribution

Running `flutter build windows --release` produces an unsigned `.exe`; this
is fine for direct distribution (a user runs it directly) but will trigger
SmartScreen warnings. Only becomes relevant if this ever targets the
Microsoft Store, which would need a separate Partner Center account and
package identity — out of scope until that's an actual goal.

## Versioning

`pubspec.yaml`'s `version: 1.0.0+1` (`<semantic version>+<build number>`)
drives both Android's `versionName`/`versionCode` and iOS/macOS's
`CFBundleShortVersionString`/`CFBundleVersion` automatically via
`flutter.versionName`/`flutter.versionCode` in `android/app/build.gradle` —
no separate per-platform version files to keep in sync. Bump the build
number (`+1` → `+2`, etc.) for every store submission, even ones that don't
change the semantic version; bump the semantic version itself for
user-visible changes, following normal semver judgment.

## Store listing requirements — not started

Not part of this codebase and not an engineering task: app icon (a
placeholder Flutter icon is currently in use — needs a real one),
screenshots, a privacy policy URL (this app handles hospital inventory
data — a health-adjacent context that may need explicit legal review before
any public store listing, separate from the open clinical questions already
tracked in `docs/OPEN_DECISIONS.md`), and a store description. All **human
action required**, and likely needs sign-off from whoever owns the product/
legal side of this project, not just engineering.

## Summary: what an assistant can safely help with later

- The mechanical `build.gradle` wiring in "Android release signing" step 3,
  once a human has done steps 1-2.
- Re-running `flutter build apk --release`/`flutter build appbundle`/
  `flutter build ios`/`flutter build macos`/`flutter build windows` once
  signing is configured, to confirm they succeed.
- Bumping `pubspec.yaml`'s version number for a release.

Everything else in this file needs a human with the relevant account access.
