# Tap’em

**NFC-basiertes Gym-Tracking & -Management**

Tap’em ist eine modular aufgebaute Flutter-App, die es Fitnessstudios ermöglicht, ihr Geräteangebot per NFC-Tap nahtlos zu verwalten und Mitglieder-Trainingsdaten zentral zu erfassen. White-Label-fähig und Multi-Tenant-bereit für individuelle Studio-Brandings und Datenisolation.

---

## Features

- **NFC-Integration**: Direktes Navigieren zum passenden Trainings-Dashboard per Tap am Gerät
- **Multi-Tenant-Architektur**: Jedes Studio bekommt seine eigene Konfiguration & Datenbank-Segmente
- **Firebase-Backend**: Authentifizierung, Firestore-Datenhaltung, Cloud Functions (optional)
- **Dynamisches Branding**: Farbschema, Logos und App-Namen pro Studio konfigurierbar
- **State Management**: Provider / optional Riverpod oder BLoC für skalierbare Business-Logik
- **Visualisierung**: Kalender-Übersicht, Charts (fl_chart), Streak-Badges, Trainingshistorie
- **Offline-Support**: Firestore-Persistence für unterbrechungsfreie Datenerfassung
- **CI/CD ready**: GitHub Actions für Analyse, Tests und Matrix-Builds von Flavors

---

## Voraussetzungen

- Flutter SDK ≥ 3.7.0
- Android Studio oder VS Code
- Xcode (macOS, für iOS-Builds)
- Ein Firebase-Projekt pro Studio (je Flavor) mit `google-services.json` und `GoogleService-Info.plist`
- Git ≥ 2.20 für Branch- und Remote-Management

---

## Getting Started

1. **Repository klonen**
   ```bash
   git clone git@github.com:<DeinUser>/tapem.git
   cd tapem
   ```
2. **Umgebungsdatei kopieren**
   ```bash
   cp .env.example .env.dev
   # Werte entsprechend deinem Firebase-Projekt setzen
   ```
3. **Abhängigkeiten installieren**
   ```bash
   flutter pub get
   ```

Weitere Hinweise zum eingesetzten State-Management und den vorhandenen Providern finden sich in [docs/provider_structure.md](docs/provider_structure.md).

