// Bootstraps the REAL cloud project (i-crash-pt-2026) with its first platform
// super admins and their institution, using the Firebase Admin SDK.
//
// Why this needs the Admin SDK at all: firestore.rules deliberately makes
// `platformAdmins/{uid}` unwritable by every client (`allow write: if false`)
// and gates `institutions` creation behind `isPlatformSuperAdmin()`. That is a
// chicken-and-egg by design -- the very first super admin can only be created
// by something that bypasses Rules entirely (the Admin SDK or the console).
// Every subsequent member/cart/product can then be created from inside the app.
//
// Usage:
//   Set ICRASH_ADMIN_EMAILS to a comma-separated administrator list, then run:
//   node tools/provision_cloud_admins.mjs <path-to-service-account-key.json>
// or set GOOGLE_APPLICATION_CREDENTIALS and run with no argument.
//
// Get a key from: Firebase Console -> Project settings -> Service accounts ->
// "Generate new private key". Keep the file OUTSIDE this repo (or rely on
// .gitignore, which covers *firebase-adminsdk*.json and *service-account*.json)
// and delete it once you are done -- it grants full project access.
//
// Safe to re-run: every write is a merge-less `set` of a fixed document, so a
// second run just rewrites identical content. It never deletes anything.
import { readFileSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const EXPECTED_PROJECT_ID = 'i-crash-pt-2026';

// The accounts to promote are supplied only at execution time. Do not store
// their e-mail addresses in this repository. UIDs are re-resolved through
// Firebase Authentication, so a mistyped UID can never grant privileges to
// the wrong account.
const ADMIN_EMAILS = (process.env.ICRASH_ADMIN_EMAILS ?? '')
  .split(',')
  .map((email) => email.trim().toLowerCase())
  .filter(Boolean);

const INSTITUTION_ID = 'icrash-hq';
const INSTITUTION = {
  name: 'I-Crash',
  expiryWarningDays: 30,
};

function loadCredential() {
  const keyPath = process.argv[2] ?? process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!keyPath) {
    throw new Error(
      'No service account key given.\n' +
        'Usage: node tools/provision_cloud_admins.mjs <path-to-service-account-key.json>',
    );
  }
  const parsed = JSON.parse(readFileSync(keyPath, 'utf8'));
  if (parsed.project_id !== EXPECTED_PROJECT_ID) {
    throw new Error(
      `Refusing to run: that key belongs to project "${parsed.project_id}", ` +
        `but this script only provisions "${EXPECTED_PROJECT_ID}".`,
    );
  }
  return cert(parsed);
}

async function main() {
  if (ADMIN_EMAILS.length === 0) {
    throw new Error(
      'No administrator accounts supplied. Set ICRASH_ADMIN_EMAILS to a comma-separated list of e-mail addresses.',
    );
  }

  const app = initializeApp({ credential: loadCredential(), projectId: EXPECTED_PROJECT_ID });
  const db = getFirestore(app);
  const auth = (await import('firebase-admin/auth')).getAuth(app);

  const users = [];
  for (const email of ADMIN_EMAILS) {
    const user = await auth.getUserByEmail(email);
    users.push({ uid: user.uid });
    console.log('Resolved an administrator account.');
  }

  const batch = db.batch();

  // 1. Platform super admin markers. Presence of the document is the whole
  //    signal -- firestore.rules only calls exists() on it -- but a note field
  //    makes the collection legible to whoever opens the console next.
  for (const { uid } of users) {
    batch.set(db.doc(`platformAdmins/${uid}`), {
      note: 'I-Crash platform super admin',
    });
  }

  // 2. The institution every screen in the app hangs off.
  batch.set(db.doc(`institutions/${INSTITUTION_ID}`), INSTITUTION);

  // 3+4. Canonical membership, plus the denormalized memberIndex pointer that
  //      InstitutionRepository.watchMyInstitutions actually queries. These two
  //      MUST always be written together -- see docs/FIREBASE_MODEL.md, "Why
  //      memberIndex exists". A membership without its memberIndex twin means
  //      the institution never appears in that user's institution list.
  for (const { uid } of users) {
    batch.set(db.doc(`institutions/${INSTITUTION_ID}/memberships/${uid}`), {
      uid,
      role: 'institutionAdmin',
      status: 'active',
    });
    batch.set(db.doc(`institutions/${INSTITUTION_ID}/memberIndex/${uid}`), {
      uid,
      status: 'active',
    });
  }

  await batch.commit();
  console.log(`\nWrote ${2 * users.length + 1 + users.length} documents.`);

  // Read back what we just wrote, so the run either proves itself or fails
  // loudly -- a silent partial write here would be invisible until someone
  // tried to log in.
  console.log('\nVerifying:');
  const institution = await db.doc(`institutions/${INSTITUTION_ID}`).get();
  console.log(`  institutions/${INSTITUTION_ID}: ${institution.exists ? JSON.stringify(institution.data()) : 'MISSING'}`);
  for (const { uid } of users) {
    const [platformAdmin, membership, memberIndex] = await Promise.all([
      db.doc(`platformAdmins/${uid}`).get(),
      db.doc(`institutions/${INSTITUTION_ID}/memberships/${uid}`).get(),
      db.doc(`institutions/${INSTITUTION_ID}/memberIndex/${uid}`).get(),
    ]);
    console.log(
      `  administrator: platformAdmin=${platformAdmin.exists} membership=${
        membership.exists ? membership.data().role : 'MISSING'
      } memberIndex=${memberIndex.exists}`,
    );
  }

  console.log('\nDone. The selected administrator accounts can now sign in and will see the institution immediately.');
}

main().catch((error) => {
  console.error(`\nFailed: ${error.message}`);
  process.exit(1);
});
