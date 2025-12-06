import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../../../security/domain/services/encryption_service.dart';
import '../../../../core/data/user_profile_service.dart';
import '../../domain/models/conversation_key.dart';

/// Service for managing conversation encryption keys
class ConversationKeyService {
  ConversationKeyService({
    required EncryptionService encryptionService,
    required UserProfileService userProfileService,
    FirebaseFirestore? firestore,
  })  : _encryptionService = encryptionService,
        _userProfileService = userProfileService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final EncryptionService _encryptionService;
  final UserProfileService _userProfileService;
  final FirebaseFirestore _firestore;
  final _aes = AesGcm.with256bits();

  /// Initialize a conversation key for two participants
  /// Generates a random AES key and encrypts it for both users WITH THEIR OWN PUBLIC KEYS
  /// This way, each user can decrypt it using their own private key
  Future<void> initializeConversationKey({
    required String conversationId,
    required String creatorId,
    required String userAId,
    required String userBId,
  }) async {
    if (kDebugMode) {
     debugPrint('[ConversationKeyService] Initializing key for $conversationId');
    }

    // Generate random conversation key (AES-256)
    final conversationKey = await _aes.newSecretKey();
    final conversationKeyBytes = await conversationKey.extractBytes();
    final conversationKeyBase64 = base64Encode(conversationKeyBytes);

    // Get public keys for both users
    final userAProfile = await _userProfileService.getPublicProfile(userAId);
    final userBProfile = await _userProfileService.getPublicProfile(userBId);

    final userAPublicKey = userAProfile?.publicKey;
    final userBPublicKey = userBProfile?.publicKey;

    if (userAPublicKey == null || userBPublicKey == null) {
      throw Exception('Missing public keys for participants');
    }

    // Encrypt conversation key for each user WITH THEIR OWN PUBLIC KEY
    // This allows each to decrypt with their own private key
    final encryptedForA = await _encryptionService.encryptData(
      conversationKeyBase64,
      userAPublicKey,
    );
    final encryptedForB = await _encryptionService.encryptData(
      conversationKeyBase64,
      userBPublicKey,
    );

    // Store in Firestore with creatorId to enable decryption
    final batch = _firestore.batch();
    final keysCollection = _firestore
        .collection('conversationKeys')
        .doc(conversationId)
        .collection('participants');

    batch.set(
      keysCollection.doc(userAId),
      {
        ...ConversationKey(
          conversationId: conversationId,
          userId: userAId,
          encryptedKey: encryptedForA,
          createdAt: DateTime.now(),
        ).toFirestore(),
        'encryptedBy': creatorId, // Store who encrypted it
      },
    );

    batch.set(
      keysCollection.doc(userBId),
      {
        ...ConversationKey(
          conversationId: conversationId,
          userId: userBId,
          encryptedKey: encryptedForB,
          createdAt: DateTime.now(),
        ).toFirestore(),
        'encryptedBy': creatorId, // Store who encrypted it
      },
    );

    await batch.commit();

    if (kDebugMode) {
      debugPrint('[ConversationKeyService] Key initialized successfully');
    }
  }

  /// Get the decrypted conversation key for the current user
  Future<SecretKey?> getConversationKey({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('conversationKeys')
          .doc(conversationId)
          .collection('participants')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final conversationKey = ConversationKey.fromFirestore(data);
      final encryptedBy = data['encryptedBy'] as String;
      
      // Get the creator's public key (who encrypted this)
      final creatorProfile = await _userProfileService.getPublicProfile(encryptedBy);
      final creatorPublicKey = creatorProfile?.publicKey;
      
      if (creatorPublicKey == null) {
        throw Exception('Creator public key not found');
      }
      
      // Decrypt the key using creator's public key
      final decryptedKeyBase64 = await _encryptionService.decryptData(
        conversationKey.encryptedKey,
        creatorPublicKey,
      );
      
      final keyBytes = base64Decode(decryptedKeyBase64);
      return SecretKey(keyBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversationKeyService] Failed to get conversation key: $e');
      }
      return null;
    }
  }
}
