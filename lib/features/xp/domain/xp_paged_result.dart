// lib/features/xp/domain/xp_paged_result.dart

/// Wrapper for Firestore list queries that exposes pagination metadata alongside
/// the materialised items. Keeps the pagination logic shared between sources,
/// repositories and providers.
class XpPagedResult<T> {
  XpPagedResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final T items;
  final bool hasMore;
  final String? nextCursor;
}
