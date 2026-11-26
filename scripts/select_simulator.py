#!/usr/bin/env python3
"""Choose an Xcode-compatible iOS runtime and an iPhone simulator device type."""
import json
import re
import subprocess
import sys


def select_simulator(simctl_data, xcode_version):
    match = re.search(r"Xcode\s+(\d+)(?:\.\d+)?", xcode_version)
    if match is None:
        raise ValueError(f"Cannot parse Xcode version: {xcode_version!r}")
    xcode_major = int(match.group(1))
    supported_majors = {16: 18, 17: 26}
    ios_major = supported_majors.get(xcode_major)
    if ios_major is None:
        raise ValueError(f"Unsupported Xcode {xcode_major}; select a simulator runtime explicitly")

    def runtime_version(runtime):
        name = runtime.get("name", "")
        match = re.search(rf"\biOS\s+({ios_major}(?:\.\d+)*)\b", name)
        if not runtime.get("isAvailable") or match is None:
            return None
        return tuple(int(part) for part in match.group(1).split("."))

    runtimes = [
        (runtime_version(runtime), runtime)
        for runtime in simctl_data.get("runtimes", [])
    ]
    compatible = [(version, runtime) for version, runtime in runtimes if version is not None]
    if not compatible:
        available = ", ".join(r.get("name", "unknown") for r in simctl_data.get("runtimes", []) if r.get("isAvailable"))
        raise ValueError(f"No compatible iOS {ios_major} runtime for Xcode {xcode_major}; available: {available}")
    selected_runtime = max(compatible, key=lambda item: item[0])[1]
    devices = simctl_data.get("devicetypes", [])
    device = next((d for d in devices if d.get("name") == "iPhone 16"), None)
    if device is None:
        raise ValueError("iPhone 16 simulator device type is not installed")
    return device["identifier"], selected_runtime["identifier"]


def main():
    try:
        simctl_data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j"], text=True))
        xcode_version = subprocess.check_output(["xcodebuild", "-version"], text=True)
        device, runtime = select_simulator(simctl_data, xcode_version)
    except (ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Simulator selection failed: {error}", file=sys.stderr)
        return 1
    print(device, runtime)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
