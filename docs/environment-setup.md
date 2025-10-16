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
5. **Firebase Functions deployen (Spark-Plan)**
   - Bleibe beim kostenlosen Spark-Plan, indem du die 1st-gen-Laufzeit `"node": "16"` in `functions/package.json` verwendest und in den Functions-Dateien `require('firebase-functions/v1')` einsetzt.
   - Vermeide das Aktivieren von `cloudbuild.googleapis.com` oder `artifactregistry.googleapis.com`, da diese APIs einen Wechsel auf den Blaze-Plan auslösen würden.
   - Führe anschließend `firebase deploy --only functions:mirrorTrainingSummary,functions:backfillTrainingSummaries,functions:backfillDeviceUsageSummaries` aus.
