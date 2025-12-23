.PHONY: ios android push ios-dev ios-emu ios-emu-prod ios-mobile-dev ios-mobile-prod android-emu ios-emu-both R rules rules-dev rules-prod ios-wireless admin

# Gerätedefinitionen
iOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
ANDROID_EMU_ID := emulator-5554  # Emulator-Name laut `flutter devices`
ANDROID_EMU_NAME := sdk_gphone64_x86_64  # AVD-Name zum Starten (kann angepasst werden)
TMUX_SESSION := flutter
FIREBASE_CONFIG ?= firebase.json
FIREBASE_PROJECT_DEV ?= tap-em-dev

# iOS auf echtem Gerät
ios:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d $(iOS_DEV_ID)

# Android (Prod - on physical device)
android: android-prod

android-prod:
	@echo "📱 Deploying to Android - PRODUCTION Environment"
	cp android/config/prod/google-services.json android/app/google-services.json
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter run --release -d $(ANDROID_ID) --dart-define=ENV=prod

# Android (Dev - on physical device)
android-dev:
	@echo "📱 Deploying to Android - DEV Environment"
	cp android/config/dev/google-services.json android/app/google-services.json
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter run --release -d $(ANDROID_ID) --dart-define=ENV=dev

# Android Emulator (Dev)
android-emu:
	@echo "🔧 Starting Android Emulator - DEV Environment"
	cp android/config/dev/google-services.json android/app/google-services.json
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter run -d $(ANDROID_EMU_ID) --dart-define=ENV=dev

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

# ═════════════════════════════════════════════════════
# iOS Emulator Targets
# ═════════════════════════════════════════════════════

# iOS Emulator (Dev - Debug mode) - DEFAULT
ios-emu: ios-emu-dev-d

# iOS Emulator (Dev - Debug mode) - WITH HOT RESTART ✅
ios-emu-dev-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "🔧 iOS Emulator - DEV (Debug + Hot Restart)"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem.dev"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 5
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🚀 Launching DEV app with flavor..."
	fvm flutter run --flavor dev -d "iPhone 16 Plus" --dart-define=ENV=dev

# iOS Emulator (Dev - Release mode) - WITH HOT RESTART ✅
ios-emu-dev:
	@echo "═════════════════════════════════════════════════════"
	@echo "🔧 iOS Emulator - DEV (Release)"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem.dev"
	cp ios/config/dev/GoogleServiceInfo.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 5
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🚀 Launching DEV app with flavor (Release)..."
	fvm flutter run --release --flavor dev -d "iPhone 16 Plus" --dart-define=ENV=dev

# iOS Emulator (Prod - Debug mode) - WITH HOT RESTART ✅
ios-emu-prod-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "🚀 iOS Emulator - PROD (Debug + Hot Restart)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	open -a Simulator
	@sleep 3
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🚀 Launching PROD app with flavor..."
	fvm flutter run --flavor prod -d "iPhone 16 Plus" --dart-define=ENV=prod


# iOS Emulator (Prod - Release mode) - NOT SUPPORTED
ios-emu-prod:
	@echo "═════════════════════════════════════════════════════"
	@echo "❌ iOS Emulator - Release builds NOT supported"
	@echo "═════════════════════════════════════════════════════"
	@echo "ℹ️  Simulators only support Debug builds (x86_64)"
	@echo "ℹ️  Use 'make ios-emu-prod-d' for Prod Debug testing"
	@echo "ℹ️  Or 'make ios-mobile-prod' for Release on real iPhone"
	@echo "═════════════════════════════════════════════════════"
	@exit 1

# iOS Mobile (Dev - on physical iPhone)
ios-mobile-dev:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Deploying to iPhone - DEV Environment (Release Build)"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem.dev"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🚀 Launching DEV app on iPhone (Release Build)..."
	fvm flutter run --release -d $(iOS_DEV_ID) --dart-define=ENV=dev

# iOS Mobile (Dev - on physical iPhone - DEBUG)
ios-mobile-dev-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Deploying to iPhone - DEV Environment (DEBUG Build)"
	@echo "🔥 Hot Restart Enabled"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem.dev"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🚀 Launching DEV app on iPhone (Debug Build)..."
	fvm flutter run -d $(iOS_DEV_ID) --dart-define=ENV=dev

# iOS Mobile (Prod - on physical iPhone)
ios-mobile-prod:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Deploying to iPhone - PRODUCTION Environment (Release Build)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🚀 Launching PROD app on iPhone (Release Build)..."
	./scripts/build_with_prod_config.sh Release $(iOS_DEV_ID) release

# iOS Mobile (Prod - on physical iPhone - DEBUG) - CLEAN BUILD
ios-mobile-prod-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 iPhone - PRODUCTION Environment (Debug Build)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "🔥 Hot Restart Enabled"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: com.example.tapem"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🔨 Building with xcodebuild (Debug-Prod config)..."
	cd ios && xcodebuild -workspace Runner.xcworkspace \
		-scheme Runner \
		-configuration Debug-Prod \
		-destination 'id=$(iOS_DEV_ID)' \
		-derivedDataPath build \
		build > /dev/null 2>&1 && cd ..
	@echo "📲 Installing PROD app on iPhone..."
	cd ios && ios-deploy --id $(iOS_DEV_ID) --bundle build/Build/Products/Debug-Prod-iphoneos/Runner.app --justlaunch && cd ..

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
rules: rules-prod

rules-prod:
	npx firebase deploy --only firestore:rules -c firebase.json

rules-dev:
	npx firebase deploy --only firestore:rules -c firebase.dev.json --project $(FIREBASE_PROJECT_DEV)

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

logo:
	flutter pub run flutter_launcher_icons
