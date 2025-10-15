#!/usr/bin/env bash
# Lists potentially expensive Firestore query patterns so reviewers can double-check
# that paging and limits remain in place. This script intentionally avoids
# recursion over build artifacts and only inspects the lib/ tree.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

echo "🔎 Searching for Firestore streams (snapshots/listen)"
rg --no-heading --line-number "\\.snapshots\\(" lib || true
rg --no-heading --line-number "\\.listen\\(" lib || true

echo "\n🔎 Searching for collectionGroup usage without an explicit limit"
rg --no-heading --line-number "collectionGroup\('" lib | while read -r line; do
  file="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  if ! sed -n "${lineno},$((lineno+5))p" "$file" | grep -q "limit"; then
    printf '%s\n' "$line"
  fi
done

echo "\nℹ️  Review the output above and ensure new queries keep limits and caches in place."
