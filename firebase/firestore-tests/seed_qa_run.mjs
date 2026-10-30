// One-off seed script for the full manual QA test run (not part of the
// automated rules test suite). Builds a richer, deterministic dataset than
// seed_emulator.mjs: two institutions, users of every type (D16: Super,
// Admin, Manager; one institution per user), and one
// cart with deliberately-crafted products/lots/expiry dates so the
// consumption/replenishment/expiry-warning scenarios in the QA plan are
// reproducible. Never touches the cloud project.
//
// Usage (emulators must already be running):
//   node firestore-tests/seed_qa_run.mjs
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, Timestamp } from 'firebase/firestore';
import fs from 'node:fs';
import { hashPin } from './pin_hash.mjs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';
const AUTH_EMULATOR_HOST = '127.0.0.1:9099';
const PASSWORD = 'icrash-teste-123';
// DB3: the administration sets every user's PIN. Same test PIN for everyone.
const PIN = '1234';

// D16 (30 Oct 2026): enfermeira = Admin of hospital-teste only; gestor and
// utilizador = Managers (health professionals) registered to some carts;
// adminb = Admin of hospital-teste-b (isolation tests); super = Super.
const USERS = {
  admin: 'enfermeira.teste@icrash.pt',
  manager: 'gestor.teste@icrash.pt',
  user: 'utilizador.teste@icrash.pt',
  super: 'super.teste@icrash.pt',
  adminB: 'admin.b.teste@icrash.pt',
};

// The v2 membership fields the app shows (name, e-mail, service).
const PROFILES = {
  admin: { displayName: 'Rita Lopes', service: null },
  manager: { displayName: 'Gonçalo Mendes', service: 'Urgência' },
  user: { displayName: 'Ana Silva', service: 'Medicina Interna' },
  adminB: { displayName: 'Paulo Reis', service: null },
};

function member(key, uid, role) {
  const { displayName, service } = PROFILES[key];
  return { uid, role, status: 'active', displayName, email: USERS[key], ...(service ? { service } : {}) };
}

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

    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.admin), member('admin', uids.admin, 'institutionAdmin'));
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.admin), {
      uid: uids.admin,
      status: 'active',
    });

    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.manager), member('manager', uids.manager, 'manager'));
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.manager), {
      uid: uids.manager,
      status: 'active',
    });

    // D16: there is no 'user' type any more; utilizador is a Manager.
    await setDoc(doc(db, 'institutions/hospital-teste/memberships/' + uids.user), member('user', uids.user, 'manager'));
    await setDoc(doc(db, 'institutions/hospital-teste/memberIndex/' + uids.user), {
      uid: uids.user,
      status: 'active',
    });

    // PIN hashes (DB3), in the members' private credentials document, the
    // way B7 "Criar utilizador" / "Definir novo PIN" write them.
    for (const uid of [uids.admin, uids.manager, uids.user]) {
      await setDoc(doc(db, `institutions/hospital-teste/memberships/${uid}/private/credentials`), { pinHash: hashPin(PIN) });
    }

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
      // D16: Managers registered to the cart (the Admin sees every cart anyway).
      responsibleUserIds: [uids.manager, uids.user],
    });
    for (const uid of [uids.manager, uids.user]) {
      await setDoc(doc(db, `institutions/hospital-teste/carts/carro-1/responsibleUsers/${uid}`), { uid });
    }
    // Drawers have a number and an optional name (D20, 30 Oct; drawer 3 has
    // none, so the app shows "Gaveta 3"). Every drawer has its slot documents
    // (one per cell, rows/columns 0-based in Firestore).
    const drawers = {
      'gaveta-1': { number: 1, name: 'Via aérea', rows: 2, columns: 3 },
      'gaveta-2': { number: 2, name: 'Circulação', rows: 1, columns: 2 },
      'gaveta-3': { number: 3, rows: 1, columns: 2 },
    };
    for (const [drawerId, drawer] of Object.entries(drawers)) {
      await setDoc(doc(db, `institutions/hospital-teste/carts/carro-1/drawers/${drawerId}`), drawer);
      for (let row = 0; row < drawer.rows; row++) {
        for (let column = 0; column < drawer.columns; column++) {
          await setDoc(doc(db, `institutions/hospital-teste/carts/carro-1/drawers/${drawerId}/slots/r${row}c${column}`), {
            row, column, rowSpan: 1, columnSpan: 1,
          });
        }
      }
    }

    // Assignment 1: Adrenalina, two lots, earlier lot governs earliestKnownExpiry (2026-10-15).
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      drawerId: 'gaveta-1',
      slotId: 'r0c0',
      productId: 'adrenalina',
      currentQuantity: 5,
      targetQuantity: 10,
      earliestKnownExpiry: ts('2026-10-15'),
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina/batches/lote-a'),
      { lotNumber: 'LOTE-A', expiryDate: ts('2026-12-31'), quantity: 3, source: 'manual', removedAt: null },
    );
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina/batches/lote-b'),
      { lotNumber: 'LOTE-B', expiryDate: ts('2026-10-15'), quantity: 2, source: 'manual', removedAt: null },
    );

    // Assignment 2: Atropina, below target, expiring soon (within the 30-day window).
    // Its batch has no lot number (P9: some items show only an expiry date).
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-atropina'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      drawerId: 'gaveta-1',
      slotId: 'r0c1',
      productId: 'atropina',
      currentQuantity: 2,
      targetQuantity: 5,
      earliestKnownExpiry: ts('2026-09-25'),
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-atropina/batches/lote-c'),
      { expiryDate: ts('2026-09-25'), quantity: 2, source: 'manual', removedAt: null },
    );

    // Assignment 3: Seringa, fully stocked, far-future expiry — no alerts expected.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-seringa'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      drawerId: 'gaveta-1',
      slotId: 'r0c2',
      productId: 'seringa',
      currentQuantity: 20,
      targetQuantity: 20,
      earliestKnownExpiry: ts('2028-01-01'),
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-seringa/batches/lote-d'),
      { lotNumber: 'LOTE-D', expiryDate: ts('2028-01-01'), quantity: 20, source: 'manual', removedAt: null },
    );

    // Assignment 4: already expired — expired-category testing.
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-expirado'), {
      institutionId: 'hospital-teste',
      cartId: 'carro-1',
      drawerId: 'gaveta-1',
      slotId: 'r1c0',
      productId: 'expirado',
      currentQuantity: 3,
      targetQuantity: 5,
      earliestKnownExpiry: ts('2026-08-01'),
    });
    await setDoc(
      doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-expirado/batches/lote-e'),
      { lotNumber: 'LOTE-E', expiryDate: ts('2026-08-01'), quantity: 3, source: 'manual', removedAt: null },
    );
    // r1c1, r1c2 deliberately left unassigned (empty-slot tests).

    // History for Adrenalina, so drawer 1 shows the structure lock (P1/P2):
    // the placement, its slot r0c0 and drawer 1 carry the `usedAt` marker the
    // app writes with a first event. Drawer 2 stays unused and editable.
    const usedAt = ts('2026-10-01');
    await setDoc(doc(db, 'institutions/hospital-teste/usageEvents/seed-replenishment-adrenalina'), {
      type: 'replenishment',
      cartId: 'carro-1',
      assignmentId: 'assignment-adrenalina',
      productId: 'adrenalina',
      amount: 5,
      actorUid: uids.manager,
      batchId: 'lote-a',
      serverTimestamp: usedAt,
    });
    await updateDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/assignments/assignment-adrenalina'), { usedAt });
    await updateDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/drawers/gaveta-1/slots/r0c0'), { usedAt });
    await updateDoc(doc(db, 'institutions/hospital-teste/carts/carro-1/drawers/gaveta-1'), { usedAt });

    // Cart 2: bare, only gestor is registered (not utilizador): utilizador
    // sees carro-1 only (D16).
    await setDoc(doc(db, 'institutions/hospital-teste/carts/carro-2'), {
      name: 'Carro de Emergência 2',
      status: 'operational',
      layoutVersion: 1,
      responsibleUserIds: [uids.manager],
    });
    for (const uid of [uids.manager]) {
      await setDoc(doc(db, `institutions/hospital-teste/carts/carro-2/responsibleUsers/${uid}`), { uid });
    }

    // ---- Institution B: hospital-teste-b — isolation testing only ----
    await setDoc(doc(db, 'institutions/hospital-teste-b'), {
      name: 'Hospital Teste B',
      expiryWarningDays: 30,
    });
    // RV-1 / D16: a user belongs to one institution, so B has its own Admin.
    await setDoc(doc(db, 'institutions/hospital-teste-b/memberships/' + uids.adminB), member('adminB', uids.adminB, 'institutionAdmin'));
    await setDoc(doc(db, 'institutions/hospital-teste-b/memberIndex/' + uids.adminB), {
      uid: uids.adminB,
      status: 'active',
    });
    await setDoc(doc(db, `institutions/hospital-teste-b/memberships/${uids.adminB}/private/credentials`), { pinHash: hashPin(PIN) });
    await setDoc(doc(db, 'institutions/hospital-teste-b/carts/carro-b1'), {
      name: 'Carro B1',
      status: 'operational',
      layoutVersion: 1,
      responsibleUserIds: [],
    });
  });

  await testEnv.cleanup();
  console.log(`QA seed complete. Password for every account: ${PASSWORD} · PIN: ${PIN}`);
  console.log(JSON.stringify(uids, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
