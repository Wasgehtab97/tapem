// lib/bootstrap/providers.dart
//
// Legacy import facade that re-exports Riverpod providers from their
// respective feature folders. Existing code can continue importing this file
// while new code can depend on the feature-specific definitions directly.

export '../core/providers/auth_providers.dart';
export '../core/providers/gym_context_provider.dart';
export '../core/providers/gym_scoped_resettable.dart';
export '../core/providers/shared_preferences_provider.dart';
export '../core/providers/database_provider.dart';
export '../features/report/providers/report_providers.dart';
export '../services/membership_service.dart';
