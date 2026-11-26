# Apple Photos Quality Engineering Toolkit
Independent portfolio MVP for native photo-library QA tooling. Not affiliated with Apple; tests a custom PhotoKit host, not Apple's internal Photos implementation.

## Architecture
Python fixture generator → disposable iOS simulator → SwiftUI/PhotoKit host → XCTest/XCUITest → xcresult → HTML qualification report.

## Run
Requires macOS, Xcode 16+ with an iOS runtime supporting iPhone 16, XcodeGen, Python 3 and Pillow.

```bash
brew install xcodegen
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/run.sh
```
The script creates and deletes only its own simulator, seeds three synthetic images, grants photo access, builds and executes tests. Inspect artifacts/report.html and the xcresult bundle. CI runs on push, PR, manual dispatch and nightly.

## Coverage
- PhotoKit authorization, image enumeration and asset dimensions via custom host.
- ImageIO dimensions, orientation default and corrupt-data rejection.
- Clock and memory measurements (no calibrated performance threshold yet).
- Screenshot evidence and qualification summary; missing evidence fails qualification.
- Album creation is exposed in the host but not yet covered by automated assertions.

## Next steps
Add HEIC and EXIF fixtures, duplicate detection, thumbnail decoding, limited/denied permission tests, album membership assertions, larger datasets, Swift concurrency stress tests, OSLog export and calibrated performance baselines. Add manifest-driven validation for every imported asset. iCloud synchronization is outside this MVP.

## Verification status
Native compilation and simulator execution require macOS and have not been verified in the generation environment. Run CI before claiming a passing native suite. The project is a prototype, not production-certified tooling.
