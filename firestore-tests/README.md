# Firestore Rules tests

Automated tests for `../firestore.rules`, run only against the local Firebase
emulator (project `demo-icrash-v2`). They never touch the cloud project
`i-crash-pt-2026`.

## Setup (once)

```
npm install
```

## Run

From the repository root:

```
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

`firebase emulators:exec` starts the Firestore emulator on the port configured
in `../firebase.json` (127.0.0.1:8081), runs the command, then shuts it down.

## Seed test data for manual QA

With both emulators already running (`firebase emulators:start --only auth,firestore --project demo-icrash-v2` from the repo root), run:

```
npm run seed
```

This creates an Auth emulator user (`enfermeira.teste@icrash.pt` / `icrash-teste-123`), an institution `Hospital de Teste`, an active `institutionAdmin` membership for that user, and one cart with that user as its responsible user — enough to walk through the app's login -> institution selection -> dashboard flow. Emulator data is not persisted across restarts, so re-run this after every fresh `emulators:start`.
