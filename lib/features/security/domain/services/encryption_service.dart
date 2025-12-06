import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  EncryptionService({
    required String userId,
    FlutterSecureStorage? secureStorage,
  }) : _userId = userId,
       _storage = secureStorage ?? const FlutterSecureStorage();

  final String _userId;
  final FlutterSecureStorage _storage;
  
  String get _privateKeyStorageKey => 'tapem_chat_private_key_$_userId';
  
  // Use X25519 for key exchange (ECDH)
  final _algorithm = X25519();

  /// Generates a new key pair and stores the private key securely.
  /// Returns the public key as a Base64 string.
  Future<String> generateAndStoreKeyPair() async {
    final keyPair = await _algorithm.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    
    // Store private key
    final privateKeyBase64 = base64Encode(privateKeyBytes);
    await _storage.write(key: _privateKeyStorageKey, value: privateKeyBase64);
    
    if (kDebugMode) {
      debugPrint('[EncryptionService] Generated and stored new key pair');
    }

    // Return public key
    return base64Encode(publicKey.bytes);
  }

  /// Retrieves the stored private key.
  /// Returns null if no key is found.
  Future<SimpleKeyPair?> getPrivateKey() async {
    final privateKeyBase64 = await _storage.read(key: _privateKeyStorageKey);
    if (privateKeyBase64 == null) return null;

    try {
      final privateKeyBytes = base64Decode(privateKeyBase64);
      return _algorithm.newKeyPairFromSeed(privateKeyBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EncryptionService] Error decoding private key: $e');
      }
      return null;
    }
  }

  /// Gets the public key for the stored private key.
  /// Returns null if no private key is stored.
  Future<String?> getPublicKey() async {
    final keyPair = await getPrivateKey();
    if (keyPair == null) return null;

    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

   /// Checks if a private key exists in storage.
  Future<bool> hasKeyPair() async {
    final exists = await _storage.containsKey(key: _privateKeyStorageKey);
    if (kDebugMode) {
      debugPrint('[EncryptionService] hasKeyPair for $_userId: $exists (key: $_privateKeyStorageKey)');
    }
    return exists;
  }
  
  /// Clears the stored keys (DANGER: User will lose access to encrypted messages)
  Future<void> clearKeys() async {
    await _storage.delete(key: _privateKeyStorageKey);
  }

  // AES-GCM for symmetric encryption
  final _aes = AesGcm.with256bits();

  /// Encrypts data (like a conversation key) with a recipient's public key
  /// Uses X25519 ECDH + AES-GCM
  Future<String> encryptData(String data, String recipientPublicKeyBase64) async {
    final localKeyPair = await getPrivateKey();
    if (localKeyPair == null) {
      throw Exception('Local private key not found');
    }

    // Decode recipient's public key
    final recipientPublicKeyBytes = base64Decode(recipientPublicKeyBase64);
    final recipientPublicKey = SimplePublicKey(
      recipientPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // Compute shared secret (ECDH)
    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // Encrypt data with shared secret
    final nonce = _aes.newNonce();
    final secretBox = await _aes.encrypt(
      utf8.encode(data),
      secretKey: sharedSecret,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + MAC
    final combined = [
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return base64Encode(combined);
  }

  /// Decrypts data (like a conversation key) encrypted for this user
  /// Requires the sender's public key to derive the shared secret
  Future<String> decryptData(
    String encryptedDataBase64,
    String senderPublicKeyBase64,
  ) async {
    final localKeyPair = await getPrivateKey();
    if (localKeyPair == null) {
      throw Exception('Local private key not found');
    }

    // Decode sender's public key
    final senderPublicKeyBytes = base64Decode(senderPublicKeyBase64);
    final senderPublicKey = SimplePublicKey(
      senderPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // Compute shared secret (ECDH)
    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: senderPublicKey,
    );

    final combined = base64Decode(encryptedDataBase64);
    
    // Extract: nonce(12) + ciphertext + MAC(16)
    if (combined.length < 28) {
      throw Exception('Invalid encrypted data length');
    }

    final nonce = combined.sublist(0, 12);
    final mac = combined.sublist(combined.length - 16);
    final cipherText = combined.sublist(12, combined.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final decryptedBytes = await _aes.decrypt(
      secretBox,
      secretKey: sharedSecret,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Encrypts a message with a symmetric conversation key
  Future<Map<String, String>> encryptMessageWithKey(
    String message,
    SecretKey conversationKey,
  ) async {
    final nonce = _aes.newNonce();
    final secretBox = await _aes.encrypt(
      utf8.encode(message),
      secretKey: conversationKey,
      nonce: nonce,
    );

    // Combine ciphertext + MAC
    final combined = [...secretBox.cipherText, ...secretBox.mac.bytes];

    return {
      'content': base64Encode(combined),
      'nonce': base64Encode(nonce),
    };
  }

  /// Decrypts a message with a symmetric conversation key
  Future<String> decryptMessageWithKey(
    String encryptedContent,
    String nonceBase64,
    SecretKey conversationKey,
  ) async {
    final nonce = base64Decode(nonceBase64);
    final combined = base64Decode(encryptedContent);

    // Split ciphertext and MAC (last 16 bytes)
    if (combined.length < 16) {
      throw Exception('Invalid encrypted message length');
    }

    final mac = combined.sublist(combined.length - 16);
    final cipherText = combined.sublist(0, combined.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final decryptedBytes = await _aes.decrypt(
      secretBox,
      secretKey: conversationKey,
    );

    return utf8.decode(decryptedBytes);
  }
}

