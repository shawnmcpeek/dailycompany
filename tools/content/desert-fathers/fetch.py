#!/usr/bin/env python3
"""Fetch Budge, The Paradise or Garden of the Holy Fathers (1907), both volumes."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

VOLS = {
    "budge_vol01.txt": [
        "paradiseorgarden01anan",
        "paradiseorgarden01ann",
        "theparadiseorgar01unkwuoft",
        "ParadiseOfTheHolyFathersV1",
    ],
    "budge_vol02.txt": [
        "paradiseorgarden02anan",
        "paradiseorgarden02ann",
        "theparadiseorgar00unkwuoft",
        "ParadiseOfTheHolyFathersV2",
    ],
}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        return resp.read()


def ia_djvu_url(identifier: str) -> str | None:
    meta = json.loads(get(f"https://archive.org/metadata/{identifier}").decode())
    files = meta.get("files") or []
    for f in files:
        name = f.get("name") or ""
        if name.endswith("_djvu.txt"):
            return f"https://archive.org/download/{identifier}/{name}"
    return None


def fetch_id(identifier: str, dest: Path) -> bool:
    try:
        url = ia_djvu_url(identifier)
        if not url:
            print(f"no djvu.txt for {identifier}")
            return False
        data = get(url)
        if len(data) < 50_000:
            print(f"thin {identifier} ({len(data)} bytes)")
            return False
        sample = data[:4000].decode("utf-8", errors="replace").lower()
        if "<html" in sample:
            print(f"html {identifier}")
            return False
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes) from {url}")
        return True
    except Exception as e:
        print(f"FAIL {identifier}: {e}")
        return False


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    for dest_name, idents in VOLS.items():
        dest = RAW / dest_name
        ok = False
        for ident in idents:
            print(f"try {dest_name} as {ident}")
            if fetch_id(ident, dest):
                ok = True
                break
        if not ok:
            errors.append(dest_name)
    if errors:
        raise SystemExit("fetch failed: " + ", ".join(errors))
    blob = " ".join(
        (RAW / name).read_text(encoding="utf-8", errors="replace")[:80_000]
        for name in VOLS
    ).lower()
    for must in ("paradise", "holy fathers", "palladius", "arsenius"):
        if must not in blob:
            raise SystemExit(f"fetch must-check failed: {must}")
    print("desert-fathers fetch complete")


if __name__ == "__main__":
    main()
