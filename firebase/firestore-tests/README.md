# Firestore Rules tests

Automated tests for `../firestore.rules`, run only against the local Firebase
emulator (project `demo-icrash-v2`). They never touch the cloud project
`i-crash-pt-2026`.

## Setup (once)

```
npm install
```

## Run

From the `firebase/` folder (`cd firebase`):

```
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

`firebase emulators:exec` starts the Firestore emulator on the port configured
in `../firebase.json` (127.0.0.1:8081), runs the command, then shuts it down.

## Seed test data for manual QA

With both emulators already running (`firebase emulators:start --only auth,firestore --project demo-icrash-v2` from the `firebase/` folder), run:

```
npm run seed
```

This runs `seed_qa_run.mjs`: it **wipes the emulator** (Auth accounts and Firestore), then creates Super (`super.teste@icrash.pt`), the Admins of Hospital A and B (`admin.teste@icrash.ia.pt`, `admin.teste@icrash.ib.pt`), one Manager in each (`user.teste@icrash.ia.pt`, `user.teste@icrash.ib.pt`) and three carts (A1 and A2 in Hospital A, B1 in Hospital B). Password `icrash-teste-123`; PINs and details in the repository README. Emulator data is not persisted across restarts, so re-run this after every fresh `emulators:start`.
