#!/usr/bin/env python3
"""Fetch Barmby Pastoral Rule from New Advent (NPNF II.12, 1895)."""

from __future__ import annotations

import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "newadvent"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
BASE = "https://www.newadvent.org/fathers"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for book in (1, 2, 3, 4):
        name = f"3601{book}.htm"
        dest = RAW / name
        url = f"{BASE}/{name}"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")
        time.sleep(0.15)


if __name__ == "__main__":
    main()
