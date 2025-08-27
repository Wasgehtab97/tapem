process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
const fft = require('firebase-functions-test')({ projectId: 'demo-friends' });
const admin = require('firebase-admin');
const myFuncs = require('..');

describe('public profile mirror', () => {
  afterAll(() => {
    fft.cleanup();
  });

  it('mirrors user writes to publicProfiles', async () => {
    const wrapped = fft.wrap(myFuncs.mirrorPublicProfile);
    const after = fft.firestore.makeDocumentSnapshot(
      { username: 'Alice' },
      'users/A1'
    );
    await wrapped({ before: null, after }, { params: { uid: 'A1' } });
    let snap = await admin.firestore().collection('publicProfiles').doc('A1').get();
    expect(snap.data().usernameLower).toBe('alice');

    const after2 = fft.firestore.makeDocumentSnapshot(
      { username: 'Alicia', usernameLower: 'alicia' },
      'users/A1'
    );
    await wrapped({ before: after, after: after2 }, { params: { uid: 'A1' } });
    snap = await admin.firestore().collection('publicProfiles').doc('A1').get();
    expect(snap.data().username).toBe('Alicia');
  });

  it('backfills existing users', async () => {
    await admin
      .firestore()
      .collection('users')
      .doc('B1')
      .set({ username: 'Bob' });
    await admin
      .firestore()
      .collection('users')
      .doc('C1')
      .set({ username: 'Carol', usernameLower: 'carol' });
    const wrapped = fft.wrap(myFuncs.backfillPublicProfiles);
    const res = await wrapped({}, { auth: { uid: 'admin' } });
    expect(res.processed).toBe(2);
    const snap = await admin.firestore().collection('publicProfiles').get();
    expect(snap.size).toBeGreaterThanOrEqual(2);
    const doc = await admin
      .firestore()
      .collection('publicProfiles')
      .doc('B1')
      .get();
    expect(doc.data().usernameLower).toBe('bob');
  });
});
