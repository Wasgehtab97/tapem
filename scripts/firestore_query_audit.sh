#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob

echo "🔎 Audit: forbid collectionGroup('logs') in lib/"
if rg -n --glob '*.dart' "collectionGroup\(['\"]logs['\"]\)" lib; then
  echo "❌ Found collectionGroup('logs') in app code"
  exit 1
fi

echo "🔎 Audit: forbid .snapshots() in providers/profile/report widgets"
if rg -n --glob '*.dart' "\\.snapshots\\s*\(" lib/core/providers lib/features/profile lib/features/report 2>/dev/null; then
  echo "❌ Found snapshots() in providers/widgets"
  exit 1
fi

echo "🔎 Audit: .get() must be paired with .limit() in same chain (heuristic)"
fail=0
while IFS= read -r match; do
  [[ -z "$match" ]] && continue
  IFS=':' read -r file line rest <<<"$match"
  [[ -z "$file" || -z "$line" ]] && continue
  # Skip non-Firestore usages (maps, Hive boxes, etc.)
  if [[ "$rest" != *".collection"* && "$rest" != *"FirebaseFirestore"* && "$rest" != *"_firestore"* ]]; then
    continue
  fi
  if [[ "$rest" == *".doc("* ]]; then
    continue
  fi
  if [[ "$rest" == *"query.get"* ]]; then
    continue
  fi
  start=$(( line > 3 ? line - 3 : 1 ))
  window=$(sed -n "${start},${line}p" "$file")
  if ! grep -q '\.limit\s*(' <<<"$window"; then
    echo "❌ $file:$line uses .get() without nearby .limit()"
    fail=1
  fi
done < <(rg -n --color=never --glob '*.dart' '\.get\s*\(' lib || true)
if [[ $fail -ne 0 ]]; then
  exit 1
fi

echo "✅ Firestore query audit passed."
