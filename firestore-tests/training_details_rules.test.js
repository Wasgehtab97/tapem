const path = require('path');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const rules = fs.readFileSync(
  path.resolve(__dirname, '../firestore.rules'),
  'utf8'
);

describe('Training details rules', () => {
  let testEnv;
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'tap-em',
      firestore: {
        rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const gym = 'Club Aktiv';
      await db.collection('gyms').doc(gym).set({});
      await db.collection('gyms').doc(gym).collection('devices').doc('dev1').set({});
      await db
        .collection('gyms')
        .doc(gym)
        .collection('devices')
        .doc('dev1')
        .collection('exercises')
        .doc('ex1')
        .set({ userId: 'owner' });
      await db
        .collection('gyms')
        .doc(gym)
        .collection('devices')
        .doc('dev1')
        .collection('sessions')
        .doc('s1')
        .set({ userId: 'owner' });
      await db.collection('users').doc('owner').set({});
      await db.collection('users').doc('friend').set({});
      await db.collection('users').doc('owner').collection('friends').doc('friend').set({});
      await db.collection('users').doc('friend').collection('friends').doc('owner').set({});
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const friendCtx = () => testEnv.authenticatedContext('friend');
  const strangerCtx = () => testEnv.authenticatedContext('stranger');

  it('allows friend to read device', async () => {
    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1');
    await assertSucceeds(ref.get());
  });

  it('denies unauthenticated device read', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1');
    await assertFails(ref.get());
  });

  it('allows friend to read exercise', async () => {
    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('exercises')
      .doc('ex1');
    await assertSucceeds(ref.get());
  });

  it('allows friend to read session', async () => {
    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('sessions')
      .doc('s1');
    await assertSucceeds(ref.get());
  });

  it('denies non-friend exercise read', async () => {
    const db = strangerCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('exercises')
      .doc('ex1');
    await assertFails(ref.get());
  });

  it('denies friend from writing session', async () => {
    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('sessions')
      .doc('newSession');
    await assertFails(ref.set({ userId: 'friend' }));
  });
});
