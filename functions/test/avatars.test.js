const admin = require('firebase-admin');
const functionsTest = require('firebase-functions-test')({ projectId: 'avatars-v2-test' });
functionsTest.mockConfig({ app: { avatars_v2_enabled: true, avatars_v2_grants_enabled: true } });
const { clearFirestoreData } = require('@firebase/rules-unit-testing');
const myFunctions = require('../index');
const assert = require('assert');

async function seedBase(eventWindowNow = true) {
  const db = admin.firestore();
  // Global catalog
  await db.collection('catalog').doc('avatarsGlobal').collection('items').doc('default').set({
    isActive: true,
    unlock: { type: 'manual' },
    assetUrl: 'https://example.com/default.png',
  });
  await db.collection('catalog').doc('avatarsGlobal').collection('items').doc('default2').set({
    isActive: true,
    unlock: { type: 'manual' },
  });
  await db.collection('catalog').doc('avatarsGlobal').collection('items').doc('globalX').set({
    isActive: true,
    unlock: { type: 'manual' },
  });
  // Gyms and members
  await db.collection('gyms').doc('G1').set({});
  await db.collection('gyms').doc('G1').collection('users').doc('U1').set({ role: 'member' });
  await db.collection('gyms').doc('G1').collection('users').doc('A1').set({ role: 'admin' });
  await db.collection('gyms').doc('G2').set({});
  await db.collection('gyms').doc('G2').collection('users').doc('A2').set({ role: 'admin' });
  // Gym catalog
  await db.collection('gyms').doc('G1').collection('avatarCatalog').doc('g1_x').set({
    isActive: true,
    unlock: { type: 'manual' },
  });
  await db.collection('gyms').doc('G1').collection('avatarCatalog').doc('g1_xp').set({
    isActive: true,
    unlock: { type: 'xp', params: { xpThreshold: 5000 } },
  });
  await db.collection('gyms').doc('G1').collection('avatarCatalog').doc('g1_chal').set({
    isActive: true,
    unlock: { type: 'challenge', params: { challengeId: 'c123' } },
  });
  const window = eventWindowNow
    ? {
        start: new Date(Date.now() - 1000).toISOString(),
        end: new Date(Date.now() + 60 * 1000).toISOString(),
      }
    : {
        start: new Date(Date.now() + 60 * 1000).toISOString(),
        end: new Date(Date.now() + 120 * 1000).toISOString(),
      };
  await db.collection('gyms').doc('G1').collection('avatarCatalog').doc('g1_event').set({
    isActive: true,
    unlock: { type: 'event', params: { eventId: 'e777', window } },
  });
}

beforeEach(async () => {
  await clearFirestoreData({ projectId: 'avatars-v2-test' });
  await seedBase();
});

after(() => functionsTest.cleanup());

function wrap(name) {
  return functionsTest.wrap(myFunctions[name]);
}

test('onUserCreateDefaults grants two defaults once', async () => {
  const fn = wrap('onUserCreateDefaults');
  await fn({ uid: 'U9' });
  const db = admin.firestore();
  let snap = await db.collection('users').doc('U9').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 2);
  await fn({ uid: 'U9' });
  snap = await db.collection('users').doc('U9').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 2);
});

test('adminGrantAvatar respects gym boundaries and idempotence', async () => {
  const fn = wrap('adminGrantAvatar');
  const context = { auth: { uid: 'A1', token: { role: 'gym_admin', gymId: 'G1' } } };
  let res = await fn({ uid: 'U1', avatarPath: 'gyms/G1/avatarCatalog/g1_x' }, context);
  assert.strictEqual(res.status, 'granted');
  await assert.rejects(
    fn({ uid: 'U1', avatarPath: 'gyms/G2/avatarCatalog/g2_x' }, context),
    /permission-denied/
  );
  res = await fn({ uid: 'U2', avatarPath: 'gyms/G1/avatarCatalog/g1_x' }, context);
  assert.strictEqual(res.status, 'not_member');
  res = await fn({ uid: 'U1', avatarPath: 'catalog/avatarsGlobal/globalX' }, context);
  assert.strictEqual(res.status, 'granted');
  res = await fn({ uid: 'U1', avatarPath: 'catalog/avatarsGlobal/globalX' }, context);
  assert.strictEqual(res.status, 'noop');
});

test('onXpUpdate grants once when threshold crossed', async () => {
  const fn = wrap('onXpUpdate');
  const db = admin.firestore();
  await db.collection('users').doc('U1').set({ xp: 4900 });
  const before = { data: () => ({ xp: 4900 }) };
  const after = { data: () => ({ xp: 5100 }) };
  await fn({ before, after }, { params: { uid: 'U1' } });
  let snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
  const after2 = { data: () => ({ xp: 5200 }) };
  await fn({ before: after, after: after2 }, { params: { uid: 'U1' } });
  snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
});

test('onChallengeState grants once on completion', async () => {
  const fn = wrap('onChallengeState');
  const db = admin.firestore();
  const before = { data: () => ({ state: 'started' }) };
  const after = { data: () => ({ state: 'completed' }) };
  await fn({ before, after }, { params: { gymId: 'G1', challengeId: 'c123', uid: 'U1' } });
  let snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
  await fn({ before: after, after }, { params: { gymId: 'G1', challengeId: 'c123', uid: 'U1' } });
  snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
});

test('onEventParticipation grants within window and not outside', async () => {
  const fn = wrap('onEventParticipation');
  const db = admin.firestore();
  // within window (seedBase already set window around now)
  await fn({ data: () => ({}) }, { params: { gymId: 'G1', eventId: 'e777', uid: 'U1' } });
  let snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
  // idempotent
  await fn({ data: () => ({}) }, { params: { gymId: 'G1', eventId: 'e777', uid: 'U1' } });
  snap = await db.collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 1);
  // outside window
  await clearFirestoreData({ projectId: 'avatars-v2-test' });
  await seedBase(false); // window in future
  await fn({ data: () => ({}) }, { params: { gymId: 'G1', eventId: 'e777', uid: 'U1' } });
  snap = await admin.firestore().collection('users').doc('U1').collection('avatarsOwned').get();
  assert.strictEqual(snap.size, 0);
});

test('mirrorEquippedAvatar mirrors url when asset present', async () => {
  const fn = wrap('mirrorEquippedAvatar');
  const db = admin.firestore();
  const before = { data: () => ({}) };
  const after = { data: () => ({ equippedAvatarRef: 'catalog/avatarsGlobal/default' }) };
  await fn({ before, after }, { params: { uid: 'U1' } });
  const profile = await db.collection('publicProfiles').doc('U1').get();
  assert.strictEqual(profile.data().equippedAvatarRef, 'catalog/avatarsGlobal/default');
  assert.ok(profile.data().resolvedAvatarUrl);
});

test('mirrorEquippedAvatar mirrors without url when asset missing', async () => {
  const fn = wrap('mirrorEquippedAvatar');
  const db = admin.firestore();
  const before = { data: () => ({}) };
  const after = { data: () => ({ equippedAvatarRef: 'catalog/avatarsGlobal/default2' }) };
  await fn({ before, after }, { params: { uid: 'U1' } });
  const profile = await db.collection('publicProfiles').doc('U1').get();
  assert.strictEqual(profile.data().equippedAvatarRef, 'catalog/avatarsGlobal/default2');
  assert.ok(!profile.data().resolvedAvatarUrl);
});
