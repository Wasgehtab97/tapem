jest.mock('firebase-admin');
const admin = require('firebase-admin');

const { _private } = require('../reportAggregates');

describe('reportAggregates', () => {
  beforeEach(() => {
    admin.__resetFirestore();
  });

  it('aggregates device sessions and logs on create', async () => {
    const db = admin.firestore();
    const timestamp = admin.firestore.Timestamp.fromDate(new Date('2026-02-16T10:00:00.000Z'));

    await _private.handleLogCreate({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L1',
      sessionId: 'S1',
      timestamp,
    });

    await _private.handleLogCreate({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L2',
      sessionId: 'S1',
      timestamp,
    });

    const daySnap = await db
      .collection('gyms')
      .doc('G1')
      .collection('reportDaily')
      .doc('20260216')
      .get();

    expect(daySnap.exists).toBe(true);
    expect(daySnap.data()).toMatchObject({
      dayKey: '20260216',
      totalLogs: 2,
      totalSessions: 1,
      deviceLogCounts: { D1: 2 },
      deviceSessionCounts: { D1: 1 },
      hourBuckets: { '10': 2 },
    });
  });

  it('is idempotent for retried create events', async () => {
    const db = admin.firestore();
    const timestamp = admin.firestore.Timestamp.fromDate(new Date('2026-02-16T11:00:00.000Z'));

    const payload = {
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L1',
      sessionId: 'S1',
      timestamp,
    };

    await _private.handleLogCreate(payload);
    await _private.handleLogCreate(payload);

    const daySnap = await db
      .collection('gyms')
      .doc('G1')
      .collection('reportDaily')
      .doc('20260216')
      .get();

    expect(daySnap.data().totalLogs).toBe(1);
    expect(daySnap.data().totalSessions).toBe(1);
  });

  it('reverts aggregate counters on delete', async () => {
    const db = admin.firestore();
    const timestamp = admin.firestore.Timestamp.fromDate(new Date('2026-02-16T12:00:00.000Z'));

    await _private.handleLogCreate({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L1',
      sessionId: 'S1',
      timestamp,
    });
    await _private.handleLogCreate({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L2',
      sessionId: 'S1',
      timestamp,
    });

    await _private.handleLogDelete({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L1',
      sessionId: 'S1',
      timestamp,
    });

    let daySnap = await db
      .collection('gyms')
      .doc('G1')
      .collection('reportDaily')
      .doc('20260216')
      .get();
    expect(daySnap.data()).toMatchObject({
      totalLogs: 1,
      totalSessions: 1,
      deviceLogCounts: { D1: 1 },
      deviceSessionCounts: { D1: 1 },
      hourBuckets: { '12': 1 },
    });

    await _private.handleLogDelete({
      db,
      gymId: 'G1',
      deviceId: 'D1',
      logId: 'L2',
      sessionId: 'S1',
      timestamp,
    });

    daySnap = await db
      .collection('gyms')
      .doc('G1')
      .collection('reportDaily')
      .doc('20260216')
      .get();
    expect(daySnap.exists).toBe(false);
  });
});
