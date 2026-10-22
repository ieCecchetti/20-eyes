#!/bin/sh
# Builds an unsigned, drag-to-Applications DMG: scripts/make-dmg.sh 1.0.0 → build/ChillyEye-1.0.0.dmg
set -eu
version=${1:?usage: make-dmg.sh <version>}
cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild -project ChillyEye.xcodeproj -scheme ChillyEye -configuration Release \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO MARKETING_VERSION="$version" build

stage=build/dmg
rm -rf "$stage" && mkdir -p "$stage"
cp -R "build/Build/Products/Release/Chilly Eye.app" "$stage/"
# ponytail: the widget needs a Developer ID–signed App Group; drop it until releases are signed.
rm -rf "$stage/Chilly Eye.app/Contents/PlugIns"
codesign --force --deep --sign - "$stage/Chilly Eye.app" # ad-hoc: Apple Silicon refuses unsigned apps
ln -s /Applications "$stage/Applications"

dmg="build/ChillyEye-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "Chilly Eye" -srcfolder "$stage" -format UDZO -ov "$dmg"
echo "$dmg"
