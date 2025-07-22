.PHONY: ios android push ios-dev ios-emu R

# Gerätedefinitionen
iOS_DEV_ID   := 00008030-001E59420191802E
IOS_EMU_ID   := 47B92242-AE5E-489D-9EA0-199C9CAE3003
ANDROID_ID   := 519e8f06
TMUX_SESSION := flutter

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

# iOS-Emulator in tmux-Session starten (nur einmal ausführen)
ios-emu:
	@echo "Starte iOS-Emulator in tmux-Session '$(TMUX_SESSION)'..."
	@tmux new-session -d -s $(TMUX_SESSION) "fvm flutter run -d $(IOS_EMU_ID)"
	@echo "→ Terminal-Session: tmux attach -t $(TMUX_SESSION)"

# SetAdmin: Utility-Target
admin:
	node scripts/setAdmin.js

# R: Pull, Dependencies, Gen, Hot Restart per SIGUSR2 auf die PID in PIDFILE
R:
	git pull
	fvm flutter pub get
	fvm flutter gen-l10n