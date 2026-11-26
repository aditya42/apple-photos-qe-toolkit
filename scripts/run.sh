#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
python3 scripts/generate.py
xcodegen generate
# Create a disposable simulator; never erase a user's existing device.
# Keep Python parsing in a real module; Bash must not interpret its syntax.
SELECTION="$(python3 scripts/select_simulator.py)"
read -r DEVICE RUNTIME <<< "$SELECTION"
echo "Selected simulator: $DEVICE / $RUNTIME for $(xcodebuild -version | head -1)"
UDID=$(xcrun simctl create "PhotosLab-$$" "$DEVICE" "$RUNTIME")
trap 'xcrun simctl shutdown "$UDID" || true; xcrun simctl delete "$UDID" || true' EXIT
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl addmedia "$UDID" artifacts/fixtures/small.png artifacts/fixtures/landscape.jpg artifacts/fixtures/portrait.jpg
xcodebuild -project PhotosLab.xcodeproj -scheme PhotosLab -destination "id=$UDID" -derivedDataPath artifacts/build build-for-testing CODE_SIGNING_ALLOWED=NO
xcrun simctl install "$UDID" artifacts/build/Build/Products/Debug-iphonesimulator/PhotosLab.app
xcrun simctl privacy "$UDID" grant photos org.portfolio.PhotosLab
# Report the pre-authorized state; PHPhotoLibrary.reload() uses the existing grant.
echo "Granted photos access to org.portfolio.PhotosLab on simulator $UDID"
RESULT="artifacts/run-$(date +%s).xcresult"
set +e
xcodebuild -project PhotosLab.xcodeproj -scheme PhotosLab -destination "id=$UDID" -derivedDataPath artifacts/build -parallel-testing-enabled NO -resultBundlePath "$RESULT" test-without-building CODE_SIGNING_ALLOWED=NO
STATUS=$?
set -e
xcrun xcresulttool get test-results summary --path "$RESULT" > artifacts/summary.json || true
python3 scripts/report.py artifacts/summary.json "$STATUS"
exit "$STATUS"
