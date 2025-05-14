import 'package:tapem/domain/models/tenant.dart';

/// States für den TenantBloc.
abstract class TenantState {}

/// Initialzustand.
class TenantInitial extends TenantState {}

/// Ladezustand.
class TenantLoading extends TenantState {}

/// State, wenn Tenant erfolgreich geladen/gesetzt wurde.
class TenantLoadSuccess extends TenantState {
  final Tenant tenant;
  TenantLoadSuccess(this.tenant);
}

/// Fehlerzustand.
class TenantFailure extends TenantState {
  final String message;
  TenantFailure(this.message);
}
