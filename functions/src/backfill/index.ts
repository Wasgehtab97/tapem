import * as functions from 'firebase-functions';
import { runBackfill, runBackfillVerify } from './runtime';
import { BackfillRunParams, BackfillVerifyParams } from './types';

function parseBackfillRunParams(data: any): BackfillRunParams {
  const params: BackfillRunParams = {};
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

function parseBackfillVerifyParams(data: any): BackfillVerifyParams {
  if (!data || typeof data !== 'object' || typeof data.userId !== 'string' || !data.userId.trim()) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required for verification');
  }
  const params: BackfillVerifyParams = {
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

export const backfillRunCallable = functions.https.onCall(async (data) => {
  const params = parseBackfillRunParams(data);
  return runBackfill(params);
});

export const backfillVerifyCallable = functions.https.onCall(async (data) => {
  const params = parseBackfillVerifyParams(data);
  return runBackfillVerify(params);
});

export { runBackfill, runBackfillVerify } from './runtime';
