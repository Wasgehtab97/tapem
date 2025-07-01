cd /Users/daniel/Projekte/tapem
fvm flutter clean
fvm flutter pub get
fvm flutter gen-l10n
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
fvm flutter run -d "iPhone von Daniel" --verbose
