#!/usr/bin/env node
/**
 * Phase-0 role migration:
 * - global_admin -> admin
 * - gym_admin -> gymowner
 *
 * Dry-run:
 *   KEY_FILE=./scripts/admin.json node functions/scripts/migrate_roles_phase0.js
 *
 * Apply:
 *   KEY_FILE=./scripts/admin.json node functions/scripts/migrate_roles_phase0.js --apply
 */

const path = require('path');
const admin = require('firebase-admin');

const args = process.argv.slice(2);
const APPLY = args.includes('--apply');
const KEY_FILE =
  process.env.KEY_FILE || process.env.ADMIN_KEY_FILE || './scripts/admin.json';

const ROLE_MAP = Object.freeze({
  global_admin: 'admin',
  gym_admin: 'gymowner',
});

function mapRole(value) {
  if (typeof value !== 'string') return null;
  return ROLE_MAP[value] || null;
}

function loadServiceAccount(keyFile) {
  const full = path.isAbsolute(keyFile)
    ? keyFile
    : path.resolve(process.cwd(), keyFile);
  // eslint-disable-next-line import/no-dynamic-require, global-require
  return require(full);
}

async function migrateTopLevelUserRoles(db) {
  const snap = await db.collection('users').get();
  let scanned = 0;
  let changed = 0;
  const updates = [];
  for (const doc of snap.docs) {
    scanned += 1;
    const mapped = mapRole(doc.data()?.role);
    if (!mapped) continue;
    changed += 1;
    updates.push({ ref: doc.ref, before: doc.data()?.role, after: mapped });
  }
  if (APPLY) {
    for (const item of updates) {
      // eslint-disable-next-line no-await-in-loop
      await item.ref.update({ role: item.after });
    }
  }
  return { scanned, changed };
}

async function migrateGymMembershipRoles(db) {
  const snap = await db.collectionGroup('users').get();
  let scanned = 0;
  let changed = 0;
  const updates = [];

  for (const doc of snap.docs) {
    const segments = doc.ref.path.split('/');
    const isGymMembershipPath =
      segments.length === 4 && segments[0] === 'gyms' && segments[2] === 'users';
    if (!isGymMembershipPath) {
      continue;
    }
    scanned += 1;
    const mapped = mapRole(doc.data()?.role);
    if (!mapped) continue;
    changed += 1;
    updates.push({ ref: doc.ref, before: doc.data()?.role, after: mapped });
  }

  if (APPLY) {
    for (const item of updates) {
      // eslint-disable-next-line no-await-in-loop
      await item.ref.update({ role: item.after });
    }
  }
  return { scanned, changed };
}

async function migrateAuthCustomClaims(auth) {
  let pageToken;
  let scanned = 0;
  let changed = 0;
  do {
    // eslint-disable-next-line no-await-in-loop
    const page = await auth.listUsers(1000, pageToken);
    for (const userRecord of page.users) {
      scanned += 1;
      const claims = userRecord.customClaims || {};
      const mapped = mapRole(claims.role);
      if (!mapped) continue;
      changed += 1;
      if (APPLY) {
        // eslint-disable-next-line no-await-in-loop
        await auth.setCustomUserClaims(userRecord.uid, {
          ...claims,
          role: mapped,
        });
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return { scanned, changed };
}

async function main() {
  const serviceAccount = loadServiceAccount(KEY_FILE);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const db = admin.firestore();
  const auth = admin.auth();

  console.log(APPLY ? '🚀 APPLY mode' : '🧪 DRY-RUN mode');
  console.log('Role mapping:', ROLE_MAP);

  const [usersResult, membershipsResult, claimsResult] = await Promise.all([
    migrateTopLevelUserRoles(db),
    migrateGymMembershipRoles(db),
    migrateAuthCustomClaims(auth),
  ]);

  console.log('\n=== Migration Summary ===');
  console.log(
    `Top-level users: scanned=${usersResult.scanned}, changes=${usersResult.changed}`
  );
  console.log(
    `Gym memberships: scanned=${membershipsResult.scanned}, changes=${membershipsResult.changed}`
  );
  console.log(
    `Auth claims: scanned=${claimsResult.scanned}, changes=${claimsResult.changed}`
  );

  if (!APPLY) {
    console.log('\nNo writes executed. Re-run with --apply to persist changes.');
  }
}

main().catch((error) => {
  console.error('❌ role migration failed:', error);
  process.exit(1);
});
