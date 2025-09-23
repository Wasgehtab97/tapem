import 'server-only';

import {
  FieldPath,
  Timestamp,
  type Firestore,
  type Query,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';

import { adminDb } from '@/src/server/firebase/admin';
import type {
  ActivityEventSeverity,
  AdminActivityActor,
  AdminActivityEventRecord,
  AdminActivityTarget,
  ActivityEventStats,
} from '@/src/types/admin-activity';

export type ActivityEventFilters = {
  from?: Date | null;
  to?: Date | null;
  eventTypes?: string[];
  severity?: ActivityEventSeverity[];
  userId?: string | null;
  deviceId?: string | null;
  limit?: number;
  cursor?: string | null;
};

export type ActivityEventQueryResult = {
  items: AdminActivityEventRecord[];
  nextCursor: string | null;
  stats: ActivityEventStats;
  warnings: string[];
};

type CursorPayload = {
  ts: string;
  path: string;
};

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;
const MIN_LIMIT = 1;

function toDate(value: unknown): Date | null {
  if (value instanceof Date) {
    return value;
  }
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value && typeof (value as { toDate?: () => Date }).toDate === 'function') {
    try {
      return (value as { toDate: () => Date }).toDate();
    } catch {
      return null;
    }
  }
  return null;
}

function sanitizeString(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

type NormalizedFilters = {
  eventTypes: string[];
  severity: ActivityEventSeverity[];
  userId: string | null;
  deviceId: string | null;
};

function normalizeFilters(filters: ActivityEventFilters): NormalizedFilters {
  const eventTypes = new Set<string>();
  (filters.eventTypes ?? []).forEach((type) => {
    if (typeof type !== 'string') {
      return;
    }
    const trimmed = type.trim();
    if (trimmed) {
      eventTypes.add(trimmed);
    }
  });

  const severity: ActivityEventSeverity[] = [];
  (filters.severity ?? []).forEach((value) => {
    if ((value === 'info' || value === 'warning' || value === 'error') && !severity.includes(value)) {
      severity.push(value);
    }
  });

  return {
    eventTypes: Array.from(eventTypes),
    severity,
    userId: sanitizeString(filters.userId),
    deviceId: sanitizeString(filters.deviceId),
  };
}

function sanitizeActor(value: unknown): AdminActivityActor | null {
  if (!value || typeof value !== 'object') {
    return null;
  }
  const record = value as Record<string, unknown>;
  const typeValue = record.type;
  const type = typeValue === 'user' || typeValue === 'system' || typeValue === 'admin' ? typeValue : undefined;
  if (!type) {
    return null;
  }
  const id = sanitizeString(record.id);
  const label = sanitizeString(record.label);
  return {
    type,
    id: id ?? undefined,
    label: label ?? undefined,
  };
}

function sanitizeTarget(value: unknown): AdminActivityTarget | null {
  if (!value || typeof value !== 'object') {
    return null;
  }
  const record = value as Record<string, unknown>;
  const type = sanitizeString(record.type);
  if (!type) {
    return null;
  }
  const id = sanitizeString(record.id);
  const label = sanitizeString(record.label);
  return {
    type,
    id: id ?? undefined,
    label: label ?? undefined,
  };
}

function sanitizeData(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  const record = value as Record<string, unknown>;
  const result: Record<string, unknown> = {};
  Object.entries(record).forEach(([key, entryValue]) => {
    if (!key || typeof key !== 'string') {
      return;
    }
    const normalizedKey = key.trim();
    if (!normalizedKey) {
      return;
    }
    if (normalizedKey.toLowerCase().includes('email')) {
      return;
    }
    if (
      entryValue === null ||
      typeof entryValue === 'string' ||
      typeof entryValue === 'number' ||
      typeof entryValue === 'boolean'
    ) {
      result[normalizedKey] = entryValue;
      return;
    }
    if (entryValue instanceof Timestamp) {
      result[normalizedKey] = entryValue.toDate().toISOString();
      return;
    }
    if (entryValue instanceof Date) {
      result[normalizedKey] = entryValue.toISOString();
      return;
    }
    if (Array.isArray(entryValue)) {
      const sanitizedArray = entryValue.filter((item) => {
        return (
          item === null ||
          typeof item === 'string' ||
          typeof item === 'number' ||
          typeof item === 'boolean'
        );
      });
      if (sanitizedArray.length > 0) {
        result[normalizedKey] = sanitizedArray.slice(0, 20);
      }
      return;
    }
    if (typeof entryValue === 'object') {
      const nested = sanitizeData(entryValue);
      if (nested && Object.keys(nested).length > 0) {
        result[normalizedKey] = nested;
      }
    }
  });
  return Object.keys(result).length > 0 ? result : null;
}

export function mapActivityEventDoc(doc: QueryDocumentSnapshot): AdminActivityEventRecord | null {
  const data = doc.data() as Record<string, unknown>;
  const timestamp = toDate(data.timestamp);
  if (!timestamp) {
    return null;
  }
  const segments = doc.ref.path.split('/');
  const gymId = segments.length >= 2 ? segments[1] : null;
  if (!gymId) {
    return null;
  }

  const eventTypeValue = data.eventType ?? (data as { type?: unknown }).type;
  const eventType = typeof eventTypeValue === 'string' ? eventTypeValue : 'unknown';
  const severityValue = data.severity;
  const severity:
    | ActivityEventSeverity
    | undefined = severityValue === 'warning' || severityValue === 'error' ? severityValue : 'info';
  const sourceValue = data.source;
  const source =
    sourceValue === 'device' ||
    sourceValue === 'app' ||
    sourceValue === 'backend' ||
    sourceValue === 'admin' ||
    sourceValue === 'system'
      ? sourceValue
      : 'system';
  const summary = sanitizeString(data.summary ?? (data as { description?: unknown }).description ?? (data as { message?: unknown }).message);
  const userId = sanitizeString(data.userId);
  const deviceId = sanitizeString(data.deviceId);
  const sessionId = sanitizeString(data.sessionId);
  const actor = sanitizeActor(data.actor);
  const targets = Array.isArray(data.targets)
    ? (data.targets
        .map((target) => sanitizeTarget(target))
        .filter((target): target is AdminActivityTarget => Boolean(target)) as AdminActivityTarget[])
    : undefined;
  const payload = sanitizeData(data.data);

  return {
    id: doc.id,
    gymId,
    timestamp,
    eventType,
    severity: severity ?? 'info',
    source,
    summary: summary ?? null,
    userId: userId ?? undefined,
    deviceId: deviceId ?? undefined,
    sessionId: sessionId ?? undefined,
    actor: actor ?? undefined,
    targets,
    data: payload ?? undefined,
  };
}

function buildBaseQuery(
  firestore: Firestore,
  gymId: string,
  filters: ActivityEventFilters,
  options?: { useCollectionGroup?: boolean }
): Query {
  const normalized = normalizeFilters(filters);

  let query: Query =
    options?.useCollectionGroup === false
      ? firestore.collection('gyms').doc(gymId).collection('activity')
      : firestore.collectionGroup('activity').where('gymId', '==', gymId);

  if (normalized.eventTypes.length === 1) {
    query = query.where('eventType', '==', normalized.eventTypes[0]!);
  } else if (normalized.eventTypes.length > 1) {
    query = query.where('eventType', 'in', normalized.eventTypes.slice(0, 10));
  }

  if (normalized.severity.length === 1) {
    query = query.where('severity', '==', normalized.severity[0]!);
  } else if (normalized.severity.length > 1) {
    query = query.where('severity', 'in', normalized.severity.slice(0, 10));
  }

  if (normalized.userId) {
    query = query.where('userId', '==', normalized.userId);
  }

  if (normalized.deviceId) {
    query = query.where('deviceId', '==', normalized.deviceId);
  }

  if (filters.from instanceof Date) {
    query = query.where('timestamp', '>=', Timestamp.fromDate(filters.from));
  }
  if (filters.to instanceof Date) {
    query = query.where('timestamp', '<=', Timestamp.fromDate(filters.to));
  }

  return query;
}

function parseCursor(value: string | null | undefined): CursorPayload | null {
  if (!value) {
    return null;
  }
  try {
    const decoded = Buffer.from(value, 'base64url').toString('utf8');
    const payload = JSON.parse(decoded) as Partial<CursorPayload>;
    if (!payload || typeof payload.ts !== 'string' || typeof payload.path !== 'string') {
      return null;
    }
    return { ts: payload.ts, path: payload.path };
  } catch {
    return null;
  }
}

function encodeCursor(doc: QueryDocumentSnapshot): string {
  const data = doc.data() as { timestamp?: unknown };
  const timestamp = toDate(data.timestamp);
  const payload: CursorPayload = {
    ts: timestamp ? timestamp.toISOString() : new Date().toISOString(),
    path: doc.ref.path,
  };
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

function clampLimit(value: number | null | undefined): number {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return DEFAULT_LIMIT;
  }
  return Math.min(Math.max(Math.floor(value), MIN_LIMIT), MAX_LIMIT);
}

type StartAfterArgs = [Timestamp, string];

function createStartAfterArgs(payload: CursorPayload | null): StartAfterArgs | null {
  if (!payload) {
    return null;
  }
  const cursorDate = new Date(payload.ts);
  if (Number.isNaN(cursorDate.getTime())) {
    return null;
  }
  const cursorDocId = payload.path.split('/').pop();
  if (!cursorDocId) {
    return null;
  }
  return [Timestamp.fromDate(cursorDate), cursorDocId];
}

function isFailedPrecondition(error: unknown): boolean {
  const code = (error as { code?: unknown }).code;
  if (typeof code === 'number') {
    return code === 9;
  }
  if (typeof code === 'string') {
    return code.toLowerCase() === 'failed-precondition';
  }
  const message = (error as { message?: unknown }).message;
  if (typeof message === 'string' && message.toLowerCase().includes('failed-precondition')) {
    return true;
  }
  const details = (error as { details?: unknown }).details;
  if (typeof details === 'string' && details.toLowerCase().includes('failed-precondition')) {
    return true;
  }
  return false;
}

function matchesNormalizedFilters(
  entry: AdminActivityEventRecord,
  normalized: NormalizedFilters
): boolean {
  if (normalized.eventTypes.length > 0 && !normalized.eventTypes.includes(entry.eventType)) {
    return false;
  }
  if (normalized.severity.length > 0 && !normalized.severity.includes(entry.severity)) {
    return false;
  }
  if (normalized.userId && entry.userId !== normalized.userId) {
    return false;
  }
  if (normalized.deviceId && entry.deviceId !== normalized.deviceId) {
    return false;
  }
  return true;
}

function createStats(): ActivityEventStats {
  return {
    total: 0,
    last24h: 0,
    last7d: 0,
    last30d: 0,
  };
}

export async function fetchActivityEventsForGym(
  gymId: string,
  filters: ActivityEventFilters
): Promise<ActivityEventQueryResult> {
  const firestore = adminDb();
  const limit = clampLimit(filters.limit);
  const cursorPayload = parseCursor(filters.cursor);
  const runPrimaryQuery = async (): Promise<ActivityEventQueryResult> => {
    const baseQuery = buildBaseQuery(firestore, gymId, filters);
    let itemsQuery = baseQuery.orderBy('timestamp', 'desc').orderBy(FieldPath.documentId(), 'desc');

    const startAfterArgs = createStartAfterArgs(cursorPayload);
    if (startAfterArgs) {
      itemsQuery = itemsQuery.startAfter(...startAfterArgs);
    }

    const snapshot = await itemsQuery.limit(limit + 1).get();
    const docs = snapshot.docs;
    const hasMore = docs.length > limit;
    const relevantDocs = hasMore ? docs.slice(0, limit) : docs;
    const items = relevantDocs
      .map((doc) => mapActivityEventDoc(doc))
      .filter((entry): entry is AdminActivityEventRecord => Boolean(entry));

    const stats = createStats();
    const warnings: string[] = [];

    const now = new Date();
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [totalSnapshot, daySnapshot, weekSnapshot, monthSnapshot] = await Promise.allSettled([
      baseQuery.count().get(),
      buildBaseQuery(firestore, gymId, { ...filters, from: dayAgo }).count().get(),
      buildBaseQuery(firestore, gymId, { ...filters, from: weekAgo }).count().get(),
      buildBaseQuery(firestore, gymId, { ...filters, from: monthAgo }).count().get(),
    ]);

    if (totalSnapshot.status === 'fulfilled') {
      stats.total = totalSnapshot.value.data().count ?? 0;
    } else {
      warnings.push('total-count-unavailable');
    }
    if (daySnapshot.status === 'fulfilled') {
      stats.last24h = daySnapshot.value.data().count ?? 0;
    } else {
      warnings.push('24h-count-unavailable');
    }
    if (weekSnapshot.status === 'fulfilled') {
      stats.last7d = weekSnapshot.value.data().count ?? 0;
    } else {
      warnings.push('7d-count-unavailable');
    }
    if (monthSnapshot.status === 'fulfilled') {
      stats.last30d = monthSnapshot.value.data().count ?? 0;
    } else {
      warnings.push('30d-count-unavailable');
    }

    return {
      items,
      nextCursor: hasMore ? encodeCursor(docs[docs.length - 1]!) : null,
      stats,
      warnings,
    };
  };

  const runFallbackQuery = async (): Promise<ActivityEventQueryResult> => {
    const normalized = normalizeFilters(filters);
    let baseQuery = firestore
      .collection('gyms')
      .doc(gymId)
      .collection('activity')
      .orderBy('timestamp', 'desc')
      .orderBy(FieldPath.documentId(), 'desc');

    if (filters.from instanceof Date) {
      baseQuery = baseQuery.where('timestamp', '>=', Timestamp.fromDate(filters.from));
    }
    if (filters.to instanceof Date) {
      baseQuery = baseQuery.where('timestamp', '<=', Timestamp.fromDate(filters.to));
    }

    const normalizedLimit = Math.min(500, Math.max(limit * 3, limit + 50));
    const maxIterations = 5;
    let iterations = 0;
    let exhausted = false;
    let cursorArgs = createStartAfterArgs(cursorPayload);
    let lastFetchedDoc: QueryDocumentSnapshot | null = null;
    const matches: { doc: QueryDocumentSnapshot; entry: AdminActivityEventRecord }[] = [];

    while (matches.length < limit + 1 && iterations < maxIterations) {
      let query: Query = baseQuery;
      if (cursorArgs) {
        query = query.startAfter(...cursorArgs);
      }

      const snapshot = await query.limit(normalizedLimit).get();
      if (snapshot.empty) {
        exhausted = true;
        break;
      }

      snapshot.docs.forEach((doc) => {
        const entry = mapActivityEventDoc(doc);
        lastFetchedDoc = doc;
        if (!entry) {
          return;
        }
        if (!matchesNormalizedFilters(entry, normalized)) {
          return;
        }
        matches.push({ doc, entry });
      });

      const trailingDoc = snapshot.docs[snapshot.docs.length - 1]!;
      const trailingTimestamp = toDate(trailingDoc.get('timestamp'));
      if (!trailingTimestamp) {
        exhausted = true;
        break;
      }
      cursorArgs = [Timestamp.fromDate(trailingTimestamp), trailingDoc.id];

      iterations += 1;
      if (snapshot.size < normalizedLimit) {
        exhausted = true;
        break;
      }
    }

    const warnings = new Set<string>([
      'index-required',
      'total-count-unavailable',
      '24h-count-unavailable',
      '7d-count-unavailable',
      '30d-count-unavailable',
    ]);

    const hasExtraMatch = matches.length > limit;
    const relevantMatches = hasExtraMatch ? matches.slice(0, limit) : matches;
    const items = relevantMatches.map((item) => item.entry);

    let nextCursor: string | null = null;
    if (hasExtraMatch) {
      nextCursor = encodeCursor(matches[matches.length - 1]!.doc);
    } else if (!exhausted && lastFetchedDoc) {
      nextCursor = encodeCursor(lastFetchedDoc);
    }

    return {
      items,
      nextCursor,
      stats: createStats(),
      warnings: Array.from(warnings),
    };
  };

  try {
    return await runPrimaryQuery();
  } catch (error) {
    if (isFailedPrecondition(error)) {
      try {
        return await runFallbackQuery();
      } catch (fallbackError) {
        if (isFailedPrecondition(fallbackError)) {
          throw error;
        }
        throw fallbackError;
      }
    }
    throw error;
  }
}
