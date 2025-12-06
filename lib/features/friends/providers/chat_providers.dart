import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/providers/firebase_provider.dart';
import '../data/repositories/chat_repository.dart';
import '../application/services/chat_service.dart';
import '../application/services/conversation_key_service.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/conversation.dart';
import 'friends_provider.dart';
import '../../../core/data/user_profile_service.dart';
import '../../security/providers/security_providers.dart';

/// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ChatRepository(firestore: firestore);
});

/// Provider for UserProfileService
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// Provider for ConversationKeyService
final conversationKeyServiceProvider = Provider.family<ConversationKeyService, String>((ref, userId) {
  final encryptionService = ref.watch(encryptionServiceProvider(userId));
  final userProfileService = ref.watch(userProfileServiceProvider);
  return ConversationKeyService(
    encryptionService: encryptionService,
    userProfileService: userProfileService,
  );
});

/// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final friendsState = ref.watch(friendsProvider);
  
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) {
    throw StateError('Cannot create ChatService without authenticated user');
  }
  
  final encryptionService = ref.watch(encryptionServiceProvider(currentUserId));
  final conversationKeyService = ref.watch(conversationKeyServiceProvider(currentUserId));
  
  return ChatService(
    repository: repository,
    auth: FirebaseAuth.instance,
    isFriendCallback: (friendUid) => friendsState.isFriend(friendUid),
    encryptionService: encryptionService,
    conversationKeyService: conversationKeyService,
  );
});

/// Provider for watching messages in a friend chat
///
/// Usage: ref.watch(chatMessagesProvider(friendUid))
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, friendUid) {
    final service = ref.watch(chatServiceProvider);
    return service.watchMessages(friendUid);
  },
);

/// Provider for watching conversation details
///
/// Usage: ref.watch(chatConversationProvider(friendUid))
final chatConversationProvider = StreamProvider.family<Conversation?, String>(
  (ref, friendUid) {
    final repository = ref.watch(chatRepositoryProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Stream.value(null);
    
    final conversationId = repository.getConversationId(currentUserId, friendUid);
    return repository.watchConversation(conversationId);
  },
);
