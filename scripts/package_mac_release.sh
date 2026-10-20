#!/bin/sh
# Packages the macOS release build into a DMG and a zip.
#
# When MACOS_CERT_P12 is set, the app and DMG are signed with the
# Developer ID certificate, notarized and stapled. Without it (forks,
# local builds) the outputs stay ad-hoc signed.
#
# Signing env:
#   MACOS_CERT_P12        base64 Developer ID Application .p12
#   MACOS_CERT_PASS       password of the .p12
#   APPLE_API_KEY_P8      base64 App Store Connect API key (.p8)
#   APPLE_API_KEY_ID      key ID of the API key
#   APPLE_API_ISSUER_ID   issuer ID of the API key
#
# Usage: scripts/package_mac_release.sh <zip name>
set -eu

ZIP_NAME="$1"
RELEASE_DIR="build/macos/Build/Products/Release"
APP="$RELEASE_DIR/Sidekick.app"
DMG="$RELEASE_DIR/Sidekick.dmg"
ENTITLEMENTS="macos/Runner/Release.entitlements"
WORK_DIR="${RUNNER_TEMP:-$(mktemp -d)}"

if [ -z "${MACOS_CERT_P12:-}" ]; then
  echo "::warning::MACOS_CERT_P12 is not set, the macOS build is not signed or notarized"
  ./scripts/create_mac_dmg.sh
  ditto -c -k --keepParent "$APP" "$ZIP_NAME"
  exit 0
fi

# Import the certificate into a throwaway keychain
KEYCHAIN="$WORK_DIR/signing.keychain-db"
KEYCHAIN_PASS="$(openssl rand -base64 24)"
echo "$MACOS_CERT_P12" | base64 --decode > "$WORK_DIR/cert.p12"
security create-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN"
security import "$WORK_DIR/cert.p12" -k "$KEYCHAIN" -P "$MACOS_CERT_PASS" \
  -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASS" \
  "$KEYCHAIN" > /dev/null
# shellcheck disable=SC2046
security list-keychains -d user -s "$KEYCHAIN" \
  $(security list-keychains -d user | tr -d '"')
rm "$WORK_DIR/cert.p12"

IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" \
  | grep "Developer ID Application" | head -1 | awk '{print $2}')"
if [ -z "$IDENTITY" ]; then
  echo "::error::No Developer ID Application identity in MACOS_CERT_P12"
  exit 1
fi

# Sign nested code first, innermost out, then the app itself
find "$APP/Contents/Frameworks" -depth \
  \( -name "*.framework" -o -name "*.dylib" \) -print0 \
  | xargs -0 -n1 codesign --force --timestamp --options runtime \
    --sign "$IDENTITY"
codesign --force --timestamp --options runtime \
  --entitlements "$ENTITLEMENTS" --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

./scripts/create_mac_dmg.sh
codesign --force --timestamp --sign "$IDENTITY" "$DMG"

# Notarizing the DMG also notarizes the app inside it
echo "$APPLE_API_KEY_P8" | base64 --decode > "$WORK_DIR/api_key.p8"
xcrun notarytool submit "$DMG" \
  --key "$WORK_DIR/api_key.p8" \
  --key-id "$APPLE_API_KEY_ID" \
  --issuer "$APPLE_API_ISSUER_ID" \
  --wait --timeout 30m \
  --output-format json > "$WORK_DIR/notarization.json"
cat "$WORK_DIR/notarization.json"

STATUS="$(plutil -extract status raw -o - "$WORK_DIR/notarization.json")"
if [ "$STATUS" != "Accepted" ]; then
  SUBMISSION_ID="$(plutil -extract id raw -o - "$WORK_DIR/notarization.json")"
  xcrun notarytool log "$SUBMISSION_ID" \
    --key "$WORK_DIR/api_key.p8" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_ISSUER_ID" || true
  echo "::error::Notarization finished with status $STATUS"
  exit 1
fi
rm "$WORK_DIR/api_key.p8"

xcrun stapler staple "$DMG"
xcrun stapler staple "$APP"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"
spctl --assess --type execute --verbose "$APP"

ditto -c -k --keepParent "$APP" "$ZIP_NAME"
security delete-keychain "$KEYCHAIN"
