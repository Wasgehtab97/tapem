const admin = require('firebase-admin');
const fft = require('firebase-functions-test')({ projectId: 'demo-xp-engine' });

const xpEngine = require('../xp_engine');

describe('xp engine computations', () => {
  afterAll(() => {
    fft.cleanup();
  });

  test('computeSetXp scales with load, reps, and rir', () => {
    const heavy = xpEngine.computeSetXp({ weight: 100, reps: 5, rir: 2, isBodyweight: false });
    const light = xpEngine.computeSetXp({ weight: 40, reps: 5, rir: 4, isBodyweight: false });
    const bodyweight = xpEngine.computeSetXp({ weight: 0, reps: 12, rir: null, isBodyweight: true });

    expect(heavy).toBeGreaterThan(light);
    expect(bodyweight).toBeGreaterThan(0);
    expect(xpEngine.computeSetXp({ weight: 100, reps: 0 })).toBe(0);
  });

  test('computeSessionXp aggregates devices, muscles, and bonuses', () => {
    const set1 = xpEngine.computeSetXp({ weight: 100, reps: 5, rir: null, isBodyweight: false });
    const set2 = xpEngine.computeSetXp({ weight: 80, reps: 8, rir: null, isBodyweight: false });
    const logs = [
      { data: () => ({ deviceId: 'dev1', exerciseId: 'bench_press', weight: 100, reps: 5 }) },
      { data: () => ({ deviceId: 'dev1', exerciseId: 'bench_press', drops: [{ weight: 80, reps: 8 }], reps: 0 }) },
    ];
    const prEvents = [
      { type: 'e1rm', exerciseId: 'bench_press' },
    ];
    const xp = xpEngine.computeSessionXp({ logs, prEvents });

    expect(xp.baseXp).toBe(set1 + set2);
    expect(xp.bonusXp).toBe(10);
    expect(xp.totalXp).toBe(set1 + set2 + 10);
    expect(xp.perDevice.get('dev1')).toBe(set1 + set2 + 10);
    const pecs = xp.perMuscle.get('pecs');
    const triceps = xp.perMuscle.get('triceps');
    expect(pecs).toBeCloseTo((set1 + set2 + 10) / 2, 2);
    expect(triceps).toBeCloseTo((set1 + set2 + 10) / 2, 2);
  });

  test('awardSessionXp writes idempotent daily aggregates', async () => {
    const db = admin.firestore();
    const userId = 'user-xp';
    const sessionId = 'session-xp';
    const sessionRef = db.collection('users').doc(userId).collection('sessions').doc(sessionId);
    const endAt = admin.firestore.Timestamp.fromDate(new Date('2024-01-02T10:00:00Z'));
    await sessionRef.set({ endAt, status: 'closed' });
    const log = {
      data: () => ({ deviceId: 'dev-42', exerciseId: 'bench_press', weight: 60, reps: 10 }),
    };
    const prEvents = [{ type: 'first_exercise', exerciseId: 'bench_press' }];

    const result1 = await xpEngine.awardSessionXp({
      db,
      userId,
      sessionId,
      sessionRef,
      sessionData: { endAt },
      logs: [log],
      prEvents,
    });
    expect(result1.totalXp).toBeGreaterThan(0);
    expect(result1.awarded).toBe(true);

    const result2 = await xpEngine.awardSessionXp({
      db,
      userId,
      sessionId,
      sessionRef,
      sessionData: { endAt },
      logs: [log],
      prEvents,
    });
    expect(result2.awarded).toBe(false);

    const dayRef = xpEngine._test.getDayRef({ db, userId, dayKey: result1.dayKey });
    const daySnap = await dayRef.get();
    expect(daySnap.exists).toBe(true);
    const data = daySnap.data();
    expect(data.sessions).toContain(sessionId);
    expect(data.total).toBeCloseTo(result1.totalXp, 2);
  });
});
