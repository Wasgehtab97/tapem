#!/bin/bash

# Script to add default stickers to Firestore using REST API
# Run this after logging in with: firebase login

PROJECT_ID="tap-em-dev"

echo "Adding default stickers to Firestore..."

# Get access token
TOKEN=$(firebase login:ci --no-localhost 2>/dev/null || gcloud auth print-access-token 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
  echo "❌ Could not get access token. Please run: firebase login"
  exit 1
fi

# Function to add a sticker
add_sticker() {
  local id=$1
  local name=$2
  local url=$3
  local order=$4
  
  curl -X PATCH \
    "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/stickers/${id}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"fields\": {
        \"name\": {\"stringValue\": \"${name}\"},
        \"imageUrl\": {\"stringValue\": \"${url}\"},
        \"isPremium\": {\"booleanValue\": false},
        \"sortOrder\": {\"integerValue\": \"${order}\"}
      }
    }" > /dev/null 2>&1
  
  echo "✅ Added: ${name}"
}

# Add all default stickers
add_sticker "sticker_1" "Thumbs Up" "https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif" "1"
add_sticker "sticker_2" "Heart" "https://fonts.gstatic.com/s/e/notoemoji/latest/2764_fe0f/512.gif" "2"
add_sticker "sticker_3" "Fire" "https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif" "3"
add_sticker "sticker_4" "Muscle" "https://fonts.gstatic.com/s/e/notoemoji/latest/1f4aa/512.gif" "4"
add_sticker "sticker_5" "100" "https://fonts.gstatic.com/s/e/notoemoji/latest/1f4af/512.gif" "5"
add_sticker "sticker_6" "Party" "https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif" "6"

echo ""
echo "🎉 All default stickers added successfully!"
echo "Restart your app to see them."
