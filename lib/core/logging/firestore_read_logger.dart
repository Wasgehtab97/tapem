import 'package:flutter/foundation.dart';

class FirestoreReadLogger {
  const FirestoreReadLogger._();

  static void logStart({
    required String scope,
    required String path,
    String? operation,
    String? reason,
    String? traceId,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('FS_READ_START/$scope path=$path');
    if (operation != null) buffer.write(' op=$operation');
    if (reason != null) buffer.write(' reason=$reason');
    if (traceId != null) buffer.write(' traceId=$traceId');
    debugPrint(buffer.toString());
  }

  static void logResult({
    required String scope,
    required String path,
    int? count,
    bool? exists,
    bool? fromCache,
    String? traceId,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('FS_READ_DONE/$scope path=$path');
    if (count != null) buffer.write(' count=$count');
    if (exists != null) buffer.write(' exists=$exists');
    if (fromCache != null) buffer.write(' cache=$fromCache');
    if (traceId != null) buffer.write(' traceId=$traceId');
    debugPrint(buffer.toString());
  }

  static void logCacheHit({
    required String scope,
    required String path,
    String? traceId,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('FS_CACHE_HIT/$scope path=$path');
    if (traceId != null) buffer.write(' traceId=$traceId');
    debugPrint(buffer.toString());
  }
}
