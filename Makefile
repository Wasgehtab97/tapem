.PHONY: ios android push ios-dev ios-emu ios-emu-prod android-emu ios-emu-both R rules rules-dev ios-wireless admin

# Gerätedefinitionen
iOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
ANDROID_EMU_ID := emulator-5554  # Emulator-Name laut `flutter devices`
ANDROID_EMU_NAME := sdk_gphone64_x86_64  # AVD-Name zum Starten (kann angepasst werden)
TMUX_SESSION := flutter
FIREBASE_CONFIG ?= firebase.json

# iOS auf echtem Gerät
ios:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d $(iOS_DEV_ID)

# Android auf echtem Gerät
android:
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter run --release -d $(ANDROID_ID)

# Android Emulator starten und App ausführen
android-emu:
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter run -d $(ANDROID_EMU_ID)

# Git push
push:
	git add .
	git commit -m "newest push"
	git push

# Schneller Workflow ohne clean
ios-dev:
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -v -d $(iOS_DEV_ID)

# iOS Emulator (Dev - Debug mode)
ios-emu:
	@echo "═════════════════════════════════════════════════════"
	@echo "🔧 Starting iOS Emulator - DEV Environment"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem.dev"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 5
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🚀 Launching DEV app..."
	fvm flutter run -d "iPhone 16 Plus" --dart-define=ENV=dev

# iOS Emulator (Prod - Debug-Prod configuration)
ios-emu-prod:
	@echo "═════════════════════════════════════════════════════"
	@echo "🚀 Starting iOS Emulator - PRODUCTION Environment"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 5
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🚀 Launching PROD app..."
	@# Temporarily change Debug config, run app, then restore
	@sed -i.bak 's/BUNDLE_ID_SUFFIX = \.dev;/BUNDLE_ID_SUFFIX = "";/' ios/Runner.xcodeproj/project.pbxproj
	@sed -i.bak 's/DISPLAY_NAME = "Tap'\''em DEV";/DISPLAY_NAME = "Tap'\''em";/' ios/Runner.xcodeproj/project.pbxproj
	@trap 'sed -i.bak "s/BUNDLE_ID_SUFFIX = \"\";/BUNDLE_ID_SUFFIX = .dev;/" ios/Runner.xcodeproj/project.pbxproj; sed -i.bak "s/DISPLAY_NAME = \"Tap'\''em\";/DISPLAY_NAME = \"Tap'\''em DEV\";/" ios/Runner.xcodeproj/project.pbxproj; rm -f ios/Runner.xcodeproj/*.bak; echo "✅ Restored Debug config"' EXIT; \
	fvm flutter run -d "iPhone 16 Plus" --dart-define=ENV=prod

# iOS Emulator (BOTH Dev & Prod in parallel)
ios-emu-both:
	@echo "═════════════════════════════════════════════════════"
	@echo "🚀 Installing BOTH Dev & Prod Apps"
	@echo "═════════════════════════════════════════════════════"
	@echo ""
	@echo "📱 Step 1/2: Building DEV app..."
	@echo "════════════════════════════════════════════════════"
	cp ios/Runner/GoogleService-Info-Dev.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	@echo "🏗️  Installing DEV app (detached mode)..."
	fvm flutter run -d "iPhone 16 Plus" --dart-define=ENV=dev -d &
	@echo "✅ DEV app installed!"
	@echo ""
	@sleep 10
	@echo "📱 Step 2/2: Building PROD app..."
	@echo "════════════════════════════════════════════════════"
	cp ios/Runner/GoogleService-Info-Prod.plist ios/Runner/GoogleService-Info.plist
	@sleep 2
	@echo "🏗️  Installing PROD app (detached mode)..."
	fvm flutter run -d "iPhone 16 Plus" --dart-define=ENV=prod -d &
	@sleep 10
	@echo "✅ PROD app installed!"
	@echo ""
	@echo "═════════════════════════════════════════════════════"
	@echo "✨ SUCCESS! Both apps are now running in parallel!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Tap'em DEV   → Bundle ID: com.example.tapem.dev"
	@echo "📱 Tap'em       → Bundle ID: com.example.tapem"
	@echo "═════════════════════════════════════════════════════"

# Admin-Skript
admin:
	node scripts/setAdmin.js

# Pull, Dependencies, Gen, Hot Restart
R:
	git restore lib/l10n/app_localizations.dart \
            lib/l10n/app_localizations_de.dart \
            lib/l10n/app_localizations_en.dart
	git pull
	flutter pub get
	flutter gen-l10n

# iOS über Netzwerk
ios-wireless:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d $(iOS_DEV_ID) --device-timeout=30

# Firestore-Regeln deployen
rules:
	npx firebase deploy --only firestore:rules -c $(FIREBASE_CONFIG)

rules-dev:
	$(MAKE) rules FIREBASE_CONFIG=firebase.dev.json

# 
alter-stand:
	git fetch origin
	git checkout a_gpt5 
	git reset --hard origin/(hier die alte branch einfügen)
	git push --force-with-lease origin a_gpt5

# APK Release
apk-release:
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter build apk --release

# localhost
localhost:
	cd website && rm -rf .next && TAPEM_DEBUG=1 npm run dev



reset:
	git reset --hard origin/a_gpt5 