#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
command -v xcrun >/dev/null || { echo "Cần Xcode và iOS SDK trên macOS." >&2; exit 1; }
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
mkdir -p "$root/build"
stage="$(mktemp -d "$root/build/stage.XXXXXX")"
app="$stage/Payload/FFMAXNewHUD.app"
mkdir -p "$app"
xcrun --sdk iphoneos clang -arch arm64 -isysroot "$sdk" -miphoneos-version-min=16.0 \
  -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter -O2 \
  "$root/Sources/main.m" "$root/Sources/FFReader.m" \
  -framework UIKit -framework Foundation -o "$app/FFMAXNewHUD"
cp "$root/Info.plist" "$app/Info.plist"
if command -v ldid >/dev/null; then
  ldid -S"$root/Entitlements.plist" "$app/FFMAXNewHUD"
else
  codesign --force --sign - --entitlements "$root/Entitlements.plist" "$app"
fi
(cd "$stage" && /usr/bin/zip -qr "$root/build/FFMAX-NewHUD.tipa" Payload)
echo "Đã tạo: $root/build/FFMAX-NewHUD.tipa"
