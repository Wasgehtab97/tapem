import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/features/admin/data/services/gym_member_directory_service.dart';
import 'package:tapem/features/admin/data/services/gym_user_removal_service.dart';

final adminAuditLoggerProvider = Provider<AdminAuditLogger>((ref) {
  return AdminAuditLogger();
});

final gymMemberDirectoryServiceProvider = Provider<GymMemberDirectoryService>((
  ref,
) {
  return GymMemberDirectoryService();
});

final gymUserRemovalServiceProvider = Provider<GymUserRemovalService>((ref) {
  final auditLogger = ref.watch(adminAuditLoggerProvider);
  return GymUserRemovalService(auditLogger: auditLogger);
});
