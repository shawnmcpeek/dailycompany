#!/usr/bin/env python3
"""Fetch the Benham Imitation of Christ from Project Gutenberg #1653."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"

URL = "https://www.gutenberg.org/cache/epub/1653/pg1653.txt"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "pg1653_benham.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
