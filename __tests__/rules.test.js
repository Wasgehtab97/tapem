const { before, beforeEach, after, test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'tapem-firestore-rules-tests';
let testEnv;

const rulesPath = join(__dirname, '..', 'firestore.rules');

const authedDb = ({ uid, token } = {}) => {
  if (!uid) {
    return testEnv.unauthenticatedContext().firestore();
  }

  return testEnv.authenticatedContext(uid, token ?? {}).firestore();
};

const seed = async (populator) => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await populator(context.firestore());
  });
};

const trainingDailyDoc = (db) =>
  db
    .collection('trainingSummary')
    .doc('u_owner')
    .collection('daily')
    .doc('2024-10-10');

const trainingAggregateDoc = (db) =>
  db
    .collection('trainingSummary')
    .doc('u_owner')
    .collection('aggregate')
    .doc('overview');

const deviceUsageDoc = (db) =>
  db.collection('deviceUsageSummary').doc('g1').collection('devices').doc('d1');

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
    },
  });
});

beforeEach(async () => {
  assert.ok(testEnv, 'Test environment must be initialized before running tests.');

  await testEnv.clearFirestore();

  await seed(async (db) => {
    await db.collection('users').doc('u_owner').set({});
    await db.collection('users').doc('u_friend').set({});
    await db.collection('users').doc('u_friend_no').set({});
    await db.collection('users').doc('u_stranger').set({});
    await db.collection('users').doc('u_gadmin_global').set({});
    await db.collection('users').doc('u_gadmin').set({});

    await db
      .collection('users')
      .doc('u_owner')
      .collection('friends')
      .doc('u_friend')
      .set({ calendarVisibility: true });

    await db
      .collection('users')
      .doc('u_owner')
      .collection('friends')
      .doc('u_friend_no')
      .set({ calendarVisibility: false });

    await db.collection('gyms').doc('g1').collection('users').doc('u_gadmin').set({ role: 'admin' });
    await db.collection('gyms').doc('g1').collection('users').doc('u_friend').set({ role: 'member' });

    await trainingDailyDoc(db).set({
      userId: 'u_owner',
      dateKey: '2024-10-10',
      gymId: 'g1',
      logCount: 3,
      deviceCounts: {},
      sessionCounts: {},
    });

    await trainingAggregateDoc(db).set({
      trainingDayCount: 1,
      totalSessions: 1,
      deviceCounts: {},
      favoriteExercises: [],
      muscleGroups: [],
      gymId: 'g1',
    });

    await deviceUsageDoc(db).set({
      sessionCount: 5,
      rollingSessions: {
        last7Days: 2,
        all: 5,
      },
      recentDates: [],
    });
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

test('Owner can read training summary documents but cannot perform client writes', async () => {
  const ownerDb = authedDb({ uid: 'u_owner' });

  await assertSucceeds(trainingDailyDoc(ownerDb).get());
  await assertSucceeds(trainingAggregateDoc(ownerDb).get());

  await assertFails(
    trainingDailyDoc(ownerDb).set({
      userId: 'u_owner',
      dateKey: '2024-10-10',
      gymId: 'g1',
    })
  );
  await assertFails(trainingDailyDoc(ownerDb).update({ logCount: 4 }));
  await assertFails(trainingDailyDoc(ownerDb).delete());
  await assertFails(
    trainingAggregateDoc(ownerDb).set({
      trainingDayCount: 2,
      totalSessions: 2,
      deviceCounts: {},
      favoriteExercises: [],
      muscleGroups: [],
      gymId: 'g1',
    })
  );
  await assertFails(trainingAggregateDoc(ownerDb).update({ totalSessions: 2 }));
  await assertFails(trainingAggregateDoc(ownerDb).delete());
});

test('Strangers cannot read training summary documents', async () => {
  const strangerDb = authedDb({ uid: 'u_stranger' });

  await assertFails(trainingDailyDoc(strangerDb).get());
  await assertFails(trainingAggregateDoc(strangerDb).get());
});

test('Friends require calendar visibility to read training summary documents', async () => {
  const visibleFriendDb = authedDb({ uid: 'u_friend' });
  const hiddenFriendDb = authedDb({ uid: 'u_friend_no' });

  await assertSucceeds(trainingDailyDoc(visibleFriendDb).get());
  await assertSucceeds(trainingAggregateDoc(visibleFriendDb).get());

  await assertFails(trainingDailyDoc(hiddenFriendDb).get());
  await assertFails(trainingAggregateDoc(hiddenFriendDb).get());
});

test('Gym admins of the same gym can read training summary documents', async () => {
  const gymAdminDb = authedDb({ uid: 'u_gadmin' });

  await assertSucceeds(trainingDailyDoc(gymAdminDb).get());
  await assertSucceeds(trainingAggregateDoc(gymAdminDb).get());
});

test('Global admins can read training summary documents but cannot write', async () => {
  const globalAdminDb = authedDb({ uid: 'u_gadmin_global', token: { admin: true } });

  await assertSucceeds(trainingDailyDoc(globalAdminDb).get());
  await assertSucceeds(trainingAggregateDoc(globalAdminDb).get());

  await assertFails(trainingDailyDoc(globalAdminDb).set({ gymId: 'g1' }));
  await assertFails(trainingDailyDoc(globalAdminDb).update({ logCount: 6 }));
  await assertFails(trainingDailyDoc(globalAdminDb).delete());
  await assertFails(
    trainingAggregateDoc(globalAdminDb).set({
      trainingDayCount: 1,
      totalSessions: 3,
      deviceCounts: {},
      favoriteExercises: [],
      muscleGroups: [],
      gymId: 'g1',
    })
  );
  await assertFails(trainingAggregateDoc(globalAdminDb).update({ totalSessions: 3 }));
  await assertFails(trainingAggregateDoc(globalAdminDb).delete());
});

test('Gym admins can read device usage summaries', async () => {
  const gymAdminDb = authedDb({ uid: 'u_gadmin' });

  await assertSucceeds(deviceUsageDoc(gymAdminDb).get());
});

test('Non-admins cannot read device usage summaries', async () => {
  const memberDb = authedDb({ uid: 'u_friend' });
  const strangerDb = authedDb({ uid: 'u_stranger' });

  await assertFails(deviceUsageDoc(memberDb).get());
  await assertFails(deviceUsageDoc(strangerDb).get());
});

test('Global admins can read device usage summaries but not write', async () => {
  const globalAdminDb = authedDb({ uid: 'u_gadmin_global', token: { admin: true } });

  await assertSucceeds(deviceUsageDoc(globalAdminDb).get());
  await assertFails(deviceUsageDoc(globalAdminDb).set({ sessionCount: 10 }));
  await assertFails(deviceUsageDoc(globalAdminDb).update({ 'rollingSessions.all': 10 }));
  await assertFails(deviceUsageDoc(globalAdminDb).delete());
});

test('Client writes to device usage summaries are blocked', async () => {
  const ownerDb = authedDb({ uid: 'u_owner' });

  await assertFails(
    deviceUsageDoc(ownerDb).set({
      sessionCount: 10,
      rollingSessions: { last7Days: 5, all: 10 },
      recentDates: [],
    })
  );
  await assertFails(deviceUsageDoc(ownerDb).update({ sessionCount: 99 }));
  await assertFails(deviceUsageDoc(ownerDb).delete());
});
