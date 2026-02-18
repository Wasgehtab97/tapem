jest.mock('firebase-admin');
const admin = require('firebase-admin');
const fft = require('firebase-functions-test')({ projectId: 'demo-gym-management' });

const { removeUserFromGym } = require('../gymManagement');

describe('removeUserFromGym', () => {
  const wrapped = fft.wrap(removeUserFromGym);

  beforeEach(() => {
    admin.__resetFirestore();
  });

  afterAll(() => {
    fft.cleanup();
  });

  it('rejects unauthenticated calls', async () => {
    await expect(wrapped({ gymId: 'G1', uid: 'U1' }, {})).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('rejects invalid payload', async () => {
    await expect(
      wrapped(
        { gymId: '', uid: '' },
        { auth: { uid: 'A1', token: { role: 'admin' } } }
      )
    ).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('blocks gymowner from removing staff', async () => {
    const db = admin.firestore();
    await db.collection('users').doc('U2').set({ gymCodes: ['G1'], activeGymId: 'G1' });
    await db.collection('gyms').doc('G1').collection('users').doc('A1').set({ role: 'gymowner' });
    await db.collection('gyms').doc('G1').collection('users').doc('U2').set({ role: 'gymowner' });

    await expect(
      wrapped(
        { gymId: 'G1', uid: 'U2' },
        { auth: { uid: 'A1', token: { role: 'gymowner', gymId: 'G1' } } }
      )
    ).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('removes member membership, strips gym code and writes audit entry', async () => {
    const db = admin.firestore();
    await db.collection('users').doc('U1').set({ gymCodes: ['G1', 'G2'], activeGymId: 'G1' });
    await db.collection('gyms').doc('G1').collection('users').doc('A1').set({ role: 'gymowner' });
    await db.collection('gyms').doc('G1').collection('users').doc('U1').set({ role: 'member' });
    await db.collection('gyms').doc('G1').collection('devices').doc('D1').set({ name: 'Device' });
    await db
      .collection('gyms')
      .doc('G1')
      .collection('devices')
      .doc('D1')
      .collection('leaderboard')
      .doc('U1')
      .set({ sessions: 2 });

    const result = await wrapped(
      { gymId: 'G1', uid: 'U1' },
      { auth: { uid: 'A1', token: { role: 'gymowner', gymId: 'G1' } } }
    );
    expect(result).toEqual({ ok: true, gymId: 'G1', uid: 'U1' });

    const userSnap = await db.collection('users').doc('U1').get();
    expect(userSnap.data().gymCodes).toEqual(['G2']);
    expect(userSnap.data().activeGymId).toBe('G2');

    const membershipSnap = await db.collection('gyms').doc('G1').collection('users').doc('U1').get();
    expect(membershipSnap.exists).toBe(false);

    const leaderboardSnap = await db
      .collection('gyms')
      .doc('G1')
      .collection('devices')
      .doc('D1')
      .collection('leaderboard')
      .doc('U1')
      .get();
    expect(leaderboardSnap.exists).toBe(false);

    const auditSnap = await db.collection('gyms').doc('G1').collection('adminAudit').get();
    expect(auditSnap.size).toBe(1);
    expect(auditSnap.docs[0].data()).toMatchObject({
      action: 'remove_user_from_gym',
      actorUid: 'A1',
      targetUid: 'U1',
      gymId: 'G1',
    });
  });
});
