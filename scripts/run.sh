#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
python3 scripts/generate.py
xcodegen generate
# Create a disposable simulator; never erase a user's existing device.
read -r DEVICE RUNTIME < <(python3 - <<'PY'
import json, re, subprocess
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j"]))
xcode_version = subprocess.check_output(["xcodebuild", "-version"], text=True)
xcode_major = int(re.search(r"Xcode\\s+(\\d+)", xcode_version).group(1))
# Xcode 16 supports the iOS 18 simulator; Xcode 17 supports iOS 26.
ios_major = {16: 18, 17: 26}.get(xcode_major)
if ios_major is None:
    raise SystemExit(f"Unrecognized Xcode major: {xcode_major}; configure runtime explicitly")
runtimes = [r for r in data["runtimes"] if r.get("isAvailable") and
            re.search(rf"iOS {ios_major}(?:\\.|$)", r["name"])]
if not runtimes:
    raise SystemExit(f"No compatible iOS {ios_major} runtime for Xcode {xcode_major}; available: " +
                     ", ".join(r["name"] for r in data["runtimes"] if r.get("isAvailable")))
runtimes.sort(key=lambda r: tuple(int(n) for n in re.findall(r"\\d+", r["name"])))
devices = [d for d in data["devicetypes"] if d["name"] == "iPhone 16"]
if not devices:
    raise SystemExit("iPhone 16 simulator device type is unavailable")
print(devices[0]["identifier"], runtimes[-1]["identifier"])
PY
)
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
