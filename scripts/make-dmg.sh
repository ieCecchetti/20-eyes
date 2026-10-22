#!/bin/sh
# Builds a drag-to-Applications DMG: scripts/make-dmg.sh 1.0.0 → build/ChillyEye-1.0.0.dmg
#
# With a "Developer ID Application" certificate in the keychain, the app is signed (widget included)
# and notarized using either:
#   NOTARY_PROFILE (default: chilly-notary), a `notarytool store-credentials` keychain profile, or
#   NOTARY_APPLE_ID + NOTARY_PASSWORD + TEAM_ID env vars (CI).
# Without a certificate it falls back to an ad-hoc signed build without the widget.
set -eu
version=${1:?usage: make-dmg.sh <version>}
cd "$(dirname "$0")/.."

identity=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)

xcodegen generate
if [ -n "$identity" ]; then
  echo "Signing with: $identity"
  xcodebuild -project ChillyEye.xcodeproj -scheme ChillyEye -configuration Release \
    -derivedDataPath build MARKETING_VERSION="$version" \
    ${TEAM_ID:+DEVELOPMENT_TEAM="$TEAM_ID"} \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$identity" OTHER_CODE_SIGN_FLAGS=--timestamp \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO build # no get-task-allow: notarization rejects it
else
  echo "No Developer ID certificate: building unsigned (no widget)"
  xcodebuild -project ChillyEye.xcodeproj -scheme ChillyEye -configuration Release \
    -derivedDataPath build CODE_SIGNING_ALLOWED=NO MARKETING_VERSION="$version" build
fi

stage=build/dmg
rm -rf "$stage" && mkdir -p "$stage"
cp -R "build/Build/Products/Release/Chilly Eye.app" "$stage/"
if [ -z "$identity" ]; then
  # The widget needs a Developer ID–signed App Group, so it's left out here.
  rm -rf "$stage/Chilly Eye.app/Contents/PlugIns"
  codesign --force --deep --sign - "$stage/Chilly Eye.app" # ad-hoc: Apple Silicon refuses unsigned apps
fi
codesign --verify --deep --strict "$stage/Chilly Eye.app"
ln -s /Applications "$stage/Applications"

dmg="build/ChillyEye-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "Chilly Eye" -srcfolder "$stage" -format UDZO -ov "$dmg"

if [ -n "$identity" ]; then
  codesign --sign "$identity" --timestamp "$dmg"
  if [ -n "${NOTARY_APPLE_ID:-}" ]; then
    xcrun notarytool submit "$dmg" --wait \
      --apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$TEAM_ID"
  else
    xcrun notarytool submit "$dmg" --wait --keychain-profile "${NOTARY_PROFILE:-chilly-notary}"
  fi
  xcrun stapler staple "$dmg"
  spctl --assess --type open --context context:primary-signature -v "$dmg"
fi
echo "$dmg"
