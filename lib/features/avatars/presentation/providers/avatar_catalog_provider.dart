import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/avatar_repository.dart';
import '../../domain/models/avatar_catalog_item.dart';
import '../../domain/models/visible_avatar.dart';
import '../../../core/config/remote_config.dart';

class AvatarCatalogProvider extends ChangeNotifier {
  AvatarCatalogProvider({FirebaseFirestore? firestore})
      : _repo = AvatarRepository(firestore ?? FirebaseFirestore.instance);

  final AvatarRepository _repo;
  List<AvatarCatalogItem> _items = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load(String gymId) async {
    if (!RC.avatarsV2Enabled) return;
    _items = await _repo.loadCatalog(gymId);
    _isLoaded = true;
    assert(() {
      debugPrint('Loaded avatars: ' + _items.map((e) => e.id).join(', '));
      return true;
    }());
    notifyListeners();
  }

  List<VisibleAvatar> getAllVisibleAvatarsForUser(String userId, String gymId) {
    if (!_isLoaded || !RC.avatarsV2Enabled) return [];
    return _items
        .map((e) => VisibleAvatar(item: e, locked: true))
        .toList(growable: false);
  }
}
