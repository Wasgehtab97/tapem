const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

const GRANTS_FLAG = 'avatars_v2_grants_enabled';
const ENABLED_FLAG = 'avatars_v2_enabled';

function flagsOn() {
  const cfg = functions.config().app || {};
  const enabled = cfg[ENABLED_FLAG];
  const grants = cfg[GRANTS_FLAG];
  const isOn = (v) => v === true || v === 'true';
  return isOn(enabled) && isOn(grants);
}

function telemetry(event, details) {
  console.log(`TELEMETRY ${event}`, details);
}

function canonicalString(obj) {
  const keys = Object.keys(obj).sort();
  const canonical = {};
  for (const k of keys) {
    const v = obj[k];
    canonical[k] = typeof v === 'object' && v !== null ? canonicalString(v) : v;
  }
  return JSON.stringify(canonical);
}

async function isUserMemberOfGym(uid, gymId) {
  const snap = await admin
    .firestore()
    .collection('gyms')
    .doc(gymId)
    .collection('users')
    .doc(uid)
    .get();
  return snap.exists;
}

async function grantAvatar({ uid, avatarPath, reason, context, adminId }) {
  telemetry('avatar_grant_attempt', { uid, avatarPath, reason });
  if (!flagsOn()) {
    telemetry('avatar_grant_denied', { reason: 'flag_off' });
    return { status: 'flag_off' };
  }
  const db = admin.firestore();
  const catalogSnap = await db.doc(avatarPath).get();
  if (!catalogSnap.exists || catalogSnap.data().isActive !== true) {
    telemetry('avatar_grant_denied', { reason: 'catalog_missing' });
    return { status: 'catalog_missing' };
  }
  const catalog = catalogSnap.data();
  const parts = avatarPath.split('/');
  let source = 'global';
  let gymId = null;
  if (parts[0] === 'gyms') {
    gymId = parts[1];
    source = `gym:${gymId}`;
    if (!(await isUserMemberOfGym(uid, gymId))) {
      telemetry('avatar_grant_denied', { reason: 'not_member' });
      return { status: 'not_member' };
    }
  }
  if (reason !== 'admin' && catalog.unlock && catalog.unlock.type && catalog.unlock.type !== reason) {
    telemetry('avatar_grant_denied', { reason: 'unlock_mismatch' });
    return { status: 'unlock_mismatch' };
  }
  if (reason === 'admin' && catalog.unlock && catalog.unlock.type !== 'manual') {
    telemetry('avatar_grant_denied', { reason: 'unlock_mismatch' });
    return { status: 'unlock_mismatch' };
  }
  const canonicalContext = canonicalString(context || {});
  const hash = crypto
    .createHash('sha256')
    .update(`${uid}|${avatarPath}|${reason}|${canonicalContext}`)
    .digest('hex');
  const avatarId = parts[parts.length - 1];
  const ownedRef = db.collection('users').doc(uid).collection('avatarsOwned').doc(avatarId);
  const ownedSnap = await ownedRef.get();
  if (ownedSnap.exists && ownedSnap.data().grantHash === hash) {
    telemetry('avatar_grant_noop', { uid, avatarId });
    return { status: 'noop' };
  }
  await ownedRef.set(
    {
      source,
      unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
      reason,
      by: adminId || 'system',
      grantHash: hash,
    },
    { merge: true }
  );
  telemetry('avatar_grant_success', { uid, avatarId });
  return { status: 'granted' };
}

async function revokeAvatar({ uid, avatarPath }) {
  telemetry('avatar_revoke_attempt', { uid, avatarPath });
  if (!flagsOn()) {
    telemetry('avatar_revoke_denied', { reason: 'flag_off' });
    return { status: 'flag_off' };
  }
  const parts = avatarPath.split('/');
  const avatarId = parts[parts.length - 1];
  const ref = admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('avatarsOwned')
    .doc(avatarId);
  await ref.delete().catch(() => {});
  telemetry('avatar_revoke_success', { uid, avatarId });
  return { status: 'revoked' };
}

exports.adminGrantAvatar = functions.https.onCall(async (data, context) => {
  const uid = data && data.uid;
  const avatarPath = data && data.avatarPath;
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'auth_required');
  }
  const claims = context.auth.token || {};
  if (claims.role !== 'gym_admin') {
    throw new functions.https.HttpsError('permission-denied', 'admin_only');
  }
  const targetGym = claims.gymId;
  if (avatarPath.startsWith('gyms/') && !avatarPath.startsWith(`gyms/${targetGym}/`)) {
    throw new functions.https.HttpsError('permission-denied', 'cross_gym');
  }
  const res = await grantAvatar({
    uid,
    avatarPath,
    reason: 'admin',
    context: { gymId: targetGym, adminId: context.auth.uid },
    adminId: context.auth.uid,
  });
  return res;
});

exports.adminRevokeAvatar = functions.https.onCall(async (data, context) => {
  const uid = data && data.uid;
  const avatarPath = data && data.avatarPath;
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'auth_required');
  }
  const claims = context.auth.token || {};
  if (claims.role !== 'gym_admin') {
    throw new functions.https.HttpsError('permission-denied', 'admin_only');
  }
  const targetGym = claims.gymId;
  if (avatarPath.startsWith('gyms/') && !avatarPath.startsWith(`gyms/${targetGym}/`)) {
    throw new functions.https.HttpsError('permission-denied', 'cross_gym');
  }
  const res = await revokeAvatar({ uid, avatarPath });
  return res;
});

exports.onUserCreateDefaults = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  await grantAvatar({ uid, avatarPath: 'catalog/avatarsGlobal/default', reason: 'default_bootstrap', context: {} });
  await grantAvatar({ uid, avatarPath: 'catalog/avatarsGlobal/default2', reason: 'default_bootstrap', context: {} });
});

async function grantXpAvatars(uid, totalXp) {
  const db = admin.firestore();
  const globalSnap = await db
    .collection('catalog')
    .doc('avatarsGlobal')
    .collection('items')
    .where('isActive', '==', true)
    .where('unlock.type', '==', 'xp')
    .where('unlock.params.xpThreshold', '<=', totalXp)
    .get();
  for (const doc of globalSnap.docs) {
    await grantAvatar({
      uid,
      avatarPath: `catalog/avatarsGlobal/${doc.id}`,
      reason: 'xp',
      context: { threshold: doc.data().unlock.params.xpThreshold },
    });
  }
  const membershipsSnap = await db.collectionGroup('users').where('uid', '==', uid).get();
  for (const member of membershipsSnap.docs) {
    const gymId = member.ref.parent.parent.id;
    const snap = await db
      .collection('gyms')
      .doc(gymId)
      .collection('avatarCatalog')
      .where('isActive', '==', true)
      .where('unlock.type', '==', 'xp')
      .where('unlock.params.xpThreshold', '<=', totalXp)
      .get();
    for (const doc of snap.docs) {
      await grantAvatar({
        uid,
        avatarPath: `gyms/${gymId}/avatarCatalog/${doc.id}`,
        reason: 'xp',
        context: { gymId, threshold: doc.data().unlock.params.xpThreshold },
      });
    }
  }
}

exports.onXpUpdate = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data().xp || 0;
    const after = change.after.data().xp || 0;
    if (after <= before) return null;
    await grantXpAvatars(context.params.uid, after);
    return null;
  });

exports.onChallengeState = functions.firestore
  .document('gyms/{gymId}/challenges/{challengeId}/participants/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data().state;
    const after = change.after.data().state;
    if (before === 'completed' || after !== 'completed') return null;
    const db = admin.firestore();
    const avatars = await db
      .collection('gyms')
      .doc(context.params.gymId)
      .collection('avatarCatalog')
      .where('isActive', '==', true)
      .where('unlock.type', '==', 'challenge')
      .where('unlock.params.challengeId', '==', context.params.challengeId)
      .get();
    for (const doc of avatars.docs) {
      await grantAvatar({
        uid: context.params.uid,
        avatarPath: `gyms/${context.params.gymId}/avatarCatalog/${doc.id}`,
        reason: 'challenge',
        context: { gymId: context.params.gymId, challengeId: context.params.challengeId },
      });
    }
    return null;
  });

exports.onEventParticipation = functions.firestore
  .document('gyms/{gymId}/events/{eventId}/participants/{uid}')
  .onCreate(async (snap, context) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();
    const avatars = await db
      .collection('gyms')
      .doc(context.params.gymId)
      .collection('avatarCatalog')
      .where('isActive', '==', true)
      .where('unlock.type', '==', 'event')
      .where('unlock.params.eventId', '==', context.params.eventId)
      .get();
    for (const doc of avatars.docs) {
      const window = doc.data().unlock.params.window || {};
      const start = window.start ? admin.firestore.Timestamp.fromDate(new Date(window.start)) : null;
      const end = window.end ? admin.firestore.Timestamp.fromDate(new Date(window.end)) : null;
      if (start && now < start) continue;
      if (end && now > end) continue;
      await grantAvatar({
        uid: context.params.uid,
        avatarPath: `gyms/${context.params.gymId}/avatarCatalog/${doc.id}`,
        reason: 'event',
        context: { gymId: context.params.gymId, eventId: context.params.eventId },
      });
    }
    return null;
  });

exports.grantAvatar = grantAvatar;
exports.revokeAvatar = revokeAvatar;
