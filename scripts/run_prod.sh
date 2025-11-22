#!/bin/bash

# This script builds and runs the Prod app with Debug-Prod configuration

set -e

WORKSPACE="ios/Runner.xcworkspace"
SCHEME="Runner"
CONFIGURATION="Debug-Prod"
DEVICE="iPhone 16 Plus"

cd "$(dirname "$0")/.."

echo "📦 Building with Debug-Prod configuration using xcodebuild..."

# First, build the app with Debug-Prod configuration
fvm flutter build ios --debug --no-codesign

# Then do manual xcodebuild with Debug-Prod
cd ios

xcodebuild -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath ../build/ios \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

cd ..

# Get simulator UDID
SIMULATOR_UDID=$(xcrun simctl list devices | grep "$DEVICE" | grep "Booted" | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')

if [ -z "$SIMULATOR_UDID" ]; then
  echo "Simulator not found or not booted. Opening simulator..."
  open -a Simulator
  sleep 5
  SIMULATOR_UDID=$(xcrun simctl list devices | grep "$DEVICE" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
fi

# Install the app
APP_PATH="build/ios/Build/Products/Debug-Prod-iphonesimulator/Runner.app"

if [ -d "$APP_PATH" ]; then
  echo "📱 Installing Prod app..."
  xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
  echo "🚀 Launching Prod app..."
  xcrun simctl launch "$SIMULATOR_UDID" com.example.tapem
  
  # Attach debugger with flutter attach
  echo "🔧 Attaching Flutter debugger..."
  fvm flutter attach -d "$DEVICE"
else
  echo "❌ App not found af $APP_PATH"
  exit 1
fi
