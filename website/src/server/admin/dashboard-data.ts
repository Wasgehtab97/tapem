import 'server-only';

import { Timestamp } from 'firebase-admin/firestore';

import { adminDb } from '@/src/server/firebase/admin';

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

export type AdminDashboardWarning = {
  metricId: string;
  message: string;
  indexUrl?: string;
};

export type AdminDashboardData = {
  metrics: {
    items: AdminKpiMetric[];
    generatedAt: Date;
    error?: string;
    warnings: AdminDashboardWarning[];
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

function extractIndexUrl(error: unknown): string | null {
  const message = error instanceof Error ? error.message : (error as { message?: string })?.message;
  if (!message) {
    return null;
  }

  const match = message.match(/https:\/\/console\.firebase\.google\.com\/[\w\-/.?=&%]+/);
  return match ? match[0] : null;
}

function isFailedPrecondition(error: unknown): boolean {
  const code = (error as { code?: unknown })?.code;
  if (typeof code === 'number') {
    return code === 9;
  }

  if (typeof code === 'string') {
    return code.toLowerCase() === 'failed-precondition';
  }

  const details = (error as { details?: unknown })?.details;
  if (typeof details === 'string' && details.toLowerCase().includes('failed_precondition')) {
    return true;
  }

  const message = error instanceof Error ? error.message : null;
  return Boolean(message && message.toUpperCase().includes('FAILED_PRECONDITION'));
}

type MetricComputation = {
  id: string;
  label: string;
  run: () => Promise<number>;
  fallback?: {
    run: () => Promise<number>;
    hint?: string;
  };
};

type MetricComputationResult = {
  value: number | null;
  warning?: AdminDashboardWarning;
};

async function computeMetric({ id, label, run, fallback }: MetricComputation): Promise<MetricComputationResult> {
  try {
    const value = await run();
    return { value };
  } catch (error) {
    const indexUrl = extractIndexUrl(error);
    if (isFailedPrecondition(error) && fallback) {
      console.warn(
        `[admin-dashboard] Firestore Index für Kennzahl "${id}" erforderlich${indexUrl ? `: ${indexUrl}` : ''}`
      );
      try {
        const fallbackValue = await fallback.run();
        const messageParts = [`Firestore Index für "${label}" wird erstellt bzw. benötigt.`];
        if (fallback.hint) {
          messageParts.push(fallback.hint);
        }
        if (indexUrl) {
          messageParts.push(`Index-Link: ${indexUrl}`);
        }
        return {
          value: fallbackValue,
          warning: {
            metricId: id,
            message: messageParts.join(' '),
            indexUrl: indexUrl ?? undefined,
          },
        };
      } catch (fallbackError) {
        console.error('[admin-dashboard] fallback metric computation failed', fallbackError);
      }
    }

    console.error(`[admin-dashboard] metric computation failed for ${id}`, error);
    return { value: null };
  }
}

function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export async function fetchAdminDashboardData(): Promise<AdminDashboardData> {
  const firestore = adminDb();
  const now = new Date();
  const nowTimestamp = Timestamp.fromDate(now);
  const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const twoWeeksAgo = new Date(now.getTime() - 13 * 24 * 60 * 60 * 1000);

  const metricsWarnings: AdminDashboardWarning[] = [];
  const [
    totalGyms,
    totalUsers,
    checkIns24h,
    checkIns30d,
    activeChallenges,
    dailyActiveUserCount,
  ] = await Promise.all([
    computeMetric({
      id: 'gyms',
      label: 'Studios im Verbund',
      run: async () => {
        const snapshot = await firestore.collection('gyms').count().get();
        return snapshot.data().count ?? 0;
      },
    }),
    computeMetric({
      id: 'members',
      label: 'Registrierte Mitglieder',
      run: async () => {
        const snapshot = await firestore.collection('users').count().get();
        return snapshot.data().count ?? 0;
      },
    }),
    computeMetric({
      id: 'checkins24h',
      label: 'Check-ins (24h)',
      run: async () => {
        const snapshot = await firestore
          .collectionGroup('logs')
          .where('timestamp', '>=', Timestamp.fromDate(dayAgo))
          .count()
          .get();
        return snapshot.data().count ?? 0;
      },
      fallback: {
        run: async () => {
          const snapshot = await firestore
            .collectionGroup('logs')
            .where('timestamp', '>=', Timestamp.fromDate(dayAgo))
            .select('timestamp')
            .limit(1000)
            .get();
          return snapshot.size;
        },
        hint: 'Temporäre Zählung (max. 1.000 Logs) aktiv.',
      },
    }),
    computeMetric({
      id: 'checkins30d',
      label: 'Check-ins (30 Tage)',
      run: async () => {
        const snapshot = await firestore
          .collectionGroup('logs')
          .where('timestamp', '>=', Timestamp.fromDate(monthAgo))
          .count()
          .get();
        return snapshot.data().count ?? 0;
      },
      fallback: {
        run: async () => {
          const snapshot = await firestore
            .collectionGroup('logs')
            .where('timestamp', '>=', Timestamp.fromDate(monthAgo))
            .select('timestamp')
            .limit(1000)
            .get();
          return snapshot.size;
        },
        hint: 'Temporäre Zählung (max. 1.000 Logs) aktiv.',
      },
    }),
    computeMetric({
      id: 'activeChallenges',
      label: 'Aktive Challenges',
      run: async () => {
        const snapshot = await firestore
          .collection('challenges')
          .where('end', '>=', nowTimestamp)
          .count()
          .get();
        return snapshot.data().count ?? 0;
      },
      fallback: {
        run: async () => {
          const snapshot = await firestore
            .collection('challenges')
            .where('end', '>=', nowTimestamp)
            .limit(1000)
            .get();
          return snapshot.size;
        },
        hint: 'Temporäre Zählung (max. 1.000 Dokumente) aktiv.',
      },
    }),
    computeMetric({
      id: 'dau',
      label: 'Tägliche aktive Nutzer:innen',
      run: async () => {
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
      },
    }),
  ]);

  [totalGyms, totalUsers, checkIns24h, checkIns30d, activeChallenges, dailyActiveUserCount].forEach((result) => {
    if (result.warning) {
      metricsWarnings.push(result.warning);
    }
  });

  const metrics: AdminKpiMetric[] = [
    { id: 'gyms', label: 'Studios im Verbund', value: totalGyms.value ?? 0 },
    { id: 'members', label: 'Registrierte Mitglieder', value: totalUsers.value ?? 0 },
    { id: 'checkins24h', label: 'Check-ins (24h)', value: checkIns24h.value ?? 0 },
    { id: 'checkins30d', label: 'Check-ins (30 Tage)', value: checkIns30d.value ?? 0 },
    { id: 'activeChallenges', label: 'Aktive Challenges', value: activeChallenges.value ?? 0 },
    { id: 'dau', label: 'Tägliche aktive Nutzer:innen', value: dailyActiveUserCount.value ?? 0 },
  ];

  const metricError =
    totalGyms.value === null ||
    totalUsers.value === null ||
    checkIns24h.value === null ||
    checkIns30d.value === null ||
    activeChallenges.value === null ||
    dailyActiveUserCount.value === null
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
    if (isFailedPrecondition(error)) {
      console.warn('[admin-dashboard] Event-Log Index erforderlich – Fallback aktiv.', error);
      try {
        const fallbackSnapshot = await firestore
          .collectionGroup('logs')
          .where('timestamp', '>=', Timestamp.fromDate(twoWeeksAgo))
          .select('timestamp', 'type', 'eventType', 'description', 'message')
          .limit(1000)
          .get();

        const fallbackEntries = fallbackSnapshot.docs
          .map((doc) => {
            const data = doc.data();
            const timestampValue = data.timestamp;
            const timestamp =
              timestampValue instanceof Timestamp
                ? timestampValue.toDate()
                : typeof timestampValue?.toDate === 'function'
                ? timestampValue.toDate()
                : null;
            if (!timestamp) return null;
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
            return {
              id: doc.id,
              timestamp,
              gymId,
              deviceId,
              type,
              description,
            } as AdminEventLogEntry;
          })
          .filter((entry): entry is AdminEventLogEntry => Boolean(entry))
          .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
          .slice(0, 20);

        eventEntries.push(...fallbackEntries);
        eventsError = 'Index für Aktivitätsprotokoll wird erstellt – Fallback aktiv.';
      } catch (fallbackError) {
        console.error('[admin-dashboard] event log fallback failed', fallbackError);
        eventsError = 'Aktivitätsprotokoll konnte nicht geladen werden.';
      }
    } else {
      console.error('[admin-dashboard] event log query failed', error);
      eventsError = 'Aktivitätsprotokoll konnte nicht geladen werden.';
    }
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
    if (isFailedPrecondition(error)) {
      console.warn('[admin-dashboard] Activity Index erforderlich – Fallback aktiv.', error);
      try {
        const fallbackSnapshot = await firestore.collectionGroup('logs').limit(1000).get();
        const totals = new Map<string, number>();
        fallbackSnapshot.docs.forEach((doc) => {
          const timestampValue = doc.get('timestamp');
          const ts =
            timestampValue instanceof Timestamp
              ? timestampValue.toDate()
              : typeof timestampValue?.toDate === 'function'
              ? timestampValue.toDate()
              : null;
          if (!ts || ts < twoWeeksAgo) {
            return;
          }
          const key = formatDateKey(ts);
          totals.set(key, (totals.get(key) ?? 0) + 1);
        });
        for (let i = 0; i < 14; i += 1) {
          const date = new Date(twoWeeksAgo.getTime() + i * 24 * 60 * 60 * 1000);
          const key = formatDateKey(date);
          activityPoints.push({ date: key, totalCheckIns: totals.get(key) ?? 0 });
        }
        activityError = 'Index für Check-in-Verlauf wird erstellt – Fallback aktiv.';
      } catch (fallbackError) {
        console.error('[admin-dashboard] activity fallback failed', fallbackError);
        activityError = 'Check-in-Verlauf konnte nicht geladen werden.';
      }
    } else {
      console.error('[admin-dashboard] activity aggregation failed', error);
      activityError = 'Check-in-Verlauf konnte nicht geladen werden.';
    }
  }

  return {
    metrics: {
      items: metrics,
      generatedAt: now,
      error: metricError,
      warnings: metricsWarnings,
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
