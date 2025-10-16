import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { buildArtifacts } from './build';
import { buildReport } from './report';
import { scanGym, normalizeTimestamp } from './scan';
import {
  AggregateSummaryDoc,
  BackfillRunParams,
  BackfillVerifyParams,
  BuildArtifacts,
  DailySummaryDoc,
  DeviceUsageDoc,
  ReportData,
  VerificationDiff,
  WriterStats,
} from './types';
import { createBackfillWriter } from './write';

async function listGymIds(target?: string) {
  if (target) {
    return [target];
  }
  const db = getFirestore();
  const snapshot = await db.collection('gyms').get();
  return snapshot.docs.map((doc) => doc.id);
}

function dailyToComparable(doc: DailySummaryDoc) {
  const sessionEntries = Object.entries(doc.sessionCounts).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  const deviceEntries = Object.entries(doc.deviceCounts).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  return {
    userId: doc.userId,
    dateKey: doc.dateKey,
    date: doc.date.toMillis(),
    logCount: doc.logCount,
    totalSessions: doc.totalSessions,
    sessionCounts: sessionEntries,
    deviceCounts: deviceEntries,
    gymId: doc.gymId,
  };
}

function isDailyEqual(a: DailySummaryDoc, b: DailySummaryDoc) {
  return JSON.stringify(dailyToComparable(a)) === JSON.stringify(dailyToComparable(b));
}

function isDeviceContributionSatisfied(expected: DeviceUsageDoc, actual: DeviceUsageDoc) {
  if (actual.totalSessions < expected.totalSessions) {
    return false;
  }
  for (const [rangeKey, expectedValue] of Object.entries(expected.rangeCounts)) {
    const actualValue = Number(actual.rangeCounts[rangeKey] ?? 0);
    if (actualValue < expectedValue) {
      return false;
    }
  }
  const expectedDates = new Set(expected.recentDates);
  const actualDates = new Set(actual.recentDates);
  for (const date of expectedDates) {
    if (!actualDates.has(date)) {
      return false;
    }
  }
  if (expected.lastActive && actual.lastActive) {
    if (actual.lastActive.toMillis() < expected.lastActive.toMillis()) {
      return false;
    }
  }
  if (expected.lastActive && !actual.lastActive) {
    return false;
  }
  return true;
}

function filterDailyByRange(
  source: Map<string, DailySummaryDoc>,
  from?: Timestamp,
  to?: Timestamp,
) {
  if (!from && !to) {
    return new Map(source);
  }
  const result = new Map<string, DailySummaryDoc>();
  for (const [key, value] of source.entries()) {
    const millis = value.date.toMillis();
    if (from && millis < from.toMillis()) {
      continue;
    }
    if (to && millis > to.toMillis()) {
      continue;
    }
    result.set(key, value);
  }
  return result;
}

async function applyArtifacts(artifacts: BuildArtifacts, apply: boolean) {
  if (!apply) {
    return { attempted: 0, written: 0, skipped: 0 } as WriterStats;
  }
  const writer = createBackfillWriter();
  for (const doc of artifacts.daily.values()) {
    await writer.upsertDailySummary(doc.userId, doc);
  }
  for (const doc of artifacts.aggregates.values()) {
    await writer.upsertAggregate(doc.userId, doc);
  }
  for (const doc of artifacts.devices.values()) {
    await writer.upsertDeviceUsage(doc.gymId, doc);
  }
  await writer.close();
  return writer.stats;
}

export async function runBackfill(params: BackfillRunParams): Promise<ReportData> {
  const gymIds = await listGymIds(params.gymId);
  const scanResults = [];
  for (const gymId of gymIds) {
    const scan = await scanGym(gymId, {
      from: params.from,
      to: params.to,
      userId: params.userId,
    });
    scanResults.push(scan);
  }
  const artifacts = buildArtifacts(scanResults);
  const writerStats = await applyArtifacts(artifacts, Boolean(params.apply));
  return buildReport(scanResults, artifacts, writerStats, Boolean(params.apply));
}

function parseDailySnapshot(userId: string, docId: string, data: FirebaseFirestore.DocumentData): DailySummaryDoc {
  return {
    userId,
    dateKey: typeof data.dateKey === 'string' ? data.dateKey : docId,
    date: data.date instanceof Timestamp ? data.date : Timestamp.fromMillis(0),
    logCount: Number(data.logCount ?? 0),
    totalSessions: Number(data.totalSessions ?? 0),
    sessionCounts: (data.sessionCounts as Record<string, any>) || {},
    deviceCounts: (data.deviceCounts as Record<string, number>) || {},
    gymId: typeof data.gymId === 'string' ? data.gymId : 'unknown',
  };
}

function parseAggregateSnapshot(userId: string, data: FirebaseFirestore.DocumentData | undefined): AggregateSummaryDoc | null {
  if (!data) {
    return null;
  }
  return {
    userId,
    gymId: typeof data.gymId === 'string' ? data.gymId : 'unknown',
    trainingDayCount: Number(data.trainingDayCount ?? 0),
    totalSessions: Number(data.totalSessions ?? 0),
    firstWorkoutDate: data.firstWorkoutDate instanceof Timestamp ? data.firstWorkoutDate : null,
    lastWorkoutDate: data.lastWorkoutDate instanceof Timestamp ? data.lastWorkoutDate : null,
    deviceCounts: (data.deviceCounts as Record<string, number>) || {},
  };
}

function parseDeviceSnapshot(
  gymId: string,
  deviceId: string,
  data: FirebaseFirestore.DocumentData | undefined,
): DeviceUsageDoc | null {
  if (!data) {
    return null;
  }
  return {
    gymId,
    deviceId,
    totalSessions: Number(data.totalSessions ?? 0),
    rangeCounts: (data.rangeCounts as Record<string, number>) || {},
    lastActive: data.lastActive instanceof Timestamp ? data.lastActive : null,
    recentDates: Array.isArray(data.recentDates)
      ? data.recentDates.map(String)
      : [],
  };
}

export async function runBackfillVerify(params: BackfillVerifyParams): Promise<VerificationDiff> {
  const db = getFirestore();
  const gymIds = await listGymIds();
  const scanResults = [];
  const userDeviceKeys = new Set<string>();
  for (const gymId of gymIds) {
    const scan = await scanGym(gymId, {
      from: params.from,
      to: params.to,
      userId: params.userId,
    });
    scanResults.push(scan);
    for (const [key, device] of scan.devices.entries()) {
      if (device.userIds.has(params.userId)) {
        userDeviceKeys.add(key);
      }
    }
  }
  const artifacts = buildArtifacts(scanResults);
  const fromTs = normalizeTimestamp(params.from);
  const toTs = normalizeTimestamp(params.to);
  const expectedDailyAll = new Map(
    Array.from(artifacts.daily.entries()).filter(([_, doc]) => doc.userId === params.userId),
  );
  const expectedDaily = filterDailyByRange(expectedDailyAll, fromTs, toTs);
  const expectedAggregate = artifacts.aggregates.get(params.userId) ?? null;
  const expectedDevices = new Map(
    Array.from(artifacts.devices.entries()).filter(([key]) => userDeviceKeys.has(key)),
  );

  let dailyQuery: FirebaseFirestore.Query = db
    .collection('trainingSummary')
    .doc(params.userId)
    .collection('daily');
  if (fromTs) {
    dailyQuery = dailyQuery.where('date', '>=', fromTs);
  }
  if (toTs) {
    dailyQuery = dailyQuery.where('date', '<=', toTs);
  }
  const dailySnap = await dailyQuery.get();
  const actualDaily = new Map<string, DailySummaryDoc>();
  dailySnap.forEach((doc) => {
    actualDaily.set(doc.id, parseDailySnapshot(params.userId, doc.id, doc.data()));
  });

  const missingDaily: string[] = [];
  const extraDaily: string[] = [];
  const mismatchedDaily: Array<{
    dateKey: string;
    expected: DailySummaryDoc;
    actual: DailySummaryDoc;
  }> = [];

  for (const [key, expectedDoc] of expectedDaily.entries()) {
    const actualDoc = actualDaily.get(key);
    if (!actualDoc) {
      missingDaily.push(key);
      continue;
    }
    if (!isDailyEqual(expectedDoc, actualDoc)) {
      mismatchedDaily.push({ dateKey: key, expected: expectedDoc, actual: actualDoc });
    }
  }
  for (const key of actualDaily.keys()) {
    if (!expectedDaily.has(key)) {
      extraDaily.push(key);
    }
  }

  const aggregateSnap = await db
    .collection('trainingSummary')
    .doc(params.userId)
    .collection('aggregate')
    .doc('overview')
    .get();
  const actualAggregate = parseAggregateSnapshot(params.userId, aggregateSnap.data());

  const deviceMissing: Array<{ gymId: string; deviceId: string; expected: DeviceUsageDoc }> = [];
  const deviceExtra: Array<{ gymId: string; deviceId: string; actual: DeviceUsageDoc }> = [];
  const deviceMismatched: Array<{
    gymId: string;
    deviceId: string;
    expected: DeviceUsageDoc;
    actual: DeviceUsageDoc;
  }> = [];

  for (const [key, expectedDoc] of expectedDevices.entries()) {
    const [gymId, deviceId] = key.split('::');
    const snapshot = await db
      .collection('deviceUsageSummary')
      .doc(gymId)
      .collection('devices')
      .doc(deviceId)
      .get();
    const actualDoc = parseDeviceSnapshot(gymId, deviceId, snapshot.data());
    if (!actualDoc) {
      deviceMissing.push({ gymId, deviceId, expected: expectedDoc });
      continue;
    }
    if (!isDeviceContributionSatisfied(expectedDoc, actualDoc)) {
      deviceMismatched.push({ gymId, deviceId, expected: expectedDoc, actual: actualDoc });
    }
  }

  return {
    daily: {
      missing: missingDaily,
      extra: extraDaily,
      mismatched: mismatchedDaily,
    },
    aggregate: {
      expected: expectedAggregate,
      actual: actualAggregate,
    },
    devices: {
      missing: deviceMissing,
      extra: deviceExtra,
      mismatched: deviceMismatched,
    },
  };
}
