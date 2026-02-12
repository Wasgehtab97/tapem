# Gerätehersteller-Management Implementierung

Spezifikation zur Implementierung einer strukturierten Verwaltung von Geräteherstellern in Tapem.

## Ist-Zustand (Status Quo)
*   **Geräte-Modell (`Device`)**: Besitzt Felder `name` und `description`.
*   **Aktuelle Praxis**: Der Hersteller wird manuell in das Freitextfeld `description` eingetragen (z.B. "Technogym", "Lifefitness").
*   **Nachteile**:
    *   Keine Standardisierung (Tippfehler: "TechnoGYM", "technogym").
    *   Keine Aggregation oder Statistik über alle Gyms möglich.
    *   Keine Filterung nach Hersteller möglich.
    *   Redundante Dateneingabe bei jedem neuen Gerät.

## Soll-Zustand (Zielbild)
1.  **Globale Hersteller-Datenbank (`Global Manufacturers`)**:
    *   Eine zentrale Firestore-Collection (`manufacturers`), die eine kuratierte Liste aller bekannten Hersteller enthält.
    *   Dient als "Single Source of Truth" für zukünftige übergreifende Statistiken.
2.  **Gym-Spezifische Hersteller-Verwaltung**:
    *   Jedes Gym wählt aus der globalen Liste die Hersteller aus, die es tatsächlich verwendet.
    *   Diese Auswahl wird in einer gym-internen Struktur gespeichert (z.B. Sub-Collection oder Array im Gym-Dokument).
3.  **Geräte-Zuordnung**:
    *   Beim Anlegen/Bearbeiten eines Geräts wird der Hersteller aus der *gym-spezifischen* Liste ausgewählt (Dropdown/Picker).
    *   Das `Device`-Dokument speichert eine Referenz (`manufacturerId`) und idealerweise den Namen (für einfache Anzeige ohne Join).

## Datenmodell-Design

### 1. Globale Collection: `manufacturers`
Pfad: `/manufacturers/{manufacturerId}`
```json
{
  "id": "rogue",
  "name": "Rogue",
  "logoUrl": "https://...", // Optional für spätere UI-Features
  "website": "https://roguefitness.com" // Optional
}
```

### 2. Gym-Spezifische Konfiguration
Option A (Empfohlen): Sub-Collection im Gym
Pfad: `/gyms/{gymId}/manufacturers/{manufacturerId}`
*   Kopie des globalen Datensatzes oder Referenz.
*   Erlaubt gym-spezifische Zusatzdaten (z.B. "Wartungskontakt für Matrix-Geräte").
```json
{
  "id": "matrix",
  "name": "Matrix",
  "globalRef": "/manufacturers/matrix", // Referenz auf Original
  "supportContact": "service@matrix-germany.de" // Optional: Gym-spezifisch
}
```

### 3. Aktualisiertes `Device`-Modell
Pfad: `/gyms/{gymId}/devices/{deviceId}`
```json
{
  "id": 123,
  "name": "Beinpresse",
  "description": "45 Grad", // Echte Beschreibung, nicht mehr Hersteller
  "manufacturerId": "matrix", // Neu
  "manufacturerName": "Matrix", // Denormalisiert für einfacheres Lesen
  // ... andere Felder
}
```

## Implementierungs-Roadmap

### Phase 1: Backend & Datenstruktur [x]
1.  **Firestore**: Top-Level Collection `manufacturers` definiert.
2.  **Seeding**: Logik in `ManufacturerRepositoryImpl` integriert (Rogue, Matrix, etc.).
3.  **Domain Models**: `Manufacturer` Model und `ManufacturerRepository` erstellt.

### Phase 2: Gym-Administration UI [x]
1.  **Screen "Hersteller verwalten"**: Erstellt unter `lib/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart`.
2.  **Navigation**: Button in `AdminDevicesScreen` AppBar hinzugefügt.
3.  **Repository-Integration**: Logik zum Hinzufügen/Entfernen von Herstellern für ein Gym implementiert.

### Phase 3: Geräte-Erstellung (`CreateDeviceDialog`) [x]
1.  **Update UI**: Dropdown für Hersteller im `CreateDeviceDialog` hinzugefügt.
2.  **Update Logik**: `Device` Model erweitert und Speicherlogik angepasst.
3.  **Anzeige**: Herstellername wird jetzt in der Geräteliste angezeigt.

### Phase 4: Migration & Bearbeitung [x]
1.  **Bearbeitungs-Funktion**: `CreateDeviceDialog` durch `DeviceFormDialog` ersetzt, um bestehende Geräte nachträglich herstellern zuzuweisen.
2.  **UI-Polishing**: Geräteliste zeigt nun Name, Hersteller und Beschreibung klar strukturiert an.
3.  **Infrastruktur**: `UpdateDeviceUseCase` und Repository-Erweiterungen implementiert.

## Zusammenfassung
Die Implementierung ist abgeschlossen. Alle Phasen wurden erfolgreich durchlaufen. Gym-Admins können nun Hersteller global verwalten und diese ihren Geräten strukturiert zuweisen – sowohl bei der Neuanlage als auch nachträglich.
