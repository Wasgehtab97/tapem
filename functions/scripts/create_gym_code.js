#!/usr/bin/env node
/**
 * Create a new rotating gym registration code for a gym.
 *
 * Usage (dry-run):
 *   KEY_FILE=./scripts/admin.json GYM_ID=lifthouse_koblenz node functions/scripts/create_gym_code.js
 *
 * Apply (writes to Firestore):
 *   KEY_FILE=./scripts/admin.json GYM_ID=lifthouse_koblenz node functions/scripts/create_gym_code.js --apply
 *
 * Options:
 *   --code=ABC123        Use a specific code (6 chars, readable charset recommended)
 *   --days=30            Expiration in days (default: 30)
 *   --next-month-start   Expire at start of next month (overrides --days)
 *   --grace-hours=24     Deactivate other active codes older than this (default: 24)
 */

const path = require('path');
const admin = require('firebase-admin');
const crypto = require('crypto');

const args = process.argv.slice(2);
const APPLY = args.includes('--apply');

function getArgValue(prefix) {
  const hit = args.find((a) => a.startsWith(prefix));
  if (!hit) return null;
  const [, value] = hit.split('=');
  return value ?? null;
}

const KEY_FILE = process.env.KEY_FILE || process.env.ADMIN_KEY_FILE || './scripts/admin.json';
const GYM_ID = process.env.GYM_ID || getArgValue('--gymId') || getArgValue('--gym-id');

const requestedCodeRaw = process.env.CODE || getArgValue('--code');
const daysRaw = process.env.DAYS || getArgValue('--days');
const graceHoursRaw = process.env.GRACE_HOURS || getArgValue('--grace-hours');
const NEXT_MONTH_START = args.includes('--next-month-start');

const readableChars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
const codeLength = 6;

function generateCode() {
  let code = '';
  for (let i = 0; i < codeLength; i++) {
    code += readableChars[crypto.randomInt(0, readableChars.length)];
  }
  return code;
}

function normalizeCode(code) {
  return String(code || '').trim().toUpperCase();
}

function parsePositiveInt(value, fallback) {
  const n = Number.parseInt(String(value ?? ''), 10);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return n;
}

function nextMonthStart(now = new Date()) {
  return new Date(now.getFullYear(), now.getMonth() + 1, 1);
}

function expiresAtDate(now) {
  if (NEXT_MONTH_START) return nextMonthStart(now);
  const days = parsePositiveInt(daysRaw, 30);
  const d = new Date(now);
  d.setDate(d.getDate() + days);
  return d;
}

function loadServiceAccount(keyFile) {
  const full = path.isAbsolute(keyFile) ? keyFile : path.resolve(process.cwd(), keyFile);
  // eslint-disable-next-line import/no-dynamic-require, global-require
  return require(full);
}

async function main() {
  if (!GYM_ID) {
    console.error('❌ Missing gym id. Set env GYM_ID=... (e.g. lifthouse_koblenz).');
    process.exit(1);
  }

  const nowDate = new Date();
  const expires = expiresAtDate(nowDate);
  const graceHours = parsePositiveInt(graceHoursRaw, 24);
  const graceThresholdDate = new Date(Date.now() - graceHours * 60 * 60 * 1000);

  const requestedCode = requestedCodeRaw ? normalizeCode(requestedCodeRaw) : null;
  const code = requestedCode || generateCode();

  const planned = {
    gymId: String(GYM_ID),
    code,
    createdAt: nowDate.toISOString(),
    expiresAt: expires.toISOString(),
    isActive: true,
    createdBy: 'script',
  };

  if (!APPLY) {
    console.log('🧪 Dry-run (no writes). Use --apply to write to Firestore.\n');
    console.log('Would write document to:');
    console.log(`  gym_codes/${planned.gymId}/codes/{auto-id}\n`);
    console.log('Fields:');
    console.log(JSON.stringify(planned, null, 2));
    console.log(`\nWould deactivate other active codes older than ${graceHours}h (createdAt < ${graceThresholdDate.toISOString()}).`);
    return;
  }

  const serviceAccount = loadServiceAccount(KEY_FILE);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  const db = admin.firestore();

  const createdAtTs = admin.firestore.Timestamp.now();
  const expiresAtTs = admin.firestore.Timestamp.fromDate(expires);

  // Create new code document (auto-id, so we keep history even if codes repeat in IDs).
  const newDocRef = await db.collection('gym_codes').doc(planned.gymId).collection('codes').add({
    code: planned.code,
    gymId: planned.gymId,
    createdAt: createdAtTs,
    expiresAt: expiresAtTs,
    isActive: true,
    createdBy: planned.createdBy,
  });

  // Deactivate other active codes older than the grace threshold (single-field query to avoid index requirements).
  const activeSnap = await db
    .collection('gym_codes')
    .doc(planned.gymId)
    .collection('codes')
    .where('isActive', '==', true)
    .get();

  const batch = db.batch();
  let deactivated = 0;
  activeSnap.docs.forEach((doc) => {
    if (doc.id === newDocRef.id) return;
    const data = doc.data() || {};
    const createdAt = data.createdAt && typeof data.createdAt.toDate === 'function' ? data.createdAt.toDate() : null;
    if (createdAt && createdAt < graceThresholdDate) {
      batch.update(doc.ref, { isActive: false });
      deactivated += 1;
    }
  });
  if (deactivated > 0) {
    await batch.commit();
  }

  console.log('✅ Gym code created');
  console.log(`- gymId:     ${planned.gymId}`);
  console.log(`- code:      ${planned.code}`);
  console.log(`- expiresAt: ${planned.expiresAt}`);
  console.log(`- docId:     ${newDocRef.id}`);
  console.log(`- deactivated(old): ${deactivated}`);
}

main().catch((err) => {
  console.error('❌ Failed to create gym code:', err);
  process.exit(1);
});

