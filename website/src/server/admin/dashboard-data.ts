import 'server-only';

import { Timestamp } from 'firebase-admin/firestore';

import { getFirebaseAdminFirestore } from '@/src/server/firebase/admin';

export type AdminKpiMetric = {
  id: string;
  label: string;
  value: number;
  helper?: string;
};

export type AdminEventLogEntry = {
  id: string;
  timestamp: Date;
  gymId?: string;
  deviceId?: string;
  type?: string;
  description?: string;
};

export type AdminActivityPoint = {
  date: string;
  totalCheckIns: number;
};

export type AdminDashboardData = {
  metrics: {
    items: AdminKpiMetric[];
    generatedAt: Date;
    error?: string;
  };
  events: {
    items: AdminEventLogEntry[];
    error?: string;
  };
  activity: {
    points: AdminActivityPoint[];
    range: { start: Date; end: Date };
    error?: string;
  };
};

async function safeCount<T>(factory: () => Promise<T>): Promise<T | null> {
  try {
    return await factory();
  } catch (error) {
    console.error('[admin-dashboard] aggregate failed', error);
    return null;
  }
}

function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export async function fetchAdminDashboardData(): Promise<AdminDashboardData> {
  const firestore = getFirebaseAdminFirestore();
  const now = new Date();
  const nowTimestamp = Timestamp.fromDate(now);
  const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const twoWeeksAgo = new Date(now.getTime() - 13 * 24 * 60 * 60 * 1000);

  const [
    totalGyms,
    totalUsers,
    checkIns24h,
    checkIns30d,
    activeChallenges,
    dailyActiveUserCount,
  ] = await Promise.all([
    safeCount(async () => {
      const snapshot = await firestore.collection('gyms').count().get();
      return snapshot.data().count ?? 0;
    }),
    safeCount(async () => {
      const snapshot = await firestore.collection('users').count().get();
      return snapshot.data().count ?? 0;
    }),
    safeCount(async () => {
      const snapshot = await firestore
        .collectionGroup('logs')
        .where('timestamp', '>=', Timestamp.fromDate(dayAgo))
        .count()
        .get();
      return snapshot.data().count ?? 0;
    }),
    safeCount(async () => {
      const snapshot = await firestore
        .collectionGroup('logs')
        .where('timestamp', '>=', Timestamp.fromDate(monthAgo))
        .count()
        .get();
      return snapshot.data().count ?? 0;
    }),
    safeCount(async () => {
      const snapshot = await firestore
        .collection('challenges')
        .where('end', '>=', nowTimestamp)
        .count()
        .get();
      return snapshot.data().count ?? 0;
    }),
    safeCount(async () => {
      const snapshot = await firestore
        .collectionGroup('logs')
        .where('timestamp', '>=', Timestamp.fromDate(dayAgo))
        .select('userId')
        .limit(5000)
        .get();
      const users = new Set<string>();
      snapshot.docs.forEach((doc) => {
        const userId = doc.get('userId');
        if (typeof userId === 'string' && userId.length > 0) {
          users.add(userId);
        }
      });
      return users.size;
    }),
  ]);

  const metrics: AdminKpiMetric[] = [
    { id: 'gyms', label: 'Studios im Verbund', value: totalGyms ?? 0 },
    { id: 'members', label: 'Registrierte Mitglieder', value: totalUsers ?? 0 },
    { id: 'checkins24h', label: 'Check-ins (24h)', value: checkIns24h ?? 0 },
    { id: 'checkins30d', label: 'Check-ins (30 Tage)', value: checkIns30d ?? 0 },
    { id: 'activeChallenges', label: 'Aktive Challenges', value: activeChallenges ?? 0 },
    { id: 'dau', label: 'Tägliche aktive Nutzer:innen', value: dailyActiveUserCount ?? 0 },
  ];

  const metricError =
    totalGyms === null ||
    totalUsers === null ||
    checkIns24h === null ||
    checkIns30d === null ||
    activeChallenges === null ||
    dailyActiveUserCount === null
      ? 'Mindestens eine Kennzahl konnte nicht geladen werden.'
      : undefined;

  let eventsError: string | undefined;
  const eventEntries: AdminEventLogEntry[] = [];

  try {
    const eventSnapshot = await firestore
      .collectionGroup('logs')
      .orderBy('timestamp', 'desc')
      .limit(20)
      .get();

    eventSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      const timestampValue = data.timestamp;
      const timestamp =
        timestampValue instanceof Timestamp
          ? timestampValue.toDate()
          : typeof timestampValue?.toDate === 'function'
          ? timestampValue.toDate()
          : null;

      const segments = doc.ref.path.split('/');
      const gymId = segments.length >= 2 ? segments[1] : undefined;
      const deviceId = segments.length >= 4 ? segments[3] : undefined;
      const type = typeof data.type === 'string' ? data.type : typeof data.eventType === 'string' ? data.eventType : undefined;
      const description =
        typeof data.description === 'string'
          ? data.description
          : typeof data.message === 'string'
          ? data.message
          : undefined;

      if (timestamp) {
        eventEntries.push({
          id: doc.id,
          timestamp,
          gymId,
          deviceId,
          type,
          description,
        });
      }
    });
  } catch (error) {
    console.error('[admin-dashboard] event log query failed', error);
    eventsError = 'Aktivitätsprotokoll konnte nicht geladen werden.';
  }

  let activityError: string | undefined;
  const activityPoints: AdminActivityPoint[] = [];

  try {
    const activitySnapshot = await firestore
      .collectionGroup('logs')
      .where('timestamp', '>=', Timestamp.fromDate(twoWeeksAgo))
      .select('timestamp')
      .get();

    const totals = new Map<string, number>();
    activitySnapshot.docs.forEach((doc) => {
      const timestampValue = doc.get('timestamp');
      const ts =
        timestampValue instanceof Timestamp
          ? timestampValue.toDate()
          : typeof timestampValue?.toDate === 'function'
          ? timestampValue.toDate()
          : null;
      if (!ts) {
        return;
      }
      const key = formatDateKey(ts);
      totals.set(key, (totals.get(key) ?? 0) + 1);
    });

    const days: AdminActivityPoint[] = [];
    for (let i = 0; i < 14; i += 1) {
      const date = new Date(twoWeeksAgo.getTime() + i * 24 * 60 * 60 * 1000);
      const key = formatDateKey(date);
      days.push({ date: key, totalCheckIns: totals.get(key) ?? 0 });
    }
    activityPoints.push(...days);
  } catch (error) {
    console.error('[admin-dashboard] activity aggregation failed', error);
    activityError = 'Check-in-Verlauf konnte nicht geladen werden.';
  }

  return {
    metrics: {
      items: metrics,
      generatedAt: now,
      error: metricError,
    },
    events: {
      items: eventEntries,
      error: eventsError,
    },
    activity: {
      points: activityPoints,
      range: { start: twoWeeksAgo, end: now },
      error: activityError,
    },
  };
}
