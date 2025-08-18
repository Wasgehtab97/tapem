import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/core/services/membership_service.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';

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

  BrandingProvider({required FirestoreGymSource source, LogFn? log})
      : _source = source,
        _log = log ?? _defaultLog;

  Branding? _branding;
  bool _isLoading = false;
  String? _error;
  String? _gymId;

  Branding? get branding => _branding;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get gymId => _gymId;

  Future<void> loadBranding(String gymId) async {
    _isLoading = true;
    _error = null;
    _gymId = gymId;
    notifyListeners();

    final service =
        MembershipService(FirebaseFirestore.instance, FirebaseAuth.instance);

    Future<void> run() async {
      _branding = await _source.getBranding(gymId);
    }

    try {
      await service.ensureMembership(gymId: gymId);
      await run();
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        _log('RULES_DENIED(gyms/$gymId/config/branding)');
        try {
          await service.ensureMembership(gymId: gymId);
          await run();
        } catch (e2, st2) {
          _error = 'Fehler beim Laden: ${e2.toString()}';
          _log('BrandingProvider.loadBranding error: $e2', st2);
          _branding = null;
        }
      } else {
        _error = 'Fehler beim Laden: ${e.toString()}';
        _log('BrandingProvider.loadBranding error: $e', st);
        _branding = null;
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

  void loadBrandingWithGym(String? gymId) {
    if (gymId == null || gymId.isEmpty) {
      _branding = null;
      _gymId = null;
      notifyListeners();
      return;
    }
    loadBranding(gymId);
  }
}
