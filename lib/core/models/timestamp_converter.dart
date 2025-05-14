// lib/core/models/timestamp_converter.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Konvertiert zwischen Firestore- [Timestamp] und Dart [DateTime].
///
/// Wird genutzt in `json_serializable`-annotierten Klassen, um
/// Firestore-Timestamps automatisch in DateTime und zurück zu wandeln.
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime dateTime) => Timestamp.fromDate(dateTime);
}
