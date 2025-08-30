process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
const fft = require('firebase-functions-test')({ projectId: 'demo-friends' });
const admin = require('firebase-admin');
const myFuncs = require('..');

describe('changeUsername', () => {
  afterAll(() => {
    fft.cleanup();
  });

  it('changes username and mapping', async () => {
    const uid = 'user1';
    await admin.firestore().collection('users').doc(uid).set({ username: 'Old', usernameLower: 'old' });
    await admin.firestore().collection('usernames').doc('old').set({ uid });
    const wrapped = fft.wrap(myFuncs.changeUsername);
    const res = await wrapped({ newUsername: 'Alice' }, { auth: { uid } });
    expect(res.usernameLower).toBe('alice');
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    expect(userDoc.data().username).toBe('Alice');
    const mapping = await admin.firestore().collection('usernames').doc('alice').get();
    expect(mapping.data().uid).toBe(uid);
    const old = await admin.firestore().collection('usernames').doc('old').get();
    expect(old.exists).toBe(false);
  });

  it('rejects taken username', async () => {
    await admin.firestore().collection('usernames').doc('bob').set({ uid: 'other' });
    const wrapped = fft.wrap(myFuncs.changeUsername);
    await expect(wrapped({ newUsername: 'Bob' }, { auth: { uid: 'user2' } })).rejects.toThrow();
  });

  it('normalizes case', async () => {
    const uid = 'user3';
    await admin.firestore().collection('users').doc(uid).set({});
    const wrapped = fft.wrap(myFuncs.changeUsername);
    const res = await wrapped({ newUsername: 'CaseTest' }, { auth: { uid } });
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    expect(userDoc.data().usernameLower).toBe('casetest');
  });
});
