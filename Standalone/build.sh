#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/standalone
clang -fobjc-arc -fmodules -Wall -Wextra -Werror Standalone/State.m Standalone/Tests.m -framework Foundation -o build/standalone/state-tests
build/standalone/state-tests | tee build/standalone/tests.txt
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
stage="$(mktemp -d "$PWD/build/standalone/stage.XXXXXX")"
app="$stage/Payload/HUDFoundation.app"
mkdir -p "$app"
xcrun --sdk iphoneos clang -arch arm64 -isysroot "$sdk" -miphoneos-version-min=16.0 -fobjc-arc -fmodules -Wall -Wextra -Werror -Wno-unused-parameter -O2 Standalone/main.m Standalone/State.m -framework UIKit -framework Foundation -o "$app/HUDFoundation"
cp Standalone/Info.plist "$app/Info.plist"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
output="$PWD/build/standalone/FFMAX-HUD-Foundation-0.2.0.tipa"
(cd "$stage" && zip -qr "$output" Payload)
python3 Standalone/verify-package.py build/standalone/FFMAX-HUD-Foundation-0.2.0.tipa > build/standalone/package-validation.json
