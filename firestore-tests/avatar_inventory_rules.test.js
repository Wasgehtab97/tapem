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

  const adminA = () =>
    testEnv.authenticatedContext('adminA', { gymId: 'g1', role: 'admin' });
  const adminB = () =>
    testEnv.authenticatedContext('adminB', { gymId: 'g2', role: 'admin' });
  const member = () =>
    testEnv.authenticatedContext('userA', { gymId: 'g1', role: 'member' });

  it('allows gym admin to create and read', async () => {
    const db = adminA().firestore();
    const ref = db
      .collection('users')
      .doc('userA')
      .collection('avatarInventory')
      .doc('g1__kurzhantel');
    await assertSucceeds(
      ref.set({
        key: 'g1/kurzhantel',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        gymId: 'g1',
      }),
    );
    await assertSucceeds(ref.get());
  });

  it('blocks admin from other gym', async () => {
    const db = adminA().firestore();
    const ref = db
      .collection('users')
      .doc('userA')
      .collection('avatarInventory')
      .doc('g2__kurzhantel');
    await assertFails(
      ref.set({
        key: 'g2/kurzhantel',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        gymId: 'g2',
      }),
    );
  });

  it('allows user self-service', async () => {
    const db = member().firestore();
    const ref = db
      .collection('users')
      .doc('userA')
      .collection('avatarInventory')
      .doc('global__x');
    await assertSucceeds(
      ref.set({
        key: 'global/x',
        source: 'user/self',
        createdAt: FieldValue.serverTimestamp(),
      }),
    );
  });

  it('denies invalid fields', async () => {
    const db = adminA().firestore();
    const ref = db
      .collection('users')
      .doc('userA')
      .collection('avatarInventory')
      .doc('bad');
    await assertFails(
      ref.set({
        key: 'bad key',
        source: 'admin/manual',
        createdAt: FieldValue.serverTimestamp(),
        gymId: 'g1',
        extra: true,
      }),
    );
  });

  it('allows admin delete', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection('users')
        .doc('userA')
        .collection('avatarInventory')
        .doc('g1__y')
        .set({ key: 'g1/y', source: 'admin/manual', gymId: 'g1' });
    });
    const db = adminA().firestore();
    const ref = db
      .collection('users')
      .doc('userA')
      .collection('avatarInventory')
      .doc('g1__y');
    await assertSucceeds(ref.delete());
  });
});
