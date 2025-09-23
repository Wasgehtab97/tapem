const admin = require('firebase-admin');

const { buildDeviceLogActivityEvent } = require('../activity');

describe('buildDeviceLogActivityEvent', () => {
  const baseContext = {
    params: { gymId: 'gym123', deviceId: 'deviceA', logId: 'log1' },
  };

  it('maps device log fields to activity event', () => {
    const logTimestamp = admin.firestore.Timestamp.fromDate(new Date('2024-01-01T12:00:00Z'));
    const now = admin.firestore.Timestamp.fromDate(new Date('2024-01-02T08:00:00Z'));
    const event = buildDeviceLogActivityEvent(
      {
        timestamp: logTimestamp,
        userId: 'user42',
        sessionId: 'session88',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        setType: 'drop',
        reps: 10,
        weight: 80,
        durationSeconds: 45,
      },
      baseContext,
      { now, serverTimestamp: 'SERVER_TS' }
    );

    expect(event).toEqual({
      gymId: 'gym123',
      timestamp: logTimestamp,
      eventType: 'training.set_logged',
      severity: 'info',
      source: 'device',
      summary: 'Trainingseintrag gespeichert (Bench Press)',
      userId: 'user42',
      deviceId: 'deviceA',
      sessionId: 'session88',
      actor: { type: 'user', id: 'user42' },
      targets: [
        { type: 'session', id: 'session88' },
        { type: 'exercise', id: 'bench' },
      ],
      data: {
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        setType: 'drop',
        reps: 10,
        weight: 80,
        duration: 45,
      },
      updatedAt: 'SERVER_TS',
      idempotencyKey: 'gym123:deviceA:log1',
    });
  });

  it('falls back to now timestamp and omits optional fields', () => {
    const now = admin.firestore.Timestamp.fromDate(new Date('2024-02-01T10:00:00Z'));
    const event = buildDeviceLogActivityEvent(
      {},
      baseContext,
      { now, serverTimestamp: 'SERVER_TS' }
    );

    expect(event).toEqual({
      gymId: 'gym123',
      timestamp: now,
      eventType: 'training.set_logged',
      severity: 'info',
      source: 'device',
      summary: 'Trainingseintrag gespeichert',
      userId: undefined,
      deviceId: 'deviceA',
      sessionId: undefined,
      actor: { type: 'system' },
      targets: undefined,
      data: undefined,
      updatedAt: 'SERVER_TS',
      idempotencyKey: 'gym123:deviceA:log1',
    });
  });

  it('returns null for missing context params', () => {
    const event = buildDeviceLogActivityEvent({}, { params: {} }, {});
    expect(event).toBeNull();
  });
});
