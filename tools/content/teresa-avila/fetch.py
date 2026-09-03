#!/usr/bin/env python3
"""Fetch Stanbrook/Zimmerman Way of Perfection and Interior Castle (CCEL)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
WAY = "https://www.ccel.org/ccel/t/teresa/way/cache/way.txt"
CASTLE = "https://www.ccel.org/ccel/t/teresa/castle2/cache/castle2.txt"


def get(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    get(WAY, RAW / "ccel_way.txt")
    get(CASTLE, RAW / "ccel_castle.txt")


if __name__ == "__main__":
    main()
