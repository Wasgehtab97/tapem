import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';

class BrandingSaveInput {
  const BrandingSaveInput({
    required this.gymId,
    required this.actorUid,
    required this.primaryHex,
    required this.accentHex,
    this.logoUrl,
  });

  final String gymId;
  final String actorUid;
  final String primaryHex;
  final String accentHex;
  final String? logoUrl;
}

class BrandingAdminService {
  BrandingAdminService({
    FirebaseFirestore? firestore,
    AdminAuditLogger? auditLogger,
    OwnerActionObservabilityService? observability,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogger = auditLogger ?? AdminAuditLogger(),
       _observability =
           observability ?? OwnerActionObservabilityService.instance;

  final FirebaseFirestore _firestore;
  final AdminAuditLogger _auditLogger;
  final OwnerActionObservabilityService _observability;
  static final RegExp _hexRegExp = RegExp(r'^[0-9a-fA-F]{6}$');

  Future<void> saveBranding(BrandingSaveInput input) async {
    final gymId = input.gymId.trim();
    if (gymId.isEmpty) {
      throw ArgumentError('gymId must not be empty.');
    }
    if (!_hexRegExp.hasMatch(input.primaryHex)) {
      throw ArgumentError('primaryHex must be a 6-char hex value.');
    }
    if (!_hexRegExp.hasMatch(input.accentHex)) {
      throw ArgumentError('accentHex must be a 6-char hex value.');
    }

    final logoUrl = input.logoUrl?.trim();
    final normalizedLogoUrl = (logoUrl == null || logoUrl.isEmpty)
        ? null
        : logoUrl;
    final gymRef = _firestore.collection('gyms').doc(gymId);
    final brandingPayload = <String, dynamic>{
      'primaryColor': input.primaryHex,
      'secondaryColor': input.accentHex,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final gymPayload = <String, dynamic>{
      'primaryColor': input.primaryHex,
      'accentColor': input.accentHex,
    };
    if (normalizedLogoUrl != null) {
      brandingPayload['logoUrl'] = normalizedLogoUrl;
      gymPayload['logoUrl'] = normalizedLogoUrl;
    }

    await _observability.trackAction(
      action: 'owner.branding.save',
      command: () async {
        final batch = _firestore.batch();
        batch.set(
          gymRef.collection('config').doc('branding'),
          brandingPayload,
          SetOptions(merge: true),
        );
        batch.set(gymRef, gymPayload, SetOptions(merge: true));
        await batch.commit();
      },
    );

    await _auditLogger.logGymAction(
      gymId: gymId,
      action: 'branding_update',
      actorUid: input.actorUid,
      metadata: <String, dynamic>{
        'primaryColor': input.primaryHex,
        'accentColor': input.accentHex,
        'hasLogoUrl': normalizedLogoUrl != null,
      },
    );
  }
}
