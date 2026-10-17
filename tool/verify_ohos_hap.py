#!/usr/bin/env python3
"""Check an unsigned arm64 Release HAP and its Native Assets mappings."""

import argparse
import json
from pathlib import Path
import re
import struct
import zipfile


ROOT = Path(__file__).resolve().parent.parent


def verify_hap(path, bundle_name="com.predidit.kazumi"):
    version = re.search(
        r"^version: ([0-9.]+)\+([0-9]+)$",
        (ROOT / "pubspec.yaml").read_text(), re.M,
    )
    if not version:
        raise ValueError("Cannot read the application version from pubspec.yaml")
    with zipfile.ZipFile(path) as hap:
        corrupt = hap.testzip()
        if corrupt:
            raise ValueError(f"Corrupt HAP member: {corrupt}")
        app = json.loads(hap.read("module.json"))["app"]
        expected = {
            "bundleName": bundle_name,
            "versionName": version[1],
            "versionCode": int(version[2]),
            "debug": False,
        }
        for key, value in expected.items():
            if app.get(key) != value:
                raise ValueError(f"Unexpected {key}: {app.get(key)!r}, expected {value!r}")
        if any(name.endswith("kernel_blob.bin") for name in hap.namelist()):
            raise ValueError("Release HAP contains a Debug kernel")
        libraries = (
            "libapp.so", "libflutter.so", "libmpv.so", "libech_http.so",
            "libmedia_kit_event_loop.so", "libc++_shared.so",
        )
        for library in libraries:
            header = hap.read(f"libs/arm64-v8a/{library}")[:20]
            if (header[:6] != b"\x7fELF\x02\x01"
                    or struct.unpack_from("<H", header, 18)[0] != 183):
                raise ValueError(f"{library} is not a little-endian arm64 ELF library")
        manifest = json.loads(hap.read(
            "resources/rawfile/flutter_assets/NativeAssetsManifest.json",
        ))
        assets = manifest["native-assets"]["ohos_arm64"]
        for asset, library in {
            "package:ech_http/ech_http_bindings": "libech_http.so",
            "package:media_kit/libmpv": "libmpv.so",
            "package:media_kit/src/player/native/core/native_event_loop_bindings.dart":
                "libmedia_kit_event_loop.so",
            "package:media_kit/native/libc++_shared.so": "libc++_shared.so",
        }.items():
            if assets.get(asset) != ["absolute", library]:
                raise ValueError(f"Missing or incorrect native asset: {asset}")
    return app


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hap", type=Path)
    parser.add_argument("--bundle-name", default="com.predidit.kazumi")
    args = parser.parse_args()
    app = verify_hap(args.hap, args.bundle_name)
    print(f"Verified arm64 Release HAP: {app['bundleName']} {app['versionName']}")
