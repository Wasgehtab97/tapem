jest.mock('firebase-admin');
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
const admin = require('firebase-admin');
const fft = require('firebase-functions-test')({ projectId: 'demo-friends' });
const myFuncs = require('..');

describe('public profile mirror', () => {
  const makeSnapshot = (data) => ({
    data: () => data,
    exists: data !== null && data !== undefined,
  });

  beforeEach(() => {
    admin.__resetFirestore();
  });

  afterAll(() => {
    fft.cleanup();
  });

  it('mirrors user writes to publicProfiles', async () => {
    const wrapped = fft.wrap(myFuncs.mirrorPublicProfile);
    const before = makeSnapshot(null);
    const after = makeSnapshot({ username: 'Alice' });
    await wrapped({ before, after }, { params: { uid: 'A1' } });
    let snap = await admin.firestore().collection('publicProfiles').doc('A1').get();
    expect(snap.data().usernameLower).toBe('alice');

    const after2 = makeSnapshot({ username: 'Alicia', usernameLower: 'alicia' });
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
