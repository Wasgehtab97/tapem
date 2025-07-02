import '../models/level_info.dart';

class LevelService {
  static const int xpPerLevel = 1000;
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
}
