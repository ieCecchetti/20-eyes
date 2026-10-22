#!/bin/sh
# Regenerates docs/images/*.png from the real SwiftUI views, using demo data.
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# One module: strip the package import and the app/widget entry points.
for f in Core/Sources/ChillyCore/*.swift App/*.swift Widget/*.swift; do
  [ "$(basename "$f")" = ChillyEyeApp.swift ] && continue
  sed -e '/^import ChillyCore$/d' -e '/^@main$/d' "$f" > "$tmp/$(basename "$f")"
done
cp scripts/Screenshots.swift "$tmp/"

swiftc -O -parse-as-library -target arm64-apple-macos14.0 -o "$tmp/screenshots" "$tmp"/*.swift
# Fake HOME keeps the demo data out of your real Application Support.
mkdir -p "$tmp/home" docs/images
HOME="$tmp/home" CFFIXED_USER_HOME="$tmp/home" "$tmp/screenshots" "$PWD/docs/images"
# The overlay is a big gradient; JPEG keeps it light for the README.
sips -s format jpeg -s formatOptions 82 docs/images/overlay.png --out docs/images/overlay.jpg >/dev/null
rm docs/images/overlay.png
