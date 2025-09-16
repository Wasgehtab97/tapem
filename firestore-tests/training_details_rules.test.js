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
        .collection('users')
        .doc('owner')
        .set({ role: 'member' });
      await db
        .collection('gyms')
        .doc(gym)
        .collection('users')
        .doc('friend')
        .set({ role: 'member' });
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
  const ownerCtx = () => testEnv.authenticatedContext('owner');

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

  it('allows owner to delete own log entry', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('logs')
        .doc('log1')
        .set({
          userId: 'owner',
          sessionId: 's1',
          timestamp: new Date(),
        });
    });

    const db = ownerCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('logs')
      .doc('log1');
    await assertSucceeds(ref.delete());
  });

  it('denies friend from deleting owners log entry', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('logs')
        .doc('log1')
        .set({
          userId: 'owner',
          sessionId: 's1',
          timestamp: new Date(),
        });
    });

    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('logs')
      .doc('log1');
    await assertFails(ref.delete());
  });

  it('allows owner to delete fallback log entry', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('legacyDevices')
        .doc('dev1')
        .collection('logs')
        .doc('log1')
        .set({
          userId: 'owner',
          sessionId: 'legacySession',
          timestamp: new Date(),
        });
    });

    const db = ownerCtx().firestore();
    const ref = db
      .collection('legacyDevices')
      .doc('dev1')
      .collection('logs')
      .doc('log1');
    await assertSucceeds(ref.delete());
  });

  it('denies friend from deleting fallback log entry', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('legacyDevices')
        .doc('dev1')
        .collection('logs')
        .doc('log1')
        .set({
          userId: 'owner',
          sessionId: 'legacySession',
          timestamp: new Date(),
        });
    });

    const db = friendCtx().firestore();
    const ref = db
      .collection('legacyDevices')
      .doc('dev1')
      .collection('logs')
      .doc('log1');
    await assertFails(ref.delete());
  });

  it('allows owner to delete own session snapshot', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('sessions')
        .doc('s1')
        .set({ userId: 'owner' });
    });

    const db = ownerCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('sessions')
      .doc('s1');
    await assertSucceeds(ref.delete());
  });

  it('denies friend from deleting owners session snapshot', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('sessions')
        .doc('s1')
        .set({ userId: 'owner' });
    });

    const db = friendCtx().firestore();
    const ref = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('sessions')
      .doc('s1');
    await assertFails(ref.delete());
  });

  it('allows owner to delete leaderboard markers', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const base = db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('leaderboard')
        .doc('owner');
      await base.set({ userId: 'owner', xp: 10, level: 1 });
      await base.collection('sessions').doc('s1').set({ createdAt: new Date() });
      await base.collection('days').doc('2025-09-16').set({ sessionCount: 1 });
      await base
        .collection('exercises')
        .doc('ex1-2025-09-16')
        .set({ sessionId: 's1' });
    });

    const db = ownerCtx().firestore();
    const base = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('leaderboard')
      .doc('owner');
    await assertSucceeds(base.collection('sessions').doc('s1').delete());
    await assertSucceeds(base.collection('days').doc('2025-09-16').delete());
    await assertSucceeds(base.collection('exercises').doc('ex1-2025-09-16').delete());
  });

  it('denies friend from deleting owners leaderboard markers', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const base = db
        .collection('gyms')
        .doc('Club Aktiv')
        .collection('devices')
        .doc('dev1')
        .collection('leaderboard')
        .doc('owner');
      await base.set({ userId: 'owner', xp: 10, level: 1 });
      await base.collection('sessions').doc('s1').set({ createdAt: new Date() });
      await base.collection('days').doc('2025-09-16').set({ sessionCount: 1 });
      await base
        .collection('exercises')
        .doc('ex1-2025-09-16')
        .set({ sessionId: 's1' });
    });

    const db = friendCtx().firestore();
    const base = db
      .collection('gyms')
      .doc('Club Aktiv')
      .collection('devices')
      .doc('dev1')
      .collection('leaderboard')
      .doc('owner');
    await assertFails(base.collection('sessions').doc('s1').delete());
    await assertFails(base.collection('days').doc('2025-09-16').delete());
    await assertFails(base.collection('exercises').doc('ex1-2025-09-16').delete());
  });
});
