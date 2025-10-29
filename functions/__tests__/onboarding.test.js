jest.mock('firebase-admin');
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const admin = require('firebase-admin');
const fft = require('firebase-functions-test')({ projectId: 'demo-onboarding' });
const onboarding = require('../onboarding');

describe('onGymMemberCreate', () => {
  beforeEach(() => {
    admin.__resetFirestore();
  });

  afterAll(() => {
    fft.cleanup();
  });

  it('assigns member number and timestamp when missing', async () => {
    await admin.firestore().doc('gyms/gymA/config/onboarding').set({ nextMemberNumber: 7 });
    const membershipRef = admin
      .firestore()
      .collection('gyms')
      .doc('gymA')
      .collection('users')
      .doc('user1');
    await membershipRef.set({
      role: 'member',
    });

    const snap = await membershipRef.get();
    const wrapped = fft.wrap(onboarding.onGymMemberCreate);

    await wrapped(snap, { params: { gymId: 'gymA', userId: 'user1' } });

    const membership = await admin.firestore().collection('gyms').doc('gymA').collection('users').doc('user1').get();
    expect(membership.data().memberNumber).toBe('0007');
    const createdAt = membership.data().createdAt;
    expect(createdAt).toBeDefined();
    expect(createdAt).toHaveProperty('_date');

    const config = await admin.firestore().doc('gyms/gymA/config/onboarding').get();
    expect(config.data().nextMemberNumber).toBe(8);
  });

  it('increments member numbers sequentially with concurrent creations', async () => {
    const wrapped = fft.wrap(onboarding.onGymMemberCreate);
    await admin.firestore().doc('gyms/gymB/config/onboarding').set({ nextMemberNumber: 1 });

    const createMember = async (id) => {
      const ref = admin
        .firestore()
        .collection('gyms')
        .doc('gymB')
        .collection('users')
        .doc(id);
      await ref.set({ role: 'member' });
      const snap = await ref.get();
      await wrapped(snap, { params: { gymId: 'gymB', userId: id } });
    };

    await Promise.all(['user1', 'user2', 'user3', 'user4'].map(createMember));

    const results = await Promise.all(
      ['user1', 'user2', 'user3', 'user4'].map((id) =>
        admin.firestore().collection('gyms').doc('gymB').collection('users').doc(id).get()
      )
    );

    const assignedNumbers = results.map((doc) => doc.data().memberNumber);
    expect(new Set(assignedNumbers).size).toBe(4);
    expect([...assignedNumbers].sort()).toEqual(['0001', '0002', '0003', '0004']);
  });

  it('throws when member numbers are exhausted', async () => {
    await admin.firestore().doc('gyms/gymC/config/onboarding').set({ nextMemberNumber: 10000 });
    const ref = admin
      .firestore()
      .collection('gyms')
      .doc('gymC')
      .collection('users')
      .doc('user1');
    await ref.set({
      role: 'member',
    });

    const snap = await ref.get();
    const wrapped = fft.wrap(onboarding.onGymMemberCreate);

    await expect(
      wrapped(snap, { params: { gymId: 'gymC', userId: 'user1' } })
    ).rejects.toThrow('Member number pool exhausted');
  });
});
