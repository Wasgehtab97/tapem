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