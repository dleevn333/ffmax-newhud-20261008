#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$root/build"
clang "$root/ESP/Geometry.c" "$root/ESP/GeometryTests.c" -Wall -Wextra -Werror -o "$root/build/geometry-tests"
"$root/build/geometry-tests"
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang -dynamiclib -arch arm64 -isysroot "$sdk" -miphoneos-version-min=16.0 \
 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter -O2 \
 "$root/ESP/UnityBridge.m" "$root/ESP/Overlay.m" "$root/ESP/Geometry.c" \
 -framework UIKit -framework Foundation -install_name @rpath/FFMAXESP.dylib -o "$root/build/FFMAXESP.dylib"
codesign --force --sign - "$root/build/FFMAXESP.dylib"
