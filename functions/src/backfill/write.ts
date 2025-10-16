import crypto from 'crypto';
import {
  BulkWriter,
  DocumentReference,
  FieldValue,
  getFirestore,
} from 'firebase-admin/firestore';
import {
  AggregateSummaryDoc,
  DailySummaryDoc,
  DeviceUsageDoc,
  WriterStats,
} from './types';

export interface BackfillWriter {
  upsertDailySummary: (uid: string, doc: DailySummaryDoc) => Promise<void>;
  upsertAggregate: (uid: string, doc: AggregateSummaryDoc) => Promise<void>;
  upsertDeviceUsage: (gymId: string, doc: DeviceUsageDoc) => Promise<void>;
  close: () => Promise<void>;
  stats: WriterStats;
}

function stableSerialize(value: unknown): string {
  if (value === null || value === undefined) {
    return 'null';
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return JSON.stringify(value);
  }
  if (typeof value === 'string') {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableSerialize(item)).join(',')}]`;
  }
  if (typeof value === 'object' && 'toMillis' in (value as any) && typeof (value as any).toMillis === 'function') {
    return JSON.stringify((value as any).toMillis());
  }
  if (typeof value === 'object') {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj).sort();
    return `{${keys
      .map((key) => `${JSON.stringify(key)}:${stableSerialize(obj[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(String(value));
}

function createHash(payload: unknown) {
  return crypto.createHash('md5').update(stableSerialize(payload)).digest('hex');
}

function createWriter(): { writer: BulkWriter; stats: WriterStats } {
  const db = getFirestore();
  const writer = db.bulkWriter();
  return {
    writer,
    stats: { attempted: 0, written: 0, skipped: 0 },
  };
}

async function upsertWithHash<T extends object>(
  writer: BulkWriter,
  ref: DocumentReference,
  payload: T,
  hashPayload: unknown,
  stats: WriterStats,
) {
  stats.attempted += 1;
  const hash = createHash(hashPayload);
  const snapshot = await ref.get();
  if (snapshot.exists) {
    const existing = snapshot.get('_hash');
    if (existing === hash) {
      stats.skipped += 1;
      return;
    }
  }
  await writer.set(ref, { ...payload, _hash: hash, updatedAt: FieldValue.serverTimestamp() });
  stats.written += 1;
}

function dailyHashPayload(doc: DailySummaryDoc) {
  return {
    userId: doc.userId,
    dateKey: doc.dateKey,
    date: doc.date,
    logCount: doc.logCount,
    totalSessions: doc.totalSessions,
    sessionCounts: doc.sessionCounts,
    deviceCounts: doc.deviceCounts,
    gymId: doc.gymId,
  };
}

function aggregateHashPayload(doc: AggregateSummaryDoc) {
  return {
    userId: doc.userId,
    gymId: doc.gymId,
    trainingDayCount: doc.trainingDayCount,
    totalSessions: doc.totalSessions,
    firstWorkoutDate: doc.firstWorkoutDate,
    lastWorkoutDate: doc.lastWorkoutDate,
    deviceCounts: doc.deviceCounts,
  };
}

function deviceHashPayload(doc: DeviceUsageDoc) {
  return {
    gymId: doc.gymId,
    deviceId: doc.deviceId,
    totalSessions: doc.totalSessions,
    rangeCounts: doc.rangeCounts,
    lastActive: doc.lastActive,
    recentDates: doc.recentDates,
  };
}

export function createBackfillWriter(): BackfillWriter {
  const context = createWriter();
  const db = getFirestore();

  return {
    stats: context.stats,
    upsertDailySummary: async (uid: string, doc: DailySummaryDoc) => {
      const ref = db
        .collection('trainingSummary')
        .doc(uid)
        .collection('daily')
        .doc(doc.dateKey);
      await upsertWithHash(context.writer, ref, doc, dailyHashPayload(doc), context.stats);
    },
    upsertAggregate: async (uid: string, doc: AggregateSummaryDoc) => {
      const ref = db
        .collection('trainingSummary')
        .doc(uid)
        .collection('aggregate')
        .doc('overview');
      await upsertWithHash(
        context.writer,
        ref,
        doc,
        aggregateHashPayload(doc),
        context.stats,
      );
    },
    upsertDeviceUsage: async (gymId: string, doc: DeviceUsageDoc) => {
      const ref = db
        .collection('deviceUsageSummary')
        .doc(gymId)
        .collection('devices')
        .doc(doc.deviceId);
      await upsertWithHash(context.writer, ref, doc, deviceHashPayload(doc), context.stats);
    },
    close: async () => {
      await context.writer.close();
    },
  };
}
