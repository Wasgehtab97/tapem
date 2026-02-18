import 'package:tapem/l10n/app_localizations.dart';

enum WorkoutFlowErrorCode {
  missingUserContext,
  missingGymContext,
  saveFailed,
  discardFailed,
}

String workoutFlowErrorMessage(
  AppLocalizations loc,
  WorkoutFlowErrorCode code,
) {
  final details = switch (code) {
    WorkoutFlowErrorCode.missingUserContext => 'Nutzerkontext fehlt.',
    WorkoutFlowErrorCode.missingGymContext => 'Studio-Kontext fehlt.',
    WorkoutFlowErrorCode.saveFailed =>
      'Training konnte nicht gespeichert werden.',
    WorkoutFlowErrorCode.discardFailed =>
      'Training konnte nicht beendet werden.',
  };
  return '${loc.errorPrefix}: $details';
}
