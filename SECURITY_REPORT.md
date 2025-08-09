# Gitleaks Security Report

Dieses Repository verwendet [Gitleaks](https://github.com/gitleaks/gitleaks), um versehentlich eingecheckte Secrets zu finden.

## Workflow ausführen

1. Öffne den Reiter **Actions** in GitHub.
2. Wähle **Security - Gitleaks**.
3. Klicke auf **Run workflow**.

## Report abrufen

Nach Abschluss des Laufs steht der Report als Artifact **gitleaks-report** zum Download bereit.

## Bei Findings > 0

1. Betroffene Dateien aus dem Commit entfernen.
2. Schlüssel im jeweiligen Dienst rotieren und neu konfigurieren.
3. Nur im Ausnahmefall Git-Historie neu schreiben.
