// Migrates data written before the 29-30 Oct 2026 changes to the current
// model (docs/FIREBASE.md §11). The app reads old documents tolerantly; this
// makes them what the app and firestore.rules now expect.
//
// Default: a DRY RUN against the LOCAL EMULATOR (project demo-icrash-v2). It
// prints every change and writes nothing. Add --apply to write.
//   cd firebase/tools && npm install
//   node migrate_v2.mjs                  # emulator, dry run
//   node migrate_v2.mjs --apply          # emulator, writes
//
// Cloud project (i-crash-pt-2026): only with an explicit OK from a project
// owner (README "Notes for AI assistants"), a service-account key kept
// OUTSIDE the repository, and --cloud. With --apply on the cloud a full JSON
// backup of Firestore is written first (--backup, outside the repository):
//   node migrate_v2.mjs --cloud /outside/repo/key.json
//   node migrate_v2.mjs --cloud /outside/repo/key.json --apply --backup /outside/repo/backup.json
// Delete the key afterwards; it grants full project access.
//
// What it changes (safe to run again: a second run finds nothing to do):
// - drawers without `number` get the next free numbers, in creation order (P17);
// - drawers without slot documents get one slot per cell (`r{row}c{col}`);
// - assignments without `drawerId` get the first drawer, by number, that has
//   their slot; `minimumQuantity` and `status` are removed (D10);
// - `usedAt` on assignments with usage events, and on their slot and drawer;
// - GTINs on products and batches padded to 14 digits (P16).
// Batches keep a missing `removedAt` as it is: it already means active, and
// the rules allow removing a batch only while the field is absent.
// What it only reports (needs a person): members without a PIN hash (DB3),
// overfilled assignments (P5), batches without `quantity`, drawer names to
// check (D20), assignments whose slot is in no drawer.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

const EMULATOR_PROJECT_ID = 'demo-icrash-v2';
const CLOUD_PROJECT_ID = 'i-crash-pt-2026';
const REPO_ROOT = resolve(import.meta.dirname, '..', '..');

const { values } = parseArgs({
  options: {
    cloud: { type: 'string' },
    apply: { type: 'boolean', default: false },
    backup: { type: 'string' },
  },
});

function fail(message) {
  console.error(message);
  process.exit(1);
}

function outsideRepo(path) {
  const full = resolve(path);
  return !(full === REPO_ROOT || full.startsWith(REPO_ROOT + sep));
}

let app;
if (values.cloud) {
  if (!outsideRepo(values.cloud)) fail('Refusing: keep the service-account key outside the repository.');
  const key = JSON.parse(readFileSync(values.cloud, 'utf8'));
  if (key.project_id !== CLOUD_PROJECT_ID) {
    fail(`Refusing: that key is for "${key.project_id}", not "${CLOUD_PROJECT_ID}".`);
  }
  if (values.apply) {
    if (!values.backup) fail('--apply on the cloud needs --backup <file outside the repository>.');
    if (!outsideRepo(values.backup)) fail('Refusing: write the backup outside the repository.');
    if (existsSync(values.backup)) fail(`Refusing to overwrite ${values.backup}.`);
  }
  app = initializeApp({ credential: cert(key), projectId: CLOUD_PROJECT_ID });
  console.log(`Target: CLOUD project ${CLOUD_PROJECT_ID}.`);
} else {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
  app = initializeApp({ projectId: EMULATOR_PROJECT_ID });
  console.log(`Target: emulator (${EMULATOR_PROJECT_ID}).`);
}
console.log(values.apply ? 'Mode: APPLY (writes).' : 'Mode: dry run (writes nothing; add --apply).');

const db = getFirestore(app);

// ---------------------------------------------------------------- backup

async function dumpCollection(ref) {
  const out = {};
  for (const doc of (await ref.get()).docs) {
    const sub = {};
    for (const col of await doc.ref.listCollections()) sub[col.id] = await dumpCollection(col);
    out[doc.id] = { data: encode(doc.data()), ...(Object.keys(sub).length ? { collections: sub } : {}) };
  }
  // Documents that only hold subcollections ("missing" parents).
  for (const missing of await ref.listDocuments()) {
    if (out[missing.id]) continue;
    const sub = {};
    for (const col of await missing.listCollections()) sub[col.id] = await dumpCollection(col);
    if (Object.keys(sub).length) out[missing.id] = { data: null, collections: sub };
  }
  return out;
}

function encode(value) {
  if (value instanceof Timestamp) return { __timestamp: value.toDate().toISOString() };
  if (Array.isArray(value)) return value.map(encode);
  if (value && typeof value === 'object') {
    if (typeof value.path === 'string' && typeof value.id === 'string') return { __ref: value.path };
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, encode(v)]));
  }
  return value;
}

if (values.apply && values.backup) {
  const backup = {};
  for (const col of await db.listCollections()) backup[col.id] = await dumpCollection(col);
  writeFileSync(values.backup, JSON.stringify({ project: values.cloud ? CLOUD_PROJECT_ID : EMULATOR_PROJECT_ID, at: new Date().toISOString(), collections: backup }, null, 1));
  console.log(`Backup written to ${values.backup}.`);
}

// ---------------------------------------------------------------- helpers

const changes = [];
const notes = [];
let batch = db.batch();
let pending = 0;

function change(ref, update, why) {
  changes.push(`${ref.path}: ${why}`);
  if (!values.apply) return;
  batch.set(ref, update, { merge: true });
  pending++;
}

async function flush() {
  if (!values.apply || pending === 0) return;
  await batch.commit();
  batch = db.batch();
  pending = 0;
}

async function flushIfFull() {
  if (pending >= 400) await flush();
}

function normalizeGtin(raw) {
  if (typeof raw !== 'string') return raw;
  const value = raw.replace(/\s/g, '');
  if (!value) return raw;
  return /^(\d{8}|\d{12,14})$/.test(value) ? value.padStart(14, '0') : raw;
}

const millis = (t) => (t instanceof Timestamp ? t.toMillis() : 0);
const earlier = (a, b) => (!a ? b : !b ? a : millis(a) <= millis(b) ? a : b);

// ---------------------------------------------------------------- migrate

for (const institution of await db.collection('institutions').listDocuments()) {
  const i = institution.id;
  console.log(`\nInstitution ${i}`);

  // Products: GTIN padded to 14 (P16).
  for (const product of (await institution.collection('products').get()).docs) {
    const gtin = product.get('gtin');
    const padded = normalizeGtin(gtin);
    if (padded !== gtin) change(product.ref, { gtin: padded }, `gtin ${gtin} -> ${padded}`);
    await flushIfFull();
  }

  // First usage event per assignment (for usedAt).
  const firstUse = new Map();
  for (const event of (await institution.collection('usageEvents').get()).docs) {
    const id = event.get('assignmentId');
    if (!id) continue;
    const at = event.get('serverTimestamp') ?? event.createTime;
    firstUse.set(id, earlier(firstUse.get(id), at));
  }

  // Members without a PIN hash (DB3): someone has to set it (B7 or set_password.mjs).
  for (const member of (await institution.collection('memberships').get()).docs) {
    if (member.get('role') === 'device') continue;
    const credentials = await member.ref.collection('private').doc('credentials').get();
    if (!credentials.exists || !credentials.get('pinHash')) {
      notes.push(`No PIN: ${member.get('email') ?? member.id} (${member.get('role')}) in ${i}`);
    }
  }

  for (const cart of await institution.collection('carts').listDocuments()) {
    const drawerSnaps = (await cart.collection('drawers').get()).docs;

    // Drawers: number (P17), in the app's display order (number, creation, id).
    const drawers = drawerSnaps
      .map((d) => ({ ref: d.ref, id: d.id, data: d.data() }))
      .sort((a, b) => {
        const an = a.data.number ?? null, bn = b.data.number ?? null;
        if (an !== null && bn !== null && an !== bn) return an - bn;
        if (an !== null && bn === null) return -1;
        if (an === null && bn !== null) return 1;
        return millis(a.data.createdAt) - millis(b.data.createdAt) || a.id.localeCompare(b.id);
      });
    const taken = new Set(drawers.map((d) => d.data.number).filter((n) => n != null));
    let next = 1;
    for (const drawer of drawers) {
      if (drawer.data.number != null) continue;
      while (taken.has(next)) next++;
      taken.add(next);
      drawer.data.number = next;
      change(drawer.ref, { number: next }, `number ${next}`);
    }

    // D20 restored drawer names: show them so someone checks them in B3.
    for (const drawer of drawers) {
      const name = drawer.data.name;
      if (typeof name === 'string' && name.trim()) {
        notes.push(`Drawer name to check: "${name}" (drawer ${drawer.data.number}, ${cart.path})` +
          (name.trim().length > 50 ? ' - longer than 50 characters, the rules will refuse edits' : ''));
      }
    }

    // Slots: one document per cell when the layout was never saved.
    const slotIds = new Map();
    const newSlots = new Set();
    for (const drawer of drawers) {
      const slots = (await drawer.ref.collection('slots').get()).docs;
      if (slots.length > 0) {
        slotIds.set(drawer.id, new Set(slots.map((s) => s.id)));
        continue;
      }
      const rows = drawer.data.rows ?? 0, columns = drawer.data.columns ?? 0;
      const ids = new Set();
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < columns; c++) {
          const id = `r${r}c${c}`;
          ids.add(id);
          newSlots.add(`${drawer.id}/${id}`);
          change(drawer.ref.collection('slots').doc(id), { row: r, column: c, rowSpan: 1, columnSpan: 1 }, `new slot ${rows}x${columns} grid`);
          await flushIfFull();
        }
      }
      slotIds.set(drawer.id, ids);
    }

    // Assignments.
    const drawerUse = new Map();
    for (const assignment of (await cart.collection('assignments').get()).docs) {
      const a = assignment.data();
      const update = {};
      const why = [];

      let drawerId = a.drawerId;
      if (!drawerId) {
        drawerId = drawers.find((d) => slotIds.get(d.id)?.has(a.slotId))?.id;
        if (drawerId) {
          update.drawerId = drawerId;
          why.push(`drawerId ${drawerId}`);
        } else {
          notes.push(`Slot ${a.slotId} is in no drawer: ${assignment.ref.path}`);
        }
      }
      if ('minimumQuantity' in a) {
        update.minimumQuantity = FieldValue.delete();
        why.push('remove minimumQuantity');
      }
      if ('status' in a) {
        update.status = FieldValue.delete();
        why.push('remove status');
      }
      const used = firstUse.get(assignment.id);
      if (used && !a.usedAt) {
        update.usedAt = used;
        why.push('usedAt');
      }
      if (used && drawerId && a.slotId) {
        const key = `${drawerId}/${a.slotId}`;
        drawerUse.set(key, earlier(drawerUse.get(key), a.usedAt ?? used));
      }
      if (typeof a.targetQuantity === 'number' && typeof a.currentQuantity === 'number' && a.currentQuantity > a.targetQuantity) {
        notes.push(`Overfilled (${a.currentQuantity} > target ${a.targetQuantity}): ${assignment.ref.path}`);
      }
      if (why.length) change(assignment.ref, update, why.join(', '));
      await flushIfFull();

      // Batches.
      for (const b of (await assignment.ref.collection('batches').get()).docs) {
        // No `removedAt: null` here: the rules allow removing a batch only
        // while the field is absent, so writing null would block it for good.
        const bu = {};
        const bwhy = [];
        const gtin = b.get('gtin');
        const padded = normalizeGtin(gtin);
        if (padded !== gtin) {
          bu.gtin = padded;
          bwhy.push(`gtin ${gtin} -> ${padded}`);
        }
        if (b.get('quantity') == null) notes.push(`Batch without quantity: ${b.ref.path}`);
        if (bwhy.length) change(b.ref, bu, bwhy.join(', '));
        await flushIfFull();
      }
    }

    // usedAt on the slot and drawer of every used assignment.
    const drawerFirst = new Map();
    for (const [key, at] of drawerUse) {
      const [drawerId, slotId] = key.split('/');
      drawerFirst.set(drawerId, earlier(drawerFirst.get(drawerId), at));
      const slotRef = cart.collection('drawers').doc(drawerId).collection('slots').doc(slotId);
      if (newSlots.has(key)) {
        change(slotRef, { usedAt: at }, 'usedAt');
      } else {
        const slot = await slotRef.get();
        if (!slot.exists) notes.push(`Used slot ${slotId} has no document in drawer ${drawerId} (${cart.path})`);
        else if (!slot.get('usedAt')) change(slotRef, { usedAt: at }, 'usedAt');
      }
      await flushIfFull();
    }
    for (const [drawerId, at] of drawerFirst) {
      const drawer = drawers.find((d) => d.id === drawerId);
      if (drawer && !drawer.data.usedAt) change(drawer.ref, { usedAt: at }, 'usedAt');
    }
    await flush();
  }
}
await flush();

console.log(`\n${changes.length} change(s)${values.apply ? ' written' : ' to make'}:`);
for (const c of changes) console.log(`  ${c}`);
console.log(`\n${notes.length} item(s) for a person to check:`);
for (const n of notes) console.log(`  ${n}`);
