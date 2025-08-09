# Secrets Policy

## Do
- Nutze `.env`-Dateien und lokale Firebase-Konfigurationen.
- Prüfe Commits mit `gitleaks` bevor du pushst.
- Drehe Schlüssel sofort, wenn sie kompromittiert wurden.

## Don't
- Keine Service Accounts oder API-Keys committen.
- Keine `google-services.json` oder `GoogleService-Info.plist` ins Repo legen.
- Keine Zertifikate (`*.pem`, `*.p12`) einchecken.

## Rotation
1. Schlüssel im Anbieter-Dashboard widerrufen.
2. Neuen Schlüssel erzeugen und lokal eintragen.
3. Betroffene Secrets in `.env` oder Firebase-Konfig anpassen.
