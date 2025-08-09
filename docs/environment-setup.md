# Environment Setup

1. **Firebase CLI installieren**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
2. **FlutterFire CLI installieren**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. **Konfigurationsdateien ablegen**
   - `google-services.json` in `android/app/`
   - `GoogleService-Info.plist` in `ios/Runner/`
   - Kopiere `.env.example` zu `.env.dev` oder `.env.prod`
4. **Dateien bleiben lokal**
   Diese Dateien sind in `.gitignore` gelistet und dürfen nicht committet werden.
