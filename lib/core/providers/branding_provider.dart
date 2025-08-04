import 'package:flutter/foundation.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

void _defaultLog(String message, [StackTrace? stack]) {
  if (stack != null) {
    debugPrintStack(label: message, stackTrace: stack);
  } else {
    debugPrint(message);
  }
}

class BrandingProvider extends ChangeNotifier {
  final FirestoreGymSource _source;
  final LogFn _log;

  BrandingProvider({FirestoreGymSource? source, LogFn? log})
    : _source = source ?? FirestoreGymSource(),
      _log = log ?? _defaultLog;

  Branding? _branding;
  bool _isLoading = false;
  String? _error;

  Branding? get branding => _branding;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBranding(String gymId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _branding = await _source.getBranding(gymId);
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      _log('BrandingProvider.loadBranding error: $e', st);
      _branding = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadBrandingWithGym(String? gymId) {
    if (gymId == null || gymId.isEmpty) {
      _branding = null;
      notifyListeners();
      return;
    }
    loadBranding(gymId);
  }
}
