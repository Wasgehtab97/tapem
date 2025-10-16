"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBackfillVerify = exports.runBackfill = exports.backfillVerifyCallable = exports.backfillRunCallable = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const runtime_1 = require("./runtime");
function parseBackfillRunParams(data) {
    const params = {};
    if (data && typeof data === 'object') {
        if (typeof data.gymId === 'string' && data.gymId.trim()) {
            params.gymId = data.gymId.trim();
        }
        if (typeof data.userId === 'string' && data.userId.trim()) {
            params.userId = data.userId.trim();
        }
        if (data.from) {
            params.from = data.from;
        }
        if (data.to) {
            params.to = data.to;
        }
        if (typeof data.apply === 'boolean') {
            params.apply = data.apply;
        }
    }
    return params;
}
function parseBackfillVerifyParams(data) {
    if (!data || typeof data !== 'object' || typeof data.userId !== 'string' || !data.userId.trim()) {
        throw new functions.https.HttpsError('invalid-argument', 'userId is required for verification');
    }
    const params = {
        userId: data.userId.trim(),
    };
    if (data.from) {
        params.from = data.from;
    }
    if (data.to) {
        params.to = data.to;
    }
    return params;
}
exports.backfillRunCallable = functions.https.onCall(async (data) => {
    const params = parseBackfillRunParams(data);
    return (0, runtime_1.runBackfill)(params);
});
exports.backfillVerifyCallable = functions.https.onCall(async (data) => {
    const params = parseBackfillVerifyParams(data);
    return (0, runtime_1.runBackfillVerify)(params);
});
var runtime_2 = require("./runtime");
Object.defineProperty(exports, "runBackfill", { enumerable: true, get: function () { return runtime_2.runBackfill; } });
Object.defineProperty(exports, "runBackfillVerify", { enumerable: true, get: function () { return runtime_2.runBackfillVerify; } });
