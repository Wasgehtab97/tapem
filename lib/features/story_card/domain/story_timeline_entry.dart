import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class StoryTimelineEntry {
  final String id;
  final String sessionId;
  final String? gymId;
  final String? gymName;
  final String title;
  final DateTime createdAt;
  final List<String> prTypes;
  final int prCount;
  final double xpTotal;
  final double xpBase;
  final double xpBonus;
  final List<Color> previewColors;
  final String? thumbnailUrl;
  final int setCount;
  final double durationMin;
  final double totalVolume;

  const StoryTimelineEntry({
    required this.id,
    required this.sessionId,
    required this.gymId,
    required this.gymName,
    required this.title,
    required this.createdAt,
    required this.prTypes,
    required this.prCount,
    required this.xpTotal,
    required this.xpBase,
    required this.xpBonus,
    required this.previewColors,
    required this.thumbnailUrl,
    required this.setCount,
    required this.durationMin,
    required this.totalVolume,
  });

  factory StoryTimelineEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = (data['createdAt'] as Timestamp?) ?? (data['occurredAt'] as Timestamp?) ?? Timestamp.now();
    final previewColors = _parseColors(data['previewColors']);
    final summary = data['summary'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['summary'] as Map) : const {};
    return StoryTimelineEntry(
      id: doc.id,
      sessionId: (data['sessionId'] as String?) ?? doc.id,
      gymId: data['gymId'] as String?,
      gymName: (data['gymName'] as String?)?.trim().isEmpty ?? true ? null : (data['gymName'] as String?)?.trim(),
      title: (data['title'] as String?)?.trim() ?? 'Session',
      createdAt: createdAt.toDate(),
      prTypes: _parseStringList(data['prTypes']),
      prCount: _parseInt(data['prCount']),
      xpTotal: _parseDouble(data['xpTotal']),
      xpBase: _parseDouble(data['xpBase']),
      xpBonus: _parseDouble(data['xpBonus']),
      previewColors: previewColors,
      thumbnailUrl: (data['thumbnailUrl'] as String?)?.trim().isEmpty ?? true ? null : (data['thumbnailUrl'] as String?)?.trim(),
      setCount: _parseInt(summary['setCount']),
      durationMin: _parseDouble(summary['durationMin']),
      totalVolume: _parseDouble(summary['totalVolume']),
    );
  }

  static List<Color> _parseColors(dynamic value) {
    if (value is List) {
      final colors = <Color>[];
      for (final entry in value) {
        if (entry is String && entry.trim().isNotEmpty) {
          colors.add(_colorFromHex(entry.trim()));
        }
      }
      if (colors.isNotEmpty) {
        return colors;
      }
    }
    return const [Color(0xFF36D1DC), Color(0xFF5B86E5)];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is Iterable) {
      return value.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    }
    return const [];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

@immutable
class StoryTimelineMetrics {
  final int sessionCount;
  final int prSessionCount;
  final int prEventCount;
  final int shareCount;
  final int viewCount;
  final double totalXp;

  const StoryTimelineMetrics({
    required this.sessionCount,
    required this.prSessionCount,
    required this.prEventCount,
    required this.shareCount,
    required this.viewCount,
    required this.totalXp,
  });

  factory StoryTimelineMetrics.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return StoryTimelineMetrics(
      sessionCount: _parseInt(data['sessionCount']),
      prSessionCount: _parseInt(data['prSessionCount']),
      prEventCount: _parseInt(data['prEventCount']),
      shareCount: _parseInt(data['shareCount']),
      viewCount: _parseInt(data['storyShownCount']),
      totalXp: _parseDouble(data['totalXp']),
    );
  }

  double get shareRate => sessionCount == 0 ? 0 : shareCount / sessionCount;

  double get prSessionsPerHundred => sessionCount == 0 ? 0 : (prSessionCount / sessionCount) * 100;

  double get averageXpPerSession => sessionCount == 0 ? 0 : totalXp / sessionCount;
}
