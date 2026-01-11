#!/usr/bin/env bash
set -euo pipefail

# Helper to locate the built APK/AAB and install it via adb.
# Usage: ./scripts/install_apk.sh [--uninstall-first] [path-to-apk-or-aab]
# If no path provided, it prefers: build/app/outputs/flutter-apk/app-release.apk,
# then app-debug.apk, then bundle release AAB.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK_DEBUG="$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
APK_RELEASE="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
AAB_RELEASE="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"

UNINSTALL_FIRST=0
INPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall-first) UNINSTALL_FIRST=1; shift ;;
    *) INPUT_PATH="$1"; shift ;;
  esac
done

if [[ -n "$INPUT_PATH" ]]; then
  TARGET="$INPUT_PATH"
elif [[ -f "$APK_RELEASE" ]]; then
  TARGET="$APK_RELEASE"
elif [[ -f "$APK_DEBUG" ]]; then
  TARGET="$APK_DEBUG"
elif [[ -f "$AAB_RELEASE" ]]; then
  TARGET="$AAB_RELEASE"
else
  echo "No APK or AAB found in expected locations." >&2
  echo "Build the app first, e.g. 'flutter build apk --release' or 'flutter build appbundle --release'" >&2
  exit 2
fi

echo "Using target: $TARGET"

if [[ "$TARGET" != *.apk ]] && [[ "$TARGET" != *.aab ]]; then
  echo "Target must be an .apk or .aab file" >&2
  exit 2
fi

# Ensure adb available
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found in PATH. Install Android platform-tools and ensure 'adb' is available." >&2
  exit 3
fi

# Optional: try to detect package name from AndroidManifest
PACKAGE_NAME="africa.hoop.mobile"
MANIFEST="$ROOT_DIR/android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST" ]]; then
  if grep -q "package=\"" "$MANIFEST"; then
    PACKAGE_NAME=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' "$MANIFEST" | head -n1)
  fi
fi

install_apk() {
  local apk="$1"
  echo "Installing $apk ..."
  set +e
  adb install -r "$apk"
  local status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    echo "adb install failed with exit $status"
    return $status
  fi
  echo "Installed successfully."
  return 0
}

if [[ "$TARGET" == *.aab ]]; then
  # Need bundletool to create an installable universal APK
  BUNDLETOOL_JAR="$ROOT_DIR/tools/bundletool.jar"
  if [[ ! -f "$BUNDLETOOL_JAR" ]]; then
    echo "bundletool.jar not found at $BUNDLETOOL_JAR"
    echo "Downloading bundletool.jar..."
    mkdir -p "$(dirname "$BUNDLETOOL_JAR")"
    curl -L -o "$BUNDLETOOL_JAR" https://github.com/google/bundletool/releases/download/1.14.0/bundletool-all-1.14.0.jar
  fi

  TMP_APKS="$ROOT_DIR/build/app/outputs/bundle/output.apks"
  echo "Building universal APK from AAB..."
  java -jar "$BUNDLETOOL_JAR" build-apks --bundle="$TARGET" --output="$TMP_APKS" --mode=universal
  unzip -o -d "$ROOT_DIR/build/app/outputs/bundle/" "$TMP_APKS" universal.apk
  UNIVERSAL="$ROOT_DIR/build/app/outputs/bundle/universal.apk"
  if [[ ! -f "$UNIVERSAL" ]]; then
    echo "Failed to produce universal.apk" >&2
    exit 4
  fi

  if [[ $UNINSTALL_FIRST -eq 1 ]]; then
    echo "Uninstalling existing app (if any): $PACKAGE_NAME"
    adb uninstall "$PACKAGE_NAME" || true
  fi

  install_apk "$UNIVERSAL" || {
    echo "Install failed. If you have an existing app signed with a different key, try uninstalling it first:" >&2
    echo "  adb uninstall $PACKAGE_NAME" >&2
    exit 5
  }

  exit 0
fi

# For APK path
if [[ $UNINSTALL_FIRST -eq 1 ]]; then
  echo "Uninstalling existing app (if any): $PACKAGE_NAME"
  adb uninstall "$PACKAGE_NAME" || true
fi

if ! install_apk "$TARGET"; then
  echo "Attempting to uninstall and reinstall..."
  adb uninstall "$PACKAGE_NAME" || true
  install_apk "$TARGET" || {
    echo "Failed to install after uninstall. See adb output above for details." >&2
    exit 6
  }
fi

echo "Done."
