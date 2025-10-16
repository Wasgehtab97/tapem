"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizeTimestamp = normalizeTimestamp;
exports.scanGym = scanGym;
const firestore_1 = require("firebase-admin/firestore");
const DEFAULT_PAGE_SIZE = 500;
const ORPHAN_RECORD_LIMIT = 200;
function normalizeTimestamp(value) {
    if (!value) {
        return undefined;
    }
    if (value instanceof firestore_1.Timestamp) {
        return value;
    }
    if (value instanceof Date) {
        return firestore_1.Timestamp.fromDate(value);
    }
    if (typeof value === 'string') {
        const parsed = Date.parse(value);
        if (!Number.isNaN(parsed)) {
            return firestore_1.Timestamp.fromMillis(parsed);
        }
        return undefined;
    }
    if (typeof value === 'number') {
        return firestore_1.Timestamp.fromMillis(value);
    }
    return undefined;
}
async function fetchSessionMeta(db, gymId, userId, sessionId) {
    const snapshot = await db
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('session_meta')
        .doc(sessionId)
        .get();
    if (!snapshot.exists) {
        return null;
    }
    const data = snapshot.data() || {};
    const meta = {};
    if (typeof data.dayKey === 'string') {
        meta.dayKey = data.dayKey;
    }
    if (typeof data.timezone === 'string') {
        meta.timezone = data.timezone;
    }
    if (typeof data.offsetMinutes === 'number') {
        meta.offsetMinutes = data.offsetMinutes;
    }
    if (typeof data.utcOffsetMinutes === 'number' && meta.offsetMinutes === undefined) {
        meta.offsetMinutes = data.utcOffsetMinutes;
    }
    return meta;
}
function ensureDayAccumulator(map, userId, dayKey, dayTimestamp, timezone) {
    const key = `${userId}::${dayKey}`;
    if (!map.has(key)) {
        map.set(key, {
            userId,
            dayKey,
            dayTimestamp,
            timezone,
            logCount: 0,
            sessionCounts: new Map(),
            deviceCounts: new Map(),
            gymCounts: new Map(),
            sessionIds: new Set(),
        });
    }
    return map.get(key);
}
function ensureSessionAccumulator(map, sessionId) {
    if (!map.has(sessionId)) {
        map.set(sessionId, {
            count: 0,
            deviceCounts: new Map(),
            gymCounts: new Map(),
        });
    }
    return map.get(sessionId);
}
function ensureDeviceAccumulator(map, gymId, deviceId) {
    const key = `${gymId}::${deviceId}`;
    if (!map.has(key)) {
        map.set(key, {
            gymId,
            deviceId,
            sessions: new Map(),
            lastActive: null,
            dayKeys: new Set(),
            userIds: new Set(),
        });
    }
    return map.get(key);
}
function ensureDeviceSessionRecord(map, sessionId) {
    if (!map.has(sessionId)) {
        map.set(sessionId, {
            count: 0,
            lastTimestamp: 0,
            dayKeys: new Set(),
        });
    }
    return map.get(sessionId);
}
function resolveTimezone(meta, timezone) {
    if (meta?.timezone) {
        return meta.timezone;
    }
    if (timezone) {
        return timezone;
    }
    return 'UTC';
}
function resolveOffset(meta, offsetMinutes) {
    if (typeof meta?.offsetMinutes === 'number') {
        return meta.offsetMinutes;
    }
    if (typeof offsetMinutes === 'number') {
        return offsetMinutes;
    }
    return undefined;
}
function extractDayParts(millis, timezone) {
    try {
        const formatter = new Intl.DateTimeFormat('en-CA', {
            timeZone: timezone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
        });
        const parts = formatter.formatToParts(new Date(millis));
        const year = parts.find((p) => p.type === 'year')?.value;
        const month = parts.find((p) => p.type === 'month')?.value;
        const day = parts.find((p) => p.type === 'day')?.value;
        if (year && month && day) {
            return { dayKey: `${year}-${month}-${day}` };
        }
    }
    catch (error) {
        console.warn(`Failed to extract day parts for timezone ${timezone}:`, error);
    }
    const fallback = new Date(millis).toISOString().split('T')[0];
    return { dayKey: fallback };
}
function parseOffsetLabel(value) {
    const match = value.match(/(UTC|GMT)?([+-])(\d{1,2})(?::(\d{2}))?/i);
    if (!match) {
        if (/UTC|GMT/.test(value)) {
            return 0;
        }
        return undefined;
    }
    const sign = match[2] === '-' ? -1 : 1;
    const hours = Number(match[3] ?? 0);
    const minutes = Number(match[4] ?? 0);
    return sign * (hours * 60 + minutes);
}
function computeOffsetMinutes(timezone, millis) {
    try {
        const formatter = new Intl.DateTimeFormat('en-US', {
            timeZone: timezone,
            timeZoneName: 'shortOffset',
            hour: '2-digit',
        });
        const parts = formatter.formatToParts(new Date(millis));
        const tzName = parts.find((p) => p.type === 'timeZoneName')?.value;
        if (tzName) {
            const parsed = parseOffsetLabel(tzName);
            if (typeof parsed === 'number') {
                return parsed;
            }
        }
    }
    catch (error) {
        console.warn(`Failed to compute offset for timezone ${timezone}:`, error);
    }
    return undefined;
}
function buildDayTimestamp(dayKey, offsetMinutes) {
    const [yearStr, monthStr, dayStr] = dayKey.split('-');
    const year = Number(yearStr);
    const month = Number(monthStr);
    const day = Number(dayStr);
    const utcMillis = Date.UTC(year, month - 1, day, 0, 0, 0) - offsetMinutes * 60 * 1000;
    return firestore_1.Timestamp.fromMillis(utcMillis);
}
function deriveDayInfo(log) {
    const timezone = resolveTimezone(log.sessionMeta ?? undefined, log.timezone);
    const offsetFromMeta = resolveOffset(log.sessionMeta ?? undefined, log.offsetMinutes ?? undefined);
    if (log.sessionMeta?.dayKey) {
        const offset = typeof offsetFromMeta === 'number'
            ? offsetFromMeta
            : computeOffsetMinutes(timezone, log.timestamp.toMillis()) ?? 0;
        return {
            dayKey: log.sessionMeta.dayKey,
            dayTimestamp: buildDayTimestamp(log.sessionMeta.dayKey, offset),
            timezone,
        };
    }
    const dayParts = extractDayParts(log.timestamp.toMillis(), timezone);
    const offset = typeof offsetFromMeta === 'number'
        ? offsetFromMeta
        : computeOffsetMinutes(timezone, log.timestamp.toMillis()) ?? 0;
    return {
        dayKey: dayParts.dayKey,
        dayTimestamp: buildDayTimestamp(dayParts.dayKey, offset),
        timezone,
    };
}
async function scanGym(gymId, options = {}) {
    const db = (0, firestore_1.getFirestore)();
    const from = normalizeTimestamp(options.from);
    const to = normalizeTimestamp(options.to);
    const pageSize = options.pageSize ?? DEFAULT_PAGE_SIZE;
    const devicesSnapshot = await db
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .get();
    const dayMap = new Map();
    const deviceMap = new Map();
    const sessionMetaCache = new Map();
    const metrics = {
        totalLogs: 0,
        deviceLogCounts: new Map(),
        userLogCounts: new Map(),
        dayLogCounts: new Map(),
        orphans: [],
    };
    const dbFieldPath = firestore_1.FieldPath.documentId();
    for (const deviceDoc of devicesSnapshot.docs) {
        const deviceId = deviceDoc.id;
        let baseQuery = deviceDoc.ref
            .collection('logs')
            .orderBy('timestamp', 'asc')
            .orderBy(dbFieldPath, 'asc');
        if (from) {
            baseQuery = baseQuery.where('timestamp', '>=', from);
        }
        if (to) {
            baseQuery = baseQuery.where('timestamp', '<=', to);
        }
        let cursor = null;
        let hasMore = true;
        while (hasMore) {
            let query = baseQuery.limit(pageSize);
            if (cursor) {
                query = query.startAfter(cursor.timestamp, cursor.id);
            }
            const snapshot = await query.get();
            if (snapshot.empty) {
                break;
            }
            for (const doc of snapshot.docs) {
                const data = doc.data() || {};
                const timestamp = data.timestamp;
                if (!(timestamp instanceof firestore_1.Timestamp)) {
                    continue;
                }
                const userId = typeof data.userId === 'string' && data.userId ? data.userId : null;
                const sessionId = typeof data.sessionId === 'string' && data.sessionId ? data.sessionId : null;
                metrics.totalLogs += 1;
                if (!userId || !sessionId) {
                    if (metrics.orphans.length < ORPHAN_RECORD_LIMIT) {
                        metrics.orphans.push({
                            path: doc.ref.path,
                            reason: !userId ? 'missing-userId' : 'missing-sessionId',
                        });
                    }
                    continue;
                }
                if (options.userId && options.userId !== userId) {
                    continue;
                }
                const cacheKey = `${gymId}::${userId}::${sessionId}`;
                let sessionMeta = sessionMetaCache.get(cacheKey);
                if (sessionMeta === undefined) {
                    sessionMeta = await fetchSessionMeta(db, gymId, userId, sessionId).catch(() => null);
                    sessionMetaCache.set(cacheKey, sessionMeta ?? null);
                }
                const log = {
                    id: doc.id,
                    gymId,
                    deviceId,
                    timestamp,
                    userId,
                    sessionId,
                    timezone: typeof data.timezone === 'string' ? data.timezone : null,
                    offsetMinutes: typeof data.offsetMinutes === 'number'
                        ? data.offsetMinutes
                        : typeof data.utcOffsetMinutes === 'number'
                            ? data.utcOffsetMinutes
                            : null,
                    sessionMeta,
                };
                const dayInfo = deriveDayInfo(log);
                const dayKey = dayInfo.dayKey;
                const dayAccumulator = ensureDayAccumulator(dayMap, userId, dayKey, dayInfo.dayTimestamp, dayInfo.timezone);
                dayAccumulator.logCount += 1;
                dayAccumulator.sessionIds.add(sessionId);
                const sessionAccumulator = ensureSessionAccumulator(dayAccumulator.sessionCounts, sessionId);
                sessionAccumulator.count += 1;
                sessionAccumulator.deviceCounts.set(deviceId, (sessionAccumulator.deviceCounts.get(deviceId) ?? 0) + 1);
                sessionAccumulator.gymCounts.set(gymId, (sessionAccumulator.gymCounts.get(gymId) ?? 0) + 1);
                dayAccumulator.deviceCounts.set(deviceId, (dayAccumulator.deviceCounts.get(deviceId) ?? 0) + 1);
                dayAccumulator.gymCounts.set(gymId, (dayAccumulator.gymCounts.get(gymId) ?? 0) + 1);
                const deviceAccumulator = ensureDeviceAccumulator(deviceMap, gymId, deviceId);
                deviceAccumulator.userIds.add(userId);
                const sessionRecord = ensureDeviceSessionRecord(deviceAccumulator.sessions, sessionId);
                sessionRecord.count += 1;
                sessionRecord.lastTimestamp = Math.max(sessionRecord.lastTimestamp, timestamp.toMillis());
                sessionRecord.dayKeys.add(dayKey);
                deviceAccumulator.sessions.set(sessionId, sessionRecord);
                deviceAccumulator.dayKeys.add(dayKey);
                if (deviceAccumulator.lastActive === null) {
                    deviceAccumulator.lastActive = timestamp.toMillis();
                }
                else {
                    deviceAccumulator.lastActive = Math.max(deviceAccumulator.lastActive, timestamp.toMillis());
                }
                metrics.deviceLogCounts.set(`${gymId}::${deviceId}`, (metrics.deviceLogCounts.get(`${gymId}::${deviceId}`) ?? 0) + 1);
                metrics.userLogCounts.set(userId, (metrics.userLogCounts.get(userId) ?? 0) + 1);
                metrics.dayLogCounts.set(`${userId}::${dayKey}`, (metrics.dayLogCounts.get(`${userId}::${dayKey}`) ?? 0) + 1);
            }
            const lastDoc = snapshot.docs[snapshot.docs.length - 1];
            const lastTimestamp = lastDoc.get('timestamp');
            if (lastTimestamp instanceof firestore_1.Timestamp) {
                cursor = { timestamp: lastTimestamp, id: lastDoc.id };
            }
            else {
                cursor = null;
            }
            hasMore = snapshot.size >= pageSize;
        }
    }
    return {
        gymId,
        days: dayMap,
        devices: deviceMap,
        metrics,
    };
}
