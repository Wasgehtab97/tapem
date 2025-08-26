.PHONY: ios android push ios-dev ios-emu android-emu R rules rules-dev ios-wireless admin

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

# iOS Emulator
ios-emu:
	fvm flutter clean
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -d "iPhone 16 Plus"

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
	git reset --hard (hier die alte branch einfügen)
	git push --force-with-lease origin a_gpt5

# APK Release
apk-release:
	flutter clean
	flutter pub get
	flutter gen-l10n
	flutter build apk --release