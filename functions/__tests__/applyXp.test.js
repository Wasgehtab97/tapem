const { applyXp } = require('../xp');

describe('applyXp', () => {
  test('950 +50 -> level up', () => {
    const res = applyXp({ xp: 950, level: 1, add: 50 });
    expect(res).toEqual({ xp: 0, level: 2, leveledUp: true });
  });

  test('multiple overflow', () => {
    const res = applyXp({ xp: 1950, level: 1, add: 200 });
    expect(res).toEqual({ xp: 150, level: 3, leveledUp: true });
  });

  test('at max level 30', () => {
    const res = applyXp({ xp: 900, level: 30, add: 200 });
    expect(res).toEqual({ xp: 0, level: 30, leveledUp: false });
  });
});

