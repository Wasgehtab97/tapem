"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createBackfillWriter = createBackfillWriter;
const crypto_1 = __importDefault(require("crypto"));
const firestore_1 = require("firebase-admin/firestore");
function stableSerialize(value) {
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
    if (typeof value === 'object' && 'toMillis' in value && typeof value.toMillis === 'function') {
        return JSON.stringify(value.toMillis());
    }
    if (typeof value === 'object') {
        const obj = value;
        const keys = Object.keys(obj).sort();
        return `{${keys
            .map((key) => `${JSON.stringify(key)}:${stableSerialize(obj[key])}`)
            .join(',')}}`;
    }
    return JSON.stringify(String(value));
}
function createHash(payload) {
    return crypto_1.default.createHash('md5').update(stableSerialize(payload)).digest('hex');
}
function createWriter() {
    const db = (0, firestore_1.getFirestore)();
    const writer = db.bulkWriter();
    return {
        writer,
        stats: { attempted: 0, written: 0, skipped: 0 },
    };
}
async function upsertWithHash(writer, ref, payload, hashPayload, stats) {
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
    await writer.set(ref, { ...payload, _hash: hash, updatedAt: firestore_1.FieldValue.serverTimestamp() });
    stats.written += 1;
}
function dailyHashPayload(doc) {
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
function aggregateHashPayload(doc) {
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
function deviceHashPayload(doc) {
    return {
        gymId: doc.gymId,
        deviceId: doc.deviceId,
        totalSessions: doc.totalSessions,
        rangeCounts: doc.rangeCounts,
        lastActive: doc.lastActive,
        recentDates: doc.recentDates,
    };
}
function createBackfillWriter() {
    const context = createWriter();
    const db = (0, firestore_1.getFirestore)();
    return {
        stats: context.stats,
        upsertDailySummary: async (uid, doc) => {
            const ref = db
                .collection('trainingSummary')
                .doc(uid)
                .collection('daily')
                .doc(doc.dateKey);
            await upsertWithHash(context.writer, ref, doc, dailyHashPayload(doc), context.stats);
        },
        upsertAggregate: async (uid, doc) => {
            const ref = db
                .collection('trainingSummary')
                .doc(uid)
                .collection('aggregate')
                .doc('overview');
            await upsertWithHash(context.writer, ref, doc, aggregateHashPayload(doc), context.stats);
        },
        upsertDeviceUsage: async (gymId, doc) => {
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
