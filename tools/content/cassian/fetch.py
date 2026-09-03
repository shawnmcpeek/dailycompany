#!/usr/bin/env python3
"""Fetch Gibson NPNF II.11 (1894) from CCEL — whole volume; parse keeps Conferences."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = "https://www.ccel.org/ccel/s/schaff/npnf211/cache/npnf211.txt"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "ccel_npnf211.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
