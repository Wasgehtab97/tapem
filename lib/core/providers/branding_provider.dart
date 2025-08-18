import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/services/membership_service.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

// TODO: replace with real logging service
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
  final MembershipService _membership;

  BrandingProvider({
    required FirestoreGymSource source,
    required MembershipService membership,
    LogFn? log,
  })  : _source = source,
        _membership = membership,
        _log = log ?? _defaultLog;

  Branding? _branding;
  bool _isLoading = false;
  String? _error;
  String? _gymId;

  Branding? get branding => _branding;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get gymId => _gymId;

  Future<void> loadBranding(String gymId, String uid) async {
    _isLoading = true;
    _error = null;
    _gymId = gymId;
    notifyListeners();
    try {
      await _membership.ensureMembership(gymId, uid);
      try {
        _branding = await _source.getBranding(gymId);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          _log('RULES_DENIED path=gyms/$gymId/config/branding op=read');
          await _membership.ensureMembership(gymId, uid);
          _log(
              'RETRY_AFTER_ENSURE_MEMBERSHIP path=gyms/$gymId/config/branding op=read');
          _branding = await _source.getBranding(gymId);
        } else {
          rethrow;
        }
      }
    } catch (e, st) {
      _error = 'Fehler beim Laden: ${e.toString()}';
      _log('BrandingProvider.loadBranding error: $e', st);
      _branding = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadBrandingWithGym(String? gymId, String? uid) {
    if (gymId == null || gymId.isEmpty || uid == null) {
      _branding = null;
      _gymId = null;
      notifyListeners();
      return;
    }
    loadBranding(gymId, uid);
  }
}
