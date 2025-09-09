#!/usr/bin/env bash
set -euo pipefail

MANIFEST=${1:-build/flutter_assets/AssetManifest.json}

if [[ ! -f "$MANIFEST" ]]; then
  echo "AssetManifest not found: $MANIFEST"
  exit 1
fi

missing=0

grep -q "\"assets/avatars/global/default.png\"" "$MANIFEST" || {
  echo "missing: assets/avatars/global/default.png"
  missing=1
}

while IFS= read -r file; do
  rel=${file#./}
  grep -q "\"$rel\"" "$MANIFEST" || {
    echo "missing: $rel"
    missing=1
  }
  done < <(find assets/avatars -path 'assets/avatars/gym_*/*.png' -print)

if [[ $missing -ne 0 ]]; then
  exit 1
fi

echo "All avatar paths present."
