#!/bin/bash

# Simple migration script using Firebase CLI
# This creates rotating gym codes for existing gyms

echo "🚀 Starting Gym Code Migration for tap-em-dev..."
echo ""

# Make sure we're using the dev project
firebase use tap-em-dev

echo "📋 Creating rotating codes for gyms..."
echo ""

# Lifthouse_dev
CODE1=$(node -e "const chars='ABCDEFGHJKLMNPQRTUVWXY3468'; let code=''; for(let i=0; i<6; i++) code+=chars[Math.floor(Math.random()*chars.length)]; console.log(code);")
EXPIRES=$(node -e "const d=new Date(); d.setDate(d.getDate()+30); console.log(d.toISOString());")

echo "Processing: Lifthouse Dev (Lifthouse_dev)"
echo "  Generated code: $CODE1"
echo "  Expires: $EXPIRES"
echo ""

# Create the code document using Firebase CLI
cat > /tmp/gym_code_temp.json <<EOF
{
  "code": "$CODE1",
  "gymId": "Lifthouse_dev",
  "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "expiresAt": "$EXPIRES",
  "isActive": true,
  "createdBy": "migration-script"
}
EOF

echo "✅ Code generated: $CODE1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Migration Complete!"
echo ""
echo "Next steps:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/project/tap-em-dev/firestore"
echo "2. Navigate to: gym_codes/Lifthouse_dev/codes"
echo "3. Add a new document with this data:"
echo ""
cat /tmp/gym_code_temp.json
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
