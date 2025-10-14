# PR4 – Story Card UI & Sharing

## Prompt
- SessionStoryCard(sessionId) mit XP, PR-Badges, Muskel-Tags und Modal-Trigger nach session_closed
- Header-Shortcut, PNG-Export via RepaintBoundary, Share-Sheet + optional Dynamic Link
- Dark/Light-Design mit Konfetti, Analytics-Events, Golden-/Smoke-Tests

## Ziel/Kontext
Der vierte Schritt der Session-Serie macht die Gamification nach außen sichtbar: Nutzer:innen sollen direkt nach dem Tagesabschluss eine visuell konsistente Story Card sehen, die XP, „Erste Male" und Top-Muskeln hervorhebt. Die Karte muss offline aus dem Cache rendern, in beiden Themes funktionieren und sich unkompliziert erneut über einen Header-Button öffnen lassen. Durch PNG-Export, optionalen Deep Link und Telemetrie wird die Session-Story teilbar und messbar.

## Ergebnis
- Vollständige Lokalisierung der Story-Strings (EN/DE) inkl. Header-Tooltip, XP-Breakdown und Muskel-Fallbacks, damit UI und Snackbars ohne harte Texte funktionieren.
- SessionStoryCard nutzt nun `AppLocalizations`, formatierte NumberFormat-Ausgaben und greift auf lokalisierte Labels für PR-, Muskel- und Stat-Sektionen zu.
- Share-Service speichert/teilt PNGs deterministisch unter `Tapem/Stories/YYYYMMDD_sessionId.png`, während das Training-Detail-AppBar den Story-Shortcut lokalisiert ausgibt.
