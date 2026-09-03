#!/usr/bin/env python3
"""Fetch Thorold 1907 Dialogue (CCEL text of Kegan Paul)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = "https://www.ccel.org/ccel/c/catherine/dialog/cache/dialog.txt"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "ccel_thorold.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
