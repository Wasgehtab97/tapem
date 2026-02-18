const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { test, before, beforeEach, after } = require('node:test');

const projectId = 'avatars-v2-test';

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

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

test('U1 member G1 can read gyms/G1/avatarCatalog', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/U1').set({ role: 'member' });
    await db.doc('gyms/G1/avatarCatalog/a').set({});
  });
  await assertSucceeds(dbFor('U1').doc('gyms/G1/avatarCatalog/a').get());
});

test('U1 cannot read gyms/G2/avatarCatalog', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/U1').set({ role: 'member' });
    await db.doc('gyms/G2/avatarCatalog/a').set({});
  });
  await assertFails(dbFor('U1').doc('gyms/G2/avatarCatalog/a').get());
});

test('U2 non-member cannot read gyms/G1/avatarCatalog', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/avatarCatalog/a').set({});
  });
  await assertFails(dbFor('U2').doc('gyms/G1/avatarCatalog/a').get());
});

test('any authed user can read global catalog', async () => {
  await seed(async (db) => {
    await db.doc('catalogAvatarsGlobal/default').set({});
  });
  await assertSucceeds(dbFor('U1').doc('catalogAvatarsGlobal/default').get());
});

test('A1 admin G1 can write gyms/G1/avatarCatalog', async () => {
  await assertSucceeds(
    dbFor('A1', { role: 'gymowner', gymId: 'G1' })
      .doc('gyms/G1/avatarCatalog/new')
      .set({ isActive: true }),
  );
});

test('A1 cannot write gyms/G2/avatarCatalog', async () => {
  await assertFails(
    dbFor('A1', { role: 'gymowner', gymId: 'G1' })
      .doc('gyms/G2/avatarCatalog/new')
      .set({ isActive: true }),
  );
});

test('U1 cannot write gyms/G1/avatarCatalog', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/users/U1').set({ role: 'member' });
  });
  await assertFails(dbFor('U1').doc('gyms/G1/avatarCatalog/new').set({ isActive: true }));
});

test('U1 can read own avatarsOwned', async () => {
  await seed(async (db) => {
    await db.doc('users/U1/avatarsOwned/a').set({});
  });
  await assertSucceeds(dbFor('U1').doc('users/U1/avatarsOwned/a').get());
});

test('U2 cannot read U1 avatarsOwned', async () => {
  await seed(async (db) => {
    await db.doc('users/U1/avatarsOwned/a').set({});
  });
  await assertFails(dbFor('U2').doc('users/U1/avatarsOwned/a').get());
});

test('no client can write avatarsOwned', async () => {
  await assertFails(dbFor('U1').doc('users/U1/avatarsOwned/a').set({}));
});

test('U1 can read own avatarInventory', async () => {
  await seed(async (db) => {
    await db.doc('users/U1/avatarInventory/g1__a').set({
      key: 'g1/a',
      source: 'admin/manual',
      gymId: 'g1',
    });
  });
  await assertSucceeds(dbFor('U1').doc('users/U1/avatarInventory/g1__a').get());
});

test('U2 cannot read U1 avatarInventory', async () => {
  await seed(async (db) => {
    await db.doc('users/U1/avatarInventory/g1__a').set({
      key: 'g1/a',
      source: 'admin/manual',
      gymId: 'g1',
    });
  });
  await assertFails(dbFor('U2').doc('users/U1/avatarInventory/g1__a').get());
});

test('A1 admin G1 can read U1 avatarInventory', async () => {
  await seed(async (db) => {
    await db.doc('gyms/g1/users/U1').set({ role: 'member' });
    await db.doc('gyms/g1/users/A1').set({ role: 'gymowner' });
    await db.doc('users/U1/avatarInventory/g1__a').set({
      key: 'g1/a',
      source: 'admin/manual',
      gymId: 'g1',
    });
  });
  await assertSucceeds(
    dbFor('A1', { role: 'gymowner', gymId: 'g1' }).doc('users/U1/avatarInventory/g1__a').get(),
  );
});

test('A1 admin G1 cannot read U2 avatarInventory in G2', async () => {
  await seed(async (db) => {
    await db.doc('gyms/g2/users/U2').set({ role: 'member' });
    await db.doc('gyms/g1/users/A1').set({ role: 'gymowner' });
    await db.doc('users/U2/avatarInventory/g2__a').set({
      key: 'g2/a',
      source: 'admin/manual',
      gymId: 'g2',
    });
  });
  await assertFails(
    dbFor('A1', { role: 'gymowner', gymId: 'g1' }).doc('users/U2/avatarInventory/g2__a').get(),
  );
});

test('A1 admin G1 can create avatarInventory for member', async () => {
  await seed(async (db) => {
    await db.doc('gyms/g1/users/U1').set({ role: 'member' });
    await db.doc('gyms/g1/users/A1').set({ role: 'gymowner' });
  });
  await assertSucceeds(
    dbFor('A1', { role: 'gymowner', gymId: 'g1' }).doc('users/U1/avatarInventory/g1__a').set({
      key: 'g1/a',
      source: 'admin/manual',
      gymId: 'g1',
    }),
  );
});

test('A1 admin G1 cannot create avatarInventory with extra fields', async () => {
  await seed(async (db) => {
    await db.doc('gyms/g1/users/U1').set({ role: 'member' });
    await db.doc('gyms/g1/users/A1').set({ role: 'gymowner' });
  });
  await assertFails(
    dbFor('A1', { role: 'gymowner', gymId: 'g1' }).doc('users/U1/avatarInventory/g1__a').set({
      key: 'g1/a',
      source: 'admin/manual',
      gymId: 'g1',
      extra: true,
    }),
  );
});

test('A1 admin G1 cannot create avatarInventory for user in G2', async () => {
  await seed(async (db) => {
    await db.doc('gyms/g2/users/U2').set({ role: 'member' });
    await db.doc('gyms/g1/users/A1').set({ role: 'gymowner' });
  });
  await assertFails(
    dbFor('A1', { role: 'gymowner', gymId: 'g1' }).doc('users/U2/avatarInventory/g2__a').set({
      key: 'g2/a',
      source: 'admin/manual',
      gymId: 'g2',
    }),
  );
});

test('U1 can create own avatarInventory', async () => {
  await assertSucceeds(
    dbFor('U1').doc('users/U1/avatarInventory/global__x').set({
      key: 'global/x',
      source: 'user/self',
    }),
  );
});

test('U1 can write own avatarKey', async () => {
  await seed(async (db) => {
    await db.doc('users/U1').set({});
  });
  await assertSucceeds(dbFor('U1').doc('users/U1').update({ avatarKey: 'global/default' }));
});

test('U2 cannot write U1 avatarKey', async () => {
  await seed(async (db) => {
    await db.doc('users/U1').set({});
  });
  await assertFails(dbFor('U2').doc('users/U1').update({ avatarKey: 'global/default' }));
});

test('A1 admin G1 can write U1 avatarKey', async () => {
  await seed(async (db) => {
    await db.doc('users/U1').set({});
    await db.doc('gyms/G1/users/U1').set({ role: 'member' });
    await db.doc('gyms/G1/users/A1').set({ role: 'gymowner' });
  });
  await assertSucceeds(
    dbFor('A1', { role: 'gymowner', gymId: 'G1' }).doc('users/U1').update({ avatarKey: 'global/default' }),
  );
});

test('U1 can write own equippedAvatarRef', async () => {
  await seed(async (db) => {
    await db.doc('users/U1').set({});
  });
  await assertSucceeds(
    dbFor('U1').doc('users/U1').update({ equippedAvatarRef: 'catalog/avatarsGlobal/default' }),
  );
});

test('U2 cannot write U1 equippedAvatarRef', async () => {
  await seed(async (db) => {
    await db.doc('users/U1').set({});
  });
  await assertFails(
    dbFor('U2').doc('users/U1').update({ equippedAvatarRef: 'catalog/avatarsGlobal/default' }),
  );
});

test('gymowner can write surveys only in own gym', async () => {
  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });

  await assertSucceeds(
    ownerDb.doc('gyms/G1/surveys/s-1').set({
      title: 'How was training?',
      createdAt: new Date(),
    }),
  );
  await assertFails(
    ownerDb.doc('gyms/G2/surveys/s-foreign').set({
      title: 'Cross gym',
      createdAt: new Date(),
    }),
  );
});

test('gymowner can moderate feedback only in own gym', async () => {
  await seed(async (db) => {
    await db.doc('gyms/G1/feedback/fb-1').set({ userId: 'U1', status: 'open' });
    await db.doc('gyms/G2/feedback/fb-2').set({ userId: 'U2', status: 'open' });
  });

  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });

  await assertSucceeds(ownerDb.doc('gyms/G1/feedback/fb-1').update({ status: 'done' }));
  await assertFails(ownerDb.doc('gyms/G2/feedback/fb-2').update({ status: 'done' }));
});

test('reportDaily stays read-only for gymowner', async () => {
  await seed(async (db) => {
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
    }),
  );
});

test('adminAudit is writable for gymowner in own gym only', async () => {
  const ownerDb = dbFor('O1', { role: 'gymowner', gymId: 'G1' });

  await assertSucceeds(
    ownerDb.doc('gyms/G1/adminAudit/a1').set({
      action: 'manual_check',
      actorUid: 'O1',
      gymId: 'G1',
      createdAt: new Date(),
    }),
  );
  await assertFails(
    ownerDb.doc('gyms/G2/adminAudit/a2').set({
      action: 'cross_gym_check',
      actorUid: 'O1',
      gymId: 'G2',
      createdAt: new Date(),
    }),
  );
});

test('gymowner cannot write global manufacturers catalog', async () => {
  await assertFails(
    dbFor('O1', { role: 'gymowner', gymId: 'G1' })
      .doc('manufacturers/new-manufacturer')
      .set({ name: 'X' }),
  );
});
