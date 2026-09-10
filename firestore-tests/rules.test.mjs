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
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc, serverTimestamp, collectionGroup, query, where, getDocs,
} from 'firebase/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-icrash-v2';

const INST_A = 'inst-a';
const INST_B = 'inst-b';
const CART_ID = 'cart-1';
const ASSIGNMENT_ID = 'assign-1';
const ADMIN_UID = 'admin-a';
const MANAGER_UID = 'manager-a';
const USER_UID = 'user-a'; // assigned to CART_ID
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
    });
    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/responsibleUsers/${USER_UID}`), {
      uid: USER_UID,
    });
    await setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      institutionId: INST_A, cartId: CART_ID,
      slotId: 'slot-1', productId: 'product-1', currentQuantity: 5, targetQuantity: 10, status: 'ok',
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

  test('a manager can read every cart in the institution without an explicit assignment', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    await assertSucceeds(getDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}`)));
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
      name: 'Gaveta 1', rows: 2, columns: 2,
    }));
  });

  test('a manager can create a drawer', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    await assertSucceeds(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/drawers/drawer-1`), {
      name: 'Gaveta 1', rows: 2, columns: 2,
    }));
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
        slotId: 'slot-1', productId: 'product-2', currentQuantity: 1, targetQuantity: 5, status: 'ok',
      });
    });
  }

  test('a manager can list every assignment across every cart in their institution', async () => {
    await seedBaseline();
    await seedSecondCart();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
    const snapshot = await assertSucceeds(getDocs(q));
    assert.equal(snapshot.size, 2);
  });

  // Manager+ only, deliberately: a list/collection-group rule can only
  // safely reference fields the query itself filters on (confirmed
  // empirically — see the matching comment in firestore.rules and
  // docs/FIREBASE_MODEL.md). The query only filters on `institutionId`, so
  // checking `isAssignedToCart` (which needs `cartId`, not part of the
  // filter) throws instead of just excluding the denied document. A normal
  // user still reads their own responsible carts' assignments in full via
  // the ordinary per-cart nested rule (see "daily consumption write scope"
  // above); they just don't get this cross-cart aggregate view.
  test('a normal user cannot use the cross-cart assignments query at all', async () => {
    await seedBaseline();
    await seedSecondCart();
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
    await assertFails(getDocs(q));
  });

  test('a member of a different institution cannot use it either, even filtering by institution A\'s id', async () => {
    await seedBaseline();
    await seedSecondCart();
    const db = testEnv.authenticatedContext(OTHER_INST_UID).firestore();
    const q = query(collectionGroup(db, 'assignments'), where('institutionId', '==', INST_A));
    await assertFails(getDocs(q));
  });

  test('a manager cannot create an assignment whose institutionId/cartId do not match its own path', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    await assertFails(setDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/bad-1`), {
      institutionId: INST_B, cartId: CART_ID,
      slotId: 'slot-2', productId: 'product-3', currentQuantity: 0, targetQuantity: 1, status: 'ok',
    }));
  });

  test('institutionId/cartId can never be changed after creation, even by a manager', async () => {
    await seedBaseline();
    const db = testEnv.authenticatedContext(MANAGER_UID).firestore();
    await assertFails(updateDoc(doc(db, `institutions/${INST_A}/carts/${CART_ID}/assignments/${ASSIGNMENT_ID}`), {
      institutionId: INST_B,
    }));
  });
});
