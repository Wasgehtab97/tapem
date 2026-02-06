#!/usr/bin/env bash
set -euo pipefail

PREFERRED_ID="${1:-}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is not available. Install Xcode command line tools." >&2
  exit 1
fi

if [[ -n "$PREFERRED_ID" ]]; then
  if xcrun simctl list devices available 2>/dev/null | grep -Fq "$PREFERRED_ID"; then
    echo "$PREFERRED_ID"
    exit 0
  fi
  echo "Configured simulator $PREFERRED_ID not found. Selecting first available iPhone simulator..." >&2
fi

first_available_iphone_id() {
  xcrun simctl list devices available 2>/dev/null | awk -F '[()]' '
    /^[[:space:]]*iPhone/ {
      id = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      if (id ~ /^[0-9A-F-]+$/ && length(id) == 36) {
        print id
        exit
      }
    }
  '
}

first_available_ios_runtime() {
  xcrun simctl list runtimes available 2>/dev/null | awk -F ' - ' '
    /iOS/ && /com\.apple\.CoreSimulator\.SimRuntime\.iOS-/ {
      print $2
      exit
    }
  '
}

preferred_iphone_device_type() {
  local preferred_ids=(
    "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro"
    "com.apple.CoreSimulator.SimDeviceType.iPhone-16"
    "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro"
    "com.apple.CoreSimulator.SimDeviceType.iPhone-15"
  )

  for type_id in "${preferred_ids[@]}"; do
    if xcrun simctl list devicetypes 2>/dev/null | grep -Fq "$type_id"; then
      echo "$type_id"
      return 0
    fi
  done

  xcrun simctl list devicetypes 2>/dev/null | awk '
    /com\.apple\.CoreSimulator\.SimDeviceType\.iPhone-/ {
      match($0, /\((com\.apple\.CoreSimulator\.SimDeviceType\.iPhone-[^)]+)\)/, m)
      if (m[1] != "") {
        print m[1]
        exit
      }
    }
  '
}

create_iphone_simulator() {
  local runtime_id="$1"
  local device_type_id="$2"
  local name="Tapem Auto iPhone $(date +%s)"

  xcrun simctl create "$name" "$device_type_id" "$runtime_id" 2>/dev/null || true
}

RESOLVED_ID="$(first_available_iphone_id)"

if [[ -n "$RESOLVED_ID" ]]; then
  echo "$RESOLVED_ID"
  exit 0
fi

RUNTIME_ID="$(first_available_ios_runtime)"
if [[ -z "$RUNTIME_ID" ]]; then
  echo "No available iOS runtime found." >&2
  echo "Install one in Xcode > Settings > Components (iOS Simulator Runtime)." >&2
  echo "Alternative CLI: xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi

DEVICE_TYPE_ID="$(preferred_iphone_device_type)"
if [[ -z "$DEVICE_TYPE_ID" ]]; then
  echo "No iPhone device type found in simctl." >&2
  exit 1
fi

CREATED_ID="$(create_iphone_simulator "$RUNTIME_ID" "$DEVICE_TYPE_ID")"
if [[ -z "$CREATED_ID" ]]; then
  echo "Failed to create a new iPhone simulator (runtime: $RUNTIME_ID, type: $DEVICE_TYPE_ID)." >&2
  exit 1
fi

echo "Created simulator $CREATED_ID ($DEVICE_TYPE_ID on $RUNTIME_ID)." >&2
echo "$CREATED_ID"
