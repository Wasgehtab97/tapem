import 'server-only';

import { FieldPath, GeoPoint, Timestamp, type QueryDocumentSnapshot } from 'firebase-admin/firestore';

import { adminDb } from '@/src/server/firebase/admin';
import type { AdminEventLogEntry } from '@/src/server/admin/dashboard-data';

export type MonitoringGymStatus = {
  status?: 'online' | 'offline' | 'degraded';
  checkins24h?: number;
  devicesOnline?: number;
  lastEventAt?: Date | null;
};

export type MonitoringGymSummary = {
  id: string;
  name: string;
  slug: string;
  city?: string;
  state?: string;
  location: { lat: number; lng: number } | null;
  active: boolean;
  status: MonitoringGymStatus | null;
};

export type MapGymFeature = Omit<MonitoringGymSummary, 'location' | 'status'> & {
  location: { lat: number; lng: number };
  status: MonitoringGymStatus | null;
};

export type FetchGymsForMapResult = {
  gyms: MapGymFeature[];
  total: number;
  missingLocation: number;
};

export type FetchGymMonitoringSummaryResult = MonitoringGymSummary | null;

export type FetchGymEventLogsOptions = {
  limit?: number;
  cursor?: string | null;
};

export type FetchGymEventLogsResult = {
  entries: AdminEventLogEntry[];
  nextCursor: string | null;
  error?: string;
};

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

function parseGeoPoint(value: unknown): { lat: number; lng: number } | null {
  if (value instanceof GeoPoint) {
    return { lat: value.latitude, lng: value.longitude };
  }
  if (
    value &&
    typeof value === 'object' &&
    typeof (value as { latitude?: unknown }).latitude === 'number' &&
    typeof (value as { longitude?: unknown }).longitude === 'number'
  ) {
    return {
      lat: (value as { latitude: number }).latitude,
      lng: (value as { longitude: number }).longitude,
    };
  }
  if (
    value &&
    typeof value === 'object' &&
    typeof (value as { lat?: unknown }).lat === 'number' &&
    typeof (value as { lng?: unknown }).lng === 'number'
  ) {
    return {
      lat: (value as { lat: number }).lat,
      lng: (value as { lng: number }).lng,
    };
  }
  return null;
}

function parseStatus(data: unknown): MonitoringGymStatus | null {
  if (!data || typeof data !== 'object') {
    return null;
  }
  const record = data as Record<string, unknown>;
  const statusRaw = record.status;
  const status =
    statusRaw === 'online' || statusRaw === 'offline' || statusRaw === 'degraded'
      ? statusRaw
      : undefined;
  const checkins24h = typeof record.checkins24h === 'number' ? record.checkins24h : undefined;
  const devicesOnline = typeof record.devicesOnline === 'number' ? record.devicesOnline : undefined;
  const lastEventAt = toDate(record.lastEventAt) ?? null;
  if (!status && checkins24h === undefined && devicesOnline === undefined && !lastEventAt) {
    return null;
  }
  return {
    status,
    checkins24h,
    devicesOnline,
    lastEventAt,
  };
}

function mergeStatus(primary: MonitoringGymStatus | null, secondary: MonitoringGymStatus | null): MonitoringGymStatus | null {
  if (!primary && !secondary) {
    return null;
  }
  return {
    status: primary?.status ?? secondary?.status,
    checkins24h: primary?.checkins24h ?? secondary?.checkins24h,
    devicesOnline: primary?.devicesOnline ?? secondary?.devicesOnline,
    lastEventAt: primary?.lastEventAt ?? secondary?.lastEventAt ?? null,
  };
}

function encodeCursor(path: string): string {
  return Buffer.from(path, 'utf8').toString('base64url');
}

function decodeCursor(value: string | null | undefined): string | null {
  if (!value) {
    return null;
  }
  try {
    const decoded = Buffer.from(value, 'base64url').toString('utf8');
    if (!decoded.startsWith('gyms/')) {
      return null;
    }
    if (!decoded.includes('/logs/')) {
      return null;
    }
    return decoded;
  } catch {
    return null;
  }
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
  if (typeof message === 'string') {
    return message.toLowerCase().includes('failed_precondition');
  }
  const details = (error as { details?: unknown }).details;
  if (typeof details === 'string') {
    return details.toLowerCase().includes('failed_precondition');
  }
  return false;
}

export async function fetchGymsForMap(): Promise<FetchGymsForMapResult> {
  const firestore = adminDb();
  const [gymsSnapshot, rootStatusSnapshot, nestedStatusSnapshot] = await Promise.all([
    firestore.collection('gyms').get(),
    firestore.collection('gymStatus').get().catch(() => null),
    firestore
      .collectionGroup('status')
      .where(FieldPath.documentId(), '==', 'current')
      .get()
      .catch(() => null),
  ]);

  const total = gymsSnapshot.size;
  let missingLocation = 0;
  const statusMap = new Map<string, MonitoringGymStatus | null>();

  if (rootStatusSnapshot) {
    rootStatusSnapshot.docs.forEach((doc) => {
      statusMap.set(doc.id, parseStatus(doc.data()));
    });
  }

  if (nestedStatusSnapshot) {
    nestedStatusSnapshot.docs.forEach((doc) => {
      const parent = doc.ref.parent?.parent;
      const gymId = parent?.id;
      if (!gymId) {
        return;
      }
      const parsed = parseStatus(doc.data());
      const existing = statusMap.get(gymId) ?? null;
      statusMap.set(gymId, mergeStatus(parsed, existing));
    });
  }

  const gyms: MapGymFeature[] = [];

  gymsSnapshot.docs.forEach((doc) => {
    const data = doc.data() as Record<string, unknown>;
    const location = parseGeoPoint(data.location);
    if (!location) {
      missingLocation += 1;
      return;
    }

    const name = typeof data.name === 'string' && data.name.trim().length > 0 ? data.name : `Gym ${doc.id}`;
    const slug = typeof data.slug === 'string' && data.slug.trim().length > 0 ? data.slug : doc.id;
    const city = typeof data.city === 'string' && data.city.trim().length > 0 ? data.city : undefined;
    const state = typeof data.state === 'string' && data.state.trim().length > 0 ? data.state : undefined;
    const active = typeof data.active === 'boolean' ? data.active : true;
    const status = statusMap.get(doc.id) ?? null;

    gyms.push({
      id: doc.id,
      name,
      slug,
      city,
      state,
      location,
      active,
      status,
    });
  });

  return {
    gyms,
    total,
    missingLocation,
  };
}

export async function fetchGymMonitoringSummary(gymId: string): Promise<FetchGymMonitoringSummaryResult> {
  const firestore = adminDb();
  const gymRef = firestore.collection('gyms').doc(gymId);
  const [gymSnapshot, rootStatusSnapshot, nestedStatusSnapshot] = await Promise.all([
    gymRef.get(),
    firestore.collection('gymStatus').doc(gymId).get().catch(() => null),
    gymRef.collection('status').doc('current').get().catch(() => null),
  ]);

  if (!gymSnapshot.exists) {
    return null;
  }

  const data = gymSnapshot.data() as Record<string, unknown>;
  const name = typeof data.name === 'string' && data.name.trim().length > 0 ? data.name : `Gym ${gymId}`;
  const slug = typeof data.slug === 'string' && data.slug.trim().length > 0 ? data.slug : gymId;
  const city = typeof data.city === 'string' && data.city.trim().length > 0 ? data.city : undefined;
  const state = typeof data.state === 'string' && data.state.trim().length > 0 ? data.state : undefined;
  const active = typeof data.active === 'boolean' ? data.active : true;
  const location = parseGeoPoint(data.location);

  const rootStatus = rootStatusSnapshot?.exists ? parseStatus(rootStatusSnapshot.data()) : null;
  const nestedStatus = nestedStatusSnapshot?.exists ? parseStatus(nestedStatusSnapshot.data()) : null;
  const status = mergeStatus(rootStatus, nestedStatus);

  return {
    id: gymId,
    name,
    slug,
    city,
    state,
    location,
    active,
    status,
  };
}

function mapEventDoc(doc: QueryDocumentSnapshot): AdminEventLogEntry | null {
  const data = doc.data() as Record<string, unknown>;
  const timestampValue = data.timestamp ?? (data as { timestamp?: unknown }).timestamp;
  const timestamp = toDate(timestampValue);
  if (!timestamp) {
    return null;
  }
  const segments = doc.ref.path.split('/');
  const gymId = segments.length >= 2 ? segments[1] : undefined;
  const deviceId = segments.length >= 4 ? segments[3] : undefined;
  const typeValue = data.type ?? (data as { eventType?: unknown }).eventType;
  const type = typeof typeValue === 'string' ? typeValue : undefined;
  const descriptionValue =
    typeof data.description === 'string'
      ? data.description
      : typeof (data as { message?: unknown }).message === 'string'
      ? ((data as { message: string }).message as string)
      : undefined;

  return {
    id: doc.id,
    timestamp,
    gymId,
    deviceId,
    type,
    description: descriptionValue,
  };
}

export async function fetchGymEventLogs(
  gymId: string,
  options?: FetchGymEventLogsOptions
): Promise<FetchGymEventLogsResult> {
  const firestore = adminDb();
  const pageSize = Math.min(Math.max(options?.limit ?? 20, 1), 100);
  const cursorPath = decodeCursor(options?.cursor);

  try {
    let query = firestore
      .collectionGroup('logs')
      .where('gymId', '==', gymId)
      .orderBy('timestamp', 'desc');

    if (cursorPath && cursorPath.includes(`/gyms/${gymId}/`)) {
      const cursorSnapshot = await firestore.doc(cursorPath).get();
      if (cursorSnapshot.exists) {
        query = query.startAfter(cursorSnapshot);
      }
    }

    const snapshot = await query.limit(pageSize + 1).get();
    const docs = snapshot.docs;
    const hasMore = docs.length > pageSize;
    const relevantDocs = hasMore ? docs.slice(0, pageSize) : docs;
    const entries = relevantDocs
      .map((doc) => mapEventDoc(doc))
      .filter((entry): entry is AdminEventLogEntry => Boolean(entry));
    const nextCursor = hasMore ? encodeCursor(docs[docs.length - 1].ref.path) : null;

    return { entries, nextCursor };
  } catch (error) {
    if (isFailedPrecondition(error)) {
      console.warn(`[admin-monitoring] event-log index fehlt für ${gymId}`, error);
      return { entries: [], nextCursor: null, error: 'Index erforderlich' };
    }
    console.error(`[admin-monitoring] event-log abruf fehlgeschlagen für ${gymId}`, error);
    return { entries: [], nextCursor: null, error: 'Abruf fehlgeschlagen' };
  }
}
