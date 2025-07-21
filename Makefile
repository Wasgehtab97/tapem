.PHONY: ios android push ios-dev ios-emu admin R

# Geräte-IDs
IOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
PIDFILE      := /tmp/flutter.pid

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

# iOS Emulator: Start simulator, build Debug und schreibe PID zum Hot Restart
ios-emu:
	fvm flutter clean
	open -a Simulator
	@sleep 5
	fvm flutter pub get
	fvm flutter gen-l10n
	# --pid-file schreibt die Flutter-Prozess-ID hier hinein
	fvm flutter run -d $(IOS_EMU_ID) --pid-file $(PIDFILE)

# SetAdmin
admin:
	node scripts/setAdmin.js

# R: Pull, Dependencies, Gen, dann Hot Restart per SIGUSR2
R:
	git pull
	@echo "→ Pull done, warte kurz…"
	@sleep 2
	fvm flutter pub get && fvm flutter gen-l10n
	@echo "→ Dependencies up to date, führe Hot Restart aus…"
	@sleep 1
# SIGUSR2 löst im laufenden Flutter-Prozess einen Hot Restart aus
	-kill -USR2 `cat $(PIDFILE)` 2>/dev/null || echo "⚠️ Kein laufender Flutter-Prozess gefunden"