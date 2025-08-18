const path = require('path');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../firestore.rules'),
  'utf8'
);
const storageRules = fs.readFileSync(
  path.resolve(__dirname, '../storage.rules'),
  'utf8'
);

describe('Security Rules v1', function () {
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
      storage: {
        rules: storageRules,
        host: '127.0.0.1',
        port: 9199,
      },
    });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('gyms').doc('G1').set({ code: 'G1', name: 'Gym 1' });
      await db.collection('gyms').doc('G2').set({ code: 'G2', name: 'Gym 2' });
      await db.collection('gyms').doc('G1').collection('devices').doc('D1').set({ id: 1 });
      await db.collection('gyms').doc('G2').collection('devices').doc('D2').set({ id: 1 });
      await db.collection('gyms').doc('G1').collection('users').doc('userA').set({ role: 'member' });
      await db.collection('gyms').doc('G1').collection('users').doc('adminA').set({ role: 'admin' });
      await db.collection('gyms').doc('G2').collection('users').doc('userB').set({ role: 'member' });
      await db.collection('gyms').doc('G1').collection('trainingPlans').doc('planA').set({ createdBy: 'userA' });
      await db.collection('gyms').doc('G2').collection('trainingPlans').doc('planB').set({ createdBy: 'userB' });
      await db.collection('gyms').doc('G1').collection('feedback').doc('fb1').set({ userId: 'userA', text: 'hi' });
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const userA = () => testEnv.authenticatedContext('userA', { gymId: 'G1', role: 'member' });
  const userB = () => testEnv.authenticatedContext('userB', { gymId: 'G2', role: 'member' });
  const admin = () => testEnv.authenticatedContext('adminA', { gymId: 'G1', role: 'admin' });
  const noMember = () => testEnv.authenticatedContext('noMember', {});

  describe('Firestore rules', () => {
    it('blocks cross-gym device read (device_cross_gym)', async () => {
      const db = userA().firestore();
      const ref = db.collection('gyms').doc('G2').collection('devices').doc('D2');
      await assertFails(ref.get());
    });

    it('allows device read in own gym', async () => {
      const db = userA().firestore();
      const ref = db.collection('gyms').doc('G1').collection('devices').doc('D1');
      await assertSucceeds(ref.get());
    });

    it('allows user to create own membership', async () => {
      const db = noMember().firestore();
      const ref = db.collection('gyms').doc('G1').collection('users').doc('noMember');
      await assertSucceeds(ref.set({ role: 'member' }));
    });

    it('blocks user from creating admin membership', async () => {
      const db = testEnv.authenticatedContext('rogueUser', {}).firestore();
      const ref = db.collection('gyms').doc('G1').collection('users').doc('rogueUser');
      await assertFails(ref.set({ role: 'admin' }));
    });

    it('allows admin membership write', async () => {
      const db = admin().firestore();
      const ref = db.collection('gyms').doc('G1').collection('users').doc('newUser');
      await assertSucceeds(ref.set({ role: 'member' }));
    });

    it('blocks role escalation (membership_role_escalation)', async () => {
      const db = userA().firestore();
      const ref = db.collection('gyms').doc('G1').collection('users').doc('userA');
      await assertFails(ref.update({ role: 'admin' }));
    });

    it('enforces gym scoping on training plans (training_plan_scoping)', async () => {
      const dbA = userA().firestore();
      const planRef = dbA.collection('gyms').doc('G1').collection('trainingPlans').doc('planA');
      await assertSucceeds(planRef.get());
      const foreignRef = dbA.collection('gyms').doc('G2').collection('trainingPlans').doc('planB');
      await assertFails(foreignRef.get());
      const writeRef = dbA.collection('gyms').doc('G1').collection('trainingPlans').doc('planA');
      await assertSucceeds(writeRef.set({ createdBy: 'userA' }));
      const otherWrite = dbA.collection('gyms').doc('G1').collection('trainingPlans').doc('planA');
      await assertFails(otherWrite.set({ createdBy: 'userB' }));
    });

    it('allows feedback creation and restricts reads (feedback_access)', async () => {
      const dbA = userA().firestore();
      const newFeedback = dbA.collection('gyms').doc('G1').collection('feedback').doc('fb2');
      await assertSucceeds(newFeedback.set({ userId: 'userA', text: 'ok' }));
      const dbB = userB().firestore();
      const readOther = dbB.collection('gyms').doc('G1').collection('feedback').doc('fb1');
      await assertFails(readOther.get());
      const dbAdmin = admin().firestore();
      await assertSucceeds(dbAdmin.collection('gyms').doc('G1').collection('feedback').doc('fb1').get());
    });
  });

  describe('Storage rules', () => {
    it('owner can upload and read own feedback image (storage_feedback_owner)', async () => {
      const storage = userA().storage();
      const file = storage.bucket().file('feedback/G1/userA/pic.png');
      await assertSucceeds(file.save(Buffer.from('123'), { contentType: 'image/png' }));
      await assertSucceeds(file.download());
    });

    it('admin can read member feedback image', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const storage = context.storage();
        await storage
          .bucket()
          .file('feedback/G1/userA/pic2.png')
          .save(Buffer.from('123'), { contentType: 'image/png' });
      });
      const adminStorage = admin().storage();
      await assertSucceeds(
        adminStorage.bucket().file('feedback/G1/userA/pic2.png').download()
      );
    });

    it('other gym member cannot read image', async () => {
      const storageB = userB().storage();
      await assertFails(
        storageB.bucket().file('feedback/G1/userA/pic2.png').download()
      );
    });

    it('listing is denied', async () => {
      const storageA = userA().storage();
      await assertFails(storageA.bucket().getFiles({ prefix: 'feedback/G1/userA' }));
    });

    it('blocks non-image uploads (storage_feedback_mime)', async () => {
      const storageA = userA().storage();
      const bad = storageA.bucket().file('feedback/G1/userA/file.txt');
      await assertFails(bad.save(Buffer.from('hi'), { contentType: 'text/plain' }));
    });
  });
});
