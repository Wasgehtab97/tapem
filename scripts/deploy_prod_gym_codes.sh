#!/bin/bash

# scripts/deploy_prod_gym_codes.sh
# Complete production deployment for gym code system

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 PRODUCTION GYM CODE DEPLOYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Verify we're on the right project
echo "📋 Step 1: Verifying Firebase project..."
firebase use tap-em
CURRENT_PROJECT=$(firebase use | grep "Now using project" | awk '{print $4}')

if [ "$CURRENT_PROJECT" != "tap-em" ]; then
    echo "❌ ERROR: Not on tap-em project!"
    echo "Current project: $CURRENT_PROJECT"
    exit 1
fi

echo "✅ Confirmed: Using tap-em (production)"
echo ""

# Step 2: Deploy Firestore rules
echo "📋 Step 2: Deploying Firestore rules..."
firebase deploy --only firestore:rules

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to deploy Firestore rules"
    exit 1
fi

echo "✅ Firestore rules deployed"
echo ""

# Step 3: Generate gym codes
echo "📋 Step 3: Generating gym codes..."
echo ""
echo "⚠️  IMPORTANT: The Node.js script will generate codes for manual entry."
echo "   (Automatic creation requires service account credentials)"
echo ""

node scripts/create_gym_codes_prod.js

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next Steps:"
echo "1. Add the generated codes to Firebase Console"
echo "2. Test registration with one of the codes"
echo "3. Verify in Firebase Console that user was created correctly"
echo ""
echo "🔗 Firebase Console:"
echo "https://console.firebase.google.com/project/tap-em/firestore/data/~2Fgym_codes"
echo ""
