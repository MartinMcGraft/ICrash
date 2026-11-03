// Emulator-only check for migrate_v2.mjs: writes September-shaped data,
// runs the migration twice and checks the result. Never touches the cloud.
//   cd firebase && firebase emulators:exec --only firestore --project demo-icrash-v2 "node tools/migrate_v2_check.mjs"
import { execFileSync } from 'node:child_process';
import { strict as assert } from 'node:assert';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const db = getFirestore(initializeApp({ projectId: 'demo-icrash-v2' }));
const i = db.doc('institutions/old-hq');
const cart = i.collection('carts').doc('cart1');
const t = (day) => Timestamp.fromDate(new Date(Date.UTC(2026, 8, day)));

await db.recursiveDelete(i);
await i.set({ name: 'Old HQ', expiryWarningDays: 30 });
await i.collection('memberships').doc('u1').set({ uid: 'u1', role: 'institutionAdmin', status: 'active', email: 'a@old.pt' });
await i.collection('products').doc('p1').set({ name: 'Adrenalina', gtin: '5601234567890' });
await cart.set({ name: 'Carro', status: 'operational', responsibleUserIds: [] });
// Two drawers without numbers; the second (older) one should become number 1.
await cart.collection('drawers').doc('dB').set({ rows: 2, columns: 2, createdAt: t(10), name: 'Gaveta velha' });
await cart.collection('drawers').doc('dA').set({ rows: 1, columns: 2, createdAt: t(5) });
await cart.collection('assignments').doc('as1').set({
  institutionId: 'old-hq', cartId: 'cart1', slotId: 'r1c1', productId: 'p1',
  currentQuantity: 5, targetQuantity: 4, minimumQuantity: 1, status: 'ok',
});
await cart.collection('assignments').doc('as1').collection('batches').doc('b1').set({ expiryDate: t(30), gtin: '5601234567890' });
await i.collection('usageEvents').doc('e1').set({ type: 'consumption', cartId: 'cart1', assignmentId: 'as1', amount: -1, serverTimestamp: t(20) });
await i.collection('usageEvents').doc('e2').set({ type: 'consumption', cartId: 'cart1', assignmentId: 'as1', amount: -1, serverTimestamp: t(15) });

const run = (...args) => execFileSync(process.execPath, ['migrate_v2.mjs', ...args], { cwd: import.meta.dirname, encoding: 'utf8' });

const dry = run();
assert.match(dry, /dry run/);
assert.equal((await cart.collection('drawers').doc('dA').get()).get('number'), undefined, 'a dry run writes nothing');

run('--apply');
const dA = (await cart.collection('drawers').doc('dA').get()).data();
const dB = (await cart.collection('drawers').doc('dB').get()).data();
assert.equal(dA.number, 1);
assert.equal(dB.number, 2);
assert.equal((await cart.collection('drawers').doc('dB').collection('slots').get()).size, 4);
const as1 = (await cart.collection('assignments').doc('as1').get()).data();
assert.equal(as1.drawerId, 'dB', 'r1c1 only exists in the 2x2 drawer');
assert.equal(as1.minimumQuantity, undefined);
assert.equal(as1.status, undefined);
assert.equal(as1.usedAt.toMillis(), t(15).toMillis(), 'usedAt is the first event');
assert.equal((await cart.collection('drawers').doc('dB').collection('slots').doc('r1c1').get()).get('usedAt').toMillis(), t(15).toMillis());
assert.equal(dB.usedAt.toMillis(), t(15).toMillis());
assert.equal(dA.usedAt, undefined);
assert.equal((await i.collection('products').doc('p1').get()).get('gtin'), '05601234567890');
const b1 = (await cart.collection('assignments').doc('as1').collection('batches').doc('b1').get()).data();
assert.ok(!('removedAt' in b1), 'removedAt stays absent, or the rules would block removing the batch');
assert.equal(b1.gtin, '05601234567890');

const again = run('--apply');
assert.match(again, /\n0 change\(s\) written/, 'a second run finds nothing to do');
assert.match(again, /No PIN: a@old\.pt/);
assert.match(again, /Overfilled \(5 > target 4\)/);
assert.match(again, /Batch without quantity/);
assert.match(again, /Drawer name to check: "Gaveta velha"/);

await db.recursiveDelete(i);
console.log('migrate_v2 check passed.');
