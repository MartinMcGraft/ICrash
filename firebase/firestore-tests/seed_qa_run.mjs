// Seed for manual testing on the emulator (not part of the automated rules
// test suite). Never touches the cloud project.
//
// It first WIPES the emulator (every Auth account and every Firestore
// document), so old accounts and tablets registered during earlier tests
// don't stay behind, then creates (Martim, 2 Nov 2026):
//
//   super   super.teste@icrash.pt      PIN 0001  Super: the I-Crash team; no membership,
//                                                a `platformAdmins` marker (D16, D18)
//   adminA  admin.teste@icrash.ia.pt   PIN 1000  Admin of Hospital A (its IT department)
//   adminB  admin.teste@icrash.ib.pt   PIN 2000  Admin of Hospital B
//   userA   user.teste@icrash.ia.pt    PIN 1001  Manager in Hospital A, registered to carro-a1 only
//   userB   user.teste@icrash.ib.pt    PIN 2001  Manager in Hospital B, registered to carro-b1 only
//
// Password for every account: icrash-teste-123.
//
// Carts: Hospital A has carro-a1 (userA) and carro-a2 (nobody registered, so
// only adminA sees it); Hospital B has carro-b1 (userB). Expiry dates are
// relative to the day the seed runs, so "expired" and "expiring" stay true.
// Both institutions open a 7-day support window, so Super can pick A or B
// (the Admin can close it in "Acesso do suporte").
//
// Usage (Auth + Firestore emulators already running):
//   node firestore-tests/seed_qa_run.mjs      (from firebase/)
//   npm run seed                              (from firebase/firestore-tests/)
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';
import fs from 'node:fs';
import { hashPin } from './pin_hash.mjs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';
const AUTH_EMULATOR_HOST = '127.0.0.1:9099';
const PASSWORD = 'icrash-teste-123';

const A = 'hospital-a';
const B = 'hospital-b';

// userNumber: nº mecanográfico, to identify on a registered tablet (D17).
const USERS = {
  super: { email: 'super.teste@icrash.pt', pin: '0001' },
  adminA: {
    email: 'admin.teste@icrash.ia.pt', pin: '1000', institution: A, role: 'institutionAdmin',
    displayName: 'Rita Lopes', userNumber: 'A100',
  },
  adminB: {
    email: 'admin.teste@icrash.ib.pt', pin: '2000', institution: B, role: 'institutionAdmin',
    displayName: 'Paulo Reis', userNumber: 'B200',
  },
  userA: {
    email: 'user.teste@icrash.ia.pt', pin: '1001', institution: A, role: 'manager',
    displayName: 'Ana Silva', service: 'Urgência', userNumber: 'A101',
  },
  userB: {
    email: 'user.teste@icrash.ib.pt', pin: '2001', institution: B, role: 'manager',
    displayName: 'Joana Costa', service: 'Urgência', userNumber: 'B201',
  },
};

const DAY = 24 * 60 * 60 * 1000;
const inDays = (days) => Timestamp.fromDate(new Date(Date.now() + days * DAY));

async function wipeAuth() {
  const response = await fetch(`http://${AUTH_EMULATOR_HOST}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' });
  if (!response.ok) throw new Error(`Could not clear the Auth emulator: ${response.status} ${await response.text()}`);
}

async function createAuthUser(email) {
  const response = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
    },
  );
  const body = await response.json();
  if (!response.ok) throw new Error(`Could not create Auth user ${email}: ${JSON.stringify(body)}`);
  return body.localId;
}

// Catalogue of each institution (the same four consumables in both).
const PRODUCTS = {
  adrenalina: { name: 'Adrenalina', unitDescription: '1 mg/mL · ampola', gtin: '05601234500017', category: 'drug' },
  atropina: { name: 'Atropina', unitDescription: '0,5 mg/mL · ampola', gtin: '05601234500024', category: 'drug' },
  amiodarona: { name: 'Amiodarona', unitDescription: '150 mg/3 mL · ampola', category: 'drug' },
  seringa: { name: 'Seringa 5 mL', unitDescription: 'unidade', category: 'material' },
};

/**
 * One simple cart: 2 drawers of 2 × 2 slots; [placements] fill some slots,
 * each with one batch (lot, quantity, expiry in days from today).
 */
async function seedCart(db, institutionId, cartId, cart, registeredUids, placements) {
  const base = `institutions/${institutionId}/carts/${cartId}`;
  await setDoc(doc(db, base), {
    ...cart,
    status: 'operational',
    layoutVersion: 1,
    archived: false,
    // Denormalized, kept in sync with responsibleUsers (see the carts `list` rule).
    responsibleUserIds: registeredUids,
  });
  for (const uid of registeredUids) {
    await setDoc(doc(db, `${base}/responsibleUsers/${uid}`), { uid });
  }
  // Drawers: a number and an optional name (D20); drawer 2 has none ("Gaveta 2").
  const drawers = { 'gaveta-1': { number: 1, name: 'Via aérea e circulação' }, 'gaveta-2': { number: 2 } };
  for (const [drawerId, drawer] of Object.entries(drawers)) {
    await setDoc(doc(db, `${base}/drawers/${drawerId}`), { ...drawer, rows: 2, columns: 2 });
    for (let row = 0; row < 2; row++) {
      for (let column = 0; column < 2; column++) {
        await setDoc(doc(db, `${base}/drawers/${drawerId}/slots/r${row}c${column}`), { row, column, rowSpan: 1, columnSpan: 1 });
      }
    }
  }
  for (const p of placements) {
    const id = `${p.drawer}-${p.slot}`;
    await setDoc(doc(db, `${base}/assignments/${id}`), {
      institutionId,
      cartId,
      drawerId: p.drawer,
      slotId: p.slot,
      productId: p.product,
      currentQuantity: p.quantity,
      targetQuantity: p.target,
      earliestKnownExpiry: inDays(p.expiresInDays),
    });
    await setDoc(doc(db, `${base}/assignments/${id}/batches/lote-1`), {
      ...(p.lot ? { lotNumber: p.lot } : {}),
      expiryDate: inDays(p.expiresInDays),
      quantity: p.quantity,
      source: 'manual',
    });
  }
}

// What each scenario looks like in a cart (A5 / A8 / B9):
//   OK, expiring within 30 days, expired, below target, and empty slots.
const PLACEMENTS_FULL = [
  { drawer: 'gaveta-1', slot: 'r0c0', product: 'adrenalina', quantity: 10, target: 10, expiresInDays: 400, lot: 'ADR-2601' },
  { drawer: 'gaveta-1', slot: 'r0c1', product: 'atropina', quantity: 4, target: 5, expiresInDays: 12, lot: 'ATR-2511' },
  { drawer: 'gaveta-1', slot: 'r1c0', product: 'amiodarona', quantity: 3, target: 3, expiresInDays: -10, lot: 'AMI-2509' },
  { drawer: 'gaveta-2', slot: 'r0c0', product: 'seringa', quantity: 6, target: 20, expiresInDays: 900 },
];
const PLACEMENTS_OK = [
  { drawer: 'gaveta-1', slot: 'r0c0', product: 'adrenalina', quantity: 10, target: 10, expiresInDays: 300, lot: 'ADR-2604' },
  { drawer: 'gaveta-2', slot: 'r0c0', product: 'seringa', quantity: 20, target: 20, expiresInDays: 900 },
];

async function seedInstitution(db, uids, id, name, admin, carts) {
  await setDoc(doc(db, `institutions/${id}`), { name, expiryWarningDays: 30 });
  for (const [key, user] of Object.entries(USERS)) {
    if (user.institution !== id) continue;
    const uid = uids[key];
    await setDoc(doc(db, `institutions/${id}/memberships/${uid}`), {
      uid,
      role: user.role,
      status: 'active',
      displayName: user.displayName,
      email: user.email,
      userNumber: user.userNumber,
      ...(user.service ? { service: user.service } : {}),
    });
    await setDoc(doc(db, `institutions/${id}/memberIndex/${uid}`), { uid, status: 'active' });
    // DB3: the PIN hash, where B7 "Criar utilizador" writes it.
    await setDoc(doc(db, `institutions/${id}/memberships/${uid}/private/credentials`), { pinHash: hashPin(user.pin) });
  }
  for (const [productId, product] of Object.entries(PRODUCTS)) {
    await setDoc(doc(db, `institutions/${id}/products/${productId}`), { ...product, expiryWarningDays: 30 });
  }
  for (const c of carts) {
    await seedCart(db, id, c.id, c.cart, c.registered, c.placements);
  }
  // D18: support window open for 7 days, so Super can enter.
  const grant = {
    grantId: 'seed',
    reason: 'Dados de teste (seed)',
    grantedBy: uids[admin],
    grantedByName: USERS[admin].displayName,
    startsAt: inDays(0),
    endsAt: inDays(7),
  };
  await setDoc(doc(db, `institutions/${id}/supportGrants/seed`), grant);
  await setDoc(doc(db, `institutions/${id}/support/current`), grant);
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
  });

  // Start from nothing: no old accounts, institutions or tablets.
  await wipeAuth();
  await testEnv.clearFirestore();

  const uids = {};
  for (const [key, user] of Object.entries(USERS)) {
    uids[key] = await createAuthUser(user.email);
  }

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // Super: no membership anywhere; its own PIN (for A2 and signing) on its marker.
    await setDoc(doc(db, `platformAdmins/${uids.super}`), {
      note: 'Equipa I-Crash (seed)',
      email: USERS.super.email,
      pinHash: hashPin(USERS.super.pin),
    });

    await seedInstitution(db, uids, A, 'Hospital A', 'adminA', [
      {
        id: 'carro-a1',
        cart: { name: 'Carro de Urgência A1', service: 'Urgência', location: 'Piso 0' },
        registered: [uids.userA],
        placements: PLACEMENTS_FULL,
      },
      {
        id: 'carro-a2',
        cart: { name: 'Carro de Urgência A2', service: 'Medicina Interna', location: 'Piso 2' },
        registered: [],
        placements: PLACEMENTS_OK,
      },
    ]);
    await seedInstitution(db, uids, B, 'Hospital B', 'adminB', [
      {
        id: 'carro-b1',
        cart: { name: 'Carro de Urgência B1', service: 'Urgência', location: 'Piso 1' },
        registered: [uids.userB],
        placements: PLACEMENTS_FULL,
      },
    ]);
  });

  await testEnv.cleanup();
  console.log(`Seed complete. Password for every account: ${PASSWORD}`);
  for (const [key, user] of Object.entries(USERS)) {
    console.log(`  ${key.padEnd(7)} ${user.email.padEnd(26)} PIN ${user.pin}  ${uids[key]}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
