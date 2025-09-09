const path = require('path');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { FieldValue } = require('firebase/firestore');

const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../firestore.rules'),
  'utf8',
);

describe('avatarInventory rules', function () {
  this.timeout(20000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'tap-em',
      firestore: { rules: firestoreRules, host: '127.0.0.1', port: 8080 },
    });
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('gyms').doc('g1').set({ code: 'g1' });
      await db.collection('gyms').doc('g1').collection('users').doc('userA').set({ role: 'member' });
      await db.collection('gyms').doc('g1').collection('users').doc('adminA').set({ role: 'admin' });
      await db.collection('gyms').doc('g2').collection('users').doc('adminB').set({ role: 'admin' });
      await db.collection('users').doc('userA').set({});
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const adminA = () => testEnv.authenticatedContext('adminA', { gymId: 'g1', role: 'admin' });
  const adminB = () => testEnv.authenticatedContext('adminB', { gymId: 'g2', role: 'admin' });
  const member = () => testEnv.authenticatedContext('userA', { gymId: 'g1', role: 'member' });

  it('allows gym admin to create', async () => {
    const db = adminA().firestore();
    const ref = db.collection('users').doc('userA').collection('avatarInventory').doc('global__x');
    await assertSucceeds(
      ref.set({
        key: 'global/x',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        createdBy: 'adminA',
        gymId: 'g1',
      }),
    );
  });

  it('denies other gym admin', async () => {
    const db = adminB().firestore();
    const ref = db.collection('users').doc('userA').collection('avatarInventory').doc('global__y');
    await assertFails(
      ref.set({
        key: 'global/y',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        createdBy: 'adminB',
        gymId: 'g2',
      }),
    );
  });

  it('denies non-admin', async () => {
    const db = member().firestore();
    const ref = db.collection('users').doc('userA').collection('avatarInventory').doc('global__z');
    await assertFails(
      ref.set({
        key: 'global/z',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        createdBy: 'userA',
        gymId: 'g1',
      }),
    );
  });

  it('denies invalid document', async () => {
    const db = adminA().firestore();
    const ref = db.collection('users').doc('userA').collection('avatarInventory').doc('bad');
    await assertFails(
      ref.set({
        key: 'bad key',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        createdBy: 'adminA',
        gymId: 'g1',
      }),
    );
  });
});
