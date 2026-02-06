# NFC Onboarding Guide für Studio-Partner 🚀

Dieses Dokument beschreibt den optimalen Prozess für das NFC-Onboarding neuer Kunden – von der Planung bis zum Launch-ready Zustand.

## 1. Bedarfsermittlung & Bestellanforderungen

### 1.1 Geräte-Audit
Erfasse alle stationären Geräte und Übungsstationen im Studio.
*   **Single-Exercise**: Klassische Maschinen (z.B. Brustpresse).
*   **Multi-Exercise**: Stationen mit mehreren Übungen (z.B. Kabelzug, Power-Rack). Diese benötigen oft nur **einen** zentralen Chip, nach dessen Scan die App eine Auswahl der Übungen anzeigt.

### 1.2 Chip-Menge & Backups
Bestelle Chips nach folgender Formel:
**[Anzahl Geräte] + [Anzahl Multi-Stationen] + 25% Puffer = Gesamtbestellung**

> [!IMPORTANT]
> Der Puffer ist kritisch für:
> *   Verlust oder Diebstahl (Mitglieder nehmen Chips als Souvenir mit).
> *   Beschädigung (durch Schweiß, Reinigungschemikalien oder mechanischen Abrieb).
> *   Neuanschaffungen ohne Lieferverzug.

### 1.3 Hardware-Empfehlung
*   **Typ**: NTAG213 oder NTAG215 (zuverlässig, kostengünstig, hohe Reichweite).
*   **Format**: Selbstklebende PVC-Tags oder robuste Schlüsselanhänger/Tokens für Hanteln.
*   **Wichtig**: Achte bei Anbringung auf Metalloberflächen auf spezielle **"On-Metal" / "Anti-Metal" NFC Tags** ( Ferritschicht), da normales Metall das Signal stört.

---

## 2. Der Setup-Prozess (Workflow)

### Schritt 1: Geräte in Tapem anlegen
1.  Gehe im Admin-Bereich zu **Geräte**.
2.  Klicke auf **Hinzufügen (+)**.
3.  Gib Name, Beschreibung und Muskelgruppen ein.
4.  Wähle "Mehrere Übungen", falls es eine Multi-Station ist.
5.  Beim Speichern generiert die App automatisch einen **16-stelligen NFC-Code** für dieses Gerät.

### Schritt 2: Chips beschreiben
Du benötigst **keine externe App** (wie NFC Tools) mehr. Die Tapem Admin-App erledigt das direkt:
1.  Öffne die **Geräteliste** im Admin-Bereich.
2.  Klicke bei einem Gerät auf das **NFC-Icon**.
3.  Halte einen frischen Chip an die Rückseite deines Handys.
4.  Sobald die Bestätigung erscheint ("Schreiben erfolgreich"), ist der Chip einsatzbereit.

### Schritt 3: Anbringung
*   Platziere den Chip dort, wo der Nutzer das Handy **intuitiv** hinhält (meist auf Augenhöhe oder am Einstieg).
*   Säubere die Fläche vorher gründlich (Alkoholtuch), damit der Kleber dauerhaft hält.

---

## 3. Compliance & Sicherheit

### 3.1 Datenschutz (GDPR/DSGVO)
*   **Anonymität**: Auf den Chips werden **keine Userdaten** gespeichert, nur der statische Identifikationscode des Geräts.
*   **Sicherheit**: Die Chips sind schreibgeschützt (read-only), sobald sie im Admin-Modus finalisiert wurden, um Manipulationen durch Dritte zu verhindern.

### 3.2 Betriebssicherheit
*   **Platzierung**: Chips dürfen keine beweglichen Teile blockieren oder scharfe Kanten verdecken.
*   **Signalstörung**: Halte Abstand zu starken Magneten (z.B. Kopfhörerhalterungen), um Datenverlust auf dem Chip zu vermeiden.

---

## 4. Launch-Ready Checkliste
- [ ] Alle Geräte in der Datenbank angelegt.
- [ ] Alle Chips physisch beschriftet (optional mit Marker auf der Rückseite) und geklebt.
- [ ] Test-Scan jedes Chips mit einem Test-Nutzer Account durchgeführt.
- [ ] Backup-Chips (ca. 10-20 Stück) vorkonfiguriert im Büro des Studioleiters hinterlegt.
- [ ] Kleines Onboarding-Schild/Sticker ("Hier scannen") neben den Chips angebracht.

Durch diesen Prozess ist das Studio innerhalb weniger Stunden komplett digitalisiert und die Nutzer können sofort mit dem Scan-Workout starten.
