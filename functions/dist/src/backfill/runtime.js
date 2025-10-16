"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBackfill = runBackfill;
exports.runBackfillVerify = runBackfillVerify;
const firestore_1 = require("firebase-admin/firestore");
const build_1 = require("./build");
const report_1 = require("./report");
const scan_1 = require("./scan");
const write_1 = require("./write");
async function listGymIds(target) {
    if (target) {
        return [target];
    }
    const db = (0, firestore_1.getFirestore)();
    const snapshot = await db.collection('gyms').get();
    return snapshot.docs.map((doc) => doc.id);
}
function dailyToComparable(doc) {
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
function isDailyEqual(a, b) {
    return JSON.stringify(dailyToComparable(a)) === JSON.stringify(dailyToComparable(b));
}
function isDeviceContributionSatisfied(expected, actual) {
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
function filterDailyByRange(source, from, to) {
    if (!from && !to) {
        return new Map(source);
    }
    const result = new Map();
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
async function applyArtifacts(artifacts, apply) {
    if (!apply) {
        return { attempted: 0, written: 0, skipped: 0 };
    }
    const writer = (0, write_1.createBackfillWriter)();
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
async function runBackfill(params) {
    const gymIds = await listGymIds(params.gymId);
    const scanResults = [];
    for (const gymId of gymIds) {
        const scan = await (0, scan_1.scanGym)(gymId, {
            from: params.from,
            to: params.to,
            userId: params.userId,
        });
        scanResults.push(scan);
    }
    const artifacts = (0, build_1.buildArtifacts)(scanResults);
    const writerStats = await applyArtifacts(artifacts, Boolean(params.apply));
    return (0, report_1.buildReport)(scanResults, artifacts, writerStats, Boolean(params.apply));
}
function parseDailySnapshot(userId, docId, data) {
    return {
        userId,
        dateKey: typeof data.dateKey === 'string' ? data.dateKey : docId,
        date: data.date instanceof firestore_1.Timestamp ? data.date : firestore_1.Timestamp.fromMillis(0),
        logCount: Number(data.logCount ?? 0),
        totalSessions: Number(data.totalSessions ?? 0),
        sessionCounts: data.sessionCounts || {},
        deviceCounts: data.deviceCounts || {},
        gymId: typeof data.gymId === 'string' ? data.gymId : 'unknown',
    };
}
function parseAggregateSnapshot(userId, data) {
    if (!data) {
        return null;
    }
    return {
        userId,
        gymId: typeof data.gymId === 'string' ? data.gymId : 'unknown',
        trainingDayCount: Number(data.trainingDayCount ?? 0),
        totalSessions: Number(data.totalSessions ?? 0),
        firstWorkoutDate: data.firstWorkoutDate instanceof firestore_1.Timestamp ? data.firstWorkoutDate : null,
        lastWorkoutDate: data.lastWorkoutDate instanceof firestore_1.Timestamp ? data.lastWorkoutDate : null,
        deviceCounts: data.deviceCounts || {},
    };
}
function parseDeviceSnapshot(gymId, deviceId, data) {
    if (!data) {
        return null;
    }
    return {
        gymId,
        deviceId,
        totalSessions: Number(data.totalSessions ?? 0),
        rangeCounts: data.rangeCounts || {},
        lastActive: data.lastActive instanceof firestore_1.Timestamp ? data.lastActive : null,
        recentDates: Array.isArray(data.recentDates)
            ? data.recentDates.map(String)
            : [],
    };
}
async function runBackfillVerify(params) {
    const db = (0, firestore_1.getFirestore)();
    const gymIds = await listGymIds();
    const scanResults = [];
    const userDeviceKeys = new Set();
    for (const gymId of gymIds) {
        const scan = await (0, scan_1.scanGym)(gymId, {
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
    const artifacts = (0, build_1.buildArtifacts)(scanResults);
    const fromTs = (0, scan_1.normalizeTimestamp)(params.from);
    const toTs = (0, scan_1.normalizeTimestamp)(params.to);
    const expectedDailyAll = new Map(Array.from(artifacts.daily.entries()).filter(([_, doc]) => doc.userId === params.userId));
    const expectedDaily = filterDailyByRange(expectedDailyAll, fromTs, toTs);
    const expectedAggregate = artifacts.aggregates.get(params.userId) ?? null;
    const expectedDevices = new Map(Array.from(artifacts.devices.entries()).filter(([key]) => userDeviceKeys.has(key)));
    let dailyQuery = db
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
    const actualDaily = new Map();
    dailySnap.forEach((doc) => {
        actualDaily.set(doc.id, parseDailySnapshot(params.userId, doc.id, doc.data()));
    });
    const missingDaily = [];
    const extraDaily = [];
    const mismatchedDaily = [];
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
    const deviceMissing = [];
    const deviceExtra = [];
    const deviceMismatched = [];
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
