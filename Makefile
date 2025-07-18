.PHONY: ios android

# iOS: Clean, Get, Gen, Pod Install, Release-Run
ios:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	cd ios && pod install && cd ..
	fvm flutter run --release -d 00008030-001E59420191802E

# Android: Clean, Get, Gen, Release-Run
android:
	fvm flutter clean
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run --release -d 519e8f06

# git push
push:
	git add .
	git commit -m "newest push"
	git push

# iOS Dev: inkrementeller Debug-Build ohne clean und Pods
ios-dev:
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -v -d 00008030-001E59420191802E

# iOS Emulator: Start simulator and run app in debug mode
ios-emu:
	fvm flutter clean
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	fvm flutter run -d 47B92242-AE5E-489D-9EA0-199C9CAE3003

# SetAdmin
admin:
	node scripts/setAdmin.js