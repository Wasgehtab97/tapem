process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const fft = require('firebase-functions-test')({ projectId: 'demo-prs' });
const admin = require('firebase-admin');
const prs = require('../prs');
const xpEngine = require('../xp_engine');

describe('personal record detectors', () => {
  afterAll(() => {
    fft.cleanup();
  });

  afterEach(async () => {
    const db = admin.firestore();
    const gymsSnap = await db.collection('gyms').get();
    for (const gym of gymsSnap.docs) {
      const devicesSnap = await gym.ref.collection('devices').get();
      for (const device of devicesSnap.docs) {
        const logsSnap = await device.ref.collection('logs').get();
        for (const log of logsSnap.docs) {
          await log.ref.delete();
        }
        const sessionsSnap = await device.ref.collection('sessions').get();
        for (const sess of sessionsSnap.docs) {
          await sess.ref.delete();
        }
        await device.ref.delete();
      }
      const usersSnap = await gym.ref.collection('users').get();
      for (const user of usersSnap.docs) {
        await user.ref.delete();
      }
      await gym.ref.delete();
    }

    const usersSnap = await db.collection('users').get();
    for (const user of usersSnap.docs) {
      const sessionsSnap = await user.ref.collection('sessions').get();
      for (const sess of sessionsSnap.docs) {
        await sess.ref.delete();
      }
      const eventsSnap = await user.ref.collection('prEvents').get();
      for (const event of eventsSnap.docs) {
        await event.ref.delete();
      }
      await user.ref.delete();
    }
  });

  test('computeEpleyOneRepMax returns expected value', () => {
    const result = prs._test.computeEpleyOneRepMax(100, 5);
    expect(result).toBeCloseTo(116.67, 2);
    expect(prs._test.computeEpleyOneRepMax(-10, 5)).toBeNull();
    expect(prs._test.computeEpleyOneRepMax(80, 0)).toBeNull();
  });

  test('handleSessionClosed creates PR events and stays idempotent', async () => {
    const db = admin.firestore();
    const userId = 'user-1';
    const sessionId = 'session-1';
    const gymId = 'gym-1';
    const deviceId = 'dev-1';
    const exerciseId = 'bench';

    const sessionRef = db.collection('users').doc(userId).collection('sessions').doc(sessionId);
    await sessionRef.set({
      status: 'closed',
      gymId,
      startedAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T08:00:00Z')),
      endAt: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T09:00:00Z')),
      summary: {
        setCount: 1,
        exerciseCount: 1,
        totalVolume: 0,
        durationMin: 60,
      },
    });

    const eventsCol = db.collection('users').doc(userId).collection('prEvents');
    await eventsCol.doc('prior-e1rm').set({
      sessionId: 'session-0',
      occurredAt: admin.firestore.Timestamp.fromDate(new Date('2023-12-31T10:00:00Z')),
      type: 'e1rm',
      exerciseId,
      value: 110,
      confidence: 1,
      unit: 'kg',
    });
    await eventsCol.doc('prior-volume').set({
      sessionId: 'session-0',
      occurredAt: admin.firestore.Timestamp.fromDate(new Date('2023-12-31T10:00:00Z')),
      type: 'volume',
      exerciseId,
      value: 400,
      confidence: 1,
      unit: 'kg',
    });

    const logRef = db
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .doc(deviceId)
      .collection('logs')
      .doc('log-1');
    await logRef.set({
      userId,
      sessionId,
      deviceId,
      exerciseId,
      weight: 100,
      reps: 5,
      timestamp: admin.firestore.Timestamp.fromDate(new Date('2024-01-01T08:30:00Z')),
    });

    const result = await prs._test.handleSessionClosed({ userId, sessionId, gymId });
    expect(result.created).toBeGreaterThanOrEqual(4);
    expect(result.total).toBeGreaterThanOrEqual(4);
    expect(result.xp.totalXp).toBeGreaterThan(0);

    const sessionEventsSnap = await eventsCol.where('sessionId', '==', sessionId).get();
    expect(sessionEventsSnap.size).toBe(4);
    const types = sessionEventsSnap.docs.map((doc) => doc.data().type).sort();
    expect(types).toEqual(['e1rm', 'first_device', 'first_exercise', 'volume']);
    const e1rmEvent = sessionEventsSnap.docs.find((doc) => doc.data().type === 'e1rm');
    expect(e1rmEvent.data().value).toBeCloseTo(116.67, 2);
    expect(e1rmEvent.data().previousBest).toBeCloseTo(110, 2);
    expect(e1rmEvent.data().delta).toBeCloseTo(6.67, 2);

    const volumeEvent = sessionEventsSnap.docs.find((doc) => doc.data().type === 'volume');
    expect(volumeEvent.data().value).toBeCloseTo(500, 2);
    expect(volumeEvent.data().previousBest).toBeCloseTo(400, 2);
    expect(volumeEvent.data().delta).toBeCloseTo(100, 2);

    const sessionSnap = await sessionRef.get();
    expect(sessionSnap.data().summary.prCount).toBe(4);
    expect(sessionSnap.data().summary.prTypes).toEqual(['e1rm', 'first_device', 'first_exercise', 'volume']);
    expect(sessionSnap.data().summary.xpTotal).toBeCloseTo(result.xp.totalXp, 2);

    const expectedBase = xpEngine.computeSetXp({ weight: 100, reps: 5, rir: null, isBodyweight: false });
    const expectedBonus = 10 + 5 + 3 + 3;
    const dayRef = xpEngine._test.getDayRef({ db, userId, dayKey: '20240101' });
    const daySnap = await dayRef.get();
    expect(daySnap.exists).toBe(true);
    const dayData = daySnap.data();
    expect(dayData.sessions).toContain(sessionId);
    expect(dayData.total).toBeCloseTo(expectedBase + expectedBonus, 2);
    expect(dayData.byDevice.dev-1).toBeCloseTo(expectedBase + expectedBonus, 2);
    expect(dayData.byMuscle.pecs).toBeCloseTo((expectedBase + expectedBonus) / 2, 2);
    expect(dayData.byMuscle.triceps).toBeCloseTo((expectedBase + expectedBonus) / 2, 2);

    const rerun = await prs._test.handleSessionClosed({ userId, sessionId, gymId });
    expect(rerun.created).toBe(0);
    expect(rerun.total).toBe(4);
    expect(rerun.xp.awarded).toBe(false);
  });
});
