#!/bin/bash
# Script to temporarily set PROD config, run flutter, then restore DEV config

set -e

CONFIG_FILE="$1"
DEVICE_ID="$2"
BUILD_MODE="$3"

echo "📝 Backing up current config..."
cp "ios/Flutter/${CONFIG_FILE}.xcconfig" "ios/Flutter/${CONFIG_FILE}.xcconfig.backup"

echo "🔄 Setting PROD config..."
cat > "ios/Flutter/${CONFIG_FILE}.xcconfig" << 'EOF'
#include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include? "Generated.xcconfig"

SUPPORTED_PLATFORMS = iphonesimulator iphoneos
EXCLUDED_ARCHS[sdk=iphonesimulator*] =
IPHONEOS_DEPLOYMENT_TARGET = 13.0
SWIFT_VERSION = 5.0
ENABLE_BITCODE = NO
VALIDATE_WORKSPACE = YES
OTHER_LDFLAGS = $(inherited)
FRAMEWORK_SEARCH_PATHS = $(inherited)
HEADER_SEARCH_PATHS = $(inherited)

BUNDLE_ID_SUFFIX=
DISPLAY_NAME=Tap'em
EOF

echo "🔧 Re-syncing CocoaPods with new config..."
cd ios && pod install > /dev/null 2>&1 && cd ..

# Ensure cleanup happens no matter what
cleanup() {
    echo "🔙 Restoring DEV config..."
    mv "ios/Flutter/${CONFIG_FILE}.xcconfig.backup" "ios/Flutter/${CONFIG_FILE}.xcconfig"
    echo "🔧 Re-syncing CocoaPods back to DEV..."
    cd ios && pod install > /dev/null 2>&1 && cd ..
}
trap cleanup EXIT

echo "🚀 Running Flutter..."
if [ "$BUILD_MODE" = "debug" ]; then
    fvm flutter run -d "$DEVICE_ID" --dart-define=ENV=prod
else
    fvm flutter run --release -d "$DEVICE_ID" --dart-define=ENV=prod
fi

