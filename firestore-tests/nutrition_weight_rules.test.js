const path = require('path');
const fs = require('fs');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../firestore.rules'),
  'utf8'
);

describe('Nutrition weight security rules', function () {
  this.timeout(20000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'tap-em',
      firestore: {
        rules: firestoreRules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  const ownerCtx = () => testEnv.authenticatedContext('user_weight', {});
  const otherCtx = () => testEnv.authenticatedContext('someone_else', {});

  it('allows owner to write valid daily weight log', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_logs')
      .doc('20260305');
    await assertSucceeds(
      ref.set({
        kg: 82.4,
        source: 'manual',
        updatedAt: new Date(),
      })
    );
  });

  it('blocks invalid daily weight log kg range', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_logs')
      .doc('20260306');
    await assertFails(
      ref.set({
        kg: 8.2,
        source: 'manual',
        updatedAt: new Date(),
      })
    );
  });

  it('blocks invalid date key for daily weight log', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_logs')
      .doc('2026-03-06');
    await assertFails(
      ref.set({
        kg: 82.4,
        source: 'manual',
        updatedAt: new Date(),
      })
    );
  });

  it('allows owner current meta write on current doc only', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_meta')
      .doc('current');
    await assertSucceeds(
      ref.set({
        kg: 82.4,
        dateKey: '20260305',
        updatedAt: new Date(),
      })
    );
  });

  it('blocks writes to non-current meta doc id', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_meta')
      .doc('latest');
    await assertFails(
      ref.set({
        kg: 82.4,
        dateKey: '20260305',
        updatedAt: new Date(),
      })
    );
  });

  it('allows owner to update year summary map', async () => {
    const db = ownerCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_year_summary')
      .doc('2026');
    await assertSucceeds(
      ref.set({
        days: {
          '20260305': {
            kg: 82.4,
            updatedAt: new Date(),
          },
        },
      })
    );
  });

  it('blocks non-owner access', async () => {
    const db = otherCtx().firestore();
    const ref = db
      .collection('users')
      .doc('user_weight')
      .collection('nutrition_weight_logs')
      .doc('20260305');
    await assertFails(ref.get());
  });
});
