import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/friends/domain/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final now = DateTime.now();

    test('supports sticker message type', () {
      final message = ChatMessage(
        id: '123',
        senderId: 'user1',
        type: MessageType.sticker,
        createdAt: now,
        stickerId: 'sticker_1',
      );

      expect(message.type, MessageType.sticker);
      expect(message.stickerId, 'sticker_1');
    });

    test('serialization handles sticker fields', () {
      final message = ChatMessage(
        id: '123',
        senderId: 'user1',
        type: MessageType.sticker,
        createdAt: now,
        stickerId: 'sticker_1',
      );

      final json = message.toFirestore();

      expect(json['type'], 'sticker');
      expect(json['stickerId'], 'sticker_1');
      expect(json['senderId'], 'user1');
    });

    test('deserialization handles sticker fields', () {
      final json = {
        'senderId': 'user1',
        'type': 'sticker',
        'createdAt': Timestamp.fromDate(now),
        'stickerId': 'sticker_1',
      };

      final message = ChatMessage.fromFirestore('123', json);

      expect(message.type, MessageType.sticker);
      expect(message.stickerId, 'sticker_1');
      expect(message.senderId, 'user1');
    });
  });
}
