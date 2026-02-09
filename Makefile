.PHONY: ios android push ios-dev ios-emu ios-emu-prod ios-mobile-dev ios-mobile-prod android-emu ios-emu-both R rules rules-dev rules-prod ios-wireless ios-wireless-dev-d ios-wireless-prod admin admin-web admin-web-dev admin-web-prod admin-web-avatars admin-web-avatars-dev admin-web-avatars-prod logo ios-prep ios-config-dev ios-config-prod ios-check-space ios-clean-build-cache ios-upload-testflight-prod apk-release aab-release version-show

# Local, untracked environment overrides (e.g. ASC_API_* for uploads)
-include .env
-include .env.local

# Gerätedefinitionen
iOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
ANDROID_EMU_ID := emulator-5554  # Emulator-Name laut `flutter devices`
ANDROID_EMU_NAME := sdk_gphone64_x86_64  # AVD-Name zum Starten (kann angepasst werden)
TMUX_SESSION := flutter
FIREBASE_CONFIG ?= firebase.json
FIREBASE_PROJECT_DEV ?= tap-em-dev
IOS_BUNDLE_ID_DEV := com.example.tapem.dev
IOS_BUNDLE_ID_PROD := com.example.tapem
IOS_MIN_FREE_MB ?= 4096
FLUTTER ?= ./scripts/flutterw
IOS_SIM_RESOLVER ?= ./scripts/resolve_ios_simulator.sh
IOS_EXPORT_OPTIONS_PLIST ?= ios/ExportOptions.plist
IOS_IPA_DIR ?= build/ios/ipa
APP_VERSION_SCRIPT ?= ./scripts/pubspec_version.sh
# Optional manual override. If empty, build number is read from pubspec.yaml and auto-incremented after successful release.
APP_BUILD_NUMBER ?=
ASC_API_KEY_ID ?=
ASC_API_ISSUER_ID ?=
ASC_API_KEY_PATH ?=

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

# Shared iOS prep
ios-prep: ios-check-space
	$(FLUTTER) pub get > /dev/null 2>&1
	$(FLUTTER) gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..

ios-check-space:
	@FREE_MB=$$(df -Pm / | awk 'NR==2 {print $$4}'); \
	if [ "$$FREE_MB" -lt "$(IOS_MIN_FREE_MB)" ]; then \
		echo "═════════════════════════════════════════════════════"; \
		echo "❌ Not enough free disk space for iOS build"; \
		echo "ℹ️  Free: $$FREE_MB MB | Required: $(IOS_MIN_FREE_MB) MB"; \
		echo "ℹ️  Run: make ios-clean-build-cache"; \
		echo "ℹ️  Then optionally free Xcode data in ~/Library/Developer/Xcode/DerivedData"; \
		echo "═════════════════════════════════════════════════════"; \
		exit 1; \
	fi

ios-clean-build-cache:
	@echo "🧹 Cleaning project build artifacts..."
	rm -rf build ios/build
	@echo "✅ Cleaned /build and /ios/build"

ios-config-dev:
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

ios-config-prod:
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

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
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	@open -a Simulator >/dev/null 2>&1 || true
	@sleep 2
	@EMU_ID=$$($(IOS_SIM_RESOLVER) "$(IOS_EMU_ID)") && \
	echo "▶️  Booting simulator $$EMU_ID..." && \
	(xcrun simctl boot "$$EMU_ID" >/dev/null 2>&1 || true)
	@sleep 2
	$(MAKE) ios-prep
	@EMU_ID=$$($(IOS_SIM_RESOLVER) "$(IOS_EMU_ID)") && \
	echo "🚀 Launching DEV app with flavor on $$EMU_ID..." && \
	$(FLUTTER) run --flavor dev -d "$$EMU_ID" --dart-define=ENV=dev

# iOS Emulator (Dev - Release mode) - WITH HOT RESTART ✅
ios-emu-dev:
	@echo "═════════════════════════════════════════════════════"
	@echo "🔧 iOS Emulator - DEV (Release)"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	$(MAKE) ios-config-dev
	open -a Simulator
	@sleep 5
	$(MAKE) ios-prep
	@echo "🚀 Launching DEV app with flavor (Release)..."
	fvm flutter run --release --flavor dev -d $(IOS_EMU_ID) --dart-define=ENV=dev

# iOS Emulator (Prod - Debug mode) - WITH HOT RESTART ✅
ios-emu-prod-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "🚀 iOS Emulator - PROD (Debug + Hot Restart)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_PROD)"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	@open -a Simulator >/dev/null 2>&1 || true
	@sleep 2
	@EMU_ID=$$($(IOS_SIM_RESOLVER) "$(IOS_EMU_ID)") && \
	echo "▶️  Booting simulator $$EMU_ID..." && \
	(xcrun simctl boot "$$EMU_ID" >/dev/null 2>&1 || true)
	@sleep 2
	$(MAKE) ios-prep
	@EMU_ID=$$($(IOS_SIM_RESOLVER) "$(IOS_EMU_ID)") && \
	echo "🚀 Launching PROD app with flavor on $$EMU_ID..." && \
	$(FLUTTER) run --flavor prod -d "$$EMU_ID" --dart-define=ENV=prod


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
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	$(MAKE) ios-config-dev
	$(MAKE) ios-prep
	@echo "🚀 Launching DEV app on iPhone (Release Build)..."
	fvm flutter run --release --flavor dev -d $(iOS_DEV_ID) --dart-define=ENV=dev

# iOS Mobile (Dev - on physical iPhone - DEBUG)
ios-mobile-dev-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Deploying to iPhone - DEV Environment (DEBUG Build)"
	@echo "🔥 Hot Restart Enabled"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	$(MAKE) ios-config-dev
	$(MAKE) ios-prep
	@echo "🚀 Launching DEV app on iPhone (Debug Build)..."
	fvm flutter run --flavor dev -d $(iOS_DEV_ID) --dart-define=ENV=dev

# iOS Mobile (Prod - on physical iPhone)
ios-mobile-prod:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Deploying to iPhone - PRODUCTION Environment (Release Build)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_PROD)"
	$(MAKE) ios-config-prod
	$(MAKE) ios-prep
	@echo "🚀 Launching PROD app on iPhone (Release Build)..."
	fvm flutter run -d $(iOS_DEV_ID) --release --flavor prod --dart-define=ENV=prod

# iOS Mobile (Prod - on physical iPhone - DEBUG) - CLEAN BUILD
ios-mobile-prod-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 iPhone - PRODUCTION Environment (Debug Build)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "🔥 Hot Restart Enabled"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_PROD)"
	$(MAKE) ios-config-prod
	$(MAKE) ios-prep
	@echo "🔨 Building with xcodebuild (Debug-prod config)..."
	cd ios && xcodebuild -workspace Runner.xcworkspace \
		-scheme prod \
		-configuration Debug-prod \
		-destination 'id=$(iOS_DEV_ID)' \
		-derivedDataPath build \
		build > /dev/null 2>&1 && cd ..
	@echo "📲 Installing PROD app on iPhone..."
	cd ios && ios-deploy --id $(iOS_DEV_ID) --bundle build/Build/Products/Debug-prod-iphoneos/Runner.app --justlaunch && cd ..

# iOS Emulator (BOTH Dev & Prod in parallel)
ios-emu-both:
	@echo "═════════════════════════════════════════════════════"
	@echo "🚀 Installing BOTH Dev & Prod Apps"
	@echo "═════════════════════════════════════════════════════"
	@echo ""
	@echo "📱 Step 1/2: Building DEV app..."
	@echo "════════════════════════════════════════════════════"
	$(MAKE) ios-config-dev
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	@echo "🏗️  Installing DEV app (detached mode)..."
	fvm flutter run --flavor dev -d $(IOS_EMU_ID) --dart-define=ENV=dev &
	@echo "✅ DEV app installed!"
	@echo ""
	@sleep 10
	@echo "📱 Step 2/2: Building PROD app..."
	@echo "════════════════════════════════════════════════════"
	$(MAKE) ios-config-prod
	@sleep 2
	@echo "🏗️  Installing PROD app (detached mode)..."
	fvm flutter run --flavor prod -d $(IOS_EMU_ID) --dart-define=ENV=prod &
	@sleep 10
	@echo "✅ PROD app installed!"
	@echo ""
	@echo "═════════════════════════════════════════════════════"
	@echo "✨ SUCCESS! Both apps are now running in parallel!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Tap'em Dev   → Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	@echo "📱 Tap'em       → Bundle ID: $(IOS_BUNDLE_ID_PROD)"
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

# iOS über Netzwerk (Dev - Debug)
ios-wireless-dev-d:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Wireless iPhone - DEV Environment (DEBUG Build)"
	@echo "🔥 Hot Restart Enabled"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Dev Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_DEV)"
	cp ios/config/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🚀 Launching DEV app on iPhone (Wireless Debug)..."
	fvm flutter run -d $(iOS_DEV_ID) --dart-define=ENV=dev --device-timeout=30

# iOS über Netzwerk (Prod - Release)
ios-wireless-prod:
	@echo "═════════════════════════════════════════════════════"
	@echo "📱 Wireless iPhone - PROD Environment (Release Build)"
	@echo "⚠️  WARNING: Using PRODUCTION Firebase Project!"
	@echo "═════════════════════════════════════════════════════"
	@echo "📋 Using Prod Firebase config..."
	@echo "📦 Bundle ID: $(IOS_BUNDLE_ID_PROD)"
	cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
	fvm flutter pub get > /dev/null 2>&1
	fvm flutter gen-l10n > /dev/null 2>&1
	@echo "🔧 Installing CocoaPods dependencies..."
	cd ios && pod install && cd ..
	@echo "🚀 Launching PROD app on iPhone (Wireless Release)..."
	fvm flutter run --release --flavor prod -d $(iOS_DEV_ID) --dart-define=ENV=prod --device-timeout=30

# App Store Connect Upload (Prod -> TestFlight)
# Required env vars:
#   ASC_API_KEY_ID=<Key ID>
#   ASC_API_ISSUER_ID=<Issuer ID>
#   ASC_API_KEY_PATH=/absolute/path/AuthKey_<KEY_ID>.p8
# Optional:
#   APP_BUILD_NUMBER=123 (manual override; no auto-increment if set)
ios-upload-testflight-prod:
	@set -e; \
	echo "═════════════════════════════════════════════════════"; \
	echo "☁️  Uploading PROD build to App Store Connect/TestFlight"; \
	echo "═════════════════════════════════════════════════════"; \
	test -n "$(ASC_API_KEY_ID)" || (echo "❌ ASC_API_KEY_ID is missing"; exit 1); \
	test -n "$(ASC_API_ISSUER_ID)" || (echo "❌ ASC_API_ISSUER_ID is missing"; exit 1); \
	test -n "$(ASC_API_KEY_PATH)" || (echo "❌ ASC_API_KEY_PATH is missing"; exit 1); \
	test -f "$(ASC_API_KEY_PATH)" || (echo "❌ API key file not found: $(ASC_API_KEY_PATH)"; exit 1); \
	test -x "$(APP_VERSION_SCRIPT)" || (echo "❌ Missing executable script: $(APP_VERSION_SCRIPT)"; exit 1); \
	test -f "$(IOS_EXPORT_OPTIONS_PLIST)" || (echo "❌ Missing export options: $(IOS_EXPORT_OPTIONS_PLIST)"; exit 1); \
	MARKETING_VERSION=$$($(APP_VERSION_SCRIPT) marketing); \
	BUILD_NUMBER="$(APP_BUILD_NUMBER)"; \
	AUTO_BUMP=0; \
	if [ -z "$$BUILD_NUMBER" ]; then \
		BUILD_NUMBER=$$($(APP_VERSION_SCRIPT) build); \
		AUTO_BUMP=1; \
	fi; \
	echo "🔢 Releasing iOS version $$MARKETING_VERSION ($$BUILD_NUMBER)"; \
	$(MAKE) ios-clean-build-cache; \
	$(MAKE) ios-config-prod; \
	$(FLUTTER) clean; \
	$(MAKE) ios-prep; \
	echo "🏗️  Building ipa..."; \
	$(FLUTTER) build ipa --release --flavor prod --dart-define=ENV=prod --build-name=$$MARKETING_VERSION --build-number=$$BUILD_NUMBER --export-options-plist=$(IOS_EXPORT_OPTIONS_PLIST); \
	grep -q "FLAVOR=prod" ios/Flutter/Generated.xcconfig || (echo "❌ FLAVOR is not prod in ios/Flutter/Generated.xcconfig"; exit 1); \
	grep -q "RU5WPXByb2Q=" ios/Flutter/Generated.xcconfig || (echo "❌ ENV=prod missing in ios/Flutter/Generated.xcconfig (DART_DEFINES)"; exit 1); \
	grep -q "<string>tap-em</string>" ios/Runner/GoogleService-Info.plist || (echo "❌ Runner/GoogleService-Info.plist is not prod"; exit 1); \
	ARCHIVE_INFO_PLIST="build/ios/archive/Runner.xcarchive/Info.plist"; \
	test -f "$$ARCHIVE_INFO_PLIST" || (echo "❌ Archive Info.plist not found: $$ARCHIVE_INFO_PLIST"; exit 1); \
	ARCHIVE_MARKETING_VERSION=$$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "$$ARCHIVE_INFO_PLIST"); \
	ARCHIVE_BUILD_NUMBER=$$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$$ARCHIVE_INFO_PLIST"); \
	if [ "$$ARCHIVE_MARKETING_VERSION" != "$$MARKETING_VERSION" ] || [ "$$ARCHIVE_BUILD_NUMBER" != "$$BUILD_NUMBER" ]; then \
		echo "❌ Built archive version mismatch. Expected $$MARKETING_VERSION ($$BUILD_NUMBER), got $$ARCHIVE_MARKETING_VERSION ($$ARCHIVE_BUILD_NUMBER)"; \
		exit 1; \
	fi; \
	IPA_PATH=$$(ls -t $(IOS_IPA_DIR)/*.ipa 2>/dev/null | head -n1); \
	if [ -z "$$IPA_PATH" ]; then \
		echo "❌ No ipa found in $(IOS_IPA_DIR)"; \
		exit 1; \
	fi; \
	KEY_DIR=$$(mktemp -d); \
	cp "$(ASC_API_KEY_PATH)" "$$KEY_DIR/AuthKey_$(ASC_API_KEY_ID).p8"; \
	echo "📤 Uploading $$IPA_PATH"; \
	set +e; \
	API_PRIVATE_KEYS_DIR="$$KEY_DIR" xcrun altool --upload-app --type ios --file "$$IPA_PATH" --apiKey "$(ASC_API_KEY_ID)" --apiIssuer "$(ASC_API_ISSUER_ID)"; \
	STATUS=$$?; \
	if [ "$$STATUS" -ne 0 ]; then \
		echo "⚠️  altool failed, retrying with iTMSTransporter..."; \
		API_PRIVATE_KEYS_DIR="$$KEY_DIR" xcrun iTMSTransporter -m upload -assetFile "$$IPA_PATH" -apiKey "$(ASC_API_KEY_ID)" -apiIssuer "$(ASC_API_ISSUER_ID)" -v informational; \
		STATUS=$$?; \
	fi; \
	set -e; \
	rm -rf "$$KEY_DIR"; \
	if [ "$$STATUS" -ne 0 ]; then \
		echo "❌ Upload failed"; \
		exit "$$STATUS"; \
	fi; \
	if [ "$$AUTO_BUMP" -eq 1 ]; then \
		$(APP_VERSION_SCRIPT) bump-build >/dev/null; \
		echo "🔁 Next build prepared: $$($(APP_VERSION_SCRIPT) full)"; \
	fi; \
	echo "✅ Upload finished. Build should appear in App Store Connect/TestFlight shortly."

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
	@set -e; \
	test -x "$(APP_VERSION_SCRIPT)" || (echo "❌ Missing executable script: $(APP_VERSION_SCRIPT)"; exit 1); \
	MARKETING_VERSION=$$($(APP_VERSION_SCRIPT) marketing); \
	BUILD_NUMBER="$(APP_BUILD_NUMBER)"; \
	AUTO_BUMP=0; \
	if [ -z "$$BUILD_NUMBER" ]; then \
		BUILD_NUMBER=$$($(APP_VERSION_SCRIPT) build); \
		AUTO_BUMP=1; \
	fi; \
	echo "📱 Building Android APK version $$MARKETING_VERSION ($$BUILD_NUMBER)"; \
	cp android/config/prod/google-services.json android/app/google-services.json; \
	$(FLUTTER) clean; \
	$(FLUTTER) pub get; \
	$(FLUTTER) gen-l10n; \
	$(FLUTTER) build apk --release --build-name=$$MARKETING_VERSION --build-number=$$BUILD_NUMBER --dart-define=ENV=prod; \
	if [ "$$AUTO_BUMP" -eq 1 ]; then \
		$(APP_VERSION_SCRIPT) bump-build >/dev/null; \
		echo "🔁 Next build prepared: $$($(APP_VERSION_SCRIPT) full)"; \
	fi

aab-release:
	@set -e; \
	test -x "$(APP_VERSION_SCRIPT)" || (echo "❌ Missing executable script: $(APP_VERSION_SCRIPT)"; exit 1); \
	MARKETING_VERSION=$$($(APP_VERSION_SCRIPT) marketing); \
	BUILD_NUMBER="$(APP_BUILD_NUMBER)"; \
	AUTO_BUMP=0; \
	if [ -z "$$BUILD_NUMBER" ]; then \
		BUILD_NUMBER=$$($(APP_VERSION_SCRIPT) build); \
		AUTO_BUMP=1; \
	fi; \
	echo "📦 Building Android AAB version $$MARKETING_VERSION ($$BUILD_NUMBER)"; \
	cp android/config/prod/google-services.json android/app/google-services.json; \
	$(FLUTTER) clean; \
	$(FLUTTER) pub get; \
	$(FLUTTER) gen-l10n; \
	$(FLUTTER) build appbundle --release --build-name=$$MARKETING_VERSION --build-number=$$BUILD_NUMBER --dart-define=ENV=prod; \
	if [ "$$AUTO_BUMP" -eq 1 ]; then \
		$(APP_VERSION_SCRIPT) bump-build >/dev/null; \
		echo "🔁 Next build prepared: $$($(APP_VERSION_SCRIPT) full)"; \
	fi

version-show:
	@echo "$$($(APP_VERSION_SCRIPT) full)"

# localhost
localhost:
	cd website && rm -rf .next && TAPEM_DEBUG=1 npm run dev

# Admin Web (Dev/Prod)
admin-web: admin-web-dev

admin-web-dev:
	cd admin-web && npm run dev -- --mode dev

admin-web-prod:
	cd admin-web && npm run build -- --mode prod && npm run preview -- --mode prod

admin-web-avatars: admin-web-avatars-dev

admin-web-avatars-dev:
	rsync -a --delete assets/avatars/ admin-web/public/avatars/
	node scripts/generate_admin_avatar_manifest.js

admin-web-avatars-prod:
	rsync -a --delete assets/avatars/ admin-web/public/avatars/
	node scripts/generate_admin_avatar_manifest.js

dev-to-prod-and-back:
	git checkout antigravity_prod
	git reset --hard antigravity_dev
	git push --force-with-lease origin antigravity_prod
	git checkout antigravity_dev



reset:
	git reset --hard origin/a_gpt5 

logo:
	fvm flutter pub run flutter_launcher_icons
