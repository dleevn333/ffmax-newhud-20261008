#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
out="$PWD/build/standalone"
app="$out/simulator/HUDFoundation.app"
mkdir -p "$app"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun --sdk iphonesimulator clang -arch x86_64 -isysroot "$sdk" -mios-simulator-version-min=16.0 -fobjc-arc -fmodules -Wall -Wextra -Werror -Wno-unused-parameter -O2 Standalone/main.m Standalone/State.m -framework UIKit -framework Foundation -o "$app/HUDFoundation"
cp Standalone/Info.plist "$app/Info.plist"
xcrun simctl list devices available -j > "$out/simulator-devices.json"
device="$(python3 -c 'import json; d=json.load(open("build/standalone/simulator-devices.json")); print(next(x["udid"] for r,rows in d["devices"].items() if "iOS" in r for x in rows if "iPhone" in x["name"]))')"
xcrun simctl boot "$device"
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" vn.local.ffmaxhud.foundation | tee "$out/simulator-launch.txt"
sleep 3
xcrun simctl io "$device" screenshot "$out/simulator-light.png"
xcrun simctl ui "$device" appearance dark
sleep 2
xcrun simctl io "$device" screenshot "$out/simulator-dark.png"
xcrun simctl terminate "$device" vn.local.ffmaxhud.foundation
xcrun simctl uninstall "$device" vn.local.ffmaxhud.foundation
xcrun simctl shutdown "$device"
