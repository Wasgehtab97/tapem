import 'server-only';

import { FieldPath, Timestamp } from 'firebase-admin/firestore';
import type { Firestore } from 'firebase-admin/firestore';

import { adminDb } from '@/src/server/firebase/admin';
import { mapActivityEventDoc } from '@/src/server/activity/events';
import type { AdminActivityEventRecord } from '@/src/types/admin-activity';

async function sumLogCountsInRange(
  firestore: Firestore,
  start: Date,
  end: Date
): Promise<number> {
  const snapshot = await firestore
    .collectionGroup('daily')
    .where('date', '>=', Timestamp.fromDate(start))
    .where('date', '<=', Timestamp.fromDate(end))
    .select('logCount')
    .get();
  let total = 0;
  snapshot.docs.forEach((doc) => {
    const value = doc.get('logCount');
    if (typeof value === 'number') {
      total += value;
    }
  });
  return total;
}

async function collectActiveUsers(
  firestore: Firestore,
  start: Date,
  end: Date
): Promise<number> {
  const snapshot = await firestore
    .collectionGroup('daily')
    .where('date', '>=', Timestamp.fromDate(start))
    .where('date', '<=', Timestamp.fromDate(end))
    .select(FieldPath.documentId())
    .get();
  const users = new Set<string>();
  snapshot.docs.forEach((doc) => {
    const userId = doc.ref.parent.parent?.id;
    if (typeof userId === 'string' && userId.length > 0) {
      users.add(userId);
    }
  });
  return users.size;
}

async function fetchActivitySeries(
  firestore: Firestore,
  start: Date,
  end: Date
) {
  const snapshot = await firestore
    .collectionGroup('daily')
    .where('date', '>=', Timestamp.fromDate(start))
    .where('date', '<=', Timestamp.fromDate(end))
    .select('date', 'logCount')
    .get();
  const totals = new Map<string, number>();
  snapshot.docs.forEach((doc) => {
    const dateValue = doc.get('date');
    const timestamp = dateValue instanceof Timestamp ? dateValue.toDate() : null;
    if (!timestamp) {
      return;
    }
    const iso = timestamp.toISOString().slice(0, 10);
    const existing = totals.get(iso) ?? 0;
    const count = doc.get('logCount');
    totals.set(iso, existing + (typeof count === 'number' ? count : 0));
  });
  return totals;
}

export type AdminKpiMetric = {
  id: string;
  label: string;
  value: number;
  helper?: string;
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
    items: AdminActivityEventRecord[];
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
        return sumLogCountsInRange(firestore, dayAgo, now);
      },
    }),
    computeMetric({
      id: 'checkins30d',
      label: 'Check-ins (30 Tage)',
      run: async () => {
        return sumLogCountsInRange(firestore, monthAgo, now);
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
        return collectActiveUsers(firestore, dayAgo, now);
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
  const eventEntries: AdminActivityEventRecord[] = [];

  try {
    const eventSnapshot = await firestore
      .collectionGroup('activity')
      .orderBy('timestamp', 'desc')
      .orderBy(FieldPath.documentId(), 'desc')
      .limit(20)
      .get();

    eventSnapshot.docs.forEach((doc) => {
      const entry = mapActivityEventDoc(doc);
      if (entry) {
        eventEntries.push(entry);
      }
    });
  } catch (error) {
    if (isFailedPrecondition(error)) {
      console.warn('[admin-dashboard] Activity Index erforderlich – Fallback aktiv.', error);
      try {
        const fallbackSnapshot = await firestore
          .collectionGroup('activity')
          .where('timestamp', '>=', Timestamp.fromDate(twoWeeksAgo))
          .select(
            'timestamp',
            'eventType',
            'summary',
            'severity',
            'source',
            'userId',
            'deviceId',
            'sessionId',
            'actor',
            'targets',
            'data'
          )
          .limit(1000)
          .get();

        const fallbackEntries = fallbackSnapshot.docs
          .map((doc) => mapActivityEventDoc(doc))
          .filter((entry): entry is AdminActivityEventRecord => Boolean(entry))
          .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
          .slice(0, 20);

        eventEntries.push(...fallbackEntries);
        eventsError = 'Index für Aktivitätsprotokoll wird erstellt – Fallback aktiv.';
      } catch (fallbackError) {
        console.error('[admin-dashboard] activity fallback failed', fallbackError);
        eventsError = 'Aktivitätsprotokoll konnte nicht geladen werden.';
      }
    } else {
      console.error('[admin-dashboard] activity query failed', error);
      eventsError = 'Aktivitätsprotokoll konnte nicht geladen werden.';
    }
  }

  let activityError: string | undefined;
  const activityPoints: AdminActivityPoint[] = [];

  try {
    const totals = await fetchActivitySeries(firestore, twoWeeksAgo, now);
    for (let i = 0; i < 14; i += 1) {
      const date = new Date(twoWeeksAgo.getTime() + i * 24 * 60 * 60 * 1000);
      const key = formatDateKey(date);
      activityPoints.push({ date: key, totalCheckIns: totals.get(key) ?? 0 });
    }
  } catch (error) {
    console.error('[admin-dashboard] activity aggregation failed', error);
    activityError = 'Check-in-Verlauf konnte nicht geladen werden.';
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
