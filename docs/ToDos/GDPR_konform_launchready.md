# GDPR-konform Launch-Readiness Checklist (tapem)

Ziel: Eine pragmatische, umsetzbare Checkliste, damit tapem GDPR-konform an Studios vermarktet und betrieben werden kann.
Hinweis: Keine Rechtsberatung – für finale Texte/Verträge bitte juristische Prüfung.

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## 1) Dateninventar & Transparenz (Must-have)

- [ ] Verzeichnis von Verarbeitungstätigkeiten erstellen (Art. 30 DSGVO).
  - [ ] Datenkategorien (z. B. Trainingsdaten, Profile, Chat, Feedback).
  - [ ] Zwecke (z. B. Trainingslog, Community, Studio-Insights).
  - [ ] Betroffene (Mitglieder, Trainer, Admins).
  - [ ] Empfänger (Studio, tapem, Subprozessoren).
  - [ ] Speicherfristen pro Datentyp.
- [ ] Datenfluss-Diagramm (App → Firebase → Analytics/Push → Admin-Web).
- [ ] Datenschutzinformationen für Mitglieder und Studios finalisieren.
- [ ] Pflichtinformationen in App/Website verlinken (Impressum, Datenschutz, Kontakt).

## 2) Rollen & Verträge (Must-have)

- [ ] Rollen klären: Studio = Verantwortlicher, tapem = Auftragsverarbeiter (meistens).
- [ ] AVV/DPA-Vorlage erstellen und mit Pilotstudios verwenden.
- [ ] Subprozessoren-Liste dokumentieren (Firebase, Hosting, E-Mail, etc.).
- [ ] Support-/Sicherheitskontakt definieren (privacy@ / support@).

## 3) Technische Mandantentrennung (Must-have)

- [ ] Firestore Rules auditieren: Mandanten-Trennung durchsetzen.
  - [ ] Top-Level `users` nur Owner oder public-safe Subset.
  - [ ] `gyms/{gymId}` und `config` nur `inGym(gymId)`.
  - [ ] `devices`, `reports`, `surveys`, `feedback` nur Gym-Mitglieder/Role.
- [ ] Public Profile vs Private Profile trennen.
  - [ ] `public_profiles` minimal halten (Avatar, Username).
  - [ ] Private Felder ausschließlich Owner-/Gym-Admin.
- [ ] Admin-Sichten: Zugriff nur auf Mitglieder des eigenen Gyms.
- [ ] Cross-Gym Datenzugriff nur mit explizitem Opt-in.

## 4) Freunde, Social & Chat (kritisch)

- [ ] Friend-Flow nur nach gegenseitiger Zustimmung (Request → Accept).
- [ ] Chat-Erstellung nur für akzeptierte Friends (regelbasiert / via Cloud Function).
- [ ] Sichtbarkeit von Progress/Stats: Opt-in + Privacy-Settings.
- [ ] Gym-übergreifende Friends: klares Consent & UI-Schalter.
- [ ] Block/Report-Funktion für Nutzer einführen.

## 5) Datenminimierung & Speicherfristen (Must-have)

- [ ] Nur erforderliche Felder speichern (kein Over-Collection).
- [ ] Default: Privat, Nutzer entscheidet über Sichtbarkeit.
- [ ] Löschkonzept definieren:
  - [ ] Account-Löschung (inkl. Training, Chat, Tokens).
  - [ ] Studio-Offboarding (Datenexport + Löschung).
- [ ] Retention-Policy pro Datentyp dokumentieren.

## 6) Sicherheit & Zugriffskontrolle (Must-have)

- [ ] App Check aktivieren (Firebase App Check).
- [ ] Regeln testen: Emulator-Tests für Multi-Tenant & Friends.
- [ ] Least-Privilege für Admin/Coach Rollen dokumentieren.
- [ ] Backup-Strategie + Zugriff auf Backups regeln.
- [ ] Logins, Gerätezugriffe, Admin-Aktionen auditierbar machen.

## 7) Betroffenenrechte (Must-have)

- [ ] Auskunftsprozess (Data Export) definieren.
- [ ] Korrektur/Portabilität ermöglichen.
- [ ] Löschprozess (Art. 17) dokumentieren.
- [ ] Kontaktweg für Datenschutzanfragen (E-Mail + Reaktionszeit).

## 8) Tracking & Analytics (Optional, aber riskant)

- [ ] Wenn Analytics aktiv: Consent-Management + Opt-in.
- [ ] Anonymisierung/Reduktion von Identifiers prüfen.
- [ ] Datenschutzerklärung aktualisieren.

## 9) Infrastruktur & Hosting (Must-have)

- [ ] Hosting/Firestore Region prüfen (EU-Region bevorzugt).
- [ ] TLS/HTTPS erzwingen.
- [ ] Zugriffsprotokolle und Monitoring aktivieren.
- [ ] Subprozessoren-Verträge prüfen (Firebase/Google).

## 10) Launch-Ready Final Checks

- [ ] Firestore Rules Pen-Test (Multi-Tenant, Friends, Chat).
- [ ] Datenexport/Löschung einmal End-to-End testen.
- [ ] Datenschutztexte & AVV final geprüft.
- [ ] Studio-FAQ für Datenschutzfragen erstellen.
- [ ] Incident-Plan (Datenpanne) definieren.

---

## Quick-Start (Minimal-Set, um Pilotstudios anzusprechen)

- [ ] AVV/DPA-Entwurf bereit.
- [ ] Datenschutzseite + Kontakt live.
- [ ] Mandantentrennung in Firestore Rules nachgewiesen (Tests).
- [ ] Freunde/Chat nur mit Consent.
- [ ] Löschprozess dokumentiert.

