const { readFileSync } = require('node:fs');
const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { after, before, beforeEach, test } = require('node:test');
const { Timestamp } = require('firebase/firestore');

const projectId = 'phase0-roles-test';

let env;

function dbFor(uid, claims = {}) {
  return env.authenticatedContext(uid, claims).firestore();
}

async function seed(seedFn) {
  await env.withSecurityRulesDisabled(async (context) => {
    await seedFn(context.firestore());
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  await env.cleanup();
});

test('member cannot write admin collection', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/U1').set({ role: 'member' });
  });

  const memberDb = dbFor('U1', { role: 'member', gymId: 'G1' });
  await assertFails(
    memberDb.doc('gyms/G1/avatarCatalog/member-write').set({ isActive: true })
  );
});

test('gymowner can write own gym but not foreign gym', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/O1').set({ role: 'gymowner' });
    await db.doc('gyms/G2/users/O1').set({ role: 'member' });
  });

  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });
  await assertSucceeds(
    ownerDb.doc('gyms/G1/avatarCatalog/owner-write').set({ isActive: true })
  );
  await assertFails(
    ownerDb.doc('gyms/G2/avatarCatalog/owner-cross-gym').set({ isActive: true })
  );
});

test('admin can write across gyms', async () => {
  const appAdminDb = dbFor('A1', { role: 'admin' });
  await assertSucceeds(
    appAdminDb.doc('gyms/G9/avatarCatalog/admin-write').set({ isActive: true })
  );
});

test('legacy gym_admin role has no admin privileges', async () => {
  const legacyDb = dbFor('L1', { role: 'gym_admin', gymId: 'G1' });
  await assertFails(
    legacyDb.doc('gyms/G1/avatarCatalog/legacy-write').set({ isActive: true })
  );
});

test('gymowner cannot write global manufacturers catalog', async () => {
  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });
  await assertFails(
    ownerDb.doc('manufacturers/global-seed').set({ name: 'Test' })
  );
});

test('admin can write global manufacturers catalog', async () => {
  const appAdminDb = dbFor('A1', { role: 'admin' });
  await assertSucceeds(
    appAdminDb.doc('manufacturers/global-seed').set({ name: 'Test' })
  );
});

test('reportDaily is readable but not writable by gymowner', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/O1').set({ role: 'gymowner' });
    await db.doc('gyms/G1/reportDaily/20260216').set({
      dayKey: '20260216',
      totalLogs: 3,
    });
  });

  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });
  await assertSucceeds(ownerDb.doc('gyms/G1/reportDaily/20260216').get());
  await assertFails(
    ownerDb.doc('gyms/G1/reportDaily/20260216').set({
      dayKey: '20260216',
      totalLogs: 4,
    })
  );
});

test('gymowner can detach member from own gym in users/{uid}', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/O1').set({ role: 'gymowner' });
    await db.doc('gyms/G1/users/U2').set({ role: 'member' });
    await db.doc('users/U2').set({ gymCodes: ['G1', 'G2'], activeGymId: 'G1' });
  });

  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });
  await assertSucceeds(
    ownerDb.doc('users/U2').update({
      gymCodes: ['G2'],
      activeGymId: 'G2',
      updatedAt: Timestamp.now(),
    })
  );
});

test('gymowner cannot modify foreign gym membership in users/{uid}', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/O1').set({ role: 'gymowner' });
    await db.doc('gyms/G1/users/U2').set({ role: 'member' });
    await db.doc('users/U2').set({ gymCodes: ['G1', 'G2'], activeGymId: 'G1' });
  });

  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });
  await assertFails(
    ownerDb.doc('users/U2').update({
      gymCodes: ['G1'],
      activeGymId: 'G1',
      updatedAt: Timestamp.now(),
    })
  );
});

test('admin can adjust gymCodes subset in users/{uid}', async () => {
  await seed(async (db) => {
    await db.doc('users/U2').set({ gymCodes: ['G1', 'G2'], activeGymId: 'G1' });
  });

  const appAdminDb = dbFor('A1', { role: 'admin' });
  await assertSucceeds(
    appAdminDb.doc('users/U2').update({
      gymCodes: ['G2'],
      activeGymId: 'G2',
      updatedAt: Timestamp.now(),
    })
  );
});
