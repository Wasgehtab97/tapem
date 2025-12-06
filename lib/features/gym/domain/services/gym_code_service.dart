// lib/features/gym/domain/services/gym_code_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_code.dart';
import '../models/gym_code_validation_result.dart';
import '../exceptions/gym_code_exceptions.dart';

/// Service for generating, validating, and rotating gym codes
class GymCodeService {
  final FirebaseFirestore _firestore;

  // Characters without ambiguity: no O/0, I/1, S/5, Z/2
  static const _readableChars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
  static const _codeLength = 6;

  GymCodeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate a random, readable 6-character code
  String generateCode() {
    final random = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _readableChars[random.nextInt(_readableChars.length)],
    ).join();
  }

  /// Validate a gym code and return gym information
  /// Throws [GymCodeNotFoundException], [GymCodeExpiredException], or [GymCodeInactiveException]
  Future<GymCodeValidationResult> validateCode(String code) async {
    // Normalize code (uppercase, trim)
    final normalizedCode = code.trim().toUpperCase();

    // Validate format
    if (normalizedCode.length != _codeLength) {
      throw const InvalidCodeFormatException();
    }

    print('🔍 Searching for code: $normalizedCode');

    // NEW APPROACH: Get all gyms and search their codes directly
    // This avoids the collectionGroup index issue
    try {
      final gymsSnapshot = await _firestore.collection('gyms').get();
      print('📋 Found ${gymsSnapshot.docs.length} gyms to search');

      GymCode? foundCode;
      String? foundGymId;

      // Search through each gym's codes
      for (final gymDoc in gymsSnapshot.docs) {
        final gymId = gymDoc.id;
        print('  Checking gym: $gymId');

        final codesSnapshot = await _firestore
            .collection('gym_codes')
            .doc(gymId)
            .collection('codes')
            .where('code', isEqualTo: normalizedCode)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (codesSnapshot.docs.isNotEmpty) {
          print('  ✅ Found code in gym: $gymId');
          foundCode = GymCode.fromFirestore(
            codesSnapshot.docs.first.id,
            codesSnapshot.docs.first.data(),
          );
          foundGymId = gymId;
          break;
        }
      }

      if (foundCode == null || foundGymId == null) {
        print('❌ Code not found in any gym');
        throw const GymCodeNotFoundException();
      }

      print('✅ Code found and active');

      // Check if code has expired
      if (foundCode.isExpired) {
        final gymDoc = await _firestore.collection('gyms').doc(foundGymId).get();
        final gymName = gymDoc.data()?['name'] as String?;

        throw GymCodeExpiredException(
          expiredAt: foundCode.expiresAt,
          gymName: gymName,
        );
      }

      // Get gym details
      final gymDoc = await _firestore.collection('gyms').doc(foundGymId).get();
      if (!gymDoc.exists) {
        throw const GymCodeNotFoundException(
          'Gym not found for this code. Please contact support.',
        );
      }

      final gymName = gymDoc.data()?['name'] as String? ?? 'Unknown Gym';

      print('🎉 Validation successful for gym: $gymName');

      return GymCodeValidationResult(
        gymId: foundCode.gymId,
        gymName: gymName,
        code: foundCode.code,
        expiresAt: foundCode.expiresAt,
      );
    } catch (e) {
      print('❌ Validation error: $e');
      rethrow;
    }
  }

  /// Get the currently active code for a gym
  Future<GymCode?> getActiveCodeForGym(String gymId) async {
    final now = Timestamp.now();

    final querySnapshot = await _firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return GymCode.fromFirestore(doc.id, doc.data());
  }

  /// Create a new gym code
  Future<GymCode> createCode({
    required String gymId,
    required String createdBy,
    DateTime? expiresAt,
  }) async {
    final code = generateCode();
    final now = DateTime.now();
    final expiration = expiresAt ?? _getNextMonthStart();

    final gymCode = GymCode(
      id: '', // Will be set by Firestore
      code: code,
      gymId: gymId,
      createdAt: now,
      expiresAt: expiration,
      isActive: true,
      createdBy: createdBy,
    );

    final docRef = await _firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .add(gymCode.toFirestore());

    return gymCode.copyWith(id: docRef.id);
  }

  /// Rotate gym code: create new code and deactivate old ones
  Future<GymCode> rotateCode({
    required String gymId,
    required String createdBy,
  }) async {
    // Create new code
    final newCode = await createCode(
      gymId: gymId,
      createdBy: createdBy,
    );

    // Deactivate old codes (after 24h grace period)
    final gracePeriod = DateTime.now().subtract(const Duration(hours: 24));

    final oldCodes = await _firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .where('isActive', isEqualTo: true)
        .where('createdAt', isLessThan: Timestamp.fromDate(gracePeriod))
        .get();

    // Batch update to deactivate old codes
    final batch = _firestore.batch();
    for (final doc in oldCodes.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();

    return newCode;
  }

  /// Get code history for a gym
  Future<List<GymCode>> getCodeHistory(String gymId, {int limit = 10}) async {
    final querySnapshot = await _firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => GymCode.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Deactivate a specific code
  Future<void> deactivateCode(String gymId, String codeId) async {
    await _firestore
        .collection('gym_codes')
        .doc(gymId)
        .collection('codes')
        .doc(codeId)
        .update({'isActive': false});
  }

  /// Get the start of next month
  DateTime _getNextMonthStart() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth;
  }

  /// Check if a code already exists (for testing/migration)
  Future<bool> codeExists(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final querySnapshot = await _firestore
        .collectionGroup('codes')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  /// Generate a unique code (ensures no duplicates)
  Future<String> generateUniqueCode({int maxAttempts = 10}) async {
    for (var i = 0; i < maxAttempts; i++) {
      final code = generateCode();
      final exists = await codeExists(code);
      if (!exists) {
        return code;
      }
    }
    throw Exception('Failed to generate unique code after $maxAttempts attempts');
  }
}
