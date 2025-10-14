process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

jest.mock('firebase-functions', () => {
  const actual = jest.requireActual('firebase-functions');
  return {
    ...actual,
    pubsub: {
      ...actual.pubsub,
      topic: jest.fn(() => ({
        publishMessage: jest.fn().mockResolvedValue(null),
      })),
    },
  };
});

const fft = require('firebase-functions-test')({ projectId: 'demo-sessions' });
const admin = require('firebase-admin');
const myFuncs = require('..');
const sessions = require('../sessions');

describe('session helpers', () => {

  test('resolveEndAt clamps to now', () => {
    const now = new Date('2024-01-01T10:00:00Z');
    const last = new Date('2024-01-01T11:30:00Z');
    const result = sessions._test.resolveEndAt(last, now);
    expect(result.toISOString()).toBe(now.toISOString());
  });

  test('closeSessionDocument normalizes summary', async () => {
    const ref = admin.firestore().collection('users').doc('u1').collection('sessions').doc('s1');
    await ref.set({
      status: 'open',
      startedAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T08:00:00Z')),
      lastActivityAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T09:00:00Z')),
      summary: { setCount: 3, exerciseCount: 1, totalVolume: 150 },
    });

    const now = new Date('2024-01-01T10:30:00Z');
    const result = await sessions._test.closeSessionDocument(ref, {
      startedAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T08:00:00Z')),
      lastActivityAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T09:00:00Z')),
      summary: { setCount: 3, exerciseCount: 1, totalVolume: 150 },
    }, { now });

    expect(result.summary.durationMin).toBeCloseTo(90, 5);
    const doc = await ref.get();
    expect(doc.data().status).toBe('closed');
    expect(doc.data().summary.setCount).toBe(3);
    expect(doc.data().summary.prCount).toBe(0);
    expect(doc.data().summary.prTypes).toEqual([]);
  });
});

describe('session lifecycle functions', () => {
  afterEach(async () => {
    const users = await admin.firestore().collection('users').get();
    for (const user of users.docs) {
      const sessionsSnap = await user.ref.collection('sessions').get();
      for (const doc of sessionsSnap.docs) {
        await doc.ref.delete();
      }
      await user.ref.delete();
    }
  });

  afterAll(() => {
    fft.cleanup();
  });

  test('closeIdleSessions closes stale docs', async () => {
    const ref = admin.firestore().collection('users').doc('userA').collection('sessions').doc('sess1');
    await ref.set({
      status: 'open',
      gymId: 'gym1',
      startedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 3600000)),
      lastActivityAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 2 * 3600000)),
      summary: { setCount: 2, exerciseCount: 1, totalVolume: 80 },
    });

    const wrapped = fft.wrap(myFuncs.closeIdleSessions);
    await wrapped();

    const doc = await ref.get();
    expect(doc.data().status).toBe('closed');
    const endAt = doc.data().endAt.toDate();
    const expected = new Date(doc.data().lastActivityAt.toDate().getTime() + 60 * 60000);
    expect(Math.abs(endAt.getTime() - expected.getTime())).toBeLessThan(60000);
  });

  test('backfillSessions dry run reports count', async () => {
    await admin.firestore().collection('users').doc('userB').collection('sessions').doc('sess2').set({
      status: 'open',
      startedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 4 * 3600000)),
      lastActivityAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 3600000)),
    });

    const wrapped = fft.wrap(myFuncs.backfillSessions);
    const res = await wrapped({ dryRun: true }, { auth: { token: { admin: true } } });
    expect(res).toEqual({ processed: 1, closed: 0, dryRun: true });
  });
});
