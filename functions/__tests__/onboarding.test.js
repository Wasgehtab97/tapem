jest.mock('firebase-admin');

const { assignMemberNumberHandler, MAX_MEMBER_NUMBER } = require('../onboarding');

const serverTimestamp = jest.fn(() => 'SERVER_TS');

const baseLogger = {
  info: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
};

function buildFirestore(tx, configRef) {
  const gymsDoc = {
    collection: jest.fn((name) => {
      if (name !== 'config') {
        throw new Error(`Unexpected collection ${name}`);
      }
      return {
        doc: jest.fn(() => configRef),
      };
    }),
  };

  return {
    runTransaction: jest.fn(async (fn) => fn(tx)),
    collection: jest.fn((name) => {
      if (name !== 'gyms') {
        throw new Error(`Unexpected root collection ${name}`);
      }
      return {
        doc: jest.fn(() => gymsDoc),
      };
    }),
  };
}

function buildTransaction({ memberRef, configRef, memberData = {}, configData }) {
  const memberSnap = {
    data: () => memberData,
  };
  const configSnap = configData
    ? { exists: true, data: () => configData }
    : { exists: false, data: () => ({}) };

  return {
    get: jest.fn(async (ref) => {
      if (ref === memberRef) return memberSnap;
      if (ref === configRef) return configSnap;
      throw new Error('Unknown ref in transaction');
    }),
    update: jest.fn(),
    set: jest.fn(),
  };
}

describe('assignMemberNumberHandler', () => {
  const context = { params: { gymId: 'gym1', userId: 'user1' } };
  let memberRef;
  let configRef;

  beforeEach(() => {
    memberRef = { path: 'gyms/gym1/users/user1' };
    configRef = { path: 'gyms/gym1/config/onboarding' };
    jest.clearAllMocks();
    serverTimestamp.mockClear();
  });

  it('assigns the first member number when no config exists', async () => {
    const tx = buildTransaction({ memberRef, configRef });
    const firestore = buildFirestore(tx, configRef);

    await assignMemberNumberHandler({
      snap: { ref: memberRef },
      context,
      firestore,
      fieldValue: { serverTimestamp },
      logger: baseLogger,
    });

    expect(tx.update).toHaveBeenCalledWith(memberRef, {
      memberNumber: '0001',
      onboardingAssignedAt: 'SERVER_TS',
    });
    expect(tx.set).toHaveBeenCalledWith(
      configRef,
      expect.objectContaining({ nextMemberNumber: 2, lastAssignedNumber: '0001' }),
      { merge: true }
    );
    expect(baseLogger.info).toHaveBeenCalledWith('member_number_assigned', {
      gymId: 'gym1',
      userId: 'user1',
      memberNumber: '0001',
    });
  });

  it('uses the nextMemberNumber from config', async () => {
    const tx = buildTransaction({
      memberRef,
      configRef,
      configData: { nextMemberNumber: 15 },
    });
    const firestore = buildFirestore(tx, configRef);

    await assignMemberNumberHandler({
      snap: { ref: memberRef },
      context,
      firestore,
      fieldValue: { serverTimestamp },
      logger: baseLogger,
    });

    expect(tx.update).toHaveBeenCalledWith(memberRef, {
      memberNumber: '0015',
      onboardingAssignedAt: 'SERVER_TS',
    });
    expect(tx.set).toHaveBeenCalledWith(
      configRef,
      expect.objectContaining({ nextMemberNumber: 16, lastAssignedNumber: '0015' }),
      { merge: true }
    );
  });

  it('skips assignment when member already has a number', async () => {
    const tx = buildTransaction({
      memberRef,
      configRef,
      memberData: { memberNumber: '0003' },
    });
    const firestore = buildFirestore(tx, configRef);

    await assignMemberNumberHandler({
      snap: { ref: memberRef },
      context,
      firestore,
      fieldValue: { serverTimestamp },
      logger: baseLogger,
    });

    expect(tx.update).not.toHaveBeenCalled();
    expect(tx.set).not.toHaveBeenCalled();
    expect(baseLogger.debug).toHaveBeenCalledWith('member_number_exists', {
      gymId: 'gym1',
      userId: 'user1',
      memberNumber: '0003',
    });
  });

  it('logs limit reached when nextMemberNumber exceeds maximum', async () => {
    const tx = buildTransaction({
      memberRef,
      configRef,
      configData: { nextMemberNumber: MAX_MEMBER_NUMBER + 1 },
    });
    const firestore = buildFirestore(tx, configRef);

    await assignMemberNumberHandler({
      snap: { ref: memberRef },
      context,
      firestore,
      fieldValue: { serverTimestamp },
      logger: baseLogger,
    });

    expect(tx.update).not.toHaveBeenCalled();
    expect(tx.set).toHaveBeenCalledWith(
      configRef,
      expect.objectContaining({ nextMemberNumber: MAX_MEMBER_NUMBER + 1, limitReachedAt: 'SERVER_TS' }),
      { merge: true }
    );
    expect(baseLogger.error).toHaveBeenCalledWith('member_number_limit_reached', {
      gymId: 'gym1',
      userId: 'user1',
      nextNumber: MAX_MEMBER_NUMBER + 1,
    });
  });
});
