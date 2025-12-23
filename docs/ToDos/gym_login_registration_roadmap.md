## Gym-spezifischer Login & Registrierung – Roadmap (Flutter, Multi-Tenant)

Diese Roadmap strukturiert die Umsetzung des gym-spezifischen Login/Registrierungsflows. Ziel ist eine hochwertige, skalierbare Multi-Tenant-UX: Nutzer wählen zuerst ihr Studio, danach Login oder Registrierung (Gymcode/NFC) – und landen immer im klar abgegrenzten Bereich des jeweiligen Gyms.

Ziele:

- Klare Studio-Auswahl beim ersten App-Start, jederzeit wechselbar.
- Login/Registrierung ist gym-spezifisch, fühlt sich wie ein eigener Bereich pro Studio an.
- Registrierung unterstützt Gymcode und NFC-Scan; NFC setzt den Gymcode automatisch.
- Technische Skalierbarkeit für viele Studios (Tenant-Context in Navigation, Auth, Datenmodell).
- Saubere UX-Architektur, Testbarkeit und Fehlerbehandlung.

Status-Legende (bitte pflegen):

- [ ] nicht gestartet  
- [~] in Arbeit  
- [x] abgeschlossen  

---

## Phase 1: Produkt-Flow & UX-Definition (MUST-HAVE)

Ziel: Klarer Nutzerfluss, der sich hochwertig und “gym-spezifisch” anfühlt.

### 1. User-Flows definieren (Screens & States)

- [x] Flow 1: First-Launch → Gym-Auswahl → Login/Registrierung.
- [x] Flow 2: Gym-Auswahl → Registrierung → Gymcode-Flow.
- [x] Flow 3: Gym-Auswahl → Registrierung → NFC-Flow → Code vorausgefüllt.
- [x] Flow 4: Gym-Auswahl → Login → Gym-spezifischer Login.
- [x] Flow 5: Studio wechseln (in Settings oder Profilbereich).
- [~] Fehlerfälle festlegen (kein NFC, falscher Chip, ungültiger Code, Offline).

### 2. Informationsarchitektur & UI-Skizzen

- [~] Studio-Auswahl als eigenständige Entry-Page definieren (Dropdown + Suche + Logo).
- [x] Zwischenschritt “Login oder Registrierung” pro Gym definieren.
- [x] Registrierungsoptionen: “NFC” oder “Gymcode”.
- [ ] Gym-spezifisches Branding auf Login/Registrierung (Logo/Farben).
- [x] Textkonzept für alle Schritte (kurz, verständlich, ohne Tech-Jargon).

---

## Phase 2: Datenmodell & Backend-Kontext (MUST-HAVE)

Ziel: Multi-Tenant-Denke sauber abbilden und technisch skalierbar machen.

### 3. Datenmodell (Gym als Tenant)

- [x] `Gym`-Entität definieren: `gymId`, Name, Branding, NFC-Token(s), Region, Status.
- [x] Mapping: `gymId` als Pflicht-Kontext für Login/Registrierung.
- [x] Gymcode-Validierung pro Gym (6-stellig, eindeutig pro Gym).
- [x] NFC-Token-Verwaltung pro Gym (Whitelist, aktiv/inaktiv).

### 4. Auth & Context-Handling

- [x] Auth-Flow mit `gymId`-Kontext erweitern (Login, Registrierung, Session).
- [x] Session-Persistenz: ausgewähltes Gym lokal speichern.
- [x] “Studio wechseln” definiert Session-Verhalten (Logout oder Kontextwechsel).
- [x] Guard-Logik: Screens nur mit gültigem `gymId`.

---

## Phase 3: App-Routing & Architektur (MUST-HAVE)

Ziel: Flutter-Navigation und State sauber auf Multi-Tenant-Flow ausrichten.

### 5. Navigation & Routing

- [x] Routenstruktur definieren, z.B. `/gym/:gymId/login`, `/gym/:gymId/register`.
- [x] First-Launch-Detection (Onboarding-Flag) implementieren.
- [x] “Gym-Auswahl” als Root-Entry integrieren.
- [x] Deep-Link-Kompatibilität für Gym-spezifische Pfade prüfen.

### 6. State-Management & Services

- [x] `GymContext`-Provider einführen (gymId, branding, flags).
- [~] Services kapseln: `GymService`, `GymAuthService`, `NfcService`.
- [~] Fehlerzustände zentral behandeln (Toasts/Snackbars, Retry).

---

## Phase 4: Registrierung & NFC-Flow (MUST-HAVE)

Ziel: Registrierung mit Gymcode oder NFC schlank und robust umsetzen.

### 7. Gymcode-Flow

- [x] Registrierungsseite für Gymcode pro Gym anpassen.
- [x] Code-Validation pro Gym (Backend-check).
- [x] UI: 6-stelliger Code mit Auto-Fokus und Validierungsfeedback.

### 8. NFC-Flow

- [x] NFC-Scan-Start per Auswahl “NFC” (Loading + Anleitung).
- [x] Validierung gegen Gym-spezifische NFC-Tokens.
- [x] Gymcode automatisch in Registrierungsform setzen.
- [x] Fehlerfälle: falscher Chip, NFC deaktiviert, kein Gerät.

---

## Phase 5: Qualität & Betrieb (MUST-HAVE)

Ziel: Stabiler Launch, klare Fehlerkommunikation, Daten- und UX-Qualität.

### 9. Tests & Edge-Cases

- [x] Unit-Tests für Gymcode-Validierung und Tenant-Context.
- [x] Widget-Tests für Flow-Screens (Gym-Auswahl, Login, Registrierung).
- [~] NFC-Flow manuell testen mit realen Chips.
- [x] Offline-Handling prüfen (Gym-Liste gecached?).

### 10. Analytics & Monitoring

- [x] Events definieren: Gym-Auswahl, Login, Registrierung, NFC-Scan.
- [~] Funnel-Metriken: Dropoffs pro Schritt messen.
- [x] Fehler-Logging für NFC/Gymcode-Validierung.

---

## Phase 6: UX-Polish & Branding (NICE-TO-HAVE)

Ziel: Hochwertige “Studio-eigene” Experience.

### 11. Gym-Branding & Visuals

- [x] Gym-spezifisches Theme (Farben, Logo, Typo).
- [x] Mikro-Animationen beim Gym-Wechsel oder bei Auswahl.
- [x] Leichter Einstieg: “Zuletzt verwendetes Gym” hervorheben.

### 12. Erweiterungen

- [ ] Suche nach Gym via Stadt/PLZ.
- [ ] QR-Scan als Alternative zu Gymcode/NFC.
- [x] Gastzugang / Demo-Modus für Studios.
