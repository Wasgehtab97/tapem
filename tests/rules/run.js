const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { test, before, beforeEach, after } = require('node:test');
const assert = require('assert');

let env;
const projectId = 'avatars-v2-test';

before(async () => {
  env = await initializeTestEnvironment({ projectId });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

function authed(uid, claims) {
  return env.authenticatedContext(uid, claims).firestore();
}

function adminDb() {
  return env.unauthenticatedContext().firestore();
}

// Gym catalog read tests

test('U1 member G1 can read gyms/G1/avatarCatalog', async () => {
  const admin = adminDb();
  await admin.doc('gyms/G1/users/U1').set({ role: 'member' });
  await admin.doc('gyms/G1/avatarCatalog/a').set({});
  const db = authed('U1');
  await assertSucceeds(db.doc('gyms/G1/avatarCatalog/a').get());
});

test('U1 cannot read gyms/G2/avatarCatalog', async () => {
  const admin = adminDb();
  await admin.doc('gyms/G1/users/U1').set({ role: 'member' });
  await admin.doc('gyms/G2/avatarCatalog/a').set({});
  const db = authed('U1');
  await assertFails(db.doc('gyms/G2/avatarCatalog/a').get());
});

test('U2 non-member cannot read gyms/G1/avatarCatalog', async () => {
  const admin = adminDb();
  await admin.doc('gyms/G1/avatarCatalog/a').set({});
  const db = authed('U2');
  await assertFails(db.doc('gyms/G1/avatarCatalog/a').get());
});

// Global catalog read

test('any authed user can read global catalog', async () => {
  const admin = adminDb();
  await admin.doc('catalogAvatarsGlobal/default').set({});
  const db = authed('U1');
  await assertSucceeds(db.doc('catalogAvatarsGlobal/default').get());
});

// Gym catalog write

test('A1 admin G1 can write gyms/G1/avatarCatalog', async () => {
  const db = authed('A1', { role: 'gym_admin', gymId: 'G1' });
  await assertSucceeds(db.doc('gyms/G1/avatarCatalog/new').set({ isActive: true }));
});

test('A1 cannot write gyms/G2/avatarCatalog', async () => {
  const db = authed('A1', { role: 'gym_admin', gymId: 'G1' });
  await assertFails(db.doc('gyms/G2/avatarCatalog/new').set({ isActive: true }));
});

test('U1 cannot write gyms/G1/avatarCatalog', async () => {
  const db = authed('U1');
  await assertFails(db.doc('gyms/G1/avatarCatalog/new').set({ isActive: true }));
});

// Inventory

test('U1 can read own avatarsOwned', async () => {
  const admin = adminDb();
  await admin.doc('users/U1/avatarsOwned/a').set({});
  const db = authed('U1');
  await assertSucceeds(db.doc('users/U1/avatarsOwned/a').get());
});

test('U2 cannot read U1 avatarsOwned', async () => {
  const admin = adminDb();
  await admin.doc('users/U1/avatarsOwned/a').set({});
  const db = authed('U2');
  await assertFails(db.doc('users/U1/avatarsOwned/a').get());
});

test('no client can write avatarsOwned', async () => {
  const db = authed('U1');
  await assertFails(db.doc('users/U1/avatarsOwned/a').set({}));
});

// Equip tests

test('U1 can write own equippedAvatarRef', async () => {
  const admin = adminDb();
  await admin.doc('users/U1').set({});
  const db = authed('U1');
  await assertSucceeds(db.doc('users/U1').update({ equippedAvatarRef: 'catalog/avatarsGlobal/default' }));
});

test('U2 cannot write U1 equippedAvatarRef', async () => {
  const admin = adminDb();
  await admin.doc('users/U1').set({});
  const db = authed('U2');
  await assertFails(db.doc('users/U1').update({ equippedAvatarRef: 'catalog/avatarsGlobal/default' }));
});
