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

      // Friends feature setup
      await db.collection('users').doc('user1').set({ calendarVisibility: 'friends', gymCodes: ['G1'] });
      await db.collection('users').doc('user2').set({ calendarVisibility: 'friends', gymCodes: ['G1'] });
      await db.collection('users').doc('user3').set({ calendarVisibility: 'friends', gymCodes: ['G2'] });
      await db.collection('users').doc('user4').set({ calendarVisibility: 'friends', gymCodes: ['G1'] });
      await db
        .collection('users')
        .doc('user2')
        .collection('friendRequests')
        .doc('user1_user2')
        .set({ fromUserId: 'user1', toUserId: 'user2', status: 'pending' });
      await db.collection('users').doc('user1').collection('friends').doc('user2').set({});
      await db.collection('users').doc('user2').collection('friends').doc('user1').set({});
      await db.collection('users').doc('user1').collection('publicCalendar').doc('2024-01').set({ month: '2024-01' });
      await db
        .collection('gyms')
        .doc('G1')
        .collection('users')
        .doc('user4')
        .set({ role: 'member' });
      await db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('exercises')
        .doc('ex1')
        .set({ userId: 'user1' });
      await db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('exercises')
        .doc('exFriend')
        .set({ userId: 'user1' });
      await db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('exercises')
        .doc('exNF')
        .set({ userId: 'user3' });
      await db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('exercises')
        .doc('exPublic')
        .set({ name: 'public' });
      await db
        .collection('gyms')
        .doc('G2')
        .collection('users')
        .doc('adminB')
        .set({ role: 'admin' });
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const userA = () => testEnv.authenticatedContext('userA', { gymId: 'G1', role: 'member' });
  const userB = () => testEnv.authenticatedContext('userB', { gymId: 'G2', role: 'member' });
  const admin = () => testEnv.authenticatedContext('adminA', { gymId: 'G1', role: 'admin' });
  const noMember = () => testEnv.authenticatedContext('noMember', {});
  const p1 = () => testEnv.authenticatedContext('user1', {});
  const p2 = () => testEnv.authenticatedContext('user2', {});
  const p3 = () => testEnv.authenticatedContext('user3', {});
  const friend = () => testEnv.authenticatedContext('user2', { gymId: 'G1', role: 'member' });
  const stranger = () => testEnv.authenticatedContext('user4', { gymId: 'G1', role: 'member' });
  const adminB = () => testEnv.authenticatedContext('adminB', { gymId: 'G2', role: 'admin' });

  describe('Firestore rules', () => {
    it('allows cross-gym device read when authenticated', async () => {
      const db = userA().firestore();
      const ref = db.collection('gyms').doc('G2').collection('devices').doc('D2');
      await assertSucceeds(ref.get());
    });

    it('blocks device read when unauthenticated', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      const ref = db.collection('gyms').doc('G1').collection('devices').doc('D1');
      await assertFails(ref.get());
    });

    it('allows device read in own gym', async () => {
      const db = userA().firestore();
      const ref = db.collection('gyms').doc('G1').collection('devices').doc('D1');
      await assertSucceeds(ref.get());
    });

    it('allows cross-gym friend to read custom exercise', async () => {
      const db = friend().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('exercises')
        .doc('exFriend');
      await assertSucceeds(ref.get());
    });

    it('blocks non-friend cross-gym from reading custom exercise', async () => {
      const db = stranger().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('exercises')
        .doc('exNF');
      await assertFails(ref.get());
    });

    it('allows admin to read custom exercise', async () => {
      const db = adminB().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('exercises')
        .doc('exFriend');
      await assertSucceeds(ref.get());
    });

    it('allows public exercise read in same gym', async () => {
      const db = stranger().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('exercises')
        .doc('exPublic');
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

    it('allows reading public profiles when authenticated', async () => {
      const db = p1().firestore();
      await assertSucceeds(db.collection('publicProfiles').doc('user2').get());
    });

    it('allows owner to write public profile and forbids others', async () => {
      const ownerDb = p1().firestore();
      const ref = ownerDb.collection('publicProfiles').doc('user1');
      await assertSucceeds(
        ref.set({
          username: 'Alice',
          usernameLower: 'alice',
          createdAt: new Date(),
        }),
      );
      const otherDb = p2().firestore();
      await assertFails(
        otherDb.collection('publicProfiles').doc('user1').set({
          username: 'Bob',
          usernameLower: 'bob',
          createdAt: new Date(),
        }),
      );
    });

    it('enforces public profile field constraints', async () => {
      const db = p1().firestore();
      const ref = db.collection('publicProfiles').doc('user1');
      await assertSucceeds(
        ref.set({
          username: 'Alice',
          usernameLower: 'alice',
          createdAt: new Date(),
        }),
      );
      await assertFails(
        ref.set({
          usernameLower: 'alice2',
          createdAt: new Date(Date.now() + 1000),
        }, { merge: true }),
      );
      await assertFails(
        ref.set({
          username: 'Alice',
          usernameLower: 'alice',
          createdAt: new Date(),
          foo: 'bar',
        }),
      );
    });

    it('enforces friend request rules', async () => {
      const dbRecipient = p2().firestore();
      await assertSucceeds(dbRecipient.collection('users').doc('user2').collection('friendRequests').doc('user1_user2').get());
      const dbSender = p1().firestore();
      await assertSucceeds(dbSender.collection('users').doc('user2').collection('friendRequests').doc('user1_user2').get());
      const dbOther = p3().firestore();
      await assertFails(dbOther.collection('users').doc('user2').collection('friendRequests').doc('user1_user2').get());
      await assertFails(dbRecipient.collection('users').doc('user2').collection('friendRequests').doc('x').set({}));
    });

    it('restricts friends list to owner', async () => {
      const dbOwner = p1().firestore();
      await assertSucceeds(dbOwner.collection('users').doc('user1').collection('friends').doc('user2').get());
      const dbFriend = p2().firestore();
      await assertFails(dbFriend.collection('users').doc('user1').collection('friends').doc('user2').get());
    });

    it('enforces public calendar visibility', async () => {
      const ownerDb = p1().firestore();
      await assertSucceeds(ownerDb.collection('users').doc('user1').collection('publicCalendar').doc('2024-01').get());
      const friendDb = p2().firestore();
      await assertSucceeds(friendDb.collection('users').doc('user1').collection('publicCalendar').doc('2024-01').get());
      const otherDb = p3().firestore();
      await assertFails(otherDb.collection('users').doc('user1').collection('publicCalendar').doc('2024-01').get());
    });

    it('enforces username mapping rules', async () => {
      const db1 = p1().firestore();
      await assertSucceeds(
        db1.collection('usernames').doc('alice').set({ uid: 'user1', createdAt: new Date() })
      );
      await assertSucceeds(
        db1
          .collection('usernames')
          .doc('alice')
          .set({ createdAt: new Date(Date.now() + 1000) }, { merge: true })
      );
      await assertFails(
        db1
          .collection('usernames')
          .doc('alice')
          .set({ uid: 'user2' }, { merge: true })
      );
      const db2 = p2().firestore();
      await assertFails(
        db2.collection('usernames').doc('alice').set({ uid: 'user2', createdAt: new Date() })
      );
      await assertFails(
        db2
          .collection('usernames')
          .doc('alice')
          .set({ createdAt: new Date() }, { merge: true })
      );
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx.firestore().collection('usernames').doc('bob').set({ uid: 'user2' });
      });
      await assertSucceeds(db2.collection('usernames').doc('bob').delete());
      await assertFails(db1.collection('usernames').doc('bob').delete());
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
