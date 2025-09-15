import '../models/level_info.dart';

class LevelService {
  static const int xpPerLevel = 1000;
  static const int xpPerSession = 50;
  static const int maxLevel = 30;

  LevelInfo addXp(LevelInfo info, int delta) {
    if (info.level >= maxLevel) {
      return info.copyWith(xp: 0);
    }
    var totalXp = info.xp + delta;
    var level = info.level;
    while (totalXp >= xpPerLevel && level < maxLevel) {
      totalXp -= xpPerLevel;
      level++;
    }
    if (level >= maxLevel) {
      level = maxLevel;
      totalXp = 0;
    }
    return LevelInfo(level: level, xp: totalXp);
  }

  LevelInfo removeXp(LevelInfo info, int delta) {
    if (delta <= 0) return info;
    var level = info.level;
    if (level > maxLevel) {
      level = maxLevel;
    }
    var xp = info.xp;
    var remaining = delta;

    while (remaining > 0) {
      if (xp >= remaining) {
        xp -= remaining;
        remaining = 0;
      } else {
        remaining -= xp;
        if (level > 1) {
          level -= 1;
          xp = xpPerLevel;
        } else {
          xp = 0;
          remaining = 0;
        }
      }

      if (level == maxLevel && xp < 0) {
        xp = 0;
      }
      if (level <= 1 && xp <= 0) {
        xp = 0;
        remaining = 0;
      }
    }

    if (xp >= xpPerLevel) {
      xp = xpPerLevel - 1;
    }
    if (level < 1) {
      level = 1;
    }
    if (level >= maxLevel && xp < 0) {
      xp = 0;
    }

    return LevelInfo(level: level, xp: xp);
  }
}
