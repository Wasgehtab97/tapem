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
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('sFriend')
        .set({ userId: 'user1' });
      await db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('sNF')
        .set({ userId: 'user3' });
      await db
        .collection('gyms')
        .doc('G2')
        .collection('users')
        .doc('adminB')
        .set({ role: 'admin' });
      await db.collection('users').doc('userA').set({});
      await db.collection('users').doc('userB').set({});
      await db.collection('publicProfiles').doc('userA').set({ username: 'Alice' });
      await db.collection('publicProfiles').doc('userB').set({ username: 'Bob' });
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

    it('allows cross-gym friend to read session snapshot', async () => {
      const db = friend().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('sFriend');
      await assertSucceeds(ref.get());
    });

    it('blocks non-friend cross-gym from reading session snapshot', async () => {
      const db = stranger().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('sNF');
      await assertFails(ref.get());
    });

    it('allows admin to read session snapshot', async () => {
      const db = adminB().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('sFriend');
      await assertSucceeds(ref.get());
    });

    it('allows member to write own session snapshot', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('sessions')
        .doc('newSession');
      await assertSucceeds(
        ref.set({
          sessionId: 'newSession',
          deviceId: 'D1',
          createdAt: FieldValue.serverTimestamp(),
          userId: 'userA',
          note: null,
          sets: [],
          renderVersion: 1,
          uiHints: { plannedTableCollapsed: false },
          isCardio: false,
        }),
      );
    });

    it('denies friend from writing session snapshot', async () => {
      const db = friend().firestore();
      const ref = db
        .collection('gyms')
        .doc('G2')
        .collection('devices')
        .doc('D2')
        .collection('sessions')
        .doc('newSession');
      await assertFails(ref.set({ userId: 'user2' }));
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

    it('allows owner to update own usernameLower', async () => {
      const db = userA().firestore();
      const ref = db.collection('publicProfiles').doc('userA');
      await assertSucceeds(ref.set({ usernameLower: 'alice' }, { merge: true }));
    });

    it('allows gym admin to backfill usernameLower', async () => {
      const db = admin().firestore();
      const ref = db.collection('publicProfiles').doc('userA');
      await assertSucceeds(ref.set({ usernameLower: 'alice' }, { merge: true }));
    });

    it('forbids admin to write usernameLower of non-member', async () => {
      const db = admin().firestore();
      const ref = db.collection('publicProfiles').doc('userB');
      await assertFails(ref.set({ usernameLower: 'bob' }, { merge: true }));
    });

    it('forbids non-admin to write usernameLower of others', async () => {
      const db = userA().firestore();
      const ref = db.collection('publicProfiles').doc('userB');
      await assertFails(ref.set({ usernameLower: 'bob' }, { merge: true }));
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

  describe('avatarInventory rules', () => {
    it('user can read own inventory and write', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection('users')
          .doc('userA')
          .collection('avatarInventory')
          .doc('default')
          .set({
            key: 'global/default',
            createdAt: new Date(),
            source: 'admin/manual',
          });
      });
      const db = userA().firestore();
      await assertSucceeds(
        db.collection('users').doc('userA').collection('avatarInventory').get()
      );
      await assertSucceeds(
        db
          .collection('users')
          .doc('userA')
          .collection('avatarInventory')
          .doc('default2')
          .set({
            key: 'global/default2',
            createdAt: FieldValue.serverTimestamp(),
            source: 'user/self',
          })
      );
    });

    it('admin can manage inventory of gym member', async () => {
      const db = admin().firestore();
      await assertSucceeds(
        db
          .collection('users')
          .doc('userA')
          .collection('avatarInventory')
          .doc('kurzhantel')
          .set({
            key: 'G1/kurzhantel',
            source: 'admin/manual',
            createdAt: FieldValue.serverTimestamp(),
            gymId: 'G1',
          })
      );
    });

    it('admin cannot manage non-member inventory', async () => {
      const db = admin().firestore();
      await assertFails(
        db
          .collection('users')
          .doc('userB')
          .collection('avatarInventory')
          .doc('kurzhantel')
          .set({
            key: 'G1/kurzhantel',
            source: 'admin/manual',
            createdAt: FieldValue.serverTimestamp(),
            gymId: 'G1',
          })
      );
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

  describe('avatar inventory', () => {
    before(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db
          .collection('users')
          .doc('userA')
          .collection('avatarInventory')
          .doc('a1')
          .set({
            key: 'global/default',
            createdAt: new Date(),
            source: 'admin/manual',
            createdBy: 'seed',
            gymId: 'G1',
          });
      });
    });

    it('owner can list own inventory', async () => {
      const db = userA().firestore();
      const ref = db.collection('users').doc('userA').collection('avatarInventory');
      await assertSucceeds(ref.get());
    });

    it('gym admin can read member inventory', async () => {
      const db = admin().firestore();
      const ref = db.collection('users').doc('userA').collection('avatarInventory');
      await assertSucceeds(ref.get());
    });

    it('gym admin can write with allowed fields and source', async () => {
      const db = admin().firestore();
      const ref = db
        .collection('users')
        .doc('userA')
        .collection('avatarInventory')
        .doc('a2');
      await assertSucceeds(
        ref.set({
          key: 'G1/new',
          createdAt: new Date(),
          createdBy: 'adminA',
          source: 'admin/manual',
          gymId: 'G1',
        })
      );
    });

    it('gym admin write fails with extra field', async () => {
      const db = admin().firestore();
      const ref = db
        .collection('users')
        .doc('userA')
        .collection('avatarInventory')
        .doc('a3');
      await assertFails(
        ref.set({
          key: 'G1/new2',
          createdAt: new Date(),
          createdBy: 'adminA',
          source: 'admin/manual',
          gymId: 'G1',
          bad: true,
        })
      );
    });

    it('gym admin write fails with wrong source', async () => {
      const db = admin().firestore();
      const ref = db
        .collection('users')
        .doc('userA')
        .collection('avatarInventory')
        .doc('a4');
      await assertFails(
        ref.set({
          key: 'G2/new',
          createdAt: new Date(),
          createdBy: 'adminA',
          source: 'admin/manual',
          gymId: 'G2',
        })
      );
    });

    it('non-admin cannot read others inventory', async () => {
      const db = userB().firestore();
      const ref = db.collection('users').doc('userA').collection('avatarInventory');
      await assertFails(ref.get());
    });
  });

  describe('public profiles updates', () => {
    it('owner can update avatarKey', async () => {
      const db = userA().firestore();
      const ref = db.collection('publicProfiles').doc('userA');
      await assertSucceeds(ref.update({ avatarKey: 'k1' }));
    });

    it('owner or admin can update usernameLower', async () => {
      const refOwner = userA().firestore().collection('publicProfiles').doc('userA');
      await assertSucceeds(refOwner.update({ usernameLower: 'alice' }));
      const refAdmin = admin().firestore().collection('publicProfiles').doc('userA');
      await assertSucceeds(refAdmin.update({ usernameLower: 'alice' }));
    });

    it('non-owner cannot update other fields', async () => {
      const db = userB().firestore();
      const ref = db.collection('publicProfiles').doc('userA');
      await assertFails(ref.update({ username: 'bad' }));
    });
  });

  describe('leaderboard rules', () => {
    it('member can create and update own leaderboard entry', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('leaderboard')
        .doc('userA');
      await assertSucceeds(
        ref.set({ userId: 'userA', xp: 0, level: 1, showInLeaderboard: true })
      );
      await assertSucceeds(ref.update({ xp: 10 }));
    });

    it('fails without userId field', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('leaderboard')
        .doc('userA');
      await assertFails(ref.set({ xp: 0 }));
    });

    it('update denied when existing doc missing userId', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db
          .collection('gyms')
          .doc('G1')
          .collection('devices')
          .doc('D1')
          .collection('leaderboard')
          .doc('userA')
          .set({ xp: 0 });
      });
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('leaderboard')
        .doc('userA');
      await assertFails(ref.update({ xp: 5 }));
    });

    it('member can create leaderboard doc with day and session markers in one tx', async () => {
      const db = userA().firestore();
      await assertSucceeds(
        db.runTransaction(async (tx) => {
          const lbUser = db
            .collection('gyms')
            .doc('G1')
            .collection('devices')
            .doc('D1')
            .collection('leaderboard')
            .doc('userA');
          tx.set(lbUser, {
            userId: 'userA',
            xp: 0,
            level: 1,
            showInLeaderboard: true,
          });
          tx.set(lbUser.collection('days').doc('2024-01-01'), {
            creditedAt: FieldValue.serverTimestamp(),
          });
          tx.set(lbUser.collection('sessions').doc('s1'), {
            sessionId: 's1',
            creditedAt: FieldValue.serverTimestamp(),
          });
        })
      );
    });

    it('member cannot write other users leaderboard entry', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('leaderboard')
        .doc('userB');
      await assertFails(
        ref.set({ userId: 'userB', xp: 0, level: 1, showInLeaderboard: true })
      );
    });

    it('non-member cannot write leaderboard entry', async () => {
      const db = userB().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('leaderboard')
        .doc('userB');
      await assertFails(
        ref.set({ userId: 'userB', xp: 0, level: 1, showInLeaderboard: true })
      );
    });

    it('allows cardio log without durationSec', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('logs')
        .doc('l1');
      await assertSucceeds(
        ref.set({
          deviceId: 'D1',
          userId: 'userA',
          exerciseId: 'ex1',
          sessionId: 's1',
          timestamp: FieldValue.serverTimestamp(),
          setNumber: 1,
          note: '',
          tz: 'UTC',
          speedKmH: 10,
        })
      );
    });

    it('allows cardio log with durationSec', async () => {
      const db = userA().firestore();
      const ref = db
        .collection('gyms')
        .doc('G1')
        .collection('devices')
        .doc('D1')
        .collection('logs')
        .doc('l2');
      await assertSucceeds(
        ref.set({
          deviceId: 'D1',
          userId: 'userA',
          exerciseId: 'ex1',
          sessionId: 's1',
          timestamp: FieldValue.serverTimestamp(),
          setNumber: 1,
          note: '',
          tz: 'UTC',
          speedKmH: 10,
          durationSec: 5,
        })
      );
    });
  });
});
