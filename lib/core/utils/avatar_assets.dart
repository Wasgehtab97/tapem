import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

/// Legacy wrapper around [AvatarCatalog].
///
/// New code should depend on [AvatarCatalog] directly. This class remains only
/// for backwards compatibility with existing call sites.
class AvatarAssets {
  AvatarAssets._();

  /// Default avatar key.
  static const defaultKey = 'global/default';

  /// Returns global avatar keys.
  static List<String> get keys => AvatarCatalog.instance.listGlobal();

  /// Resolves [key] to an asset path using [AvatarCatalog].
  static String path(String key) {
    return AvatarCatalog.instance.resolvePath(key);
  }
}
