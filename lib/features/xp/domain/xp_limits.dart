// lib/features/xp/domain/xp_limits.dart
//
// Centralised limits for XP pagination. Using small page sizes keeps Firestore
// reads predictable during hot restarts; callers can request more data via
// explicit "load more" actions when needed.

const int kXpHistoryPageLimit = 10;
const int kXpTrainingDayPageLimit = 10;
