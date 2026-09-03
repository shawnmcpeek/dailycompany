#!/usr/bin/env python3
"""Fetch Pusey Confessions (CCEL text of the 1838 translation)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = "https://www.ccel.org/ccel/a/augustine/confess/cache/confess.txt"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "ccel_pusey.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
