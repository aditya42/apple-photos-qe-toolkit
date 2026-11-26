#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
python3 scripts/generate.py
xcodegen generate
# Create a disposable simulator; never erase a user's existing device.
read -r DEVICE RUNTIME < <(python3 -c 'import json,subprocess; d=json.loads(subprocess.check_output(["xcrun","simctl","list","-j"])); r=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x["name"]][-1]; t=next(x for x in d["devicetypes"] if x["name"]=="iPhone 16"); print(t["identifier"],r["identifier"])')
UDID=$(xcrun simctl create "PhotosLab-$$" "$DEVICE" "$RUNTIME")
trap 'xcrun simctl shutdown "$UDID" || true; xcrun simctl delete "$UDID" || true' EXIT
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl addmedia "$UDID" artifacts/fixtures/small.png artifacts/fixtures/landscape.jpg artifacts/fixtures/portrait.jpg
xcodebuild -project PhotosLab.xcodeproj -scheme PhotosLab -destination "id=$UDID" -derivedDataPath artifacts/build build-for-testing CODE_SIGNING_ALLOWED=NO
xcrun simctl install "$UDID" artifacts/build/Build/Products/Debug-iphonesimulator/PhotosLab.app
xcrun simctl privacy "$UDID" grant photos org.portfolio.PhotosLab
# Xcode may install a fresh test app; provision permission again immediately before launch.
# Log the simulator and photos database state to aid diagnosis.
xcrun simctl spawn "$UDID" launchctl print system >/dev/null || true
RESULT="artifacts/run-$(date +%s).xcresult"
set +e
xcodebuild -project PhotosLab.xcodeproj -scheme PhotosLab -destination "id=$UDID" -derivedDataPath artifacts/build -parallel-testing-enabled NO -resultBundlePath "$RESULT" test-without-building CODE_SIGNING_ALLOWED=NO
STATUS=$?
set -e
xcrun xcresulttool get test-results summary --path "$RESULT" > artifacts/summary.json || true
python3 scripts/report.py artifacts/summary.json "$STATUS"
exit "$STATUS"
