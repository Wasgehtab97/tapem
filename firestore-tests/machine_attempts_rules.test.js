const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const { FieldValue } = require('firebase/firestore');

const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../firestore.rules'),
  'utf8'
);

describe('Machine attempt security rules', function () {
  this.timeout(20000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'tap-em',
      firestore: {
        rules: firestoreRules,
        host: '127.0.0.1',
        port: 8080,
      },
    });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('gyms').doc('G1').set({ name: 'Gym 1' });
      await db.collection('gyms').doc('G1').collection('devices').doc('M1').set({ isMulti: false });
      await db.collection('gyms').doc('G1').collection('devices').doc('M2').set({ isMulti: true });
      await db.collection('gyms').doc('G1').collection('users').doc('user1').set({ role: 'member' });
      await db.collection('gyms').doc('G1').collection('users').doc('stranger').set({ role: 'member' });
      await db
        .collection('gyms')
        .doc('G1')
        .collection('machines')
        .doc('M1')
        .collection('attempts')
        .doc('attempt1')
        .set({
          gymId: 'G1',
          machineId: 'M1',
          userId: 'user1',
          username: 'Alice',
          e1rm: 120,
          reps: 5,
          weight: 100,
          createdAt: new Date(),
          isMulti: false,
        });
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const memberCtx = () => testEnv.authenticatedContext('user1', { gymId: 'G1', role: 'member' });
  const strangerCtx = () => testEnv.authenticatedContext('outsider', {});
  const foreignMemberCtx = () => testEnv.authenticatedContext('stranger', { gymId: 'G1', role: 'member' });

  it('allows members to read attempts', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc('attempt1');
    await assertSucceeds(ref.get());
  });

  it('denies non-members from reading attempts', async () => {
    const db = strangerCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc('attempt1');
    await assertFails(ref.get());
  });

  it('allows member to create attempt for themselves on single device', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc();
    await assertSucceeds(
      ref.set({
        gymId: 'G1',
        machineId: 'M1',
        userId: 'user1',
        username: 'Alice',
        e1rm: 125,
        reps: 5,
        weight: 105,
        createdAt: FieldValue.serverTimestamp(),
        isMulti: false,
        gender: 'w',
        bodyWeightKg: 60,
      })
    );
  });

  it('denies creating attempts for other users', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc();
    await assertFails(
      ref.set({
        gymId: 'G1',
        machineId: 'M1',
        userId: 'someoneElse',
        username: 'Alice',
        e1rm: 125,
        reps: 5,
        weight: 105,
        createdAt: FieldValue.serverTimestamp(),
        isMulti: false,
      })
    );
  });

  it('denies creating attempts on multi devices', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M2')
      .collection('attempts')
      .doc();
    await assertFails(
      ref.set({
        gymId: 'G1',
        machineId: 'M2',
        userId: 'user1',
        username: 'Alice',
        e1rm: 130,
        reps: 4,
        weight: 110,
        createdAt: FieldValue.serverTimestamp(),
        isMulti: false,
      })
    );
  });

  it('denies attempts with client timestamp', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc();
    await assertFails(
      ref.set({
        gymId: 'G1',
        machineId: 'M1',
        userId: 'user1',
        username: 'Alice',
        e1rm: 130,
        reps: 4,
        weight: 110,
        createdAt: new Date(),
        isMulti: false,
      })
    );
  });

  it('denies updates and deletes', async () => {
    const db = memberCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('G1')
      .collection('machines')
      .doc('M1')
      .collection('attempts')
      .doc('attempt1');
    await assertFails(ref.update({ weight: 200 }));
    await assertFails(ref.delete());
  });
});
