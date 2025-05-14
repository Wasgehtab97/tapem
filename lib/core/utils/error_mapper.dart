// lib/core/utils/error_mapper.dart

/// Ordnet verschiedene Exception-Typen zu benutzerfreundlichen Meldungen zu.
String mapExceptionToMessage(Exception e) {
  final msg = e.toString();
  if (msg.contains('Network')) {
    return 'Netzwerkfehler – bitte Internetverbindung prüfen.';
  }
  // Weitere Typen lassen sich hier ergänzen…
  return 'Ein unerwarteter Fehler ist aufgetreten: $msg';
}
