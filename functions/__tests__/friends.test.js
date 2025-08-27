process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
const fft = require('firebase-functions-test')({ projectId: 'demo-friends' });
const admin = require('firebase-admin');
const myFuncs = require('..');

describe('friend functions', () => {
  afterAll(() => {
    fft.cleanup();
  });

  it('sendFriendRequest creates pending and counter', async () => {
    await admin.firestore().collection('users').doc('B1').set({ allowFriendRequests: 'everyone' });
    await admin.firestore().collection('publicProfiles').doc('A1').set({ username: 'Alice' });
    const wrapped = fft.wrap(myFuncs.sendFriendRequest);
    const res = await wrapped({ toUserId: 'B1' }, { auth: { uid: 'A1' } });
    expect(res.status).toBe('pending');
    const req = await admin.firestore().collection('users').doc('B1').collection('friendRequests').doc('A1_B1').get();
    expect(req.exists).toBe(true);
    const meta = await admin.firestore().collection('users').doc('B1').collection('friendMeta').doc('meta').get();
    expect(meta.data().pendingCountCache).toBe(1);
  });

  it('sendFriendRequest duplicate fails', async () => {
    await admin.firestore().collection('users').doc('B2').set({ allowFriendRequests: 'everyone' });
    const wrapped = fft.wrap(myFuncs.sendFriendRequest);
    await wrapped({ toUserId: 'B2' }, { auth: { uid: 'A2' } });
    await expect(
      wrapped({ toUserId: 'B2' }, { auth: { uid: 'A2' } })
    ).rejects.toThrow('already-exists');
  });
});
