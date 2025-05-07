// lib/core/utils/error_mapper.dart

String mapExceptionToMessage(Exception e) {
  // Beispiel-Switch, je nach Typ der Exception
  if (e.toString().contains('Network')) {
    return 'Netzwerkfehler – bitte Internetverbindung prüfen.';
  }
  // Default-Fall
  return 'Es ist ein Fehler aufgetreten: ${e.toString()}';
}
