# Prompt
Überarbeitete Community-Seite reparieren: Riverpod-"overridden dependency"-Crash beseitigen, UI-Overflow verhindern, Providers auf Families mit Dependencies umstellen, Logging ergänzen, Tests aktualisieren und Dokumentation anlegen.

# Ziel & Kontext
Die Community-Ansicht löste beim Öffnen einen Riverpod-Assertion-Fehler aus, weil ProviderScopes mit Overrides verschachtelt und Abhängigkeiten nicht deklariert waren. Zusätzlich führte der Fehlerzustand zu einem RenderFlex-Overflow. Ziel war eine robuste Implementierung auf Basis von Provider-Families ohne lokale Overrides, klaren Lade-/Fehlerzuständen sowie nachvollziehbarem Logging und Tests.

# Analyse (Root Cause)
* `CommunityScreen` umgab seine Inhalte mit einem lokalen `ProviderScope` und übersteuerte `communityGymIdProvider`, während abhängige Provider in einem anderen Scope erzeugt wurden. Dadurch passten die Dependency-Chains nicht zusammen und Riverpod warf beim Lesen der Provider eine Assertion.
* Die Fehleransicht war in einer festen `Column` eingebettet und konnte bei großen Fehlermeldungen nicht scrollen, was zum RenderFlex-Overflow führte.

# Umsetzung (Datei-/Code-Änderungen)
* `community_providers.dart`: Einführung von `CommunityPeriod`, `UtcRange`, neuen `StreamProvider`-Families mit `dependencies` und Entfernung der fragilen Overrides zugunsten von `currentGymIdProvider`. `periodToUtcRange` liefert DST-sichere Zeitfenster.
* `firestore_community_stats_source.dart` und `community_stats_service.dart`: neue Range-Streams, konsistentes Aggregieren von Stats sowie Logging für `FirebaseException`.
* `main.dart`: Riverpod-Scope unterhalb des Provider-MultiProviders platziert und `currentGymIdProvider` zentral mit dem Auth-Status verknüpft.
* `community_screen.dart`: komplette Neustrukturierung mit `TabBarView`, scrollbaren Slivern, getrennten Empty/Error-/Loading-States, Refresh-Handling und Entfernung aller lokalen Overrides.
* Tests (`community_screen_test.dart`, `period_to_utc_range_test.dart`): neue Widget- und Unit-Tests für Lade-, Leer-, Fehler- und Datenzustände sowie DST-Kantenfälle.

# Screenshots (vorher/nachher)
Keine Screenshots verfügbar (Headless-Testumgebung ohne lauffähigen Flutter-Build).

# Tests/Ergebnis
Versuch, `flutter test` auszuführen, scheiterte, da im Container kein Flutter-Binary verfügbar ist (`bash: command not found: flutter`).

# Offene Punkte
* In der laufenden App sicherstellen, dass `AuthProvider` den `gymCode` fortlaufend aktualisiert, damit `currentGymIdProvider` stets aktuelle Werte liefert.
* Manuelle End-to-End-Prüfung der neuen Scroll-Layouts auf echten Geräten nachholen.
