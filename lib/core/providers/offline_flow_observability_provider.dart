import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/observability/offline_flow_observability_service.dart';

final offlineFlowObservabilityProvider =
    Provider<OfflineFlowObservabilityService>((ref) {
      return OfflineFlowObservabilityService.instance;
    });
