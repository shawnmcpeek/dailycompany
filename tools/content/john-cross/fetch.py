#!/usr/bin/env python3
"""Fetch Lewis 1864 Complete Works (vols 1–2).

Vol. 1: Ascent, Dark Night.
Vol. 2: Canticle, Living Flame, maxims, precautions.

Folkscanomy / Google scan, ABBYY FineReader 11 — same 1864 Lewis edition
as the UofT djvu, without that copy's letter-salad OCR.
"""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URLS = {
    "lewis_v1_djvu.txt": (
        "https://archive.org/download/TheCompleteWorksOfSaintJohnOfTheV1/"
        "TheCompleteWorksOfSaintJohnOfTheV1_djvu.txt"
    ),
    "lewis_v2_djvu.txt": (
        "https://archive.org/download/TheCompleteWorksOfSaintJohnOfTheV2/"
        "TheCompleteWorksOfSaintJohnOfTheV2_djvu.txt"
    ),
}


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for name, url in URLS.items():
        dest = RAW / name
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
