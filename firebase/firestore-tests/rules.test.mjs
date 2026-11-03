// Automated Firestore Rules tests (spec section 18, 60). Runs only against
// the local emulator (see README.md in this folder) and never touches the
// cloud project `i-crash-pt-2026`.
import { before, after, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, deleteField, collection, addDoc, serverTimestamp, collectionGroup, query, where, getDocs,
} from 'firebase/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';

const INST_A = 'inst-a';
const INST_B = 'inst-b';
const CART_ID = 'cart-1';
const ASSIGNMENT_ID = 'assign-1';
const ADMIN_UID = 'admin-a';
const MANAGER_UID = 'manager-a'; // role 'manager', NOT registered to any cart
const REG_MANAGER_UID = 'manager-reg'; // role 'manager', registered to CART_ID (D16)
const USER_UID = 'user-a'; // old role 'user' (reads as Manager, D16), registered to CART_ID
const USER2_UID = 'user-a2'; // member of A, but not assigned to any cart
const OTHER_INST_UID = 'user-b'; // member of institution B only
const SUPER_ADMIN_UID = 'super-admin';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

async function seedBaseline() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'institutions', INST_A), { name: 'Hospital A', expiryWarningDays: 30 });
    await setDoc(doc(db, 'institutions', INST_B), { name: 'Hospital B', expiryWarningDays: 30 });

    await setDoc(doc(db, `institutions/${INST_A}/memberships/${ADMIN_UID}`), {
      uid: ADMIN_UID, role: 'institutionAdmin', status: 'active',
    });
    await setDoc(doc(db, `institutions/${INST_A}/memberships/${MANAGER_UID}`), {
      uid: MANAGER_UID, role: 'manager', status: 'active',
    });
    await setDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`), {
      uid: USER_UID, role: 'user', status: 'active',
    });
    await setDoc(doc(db, `institutions/${INST_A}/memberships/${REG_MANAGER_UID}`), {
      uid: REG_MANAGER_UID, role: 'manager', status: 'active',
    });
    await setDoc(doc(db, `institutions/${INST_A}/memberships/${USER2_UID}`), {
      uid: USER2_UID, role: 'user', status: 'active',
    });
    await setDoc(doc(db, `institutions/${INST_B}/memberships/${OTHER_INST_UID}`), {
      uid: OTHER_INST_UID, role: 'user', status: 'active',
    });

    // Denormalized pointers InstitutionRepository.watchMyInstitutions reads
    // via collectionGroup; kept in sync with the memberships above.
    await setDoc(doc(db, `institutions/${INST_A}/memberIndex/${ADMIN_UID}`), { uid: ADMIN_UID, status: 'active' });
    await setDoc(doc(db, `institutions/${INST_A}/memberIndex/${USER_UID}`), { uid: USER_UID, status: 'active' });

    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`), {
      name: 'Cart 1', status: 'operational', layoutVersion: 1,
      responsibleUserIds: [USER_UID, REG_MANAGER_UID],
    });
    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/responsibleUsers/${USER_UID}`), {
      uid: USER_UID,
    });
    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/responsibleUsers/${REG_MANAGER_UID}`), {
      uid: REG_MANAGER_UID,
    });
    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      institutionId: INST_A, cartId: CART_ID,
      slotId: 'slot-1', productId: 'product-1', currentQuantity: 5, targetQuantity: 10,
    });
  });
}

describe('authentication and institution isolation', () => {
  test('unauthenticated access is denied', async () => {
    await seedBaseline();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'institutions', INST_A)));
  });

  test('a member of institution B cannot read anything under institution A', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(OTHER_INST_UID).firestore();
    await assertFails(getDoc(doc(db, 'institutions', INST_A)));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`)));
  });
});

describe('cart access (spec section 17)', () => {
  test('an institution member without a cart assignment cannot read the cart', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`)));
  });

  test('the assigned user can read their cart', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`)));
  });

  test('an Admin reads every cart; a Manager not registered to it can\'t (D16)', async () => {
    await seedBaseline();
    await assertSucceeds(getDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), `institutions/${INST_A}/carts/${CART_ID}`)));
    await assertFails(getDoc(doc(testEnv.authenticatedContext(MANAGER_UID).firestore(), `institutions/${INST_A}/carts/${CART_ID}`)));
  });

  // Regression coverage for a real bug found via live QA testing (not just
  // getDoc): `watchAccessibleCarts` uses a `list` query, which has a
  // stricter Firestore Rules-evaluation model than `get` -- see the long
  // comment on this collection's rule in firestore.rules. These tests
  // exercise `getDocs`/`list`, not `getDoc`/`get`, specifically because the
  // bug only manifested on `list` and every pre-existing test here only
  // ever called `getDoc`.
  test('an Admin lists every cart unfiltered; a Manager can\'t (D16)', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    const snapshot = await assertSucceeds(getDocs(collection(db, `institutions/${INST_A}/carts`)));
    assert.equal(snapshot.size, 1);
    await assertFails(getDocs(collection(testEnv.authenticatedContext(REG_MANAGER_UID).firestore(), `institutions/${INST_A}/carts`)));
  });

  test('the assigned user can list carts by filtering on responsibleUserIds array-contains their uid', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    const q = query(collection(db, `institutions/${INST_A}/carts`), where('responsibleUserIds', 'array-contains', USER_UID));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.deepEqual(snapshot.docs.map((d) => d.id), [CART_ID]);
  });

  test('the assigned user cannot list carts with an unfiltered query -- must use the array-contains query shape', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(getDocs(collection(db, `institutions/${INST_A}/carts`)));
  });

  test('a member with no cart assignment gets no results from the filtered list query', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    const q = query(collection(db, `institutions/${INST_A}/carts`), where('responsibleUserIds', 'array-contains', USER2_UID));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.equal(snapshot.size, 0);
  });
});

describe('daily consumption write scope (spec sections 22-24, 43)', () => {
  test('the assigned user can update only currentQuantity on an assignment', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      currentQuantity: 4,
      updatedAt: serverTimestamp(),
      updatedBy: USER_UID,
    }));
  });

  test('the assigned user cannot change other assignment fields such as targetQuantity', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      targetQuantity: 99,
    }));
  });

  test('an unassigned member cannot touch the assignment at all', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      currentQuantity: 4,
    }));
  });
});

describe('drawer/slot structure changes (spec section 38)', () => {
  test('a normal user cannot create a drawer', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/drawers/drawer-1`), {
      number: 1, rows: 2, columns: 2,
    }));
  });

  test('an Admin can create a drawer; a Manager, even registered to the cart, can\'t (D16)', async () => {
    await seedBaseline();
    const path = `institutions/${INST_A}/carts/${CART_ID}/drawers/drawer-1`;
    await assertFails(setDoc(doc(testEnv.authenticatedContext(REG_MANAGER_UID).firestore(), path), { number: 1, rows: 2, columns: 2 }));
    await assertSucceeds(setDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), path), { number: 1, rows: 2, columns: 2 }));
  });
});

describe('no privilege escalation (spec sections 18, 60)', () => {
  test('a user cannot change their own membership role', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`), {
      role: 'institutionAdmin',
    }));
  });

  test('an institution admin can change another member\'s role', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`), {
      role: 'manager',
    }));
  });

  test('a normal signed-in user cannot create an institution', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, 'institutions', 'inst-new'), { name: 'New', expiryWarningDays: 30 }));
  });

  test('a platform super admin can create an institution', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `platformAdmins/${SUPER_ADMIN_UID}`), { uid: SUPER_ADMIN_UID });
    });
    const db = testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, 'institutions', 'inst-new'), { name: 'New', expiryWarningDays: 30 }));
  });
});

describe('immutable audit/usage history (spec sections 18, 45, 60)', () => {
  test('an assigned user can record usage for their own cart', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: USER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1',
      type: 'consumption', amount: -1,
    }));
  });

  test('a user cannot record usage for a cart they are not assigned to', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    await assertFails(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: USER2_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1',
      type: 'consumption', amount: -1,
    }));
  });

  test('a user cannot record usage claiming a different actor', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: MANAGER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1',
      type: 'consumption', amount: -1,
    }));
  });

  test('nobody, not even an institution admin, can update or delete an audit event', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `institutions/${INST_A}/auditEvents/evt-1`), {
        actorUid: ADMIN_UID, type: 'cartCreated',
      });
    });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/auditEvents/evt-1`), { type: 'tampered' }));
    await assertFails(deleteDoc(doc(db, `institutions/${INST_A}/auditEvents/evt-1`)));
  });
});

describe('cross-institution membership index (spec section 16)', () => {
  test('a member can find their own institutions via the memberIndex collectionGroup query', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    const q = query(collectionGroup(db, 'memberIndex'), where('uid', '==', USER_UID), where('status', '==', 'active'));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.equal(snapshot.size, 1);
  });

  test('a user cannot query another member\'s memberIndex entry by filtering on their uid', async () => {
    await seedBaseline();
    // Rules require resource.data.uid == request.auth.uid, so even the
    // exact query shape the app uses is denied outright when a caller asks
    // for someone else's uid — isolation does not rely on the client
    // filtering honestly.
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    const q = query(collectionGroup(db, 'memberIndex'), where('uid', '==', ADMIN_UID), where('status', '==', 'active'));
    await assertFails(getDocs(q));
  });

  test('an institution admin can add a memberIndex entry for a new member', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `institutions/${INST_A}/memberIndex/${USER2_UID}`), {
      uid: USER2_UID, status: 'active',
    }));
  });

  test('a normal user cannot add a memberIndex entry for themselves or anyone else', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/memberIndex/${USER_UID}`), {
      uid: USER_UID, status: 'active',
    }));
  });
});

describe('cross-cart assignment alerts (spec section 49)', () => {
  const CART2_ID = 'cart-2';
  const ASSIGNMENT2_ID = 'assign-2';

  // A second cart in institution A with its own assignment, deliberately
  // with no responsibleUsers entry for USER_UID — they are only assigned
  // to CART_ID, not this one.
  async function seedSecondCart() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `institutions/${INST_A}/carts/${CART2_ID}`), {
        name: 'Cart 2', status: 'operational', layoutVersion: 1,
      });
      await setDoc(doc(db, `institutions/${INST_A}/carts/${CART2_ID}/assignments/${ASSIGNMENT2_ID}`), {
        institutionId: INST_A, cartId: CART2_ID,
        slotId: 'slot-1', productId: 'product-2', currentQuantity: 1, targetQuantity: 5,
      });
    });
  }

  test('an Admin can list every assignment across every cart in their institution', async () => {
    await seedBaseline();
    await seedSecondCart();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.equal(snapshot.size, 2);
  });

  // Manager+ only, deliberately: a list/collection-group rule can only
  // safely reference fields the query itself filters on (confirmed
  // empirically — see the matching comment in firestore.rules and
  // docs/FIREBASE.md). The query only filters on `institutionId`, so
  // checking `isAssignedToCart` (which needs `cartId`, not part of the
  // filter) throws instead of just excluding the denied document. A normal
  // user still reads their own responsible carts' assignments in full via
  // the ordinary per-cart nested rule (see "daily consumption write scope"
  // above); they just don't get this cross-cart aggregate view.
  test('a Manager cannot use the cross-cart assignments query at all (D16)', async () => {
    await seedBaseline();
    await seedSecondCart();
    for (const uid of [USER_UID, REG_MANAGER_UID, MANAGER_UID]) {
      const db = testEnv.authenticatedContext(uid).firestore();
      const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
      await assertFails(getDocs(q));
    }
  });

  test('a member of a different institution cannot use it either, even filtering by institution A\'s id', async () => {
    await seedBaseline();
    await seedSecondCart();
    const db = testEnv.authenticatedContext(OTHER_INST_UID).firestore();
    const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
    await assertFails(getDocs(q));
  });

  test('an Admin cannot create an assignment whose institutionId/cartId do not match its own path', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/bad-1`), {
      institutionId: INST_B, cartId: CART_ID,
      slotId: 'slot-2', productId: 'product-3', currentQuantity: 0, targetQuantity: 1,
    }));
  });

  test('institutionId/cartId can never be changed after creation, even by an Admin', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      institutionId: INST_B,
    }));
  });
});

describe('no overfill: 0 ≤ currentQuantity ≤ targetQuantity (P5)', () => {
  const path = `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`;

  test('an assigned user cannot raise the stock above the target', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(updateDoc(doc(db, path), { currentQuantity: 11 }));
  });

  test('nobody can take the stock below zero', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, path), { currentQuantity: -1 }));
  });

  test('an Admin cannot lower the target below the current stock', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, path), { targetQuantity: 4 }));
    await assertSucceeds(updateDoc(doc(db, path), { targetQuantity: 5 }));
  });

  test('an Admin cannot create a placement whose initial stock exceeds its target', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/over-1`), {
      institutionId: INST_A, cartId: CART_ID, slotId: 'slot-2', productId: 'product-3', currentQuantity: 3, targetQuantity: 2,
    }));
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/over-2`), {
      institutionId: INST_A, cartId: CART_ID, slotId: 'slot-3', productId: 'product-4', currentQuantity: 0, targetQuantity: 0,
    }));
  });

  test('an old overfilled placement can still have its stock lowered', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`), { uid: USER_UID, role: 'user', status: 'active' });
      await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`), { name: 'Cart 1', responsibleUserIds: [USER_UID] });
      await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/responsibleUsers/${USER_UID}`), { uid: USER_UID });
      await setDoc(doc(db, path), {
        institutionId: INST_A, cartId: CART_ID, slotId: 'slot-1', productId: 'product-1', currentQuantity: 12, targetQuantity: 10,
      });
    });
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, path), { currentQuantity: 11 }));
    await assertFails(updateDoc(doc(db, path), { currentQuantity: 12 }));
  });
});

describe('batches are never deleted (DB1); lot optional, quantity required (P9)', () => {
  const batchPath = `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}/batches`;

  test('a registered Manager can create a batch without a lot number, but not without a quantity', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `${batchPath}/b-1`), { expiryDate: new Date('2027-01-31'), quantity: 2, source: 'manual' }));
    await assertFails(setDoc(doc(db, `${batchPath}/b-2`), { expiryDate: new Date('2027-01-31'), source: 'manual' }));
    await assertFails(setDoc(doc(db, `${batchPath}/b-3`), { expiryDate: new Date('2027-01-31'), quantity: 0, source: 'manual' }));
  });

  test('nobody can delete a batch, not even an institution admin; marking it removed is allowed', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `${batchPath}/b-1`), { expiryDate: new Date('2027-01-31'), quantity: 2 });
    });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(deleteDoc(doc(db, `${batchPath}/b-1`)));
    await assertSucceeds(updateDoc(doc(db, `${batchPath}/b-1`), { removedAt: serverTimestamp() }));
  });

  test('a usage event may carry a reason of at most 500 characters', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    const base = { actorUid: USER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1', type: 'correction', amount: 1 };
    await assertSucceeds(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), { ...base, reason: 'registado na posição errada' }));
    await assertFails(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), { ...base, reason: 'x'.repeat(501) }));
  });
});

describe('a cart\'s structure is fixed once used (P1/P2, usedAt marker)', () => {
  const drawerPath = `institutions/${INST_A}/carts/${CART_ID}/drawers/drawer-1`;
  const slotPath = `${drawerPath}/slots/r0c0`;
  const assignmentPath = `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`;

  async function seedStructure({ used }) {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const mark = used ? { usedAt: new Date('2026-10-29T10:00:00Z') } : {};
      await setDoc(doc(db, drawerPath), { number: 1, rows: 2, columns: 2, ...mark });
      await setDoc(doc(db, slotPath), { row: 0, column: 0, rowSpan: 1, columnSpan: 1, ...mark });
      await setDoc(doc(db, assignmentPath), {
        institutionId: INST_A, cartId: CART_ID, drawerId: 'drawer-1', slotId: 'r0c0', productId: 'product-1',
        currentQuantity: 5, targetQuantity: 10, ...mark,
      });
    });
  }

  test('nobody can delete a drawer, used or not', async () => {
    await seedStructure({ used: false });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(deleteDoc(doc(db, drawerPath)));
  });

  test('an Admin may delete an unused slot and placement', async () => {
    await seedStructure({ used: false });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(deleteDoc(doc(db, slotPath)));
    await assertSucceeds(deleteDoc(doc(db, assignmentPath)));
  });

  test('a used slot and a used placement can\'t be deleted', async () => {
    await seedStructure({ used: true });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(deleteDoc(doc(db, slotPath)));
    await assertFails(deleteDoc(doc(db, assignmentPath)));
  });

  test('the first event marks the placement, slot and drawer used, by an assigned user', async () => {
    await seedStructure({ used: false });
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, assignmentPath), { currentQuantity: 4, usedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, slotPath), { usedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, drawerPath), { usedAt: serverTimestamp() }));
  });

  test('an assigned user can\'t change a slot or drawer beyond marking it used', async () => {
    await seedStructure({ used: false });
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(updateDoc(doc(db, drawerPath), { rows: 3 }));
    await assertFails(updateDoc(doc(db, slotPath), { rowSpan: 2, usedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, slotPath), { usedAt: new Date('2020-01-01T00:00:00Z') }));
  });

  test('the marker can\'t be removed or changed, not even by an admin', async () => {
    await seedStructure({ used: true });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, assignmentPath), { usedAt: deleteField() }));
    await assertFails(updateDoc(doc(db, slotPath), { usedAt: serverTimestamp() }));
  });

  test('a used placement keeps its slot and product; its target and stock may change', async () => {
    await seedStructure({ used: true });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, assignmentPath), { slotId: 'r0c1' }));
    await assertFails(updateDoc(doc(db, assignmentPath), { productId: 'product-2' }));
    await assertSucceeds(updateDoc(doc(db, assignmentPath), { targetQuantity: 12, currentQuantity: 6 }));
  });

  test('a used drawer keeps its grid and number; an unused one may change', async () => {
    await seedStructure({ used: true });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, drawerPath), { rows: 3 }));
    await assertFails(updateDoc(doc(db, drawerPath), { number: 2 }));
    await assertFails(updateDoc(doc(db, slotPath), { columnSpan: 2 }));
  });

  test('a drawer\'s optional name: 1–50 characters; a used drawer may be renamed (D20)', async () => {
    await seedStructure({ used: true });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, drawerPath), { name: 'Via aérea' }));
    await assertSucceeds(updateDoc(doc(db, drawerPath), { name: deleteField() }));
    await assertFails(updateDoc(doc(db, drawerPath), { name: '' }));
    await assertFails(updateDoc(doc(db, drawerPath), { name: 'x'.repeat(51) }));
    await assertFails(updateDoc(doc(db, drawerPath), { name: 7 }));
    const user = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(updateDoc(doc(user, drawerPath), { name: 'Circulação' }));
  });

  test('a new drawer may have a name, within the limit (D20)', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    const drawers = `institutions/${INST_A}/carts/${CART_ID}/drawers`;
    await assertSucceeds(setDoc(doc(db, `${drawers}/drawer-2`), { number: 2, name: 'Circulação', rows: 1, columns: 2 }));
    await assertSucceeds(setDoc(doc(db, `${drawers}/drawer-3`), { number: 3, rows: 1, columns: 2 }));
    await assertFails(setDoc(doc(db, `${drawers}/drawer-4`), { number: 4, name: 'x'.repeat(51), rows: 1, columns: 2 }));
  });

  test('a used drawer created before numbers were stored may get its first number (Q8)', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), drawerPath), { rows: 2, columns: 2, usedAt: new Date('2026-10-29T10:00:00Z') });
    });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, drawerPath), { number: 1 }));
  });
});

describe('user types: Super, Admin, Manager (D16)', () => {
  const cartPath = `institutions/${INST_A}/carts/${CART_ID}`;
  const assignmentPath = `${cartPath}/assignments/${ASSIGNMENT_ID}`;
  const batchPath = `${assignmentPath}/batches`;

  test('a Manager registered to the cart replenishes: new batch, stock and earliest expiry, event', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `${batchPath}/b-new`), { expiryDate: new Date('2027-06-30'), quantity: 2, lotNumber: 'L2' }));
    await assertSucceeds(updateDoc(doc(db, assignmentPath), {
      currentQuantity: 7, earliestKnownExpiry: new Date('2027-06-30'), updatedAt: serverTimestamp(), updatedBy: REG_MANAGER_UID,
    }));
    await assertSucceeds(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: REG_MANAGER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1', type: 'replenishment', amount: 2,
    }));
  });

  test('a registered Manager records a correction and changes the cart state, but not its name', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertSucceeds(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: REG_MANAGER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1', type: 'correction', amount: 1,
    }));
    await assertSucceeds(updateDoc(doc(db, cartPath), { status: 'replenishmentRequired', updatedAt: serverTimestamp(), updatedBy: REG_MANAGER_UID }));
    await assertFails(updateDoc(doc(db, cartPath), { name: 'Outro nome' }));
  });

  test('a registered Manager can\'t change the structure: target, product, slot', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertFails(updateDoc(doc(db, assignmentPath), { targetQuantity: 12 }));
    await assertFails(updateDoc(doc(db, assignmentPath), { productId: 'product-2' }));
    await assertFails(setDoc(doc(db, `${cartPath}/assignments/new-1`), {
      institutionId: INST_A, cartId: CART_ID, slotId: 'slot-2', productId: 'product-3', currentQuantity: 0, targetQuantity: 1,
    }));
  });

  test('a batch is marked removed once and nothing else about it changes (P21)', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `${batchPath}/b-1`), { expiryDate: new Date('2026-10-01'), quantity: 2 });
    });
    const db = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertFails(updateDoc(doc(db, `${batchPath}/b-1`), { expiryDate: new Date('2028-01-01') }));
    await assertSucceeds(updateDoc(doc(db, `${batchPath}/b-1`), { removedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, `${batchPath}/b-1`), { removedAt: deleteField() }));
    const admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(admin, `${batchPath}/b-1`), { removedAt: deleteField() }));
  });

  test('a Manager not registered to the cart is refused everything on it', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    await assertFails(getDoc(doc(db, assignmentPath)));
    await assertFails(updateDoc(doc(db, assignmentPath), { currentQuantity: 4 }));
    await assertFails(setDoc(doc(db, `${batchPath}/b-x`), { expiryDate: new Date('2027-06-30'), quantity: 1 }));
    await assertFails(updateDoc(doc(db, cartPath), { status: 'outOfService' }));
    await assertFails(addDoc(collection(db, `institutions/${INST_A}/usageEvents`), {
      actorUid: MANAGER_UID, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1', type: 'consumption', amount: -1,
    }));
  });

  test('the old \'user\' role works as a Manager on the carts it\'s registered to', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `${batchPath}/b-u`), { expiryDate: new Date('2027-06-30'), quantity: 1 }));
    await assertSucceeds(updateDoc(doc(db, cartPath), { status: 'operational', updatedAt: serverTimestamp(), updatedBy: USER_UID }));
  });

  test('the catalogue, responsible users and audit trail are the Admin\'s', async () => {
    await seedBaseline();
    const manager = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    const admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(manager, `institutions/${INST_A}/products/p-new`), { name: 'Adrenalina' }));
    await assertSucceeds(setDoc(doc(admin, `institutions/${INST_A}/products/p-new`), { name: 'Adrenalina' }));
    await assertFails(setDoc(doc(manager, `${cartPath}/responsibleUsers/${USER2_UID}`), { uid: USER2_UID }));
    await assertSucceeds(setDoc(doc(admin, `${cartPath}/responsibleUsers/${USER2_UID}`), { uid: USER2_UID }));
    await assertFails(getDocs(collection(manager, `institutions/${INST_A}/auditEvents`)));
  });
});

describe('support access: Super only inside a window the Admin opens (D18)', () => {
  const cartPath = `institutions/${INST_A}/carts/${CART_ID}`;
  const supportPath = `institutions/${INST_A}/support/current`;
  const HOUR = 60 * 60 * 1000;

  async function seedSuper({ window } = {}) {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `platformAdmins/${SUPER_ADMIN_UID}`), { uid: SUPER_ADMIN_UID });
      await setDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}/private/credentials`), {
        pinHash: 'pbkdf2-sha256$60000$c2FsdA==$aGFzaA==',
      });
      if (window) await setDoc(doc(db, supportPath), { reason: 'Erro ao sincronizar', grantedBy: ADMIN_UID, ...window });
    });
  }

  test('without a window Super reads only institution names and the window itself', async () => {
    await seedSuper();
    const db = testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'institutions', INST_A)));
    await assertSucceeds(getDocs(collection(db, 'institutions')));
    await assertSucceeds(getDoc(doc(db, supportPath)));
    await assertFails(getDoc(doc(db, cartPath)));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`)));
    await assertFails(setDoc(doc(db, `${cartPath}/drawers/d-s`), { number: 9, rows: 1, columns: 1 }));
  });

  test('inside an open window Super works as an Admin, but never reads PIN hashes', async () => {
    await seedSuper({ window: { endsAt: new Date(Date.now() + 4 * HOUR) } });
    const db = testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore();
    await assertSucceeds(getDoc(doc(db, cartPath)));
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`)));
    await assertSucceeds(setDoc(doc(db, `${cartPath}/drawers/d-s`), { number: 9, rows: 1, columns: 1 }));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}/private/credentials`)));
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/memberships/${USER2_UID}/private/credentials`), {
      pinHash: 'pbkdf2-sha256$60000$c2FsdA==$aGFzaA==',
    }));
    // Not in institution B, which opened nothing.
    await assertFails(getDoc(doc(db, `institutions/${INST_B}/memberships/${OTHER_INST_UID}`)));
  });

  test('an expired or closed window lets nothing through', async () => {
    await seedSuper({ window: { endsAt: new Date(Date.now() - HOUR) } });
    await assertFails(getDoc(doc(testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore(), cartPath)));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), supportPath), {
        reason: 'x', grantedBy: ADMIN_UID, endsAt: new Date(Date.now() + HOUR), closedAt: new Date(),
      });
    });
    await assertFails(getDoc(doc(testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore(), cartPath)));
  });

  test('only the institution\'s own Admin opens a window: with a reason, for at most 7 days', async () => {
    await seedSuper();
    const admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(admin, supportPath), { reason: '', grantedBy: ADMIN_UID, endsAt: new Date(Date.now() + 4 * HOUR) }));
    await assertFails(setDoc(doc(admin, supportPath), { reason: 'Ajuda', grantedBy: ADMIN_UID, endsAt: new Date(Date.now() + 8 * 24 * HOUR) }));
    await assertSucceeds(setDoc(doc(admin, supportPath), { reason: 'Ajuda', grantedBy: ADMIN_UID, endsAt: new Date(Date.now() + 24 * HOUR) }));
    for (const uid of [REG_MANAGER_UID, SUPER_ADMIN_UID]) {
      await assertFails(setDoc(doc(testEnv.authenticatedContext(uid).firestore(), supportPath), {
        reason: 'Ajuda', grantedBy: uid, endsAt: new Date(Date.now() + HOUR),
      }));
    }
  });

  test('the Admin closes the window; it can\'t be stretched once open', async () => {
    await seedSuper({ window: { endsAt: new Date(Date.now() + 4 * HOUR) } });
    const admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(admin, supportPath), { endsAt: new Date(Date.now() + 6 * 24 * HOUR), closedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(admin, supportPath), { closedAt: serverTimestamp(), closedBy: ADMIN_UID }));
    await assertFails(deleteDoc(doc(admin, supportPath)));
  });

  test('Super logs its entries while inside; the log is append-only and the Admin reads it', async () => {
    await seedSuper({ window: { endsAt: new Date(Date.now() + 4 * HOUR) } });
    const sup = testEnv.authenticatedContext(SUPER_ADMIN_UID).firestore();
    const log = `institutions/${INST_A}/supportLog`;
    await assertSucceeds(setDoc(doc(sup, `${log}/e1`), { superUid: SUPER_ADMIN_UID, action: 'enter', at: serverTimestamp() }));
    await assertFails(setDoc(doc(sup, `${log}/e2`), { superUid: ADMIN_UID, action: 'enter', at: serverTimestamp() }));
    await assertFails(updateDoc(doc(sup, `${log}/e1`), { action: 'leave' }));
    await assertFails(deleteDoc(doc(sup, `${log}/e1`)));
    await assertSucceeds(getDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), `${log}/e1`)));
    await assertFails(getDoc(doc(testEnv.authenticatedContext(REG_MANAGER_UID).firestore(), `${log}/e1`)));
    // Outside a window nothing is logged.
    await assertFails(setDoc(doc(sup, `institutions/${INST_B}/supportLog/e3`), { superUid: SUPER_ADMIN_UID, action: 'enter' }));
  });
});

describe('registered tablets act for the person signed in on them (D17)', () => {
  const DEVICE_UID = 'device-1';
  const cartPath = `institutions/${INST_A}/carts/${CART_ID}`;
  const events = `institutions/${INST_A}/usageEvents`;
  const event = (actorUid) => ({
    actorUid, cartId: CART_ID, assignmentId: ASSIGNMENT_ID, productId: 'product-1', type: 'consumption', amount: -1,
  });

  async function seedDevice({ status = 'active' } = {}) {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, `institutions/${INST_A}/memberships/${DEVICE_UID}`), { uid: DEVICE_UID, role: 'device', status, deviceId: 'd1' });
      await setDoc(doc(db, `institutions/${INST_A}/devices/d1`), { name: 'Tablet Carro 1', cartIds: [CART_ID], authUid: DEVICE_UID });
      await setDoc(doc(db, `institutions/${INST_A}/devices/d2`), { name: 'Outro', cartIds: [], authUid: 'device-2' });
      await setDoc(doc(db, `${cartPath}/responsibleUsers/${DEVICE_UID}`), { uid: DEVICE_UID });
      await updateDoc(doc(db, cartPath), { responsibleUserIds: [USER_UID, REG_MANAGER_UID, DEVICE_UID] });
      await setDoc(doc(db, `institutions/${INST_A}/carts/cart-2`), { name: 'Cart 2', status: 'operational', layoutVersion: 1, responsibleUserIds: [] });
      await setDoc(doc(db, `institutions/${INST_A}/memberships/${REG_MANAGER_UID}/private/credentials`), {
        pinHash: 'pbkdf2-sha256$60000$c2FsdA==$aGFzaA==',
      });
    });
  }

  test('a tablet reads its bound cart, its own device document and the PIN hashes; nothing else', async () => {
    await seedDevice();
    const db = testEnv.authenticatedContext(DEVICE_UID).firestore();
    await assertSucceeds(getDoc(doc(db, cartPath)));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/carts/cart-2`)));
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/devices/d1`)));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/devices/d2`)));
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/memberships/${REG_MANAGER_UID}/private/credentials`)));
    const q = query(collection(db, `institutions/${INST_A}/carts`), where('responsibleUserIds', 'array-contains', DEVICE_UID));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.deepEqual(snapshot.docs.map((d) => d.id), [CART_ID]);
  });

  test('a tablet records History for a person allowed on the cart, never as itself or for anyone else', async () => {
    await seedDevice();
    const db = testEnv.authenticatedContext(DEVICE_UID).firestore();
    await assertSucceeds(addDoc(collection(db, events), event(REG_MANAGER_UID)));
    await assertSucceeds(addDoc(collection(db, events), event(ADMIN_UID)));
    await assertFails(addDoc(collection(db, events), event(DEVICE_UID)));
    await assertFails(addDoc(collection(db, events), event(USER2_UID)));
    await assertFails(addDoc(collection(db, events), event(MANAGER_UID)));
    await assertFails(addDoc(collection(db, events), event('nobody')));
    // A person on a personal device still writes only as themselves.
    await assertFails(addDoc(collection(testEnv.authenticatedContext(REG_MANAGER_UID).firestore(), events), event(USER_UID)));
  });

  test('a tablet changes stock on its cart, but no structure, members or devices', async () => {
    await seedDevice();
    const db = testEnv.authenticatedContext(DEVICE_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, `${cartPath}/assignments/${ASSIGNMENT_ID}`), { currentQuantity: 4, updatedBy: REG_MANAGER_UID }));
    await assertFails(setDoc(doc(db, `${cartPath}/drawers/d-x`), { number: 5, rows: 1, columns: 1 }));
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/memberships/${USER_UID}`), { role: 'institutionAdmin' }));
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/devices/d1`), { cartIds: [CART_ID, 'cart-2'] }));
  });

  test('a revoked tablet is refused at its next request', async () => {
    await seedDevice({ status: 'disabled' });
    const db = testEnv.authenticatedContext(DEVICE_UID).firestore();
    await assertFails(getDoc(doc(db, cartPath)));
    await assertFails(getDoc(doc(db, `institutions/${INST_A}/memberships/${REG_MANAGER_UID}/private/credentials`)));
    await assertFails(addDoc(collection(db, events), event(REG_MANAGER_UID)));
    // It can still read its own device document, to show it was revoked.
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/devices/d1`)));
  });

  test('the Admin registers and revokes tablets; a Manager can\'t', async () => {
    await seedDevice();
    const admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(admin, `institutions/${INST_A}/devices/d3`), { name: 'Novo', cartIds: [CART_ID], authUid: 'device-3' }));
    await assertSucceeds(setDoc(doc(admin, `institutions/${INST_A}/memberships/device-3`), { uid: 'device-3', role: 'device', status: 'active' }));
    await assertSucceeds(updateDoc(doc(admin, `institutions/${INST_A}/devices/d1`), { revokedAt: serverTimestamp() }));
    const manager = testEnv.authenticatedContext(REG_MANAGER_UID).firestore();
    await assertFails(setDoc(doc(manager, `institutions/${INST_A}/devices/d4`), { name: 'X', cartIds: [], authUid: 'device-4' }));
    await assertFails(getDoc(doc(manager, `institutions/${INST_A}/devices/d1`)));
  });
});

describe('credentials are set by the administration only (DB3)', () => {
  const credPath = (uid) => `institutions/${INST_A}/memberships/${uid}/private/credentials`;
  const HASH = 'pbkdf2-sha256$60000$c2FsdC1mb3ItdGVzdHMtMQ==$yGloleHkdAyoaW/Eb0SMpPM7gAhWmYdCkJvDYomXLK0=';

  test('an institution admin sets another member\'s PIN hash', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, credPath(USER_UID)), { pinHash: HASH }));
  });

  test('nobody sets their own PIN, not even an admin; a manager can\'t set anyone\'s', async () => {
    await seedBaseline();
    await assertFails(setDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), credPath(ADMIN_UID)), { pinHash: HASH }));
    await assertFails(setDoc(doc(testEnv.authenticatedContext(USER_UID).firestore(), credPath(USER_UID)), { pinHash: HASH }));
    await assertFails(setDoc(doc(testEnv.authenticatedContext(MANAGER_UID).firestore(), credPath(USER_UID)), { pinHash: HASH }));
  });

  test('only a salted PBKDF2 hash is accepted, never a plain PIN', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, credPath(USER_UID)), { pinHash: '1234' }));
  });

  test('the user and admins can read the hash; other members can\'t', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), credPath(USER_UID)), { pinHash: HASH });
    });
    await assertSucceeds(getDoc(doc(testEnv.authenticatedContext(USER_UID).firestore(), credPath(USER_UID))));
    await assertSucceeds(getDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), credPath(USER_UID))));
    await assertFails(getDoc(doc(testEnv.authenticatedContext(MANAGER_UID).firestore(), credPath(USER_UID))));
    await assertFails(getDoc(doc(testEnv.authenticatedContext(USER2_UID).firestore(), credPath(USER_UID))));
  });

  test('a credentials document can\'t be deleted', async () => {
    await seedBaseline();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), credPath(USER_UID)), { pinHash: HASH });
    });
    await assertFails(deleteDoc(doc(testEnv.authenticatedContext(ADMIN_UID).firestore(), credPath(USER_UID))));
  });
});
