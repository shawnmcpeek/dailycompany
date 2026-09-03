#!/usr/bin/env python3
"""Fetch Taylor 1912 Story of a Soul (Gutenberg #16772)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = "https://www.gutenberg.org/cache/epub/16772/pg16772.txt"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = resp.read()
    dest = RAW / "pg16772_taylor.txt"
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
