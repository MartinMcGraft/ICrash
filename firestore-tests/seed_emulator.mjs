// Seeds the local Firebase emulators with one test institution, an active
// admin membership, and a minimal cart/drawer/slot/assignment, so the V2
// login -> institution selection flow has something to show during manual
// testing. Never touches the cloud project.
//
// Usage (emulators must already be running, e.g. via
// `firebase emulators:start --only auth,firestore --project demo-icrash-v2`):
//   node firestore-tests/seed_emulator.mjs
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';
const AUTH_EMULATOR_HOST = '127.0.0.1:9099';

const TEST_EMAIL = 'enfermeira.teste@icrash.pt';
const TEST_PASSWORD = 'icrash-teste-123';
const INSTITUTION_ID = 'hospital-teste';
const CART_ID = 'carro-1';

async function createAuthUser() {
  const response = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: TEST_EMAIL, password: TEST_PASSWORD, returnSecureToken: true }),
    },
  );
  const body = await response.json();
  if (!response.ok) {
    if (body.error?.message === 'EMAIL_EXISTS') {
      console.log(`Auth user ${TEST_EMAIL} already exists, reusing it.`);
      // Look it up so we can still seed Firestore docs keyed by its uid.
      const lookup = await fetch(
        `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: TEST_EMAIL, password: TEST_PASSWORD, returnSecureToken: true }),
        },
      );
      const lookupBody = await lookup.json();
      if (!lookup.ok) throw new Error(`Could not sign in existing test user: ${JSON.stringify(lookupBody)}`);
      return lookupBody.localId;
    }
    throw new Error(`Could not create Auth emulator user: ${JSON.stringify(body)}`);
  }
  return body.localId;
}

async function seedFirestore(uid) {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'institutions', INSTITUTION_ID), {
      name: 'Hospital de Teste',
      expiryWarningDays: 30,
    });

    await setDoc(doc(db, `institutions/${INSTITUTION_ID}/memberships/${uid}`), {
      uid,
      role: 'institutionAdmin',
      status: 'active',
    });

    // Kept in sync with the membership above; see firestore.rules for why
    // this denormalized pointer exists.
    await setDoc(doc(db, `institutions/${INSTITUTION_ID}/memberIndex/${uid}`), {
      uid,
      status: 'active',
    });

    await setDoc(doc(db, `institutions/${INSTITUTION_ID}/carts/${CART_ID}`), {
      name: 'Carro de Emergência 1',
      status: 'operational',
      layoutVersion: 1,
    });

    await setDoc(doc(db, `institutions/${INSTITUTION_ID}/carts/${CART_ID}/responsibleUsers/${uid}`), {
      uid,
    });
  });

  await testEnv.cleanup();
}

const uid = await createAuthUser();
await seedFirestore(uid);

console.log('\nSeed complete. Sign in from the app with:');
console.log(`  e-mail:        ${TEST_EMAIL}`);
console.log(`  palavra-passe: ${TEST_PASSWORD}`);
console.log(`Institution: Hospital de Teste (${INSTITUTION_ID}), role: institutionAdmin`);
