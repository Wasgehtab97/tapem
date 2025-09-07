#!/bin/bash
set -e
# Fail if assets/avatars is referenced directly in lib/** excluding resolver and main.dart
files=$(rg -l "assets/avatars" lib | grep -v "avatar_catalog.dart" | grep -v "core/utils/avatar_assets.dart" | grep -v "lib/main.dart" || true)
if [ -n "$files" ]; then
  echo "Disallowed assets/avatars references found:" >&2
  echo "$files" >&2
  exit 1
fi
