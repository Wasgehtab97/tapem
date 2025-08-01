.PHONY: ios android push ios-dev ios-emu R rules rules-dev

# Gerätedefinitionen
iOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
TMUX_SESSION := flutter
FIREBASE_CONFIG ?= firebase.json

# Standard-Targets
ios:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d $(IOS_DEV_ID)

android:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run --release -d $(ANDROID_ID)

push:
	git add .
	git commit -m "newest push"
	git push

# Dev-Targets ohne Clean/Pods für schnellen Workflow
ios-dev:
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -v -d $(IOS_DEV_ID)

# iOS Emulator: Start simulator und run im Debug-Mode
ios-emu:
	fvm flutter clean
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -d $(IOS_EMU_ID)

# SetAdmin: Utility-Target
admin:
	node scripts/setAdmin.js

# R: Pull, Dependencies, Gen, Hot Restart per SIGUSR2 auf die PID in PIDFILE
R:
	git pull
	fvm flutter pub get
	fvm flutter gen-l10n

# iOS Wireless: Verbindung zum iPhone über Netzwerk
ios-wireless:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d 00008030-001E59420191802E --device-timeout=30

# Deploy firestore.rules
rules:
        npx firebase deploy --only firestore:rules -c $(FIREBASE_CONFIG)

rules-dev:
        $(MAKE) rules FIREBASE_CONFIG=firebase.dev.json