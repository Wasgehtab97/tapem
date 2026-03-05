# whatsnext

Dieses Verzeichnis dokumentiert den Arbeitsstand pro Kalendertag fuer die App **tapem**.
Ziel ist, dass Arbeitskontext, Entscheidungen und offene Punkte nicht nur im Chat stehen, sondern dauerhaft im Repository nachvollziehbar sind.

Wichtig: Dieser Ordner und sein Workflow gelten **nur fuer tapem**.
Es gibt **keine** Vermischung mit `picture_deals` (keine gemischten Commits, kein Pull/Push ins falsche Repo, keine uebernommenen Tagesdateien).

## Ziel und Zweck
- Tages-Snapshot festhalten: was umgesetzt wurde, aktueller Stand, Risiken, naechste Schritte.
- Kontinuitaet im Team sicherstellen: jeder kann nahtlos dort weiterarbeiten, wo zuletzt aufgehoert wurde.
- Entscheidungen und Trade-offs dokumentieren, damit spaetere Aenderungen nachvollziehbar sind.
- Abschluss pro Arbeitssession standardisieren (inkl. sauberem Repo-Status und Push).

## Dateinamen
- Format: `DD_MM_a.md`
- Pro Kalendertag genau **eine** Datei (Suffix immer `a`).
- Beispiele:
- `05_03_a.md`
- `06_03_a.md`

## Update-Regel
- Tagesdatei existiert noch nicht:
- Datei in `whatsnext/` anlegen.
- Tagesdatei existiert bereits:
- Neuen Block `## Update HH:MM:SS` anhaengen.

Damit entsteht eine fortgeschriebene Tageschronik statt vieler einzelner Session-Dateien.

## Pflichtstruktur pro Update-Block
Jeder neue Update-Block muss folgende Sektionen enthalten:
- `### Kontext`
- `### Umgesetzt`
- `### Aktueller Stand`
- `### Offene Punkte / Risiken`
- `### Naechste sinnvolle Schritte`

## Arbeitsprinzip
- Stichpunkte statt Fliesstext.
- Konkrete Dateipfade nennen, wenn Code geaendert wurde.
- Ehrlicher Status: was funktioniert, was noch offen ist.
- Keine kosmetischen Aussagen ohne technischen Mehrwert.

## Repo-Abgrenzung (kritisch)
Bei Arbeit in `tapem` gilt strikt:
- Git-Operationen (`fetch`, `pull`, `commit`, `push`) nur im `tapem`-Repository.
- Pull/Push ausschliesslich auf Branch `antigravity_dev` (z. B. `git pull origin antigravity_dev`, `git push origin antigravity_dev`).
- Keine Dateien aus `picture_deals` uebernehmen.
- Keine gemeinsamen Commits ueber beide Projekte.
- `whatsnext`-Eintraege muessen sich ausschliesslich auf `tapem` beziehen.

## Chat-Shortcut: `make start`
Wenn im Chat `make start` steht, ist damit ein **Codex-Workflow** gemeint (kein notwendiger Terminal-Make-Target):
- Aktuellen Stand von GitHub fuer Branch `antigravity_dev` im `tapem`-Repo holen.
- Neue/geaenderte `whatsnext`-Eintraege seit dem letzten Stand kurz zusammenfassen.
- Naechste sinnvolle Schritte als klare, priorisierte Stichpunkte ausgeben.
- Eventuelle Risiken/Blocker sofort benennen.

Erwartetes Ergebnis im Chat:
- Kurze Zusammenfassung des aktuellen Stands.
- Konkrete Next Steps fuer die naechste Umsetzung.

## Chat-Shortcut: `make finish`
Wenn im Chat `make finish` steht, ist damit ein **Codex-Workflow** gemeint (kein notwendiger Terminal-Make-Target):
- Tagesdatei in `whatsnext/` erstellen oder mit `## Update HH:MM:SS` fortschreiben.
- Relevante Aenderungen im `tapem`-Repo committen.
- Commit ausschliesslich auf `origin/antigravity_dev` pushen.
- Kompakte Discord-Zusammenfassung direkt im Chat ausgeben.

Erwartetes Ergebnis im Chat:
- Welche Datei in `whatsnext/` aktualisiert wurde.
- Commit-Info (Hash/Message) und Push-Status.
- Kurze Zusammenfassung fuer Team-Weitergabe.

## Hinweis zu Makefile
`make start` und `make finish` sind hier als **Chat-Befehle/Shortcuts fuer Codex** definiert.
Selbst wenn es im technischen Makefile gleichnamige Targets geben sollte, ist fuer diesen Workflow die Chat-Ausfuehrung massgeblich.
