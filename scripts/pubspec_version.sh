#!/usr/bin/env bash
set -euo pipefail

PUBSPEC_PATH="${PUBSPEC_PATH:-pubspec.yaml}"

usage() {
  cat <<'EOF'
Usage:
  pubspec_version.sh full
  pubspec_version.sh marketing
  pubspec_version.sh build
  pubspec_version.sh set <marketing_version> <build_number>
  pubspec_version.sh bump-build
EOF
}

read_version() {
  awk '/^version:/{print $2; exit}' "$PUBSPEC_PATH"
}

version_value="$(read_version)"
if [[ -z "${version_value:-}" ]]; then
  echo "Could not read version from $PUBSPEC_PATH" >&2
  exit 1
fi

marketing_version="${version_value%%+*}"
build_number="${version_value##*+}"

write_version() {
  local new_marketing="$1"
  local new_build="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  awk -v v="version: ${new_marketing}+${new_build}" '
    BEGIN { done = 0 }
    /^version:/ {
      print v
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        exit 1
      }
    }
  ' "$PUBSPEC_PATH" > "$tmp_file"
  mv "$tmp_file" "$PUBSPEC_PATH"
}

cmd="${1:-}"
case "$cmd" in
  full)
    echo "${marketing_version}+${build_number}"
    ;;
  marketing)
    echo "${marketing_version}"
    ;;
  build)
    echo "${build_number}"
    ;;
  set)
    new_marketing="${2:-}"
    new_build="${3:-}"
    if [[ -z "$new_marketing" || -z "$new_build" ]]; then
      echo "set requires: <marketing_version> <build_number>" >&2
      usage >&2
      exit 1
    fi
    if ! [[ "$new_build" =~ ^[0-9]+$ ]]; then
      echo "build_number must be numeric" >&2
      exit 1
    fi
    write_version "$new_marketing" "$new_build"
    echo "${new_marketing}+${new_build}"
    ;;
  bump-build)
    if ! [[ "$build_number" =~ ^[0-9]+$ ]]; then
      echo "Current build number is not numeric: $build_number" >&2
      exit 1
    fi
    next_build="$((build_number + 1))"
    write_version "$marketing_version" "$next_build"
    echo "${marketing_version}+${next_build}"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
