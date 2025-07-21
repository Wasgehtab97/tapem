.PHONY: ios android push ios-dev ios-emu admin R

# Geräte-IDs
IOS_DEV_ID := 00008030-001E59420191802E
IOS_EMU_ID := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID := 519e8f06

# iOS: Clean, Get, Gen, Pod Install, Release-Run
ios:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d $(IOS_DEV_ID)

# Android: Clean, Get, Gen, Release-Run
android:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run --release -d $(ANDROID_ID)

# git push
push:
	git add .
	git commit -m "newest push"
	git push

# iOS Dev: inkrementeller Debug-Build ohne clean und Pods
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

# SetAdmin
admin:
	node scripts/setAdmin.js

# R: Pull, Dependencies, Gen, Hot Restart im laufenden Debug-Process
R:
	git pull
	@sleep 5
	fvm flutter pub get && fvm flutter gen-l10n
	@sleep 5
	@printf "R\nq\n" | fvm flutter attach -d $(IOS_EMU_ID) &>/dev/null
	@sleep 5