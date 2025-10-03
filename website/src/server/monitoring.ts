import 'server-only';

import { GeoPoint, Timestamp, type DocumentSnapshot } from 'firebase-admin/firestore';

import { adminDb } from '@/src/server/firebase/admin';
import { fetchActivityEventsForGym } from '@/src/server/activity/events';
import type { ActivityEventStats, AdminActivityEventRecord } from '@/src/types/admin-activity';
import type {
  MonitoringGymFeature,
  MonitoringGymListItem,
  MonitoringGymsAggregates,
  MonitoringGymsFeatureCollection,
} from '@/src/types/monitoring';

export type MonitoringGymStatus = {
  status?: 'online' | 'offline' | 'degraded';
  checkins24h?: number;
  devicesOnline?: number;
  lastEventAt?: Date | null;
  updatedAt?: Date | null;
};

export type MonitoringGymSummary = {
  id: string;
  name: string;
  slug: string;
  code: string | null;
  countryCode: string | null;
  city?: string;
  state?: string;
  location: { lat: number; lng: number } | null;
  active: boolean;
  deviceCount: number | null;
  statusUpdatedAt: Date | null;
  status: MonitoringGymStatus | null;
};

export type FetchGymsForMapOptions = {
  requestId?: string;
};

export type FetchGymsForMapResult = MonitoringGymsFeatureCollection;

export type FetchGymMonitoringSummaryResult = MonitoringGymSummary | null;

export type FetchGymEventLogsOptions = {
  limit?: number;
  cursor?: string | null;
};

export type FetchGymEventLogsResult = {
  entries: AdminActivityEventRecord[];
  nextCursor: string | null;
  stats: ActivityEventStats;
  warnings: string[];
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
  const toPair = (lat: number, lng: number): { lat: number; lng: number } | null => {
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return null;
    }
    return { lat, lng };
  };
  if (value instanceof GeoPoint) {
    return toPair(value.latitude, value.longitude);
  }
  if (
    value &&
    typeof value === 'object' &&
    typeof (value as { latitude?: unknown }).latitude === 'number' &&
    typeof (value as { longitude?: unknown }).longitude === 'number'
  ) {
    return toPair((value as { latitude: number }).latitude, (value as { longitude: number }).longitude);
  }
  if (
    value &&
    typeof value === 'object' &&
    typeof (value as { lat?: unknown }).lat === 'number' &&
    typeof (value as { lng?: unknown }).lng === 'number'
  ) {
    return toPair((value as { lat: number }).lat, (value as { lng: number }).lng);
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
  const updatedAt = toDate(record.updatedAt ?? (record as { lastUpdatedAt?: unknown }).lastUpdatedAt) ?? null;
  if (!status && checkins24h === undefined && devicesOnline === undefined && !lastEventAt && !updatedAt) {
    return null;
  }
  return {
    status,
    checkins24h,
    devicesOnline,
    lastEventAt,
    updatedAt,
  };
}

function mergeStatus(primary: MonitoringGymStatus | null, secondary: MonitoringGymStatus | null): MonitoringGymStatus | null {
  if (!primary && !secondary) {
    return null;
  }
  let updatedAt: Date | null = null;
  const primaryUpdated = primary?.updatedAt ?? null;
  const secondaryUpdated = secondary?.updatedAt ?? null;
  if (primaryUpdated && secondaryUpdated) {
    updatedAt = primaryUpdated >= secondaryUpdated ? primaryUpdated : secondaryUpdated;
  } else {
    updatedAt = primaryUpdated ?? secondaryUpdated ?? null;
  }
  return {
    status: primary?.status ?? secondary?.status,
    checkins24h: primary?.checkins24h ?? secondary?.checkins24h,
    devicesOnline: primary?.devicesOnline ?? secondary?.devicesOnline,
    lastEventAt: primary?.lastEventAt ?? secondary?.lastEventAt ?? null,
    updatedAt,
  };
}

function parseStatusSnapshot(
  snapshot: DocumentSnapshot | QueryDocumentSnapshot | null | undefined
): MonitoringGymStatus | null {
  if (!snapshot || !snapshot.exists) {
    return null;
  }
  const data = snapshot.data();
  if (!data) {
    return null;
  }
  const record = data as Record<string, unknown>;
  const key = record.key;
  if (typeof key === 'string' && key !== 'current') {
    return null;
  }
  return parseStatus(record);
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

const DACH_COUNTRY_CODES = ['DE', 'AT', 'CH', 'GB'] as const;

export async function fetchGymsForMap(options?: FetchGymsForMapOptions): Promise<FetchGymsForMapResult> {
  const firestore = adminDb();
  const requestId = options?.requestId;
  const debug = process.env.TAPEM_DEBUG === '1';
  const logPrefix = `[admin-monitoring]${requestId ? ` ${requestId}` : ''}`;

  const gymsSnapshot = await firestore
    .collection('gyms')
    .where('countryCode', 'in', Array.from(DACH_COUNTRY_CODES))
    .get();

  if (debug) {
    console.debug(`${logPrefix} gyms-query size=${gymsSnapshot.size}`);
  }

  const statusEntries = await Promise.all(
    gymsSnapshot.docs.map(async (doc) => {
      const [rootStatusSnapshot, nestedStatusSnapshot] = await Promise.all([
        firestore
          .collection('gymStatus')
          .doc(doc.id)
          .get()
          .catch((error) => {
            if (debug) {
              console.warn(`${logPrefix} gymStatus read failed for ${doc.id}`, error);
            }
            return null;
          }),
        doc.ref
          .collection('status')
          .doc('current')
          .get()
          .catch((error) => {
            if (debug) {
              console.warn(`${logPrefix} nested status read failed for ${doc.id}`, error);
            }
            return null;
          }),
      ]);

      const rootStatus = parseStatusSnapshot(rootStatusSnapshot);
      const nestedStatus = parseStatusSnapshot(nestedStatusSnapshot);
      const status = mergeStatus(rootStatus, nestedStatus);
      return { id: doc.id, status } as const;
    })
  );

  const statusMap = new Map<string, MonitoringGymStatus | null>();
  statusEntries.forEach((entry) => {
    statusMap.set(entry.id, entry.status ?? null);
  });

  const features: MonitoringGymFeature[] = [];
  const listItems: MonitoringGymListItem[] = [];
  const aggregates: MonitoringGymsAggregates = {
    total: 0,
    withCoords: 0,
    withoutCoords: 0,
  };

  gymsSnapshot.docs.forEach((doc) => {
    const data = doc.data() as Record<string, unknown>;
    const location = parseGeoPoint(data.location);
    const name = typeof data.name === 'string' && data.name.trim().length > 0 ? data.name : `Gym ${doc.id}`;
    const slug = typeof data.slug === 'string' && data.slug.trim().length > 0 ? data.slug : doc.id;
    const code = typeof data.code === 'string' && data.code.trim().length > 0 ? data.code : null;
    const active = typeof data.active === 'boolean' ? data.active : true;
    const status = statusMap.get(doc.id) ?? null;
    const statusUpdatedAt = status?.updatedAt ?? null;
    const countryCodeRaw = typeof data.countryCode === 'string' && data.countryCode.trim().length > 0 ? data.countryCode : null;
    const countryCode = countryCodeRaw ?? 'DE';

    aggregates.total += 1;
    if (location) {
      aggregates.withCoords += 1;
    } else {
      aggregates.withoutCoords += 1;
      if (debug) {
        console.debug(`${logPrefix} missing-location gym=${doc.id}`);
      }
    }

    listItems.push({
      id: doc.id,
      name,
      slug,
      code,
      countryCode: countryCodeRaw,
      active,
      location,
      statusUpdatedAt: statusUpdatedAt ? statusUpdatedAt.toISOString() : null,
    });

    if (!location || !active) {
      return;
    }

    const feature: MonitoringGymFeature = {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [location.lng, location.lat],
      },
      properties: {
        id: doc.id,
        name,
        slug,
        code,
        countryCode,
        active,
        statusUpdatedAt: statusUpdatedAt ? statusUpdatedAt.toISOString() : null,
      },
    };

    features.push(feature);
  });

  return {
    type: 'FeatureCollection',
    features,
    aggregates,
    gyms: listItems,
  };
}

export async function fetchGymMonitoringSummary(gymId: string): Promise<FetchGymMonitoringSummaryResult> {
  const firestore = adminDb();
  const debug = process.env.TAPEM_DEBUG === '1';
  const gymRef = firestore.collection('gyms').doc(gymId);
  const logPrefix = `[admin-monitoring] gym-detail ${gymId}`;

  const [gymSnapshot, rootStatusSnapshot, nestedStatusSnapshot, deviceCount] = await Promise.all([
    gymRef.get(),
    firestore
      .collection('gymStatus')
      .doc(gymId)
      .get()
      .catch(() => null),
    gymRef
      .collection('status')
      .doc('current')
      .get()
      .catch(() => null),
    gymRef
      .collection('devices')
      .count()
      .get()
      .then((snapshot) => snapshot.data().count ?? 0)
      .catch(async (error) => {
        if (debug) {
          console.warn(`${logPrefix} devices-count query failed`, error);
        }
        try {
          const fallbackSnapshot = await gymRef.collection('devices').select('__name__').get();
          return fallbackSnapshot.size;
        } catch (fallbackError) {
          if (debug) {
            console.warn(`${logPrefix} devices-count fallback failed`, fallbackError);
          }
          return null;
        }
      }),
  ]);

  if (!gymSnapshot.exists) {
    return null;
  }

  const data = gymSnapshot.data() as Record<string, unknown>;
  const name = typeof data.name === 'string' && data.name.trim().length > 0 ? data.name : `Gym ${gymId}`;
  const slug = typeof data.slug === 'string' && data.slug.trim().length > 0 ? data.slug : gymId;
  const code = typeof data.code === 'string' && data.code.trim().length > 0 ? data.code : null;
  const city = typeof data.city === 'string' && data.city.trim().length > 0 ? data.city : undefined;
  const state = typeof data.state === 'string' && data.state.trim().length > 0 ? data.state : undefined;
  const active = typeof data.active === 'boolean' ? data.active : true;
  const countryCode = typeof data.countryCode === 'string' && data.countryCode.trim().length > 0 ? data.countryCode : null;
  const location = parseGeoPoint(data.location);

  const rootStatus = parseStatusSnapshot(rootStatusSnapshot);
  const nestedStatus = parseStatusSnapshot(nestedStatusSnapshot);
  const status = mergeStatus(rootStatus, nestedStatus);
  const statusUpdatedAt = status?.updatedAt ?? null;

  return {
    id: gymId,
    name,
    slug,
    code,
    countryCode,
    city,
    state,
    location,
    active,
    deviceCount: typeof deviceCount === 'number' ? deviceCount : null,
    statusUpdatedAt,
    status,
  };
}

export async function fetchGymEventLogs(
  gymId: string,
  options?: FetchGymEventLogsOptions
): Promise<FetchGymEventLogsResult> {
  try {
    const result = await fetchActivityEventsForGym(gymId, {
      limit: options?.limit ?? 50,
      cursor: options?.cursor ?? null,
    });

    return {
      entries: result.items,
      nextCursor: result.nextCursor,
      stats: result.stats,
      warnings: result.warnings,
    };
  } catch (error) {
    if (isFailedPrecondition(error)) {
      console.warn(`[admin-monitoring] activity index fehlt für ${gymId}`, error);
      return {
        entries: [],
        nextCursor: null,
        stats: { total: 0, last24h: 0, last7d: 0, last30d: 0 },
        warnings: ['index-required'],
      };
    }
    console.error(`[admin-monitoring] activity abruf fehlgeschlagen für ${gymId}`, error);
    return {
      entries: [],
      nextCursor: null,
      stats: { total: 0, last24h: 0, last7d: 0, last30d: 0 },
      warnings: ['fetch-failed'],
    };
  }
}
