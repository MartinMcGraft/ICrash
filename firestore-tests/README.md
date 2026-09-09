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
