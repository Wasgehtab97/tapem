import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_provider.dart';
import '../data/friends_api.dart';
import '../data/friends_source.dart';
import '../data/user_search_source.dart';

final friendsApiProvider = Provider<FriendsApi>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FriendsApi(firestore: firestore);
});

final friendsSourceProvider = Provider<FriendsSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FriendsSource(firestore);
});

final userSearchSourceProvider = Provider<UserSearchSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserSearchSource(firestore);
});
