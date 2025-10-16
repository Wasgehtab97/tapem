"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildArtifacts = buildArtifacts;
const firestore_1 = require("firebase-admin/firestore");
function cloneSessionAccumulator(source) {
    return {
        count: source.count,
        deviceCounts: new Map(source.deviceCounts),
        gymCounts: new Map(source.gymCounts),
    };
}
function cloneDayAccumulator(source) {
    return {
        userId: source.userId,
        dayKey: source.dayKey,
        dayTimestamp: source.dayTimestamp,
        timezone: source.timezone,
        logCount: source.logCount,
        sessionCounts: new Map(Array.from(source.sessionCounts.entries()).map(([sessionId, session]) => [
            sessionId,
            cloneSessionAccumulator(session),
        ])),
        deviceCounts: new Map(source.deviceCounts),
        gymCounts: new Map(source.gymCounts),
        sessionIds: new Set(source.sessionIds),
    };
}
function mergeSessionAccumulator(target, incoming) {
    target.count += incoming.count;
    for (const [deviceId, count] of incoming.deviceCounts.entries()) {
        target.deviceCounts.set(deviceId, (target.deviceCounts.get(deviceId) ?? 0) + count);
    }
    for (const [gymId, count] of incoming.gymCounts.entries()) {
        target.gymCounts.set(gymId, (target.gymCounts.get(gymId) ?? 0) + count);
    }
}
function mergeDayAccumulator(target, incoming) {
    target.logCount += incoming.logCount;
    incoming.sessionIds.forEach((sessionId) => target.sessionIds.add(sessionId));
    for (const [sessionId, session] of incoming.sessionCounts.entries()) {
        const existing = target.sessionCounts.get(sessionId);
        if (existing) {
            mergeSessionAccumulator(existing, session);
        }
        else {
            target.sessionCounts.set(sessionId, cloneSessionAccumulator(session));
        }
    }
    for (const [deviceId, count] of incoming.deviceCounts.entries()) {
        target.deviceCounts.set(deviceId, (target.deviceCounts.get(deviceId) ?? 0) + count);
    }
    for (const [gymId, count] of incoming.gymCounts.entries()) {
        target.gymCounts.set(gymId, (target.gymCounts.get(gymId) ?? 0) + count);
    }
}
function cloneDeviceAccumulator(source) {
    return {
        gymId: source.gymId,
        deviceId: source.deviceId,
        sessions: new Map(Array.from(source.sessions.entries()).map(([sessionId, record]) => [
            sessionId,
            {
                count: record.count,
                lastTimestamp: record.lastTimestamp,
                dayKeys: new Set(record.dayKeys),
            },
        ])),
        lastActive: source.lastActive,
        dayKeys: new Set(source.dayKeys),
        userIds: new Set(source.userIds),
    };
}
function mergeDeviceAccumulator(target, incoming) {
    if (target.lastActive === null) {
        target.lastActive = incoming.lastActive;
    }
    else if (incoming.lastActive !== null) {
        target.lastActive = Math.max(target.lastActive, incoming.lastActive);
    }
    for (const dayKey of incoming.dayKeys) {
        target.dayKeys.add(dayKey);
    }
    for (const userId of incoming.userIds) {
        target.userIds.add(userId);
    }
    for (const [sessionId, record] of incoming.sessions.entries()) {
        const existing = target.sessions.get(sessionId);
        if (existing) {
            existing.count += record.count;
            existing.lastTimestamp = Math.max(existing.lastTimestamp, record.lastTimestamp);
            record.dayKeys.forEach((key) => existing.dayKeys.add(key));
        }
        else {
            target.sessions.set(sessionId, {
                count: record.count,
                lastTimestamp: record.lastTimestamp,
                dayKeys: new Set(record.dayKeys),
            });
        }
    }
}
function pickDominant(map) {
    let dominant = null;
    let dominantCount = -1;
    for (const [key, count] of map.entries()) {
        if (count > dominantCount) {
            dominant = key;
            dominantCount = count;
            continue;
        }
        if (count === dominantCount && dominant !== null && key < dominant) {
            dominant = key;
        }
    }
    return dominant ?? 'unknown';
}
function mapToRecord(map) {
    const result = {};
    for (const [key, value] of map.entries()) {
        result[key] = value;
    }
    return result;
}
function buildDailySummaries(dayMap) {
    const result = new Map();
    for (const day of dayMap.values()) {
        const sessionCounts = {};
        for (const [sessionId, session] of day.sessionCounts.entries()) {
            const deviceId = pickDominant(session.deviceCounts);
            const gymId = pickDominant(session.gymCounts);
            sessionCounts[sessionId] = {
                count: session.count,
                gymId,
                deviceId,
            };
        }
        const totalSessions = day.sessionIds.size;
        const gymId = pickDominant(day.gymCounts);
        const doc = {
            userId: day.userId,
            dateKey: day.dayKey,
            date: day.dayTimestamp,
            logCount: day.logCount,
            totalSessions,
            sessionCounts,
            deviceCounts: mapToRecord(day.deviceCounts),
            gymId,
        };
        result.set(`${day.userId}::${day.dayKey}`, doc);
    }
    return result;
}
function buildAggregateSummaries(daily) {
    const aggregates = new Map();
    const gymCounters = new Map();
    for (const doc of daily.values()) {
        let aggregate = aggregates.get(doc.userId);
        if (!aggregate) {
            aggregate = {
                userId: doc.userId,
                gymId: doc.gymId,
                trainingDayCount: 0,
                totalSessions: 0,
                firstWorkoutDate: null,
                lastWorkoutDate: null,
                deviceCounts: {},
            };
            aggregates.set(doc.userId, aggregate);
            gymCounters.set(doc.userId, new Map());
        }
        aggregate.trainingDayCount += 1;
        aggregate.totalSessions += doc.totalSessions;
        if (!aggregate.firstWorkoutDate || doc.date.toMillis() < aggregate.firstWorkoutDate.toMillis()) {
            aggregate.firstWorkoutDate = doc.date;
        }
        if (!aggregate.lastWorkoutDate || doc.date.toMillis() > aggregate.lastWorkoutDate.toMillis()) {
            aggregate.lastWorkoutDate = doc.date;
        }
        for (const [deviceId, count] of Object.entries(doc.deviceCounts)) {
            aggregate.deviceCounts[deviceId] = (aggregate.deviceCounts[deviceId] ?? 0) + count;
        }
        const gymCounter = gymCounters.get(doc.userId);
        gymCounter.set(doc.gymId, (gymCounter.get(doc.gymId) ?? 0) + doc.logCount);
    }
    for (const [userId, aggregate] of aggregates.entries()) {
        const gymCounter = gymCounters.get(userId);
        aggregate.gymId = pickDominant(gymCounter);
    }
    return aggregates;
}
function buildDeviceUsageSummaries(devices) {
    const result = new Map();
    const now = Date.now();
    const thresholds = {
        last7: now - 7 * 24 * 60 * 60 * 1000,
        last30: now - 30 * 24 * 60 * 60 * 1000,
        last90: now - 90 * 24 * 60 * 60 * 1000,
        last365: now - 365 * 24 * 60 * 60 * 1000,
    };
    for (const device of devices.values()) {
        const rangeCounts = {
            last7: 0,
            last30: 0,
            last90: 0,
            last365: 0,
            all: 0,
        };
        for (const record of device.sessions.values()) {
            rangeCounts.all += 1;
            if (record.lastTimestamp >= thresholds.last7) {
                rangeCounts.last7 += 1;
            }
            if (record.lastTimestamp >= thresholds.last30) {
                rangeCounts.last30 += 1;
            }
            if (record.lastTimestamp >= thresholds.last90) {
                rangeCounts.last90 += 1;
            }
            if (record.lastTimestamp >= thresholds.last365) {
                rangeCounts.last365 += 1;
            }
        }
        const recentDates = Array.from(device.dayKeys);
        recentDates.sort((a, b) => (a < b ? 1 : a > b ? -1 : 0));
        const doc = {
            gymId: device.gymId,
            deviceId: device.deviceId,
            totalSessions: device.sessions.size,
            rangeCounts,
            lastActive: device.lastActive ? firestore_1.Timestamp.fromMillis(device.lastActive) : null,
            recentDates,
        };
        result.set(`${device.gymId}::${device.deviceId}`, doc);
    }
    return result;
}
function extractMultiGym(dayMap) {
    const result = {};
    for (const day of dayMap.values()) {
        if (day.gymCounts.size <= 1) {
            continue;
        }
        const gyms = Array.from(day.gymCounts.keys()).sort();
        if (!result[day.userId]) {
            result[day.userId] = {};
        }
        result[day.userId][day.dayKey] = gyms;
    }
    return result;
}
function buildArtifacts(scanResults) {
    const combinedDays = new Map();
    const combinedDevices = new Map();
    for (const result of scanResults) {
        for (const [key, day] of result.days.entries()) {
            const existing = combinedDays.get(key);
            if (existing) {
                mergeDayAccumulator(existing, day);
            }
            else {
                combinedDays.set(key, cloneDayAccumulator(day));
            }
        }
        for (const [key, device] of result.devices.entries()) {
            const existing = combinedDevices.get(key);
            if (existing) {
                mergeDeviceAccumulator(existing, device);
            }
            else {
                combinedDevices.set(key, cloneDeviceAccumulator(device));
            }
        }
    }
    const daily = buildDailySummaries(combinedDays);
    const aggregates = buildAggregateSummaries(daily);
    const devices = buildDeviceUsageSummaries(combinedDevices);
    const multiGymPerDay = extractMultiGym(combinedDays);
    return {
        daily,
        aggregates,
        devices,
        multiGymPerDay,
    };
}
