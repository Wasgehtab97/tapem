#!/bin/bash

echo "═════════════════════════════════════════════════════"
echo "🚀 Installing BOTH Dev & Prod Apps"
echo "═════════════════════════════════════════════════════"
echo ""

# Start Simulator
echo "📱 Opening Simulator..."
open -a Simulator
sleep 5

# Build and install DEV app
echo ""
echo "📱 Step 1/2: Building DEV app..."
echo "════════════════════════════════════════════════════"
cp ios/Runner/GoogleService-Info-Dev.plist ios/Runner/GoogleService-Info.plist
fvm flutter pub get > /dev/null 2>&1
fvm flutter gen-l10n > /dev/null 2>&1

echo "🏗️  Installing DEV app..."
fvm flutter install -d "iPhone 16 Plus" --dart-define=ENV=dev
echo "✅ DEV app installed!"

# Build and install PROD app  
echo ""
echo "📱 Step 2/2: Building PROD app..."
echo "════════════════════════════════════════════════════"
cp ios/Runner/GoogleService-Info-Prod.plist ios/Runner/GoogleService-Info.plist  
sleep 2

echo "🏗️  Installing PROD app..."
fvm flutter install -d "iPhone 16 Plus" --dart-define=ENV=prod
echo "✅ PROD app installed!"

echo ""
echo "═════════════════════════════════════════════════════"
echo "✨ SUCCESS! Both apps are now installed!"
echo "═════════════════════════════════════════════════════"
echo "📱 Tap'em DEV   → Bundle ID: com.example.tapem.dev"
echo "📱 Tap'em       → Bundle ID: com.example.tapem"
echo "═════════════════════════════════════════════════════"
echo ""
echo "💡 You can now run both apps from the Simulator!"
echo ""
