// firestore-tests/security_rules.test.js

const path = require('path');
const fs = require('fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');

// Lade Firestore-Sicherheitsregeln relativ zum Testverzeichnis
const rulesPath = path.resolve(__dirname, '../firestore.rules');
const rules = fs.readFileSync(rulesPath, 'utf8');

describe('Firestore Security Rules', function() {
  this.timeout(10000);

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
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it('erlaubt write im eigenen Gym', async () => {
    const authCtx = testEnv.authenticatedContext('user1', { gymId: 'gymA' });
    const db = authCtx.firestore();
    const ref = db
      .collection('gyms')
      .doc('gymA')
      .collection('config')
      .doc('cfg');

    await assertSucceeds(ref.set({ foo: 'bar' }));
  });

  it('blockt write im fremden Gym', async () => {
    const authCtx = testEnv.authenticatedContext('user2', { gymId: 'gymA' });
    const db = authCtx.firestore();
    const badRef = db
      .collection('gyms')
      .doc('gymB')
      .collection('config')
      .doc('cfg');

    await assertFails(badRef.set({ foo: 'bar' }));
  });

  it('erlaubt Anlage der eigenen Mitgliedschaft', async () => {
    const authCtx = testEnv.authenticatedContext('newUser', {});
    const db = authCtx.firestore();
    const ref = db
      .collection('gyms')
      .doc('gymA')
      .collection('users')
      .doc('newUser');

    await assertSucceeds(ref.set({ role: 'member' }));
  });

  it('blockt Anlage der Mitgliedschaft für fremden Nutzer', async () => {
    const authCtx = testEnv.authenticatedContext('hacker', {});
    const db = authCtx.firestore();
    const ref = db
      .collection('gyms')
      .doc('gymA')
      .collection('users')
      .doc('otherUser');

    await assertFails(ref.set({ role: 'member' }));
  });
});
