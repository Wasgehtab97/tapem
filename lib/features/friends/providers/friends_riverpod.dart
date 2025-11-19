// lib/features/friends/providers/friends_riverpod.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/friend_chat_api.dart';
import '../data/friend_chat_source.dart';
import '../data/friends_api.dart';
import '../data/friends_source.dart';
import '../data/user_search_source.dart';
import 'friend_alerts_provider.dart';
import 'friend_calendar_provider.dart';
import 'friend_chat_summary_provider.dart';
import 'friend_presence_provider.dart';
import 'friend_search_provider.dart';
import 'friends_provider.dart';

final friendsApiProvider = Provider<FriendsApi>((ref) => FriendsApi());

final friendsSourceProvider = Provider<FriendsSource>((ref) {
  return FriendsSource(FirebaseFirestore.instance);
});

final userSearchSourceProvider = Provider<UserSearchSource>((ref) {
  return UserSearchSource(FirebaseFirestore.instance);
});

final friendChatApiProvider = Provider<FriendChatApi>((ref) {
  return FriendChatApi();
});

final friendChatSourceProvider = Provider<FriendChatSource>((ref) {
  return FriendChatSource(FirebaseFirestore.instance);
});

final friendAlertsProvider = ChangeNotifierProvider<FriendAlertsProvider>((ref) {
  final provider = FriendAlertsProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

final friendsProvider = ChangeNotifierProvider<FriendsProvider>((ref) {
  final provider = FriendsProvider(
    ref.read(friendsSourceProvider),
    ref.read(friendsApiProvider),
  );
  ref.onDispose(provider.dispose);
  return provider;
});

final friendChatSummaryProvider =
    ChangeNotifierProvider<FriendChatSummaryProvider>((ref) {
  final provider = FriendChatSummaryProvider(ref.read(friendChatSourceProvider));
  ref.onDispose(provider.dispose);
  return provider;
});

final friendSearchProvider = ChangeNotifierProvider<FriendSearchProvider>((ref) {
  final provider = FriendSearchProvider(ref.read(userSearchSourceProvider));
  ref.onDispose(provider.dispose);
  return provider;
});

final friendCalendarProvider =
    ChangeNotifierProvider<FriendCalendarProvider>((ref) {
  final provider = FriendCalendarProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

final friendPresenceProvider =
    ChangeNotifierProvider<FriendPresenceProvider>((ref) {
  final provider = FriendPresenceProvider();
  ref.onDispose(provider.dispose);
  return provider;
});
