// Resets a user's password and/or PIN (DB3: only the administration sets
// credentials). The app can't do this itself: without Cloud Functions
// (Spark plan, no billing), a client can't change ANOTHER user's Firebase
// password, so the institution's IT department runs this script instead.
//
// Default target: the LOCAL EMULATOR (project demo-icrash-v2). Start it first:
//   cd firebase && firebase emulators:start --only auth,firestore --project demo-icrash-v2
//   cd firebase/tools && npm install
//   node set_password.mjs --email user.teste@icrash.ia.pt --password 'nova-palavra-1' --pin 4321 --institution hospital-a
//
// Cloud project (i-crash-pt-2026): only with an explicit OK from a project
// owner (see README "Notes for AI assistants"), a service-account key kept
// OUTSIDE the repository, and the --cloud flag:
//   node set_password.mjs --cloud /path/outside/repo/key.json --email ... --password ...
// Delete the key afterwards; it grants full project access.
//
// --password changes the Firebase Auth password (at least 8 characters).
// --pin (4 digits) needs --institution: it writes the salted PBKDF2 hash to
//   institutions/{institution}/memberships/{uid}/private/credentials, the
//   same format the app writes (app/lib/src/services/pin_hasher.dart).
import { readFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { hashPin } from '../firestore-tests/pin_hash.mjs';

const EMULATOR_PROJECT_ID = 'demo-icrash-v2';
const CLOUD_PROJECT_ID = 'i-crash-pt-2026';
const MIN_PASSWORD_LENGTH = 8;

const { values } = parseArgs({
  options: {
    email: { type: 'string' },
    password: { type: 'string' },
    pin: { type: 'string' },
    institution: { type: 'string' },
    cloud: { type: 'string' },
  },
});

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (!values.email) fail('Missing --email.');
if (!values.password && !values.pin) fail('Nothing to do: give --password and/or --pin.');
if (values.password && values.password.length < MIN_PASSWORD_LENGTH) {
  fail(`The password must have at least ${MIN_PASSWORD_LENGTH} characters.`);
}
if (values.pin && !/^\d{4}$/.test(values.pin)) fail('The PIN is exactly 4 digits.');
if (values.pin && !values.institution) fail('--pin needs --institution <institutionId>.');

let app;
if (values.cloud) {
  const key = JSON.parse(readFileSync(values.cloud, 'utf8'));
  if (key.project_id !== CLOUD_PROJECT_ID) {
    fail(`Refusing: that key is for "${key.project_id}", not "${CLOUD_PROJECT_ID}".`);
  }
  app = initializeApp({ credential: cert(key), projectId: CLOUD_PROJECT_ID });
  console.log(`Target: CLOUD project ${CLOUD_PROJECT_ID}.`);
} else {
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
  app = initializeApp({ projectId: EMULATOR_PROJECT_ID });
  console.log(`Target: emulator (${EMULATOR_PROJECT_ID}).`);
}

const user = await getAuth(app).getUserByEmail(values.email.trim().toLowerCase());

if (values.password) {
  await getAuth(app).updateUser(user.uid, { password: values.password });
  console.log('Password changed. Hand it to the person; they can\'t change it themselves.');
}

if (values.pin) {
  const db = getFirestore(app);
  const membership = await db.doc(`institutions/${values.institution}/memberships/${user.uid}`).get();
  if (!membership.exists) fail(`No membership for that user in institution "${values.institution}".`);
  await db.doc(`institutions/${values.institution}/memberships/${user.uid}/private/credentials`).set({
    pinHash: hashPin(values.pin),
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: 'set_password.mjs',
  });
  console.log('PIN changed. It takes effect on a tablet the next time the person signs in there online.');
}
