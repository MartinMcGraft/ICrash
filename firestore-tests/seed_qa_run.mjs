// One-off seed script for the full manual QA test run (not part of the
// automated rules test suite). Builds a richer, deterministic dataset than
// seed_emulator.mjs: two institutions, four users across every role, and one
// cart with deliberately-crafted products/lots/expiry dates so the
// consumption/replenishment/expiry-warning scenarios in the QA plan are
// reproducible. Never touches the cloud project.
//
// Usage (emulators must already be running):
//   node firestore-tests/seed_qa_run.mjs
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';
const AUTH_EMULATOR_HOST = '127.0.0.1:9099';
const PASSWORD = 'icrash-teste-123';

const USERS = {
  admin: 'enfermeira.teste@icrash.pt',
  manager: 'gestor.teste@icrash.pt',
  user: 'utilizador.teste@icrash.pt',
  super: 'super.teste@icrash.pt',
};

async function createOrGetAuthUser(email) {
  const signUp = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
    },
  );
  const body = await signUp.json();
  if (signUp.ok) return body.localId;
  if (body.error?.message === 'EMAIL_EXISTS') {
    const signIn = await fetch(
      `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
      },
    );
    const signInBody = await signIn.json();
    if (!signIn.ok) throw new Error(`Could not sign in existing user ${email}: ${JSON.stringify(signInBody)}`);
    return signInBody.localId;
  }
  throw new Error(`Could not create Auth user ${email}: ${JSON.stringify(body)}`);
}

function ts(dateString) {
  return Timestamp.fromDate(new Date(dateString));
}

async function main() {
  const uids = {};
  for (const [key, email] of Object.entries(USERS)) {
    uids[key] = await createOrGetAuthUser(email);
    console.log(`${key}: ${email} -> ${uids[key]}`);
  }

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

    // Platform super admin marker — no membership anywhere, deliberately,
    // to test what a pure platform-admin-with-no-institution-membership
    // actually sees (there is no known UI to grant this role otherwise).
    await setDoc(doc(db, `platformAdmins/${uids.super}`), { note: 'QA test run — platform super admin marker' });

    // ---- Institution A: hospital-teste (reused from seed_emulator.mjs) ----
    await setDoc(doc(db, 'institutions/hospital-teste'), {
      name: 'Hospital de Teste',
      expiryWarningDays: 30,
    });

    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.admin), {
      uid: uids.admin,
      role: 'institutionAdmin',
      status: 'active',
    });
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.admin), {
      uid: uids.admin,
      status: 'active',
    });

    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.manager), {
      uid: uids.manager,
      role: 'manager',
      status: 'active',
    });
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.manager), {
      uid: uids.manager,
      status: 'active',
    });

    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.user), {
      uid: uids.user,
      role: 'user',
      status: 'active',
    });
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.user), {
      uid: uids.user,
      status: 'active',
    });

    // Products
    const products = {
      adrenalina: { name: 'Adrenalina', unitDescription: '1 mg/mL', gtin: '05412345678900' },
      atropina: { name: 'Atropina', unitDescription: '0.5 mg/mL' },
      seringa: { name: 'Seringa 5ml' },
      expirado: { name: 'Produto Expirado Teste' },
    };
    for (const [id, data] of Object.entries(products)) {
      await setDoc(doc(db, `institutions/hospital-teste/products/${id}`), data);
    }

    // Cart 1: fully equipped for daily-use testing.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1'), {
      name: 'Carro de Emergência 1',
      status: 'operational',
      layoutVersion: 1,
      // Denormalized, kept in sync with responsibleUsers below -- see
      // firestore.rules' carts/{cartId} `allow list` for why this exists.
      responsibleUserIds: [uids.admin, uids.manager, uids.user],
    });
    for (const uid of [uids.admin, uids.manager, uids.user]) {
      await setDoc(doc(db, `institutions/hospital-teste/carts/carro-1/responsibleUsers/${uid}`), { uid });
    }
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/drawers/gaveta-1'), {
      name: 'Gaveta 1',
      rows: 2,
      columns: 3,
    });
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/drawers/gaveta-2'), {
      name: 'Gaveta 2',
      rows: 1,
      columns: 2,
    });

    // Assignment 1: Adrenalina, two lots, earlier lot governs earliestKnownExpiry (2026-10-15).
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      slotId: 'r0c0',
      productId: 'adrenalina',
      currentQuantity: 5,
      targetQuantity: 10,
      minimumQuantity: 3,
      earliestKnownExpiry: ts('2026-10-15'),
      status: 'ok',
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina/batches/lote-a'),
      { lotNumber: 'LOTE-A', expiryDate: ts('2026-12-31'), source: 'manual' },
    );
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina/batches/lote-b'),
      { lotNumber: 'LOTE-B', expiryDate: ts('2026-10-15'), source: 'manual' },
    );

    // Assignment 2: Atropina, at minimum quantity, expiring soon (within the 30-day window).
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-atropina'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      slotId: 'r0c1',
      productId: 'atropina',
      currentQuantity: 2,
      targetQuantity: 5,
      minimumQuantity: 2,
      earliestKnownExpiry: ts('2026-09-25'),
      status: 'ok',
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-atropina/batches/lote-c'),
      { lotNumber: 'LOTE-C', expiryDate: ts('2026-09-25'), source: 'manual' },
    );

    // Assignment 3: Seringa, fully stocked, far-future expiry — no alerts expected.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-seringa'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      slotId: 'r0c2',
      productId: 'seringa',
      currentQuantity: 20,
      targetQuantity: 20,
      earliestKnownExpiry: ts('2028-01-01'),
      status: 'ok',
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-seringa/batches/lote-d'),
      { lotNumber: 'LOTE-D', expiryDate: ts('2028-01-01'), source: 'manual' },
    );

    // Assignment 4: already expired — expired-category testing.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-expirado'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      slotId: 'r1c0',
      productId: 'expirado',
      currentQuantity: 3,
      targetQuantity: 5,
      earliestKnownExpiry: ts('2026-08-01'),
      status: 'ok',
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-expirado/batches/lote-e'),
      { lotNumber: 'LOTE-E', expiryDate: ts('2026-08-01'), source: 'manual' },
    );
    // r1c1, r1c2 deliberately left unassigned (empty-slot tests).

    // Cart 2: bare, only the manager+admin are responsible (not the normal user) — cross-cart access test.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-2'), {
      name: 'Carro de Emergência 2',
      status: 'operational',
      layoutVersion: 1,
      responsibleUserIds: [uids.admin, uids.manager],
    });
    for (const uid of [uids.admin, uids.manager]) {
      await setDoc(doc(db, `institutions/hospital-teste/carts/carro-2/responsibleUsers/${uid}`), { uid });
    }

    // ---- Institution B: hospital-teste-b — isolation testing only ----
    await setDoc(doc(db, 'institutions/hospital-teste-b'), {
      name: 'Hospital Teste B',
      expiryWarningDays: 30,
    });
    await setDoc(doc(db, 'institutions/hospital-teste-b/memberships/' + uids.admin), {
      uid: uids.admin,
      role: 'institutionAdmin',
      status: 'active',
    });
    await setDoc(doc(db, 'institutions/hospital-teste-b/memberIndex/' + uids.admin), {
      uid: uids.admin,
      status: 'active',
    });
    await setDoc(doc(db, 'institutions/hospital-teste-b/carts/carro-b1'), {
      name: 'Carro B1',
      status: 'operational',
      layoutVersion: 1,
      responsibleUserIds: [uids.admin],
    });
    await setDoc(doc(db, 'institutions/hospital-teste-b/carts/carro-b1/responsibleUsers/' + uids.admin), {
      uid: uids.admin,
    });
  });

  await testEnv.cleanup();
  console.log('QA seed complete.');
  console.log(JSON.stringify(uids, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
