import assert from 'node:assert/strict';
import { before, after, describe, it } from 'node:test';
import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { runBackfill, runBackfillVerify } from '../src/backfill/runtime';

const projectId = process.env.GCLOUD_PROJECT || 'demo-backfill';
let app: admin.app.App;
let db: admin.firestore.Firestore;

async function clearCollection(path: string) {
  try {
    const ref = db.collection(path);
    await admin.firestore().recursiveDelete(ref);
  } catch (error: any) {
    if (error?.code !== 5 && error?.code !== 'not-found') {
      throw error;
    }
  }
}

async function resetDatabase() {
  await clearCollection('gyms');
  await clearCollection('trainingSummary');
  await clearCollection('deviceUsageSummary');
}

function ts(iso: string) {
  return Timestamp.fromDate(new Date(iso));
}

async function seedData() {
  const gyms = [
    { id: 'g1', devices: ['d1', 'd2'] },
    { id: 'g2', devices: ['d3'] },
  ];
  for (const gym of gyms) {
    for (const deviceId of gym.devices) {
      await db
        .collection('gyms')
        .doc(gym.id)
        .collection('devices')
        .doc(deviceId)
        .set({ name: `${gym.id}-${deviceId}` });
    }
  }
  const logs: Array<{ gymId: string; deviceId: string; logId: string; data: Record<string, any> }> = [];
  const pushLog = (gymId: string, deviceId: string, logId: string, data: Record<string, any>) => {
    logs.push({ gymId, deviceId, logId, data });
  };

  // User u1 sessions in gym g1
  ['s-u1-g1-1', 's-u1-g1-1', 's-u1-g1-1'].forEach((sessionId, index) => {
    pushLog('g1', 'd1', `log-u1-g1-1-${index}`, {
      userId: 'u1',
      sessionId,
      timestamp: ts(`2024-01-10T0${8 + index}:00:00Z`),
      timezone: 'Europe/Berlin',
    });
  });
  ['s-u1-g1-2', 's-u1-g1-2'].forEach((sessionId, index) => {
    pushLog('g1', 'd1', `log-u1-g1-2-${index}`, {
      userId: 'u1',
      sessionId,
      timestamp: ts(`2024-01-11T0${9 + index}:00:00Z`),
      timezone: 'Europe/Berlin',
    });
  });
  pushLog('g1', 'd2', 'log-u1-g1-3', {
    userId: 'u1',
    sessionId: 's-u1-g1-3',
    timestamp: ts('2024-01-11T18:00:00Z'),
    timezone: 'Europe/Berlin',
  });

  // User u2 in gym g1
  for (let i = 0; i < 4; i += 1) {
    pushLog('g1', 'd2', `log-u2-g1-${i}`, {
      userId: 'u2',
      sessionId: 's-u2-g1',
      timestamp: ts(`2024-01-12T0${8 + (i % 2)}:30:00Z`),
      timezone: 'Europe/Berlin',
    });
  }

  // Orphan logs
  pushLog('g1', 'd1', 'log-orphan-1', {
    timestamp: ts('2024-01-09T07:00:00Z'),
  });
  pushLog('g1', 'd1', 'log-orphan-2', {
    userId: 'u3',
    timestamp: ts('2024-01-09T08:00:00Z'),
  });

  // User u1 also trains in gym g2 same day as g1 to trigger multi-gym
  ['s-u1-g2-1', 's-u1-g2-1'].forEach((sessionId, index) => {
    pushLog('g2', 'd3', `log-u1-g2-${index}`, {
      userId: 'u1',
      sessionId,
      timestamp: ts(`2024-01-10T1${0 + index}:00:00Z`),
      timezone: 'America/New_York',
    });
  });

  // Additional logs to reach ~60 entries
  for (let i = 0; i < 40; i += 1) {
    pushLog('g2', 'd3', `log-u3-g2-${i}`, {
      userId: 'u3',
      sessionId: `s-u3-g2-${Math.floor(i / 5)}`,
      timestamp: ts(`2024-01-${13 + Math.floor(i / 10)}T0${6 + (i % 3)}:00:00Z`),
      timezone: 'UTC',
    });
  }

  for (const entry of logs) {
    await db
      .collection('gyms')
      .doc(entry.gymId)
      .collection('devices')
      .doc(entry.deviceId)
      .collection('logs')
      .doc(entry.logId)
      .set(entry.data);
  }

  // Session meta for main sessions
  await db
    .collection('gyms')
    .doc('g1')
    .collection('users')
    .doc('u1')
    .collection('session_meta')
    .doc('s-u1-g1-1')
    .set({ dayKey: '2024-01-10', timezone: 'Europe/Berlin' });
}

describe('backfill pipeline', () => {
  before(async () => {
    process.env.GCLOUD_PROJECT = projectId;
    if (!admin.apps.length) {
      app = admin.initializeApp({ projectId });
    } else {
      app = admin.app();
    }
    db = admin.firestore();
  });

  after(async () => {
    await resetDatabase();
    if (app) {
      await app.delete();
    }
  });

  it('runs backfill and writes summaries for gym g1', async () => {
    await resetDatabase();
    const originalNow = Date.now;
    Date.now = () => new Date('2024-01-20T00:00:00Z').getTime();
    try {
      await seedData();
      const report = await runBackfill({ apply: true });
      assert.equal(report.applied, true);
      assert.ok(report.gyms.g1);
      assert.ok(report.gyms.g2);
      assert.ok(report.orphans.length >= 2);
      assert.deepEqual(report.multiGymPerDay['u1']['2024-01-10'], ['g1', 'g2']);

      const dailySnap = await db
        .collection('trainingSummary')
        .doc('u1')
        .collection('daily')
        .doc('2024-01-10')
        .get();
      assert.ok(dailySnap.exists, 'daily summary exists');
      const daily = dailySnap.data()!;
      assert.equal(daily.logCount, 5);
      assert.equal(daily.totalSessions, 2);
      assert.equal(daily.gymId, 'g1');
      assert.equal(daily.deviceCounts.d1, 3);
      assert.equal(daily.deviceCounts.d3, 2);
      assert.equal(daily.sessionCounts['s-u1-g1-1'].count, 3);
      assert.equal(daily.sessionCounts['s-u1-g1-1'].deviceId, 'd1');
      assert.equal(daily.sessionCounts['s-u1-g2-1'].count, 2);
      assert.equal(daily.sessionCounts['s-u1-g2-1'].deviceId, 'd3');

      const daily11 = await db
        .collection('trainingSummary')
        .doc('u1')
        .collection('daily')
        .doc('2024-01-11')
        .get();
      assert.ok(daily11.exists);
      const day11 = daily11.data()!;
      assert.equal(day11.logCount, 3);
      assert.equal(day11.totalSessions, 2);
      assert.equal(Object.keys(day11.sessionCounts).length, 2);

      const aggSnap = await db
        .collection('trainingSummary')
        .doc('u1')
        .collection('aggregate')
        .doc('overview')
        .get();
      assert.ok(aggSnap.exists);
      const aggregate = aggSnap.data()!;
      assert.equal(aggregate.trainingDayCount, 2);
      assert.equal(aggregate.totalSessions, 4);
      assert.equal(aggregate.gymId, 'g1');
      assert.ok(aggregate.firstWorkoutDate);
      assert.ok(aggregate.lastWorkoutDate);

      const deviceSnap = await db
        .collection('deviceUsageSummary')
        .doc('g1')
        .collection('devices')
        .doc('d1')
        .get();
      assert.ok(deviceSnap.exists);
      const device = deviceSnap.data()!;
      assert.equal(device.totalSessions, 2);
      assert.deepEqual(device.recentDates, ['2024-01-11', '2024-01-10']);
      assert.equal(device.rangeCounts.last30 >= device.rangeCounts.last7, true);
    } finally {
      Date.now = originalNow;
    }
  });

  it('verifies summaries without diffs for user u1', async () => {
    await resetDatabase();
    const originalNow = Date.now;
    Date.now = () => new Date('2024-01-20T00:00:00Z').getTime();
    try {
      await seedData();
      await runBackfill({ apply: true });
      const diff = await runBackfillVerify({ userId: 'u1' });
      assert.equal(diff.daily.missing.length, 0);
      assert.equal(diff.daily.extra.length, 0);
      assert.equal(diff.daily.mismatched.length, 0);
      assert.ok(diff.aggregate.expected);
      assert.ok(diff.aggregate.actual);
      assert.equal(diff.devices.missing.length, 0);
      assert.equal(diff.devices.mismatched.length, 0);
    } finally {
      Date.now = originalNow;
    }
  });
});
