#!/usr/bin/env python3
"""Fetch Lewis 1864 Complete Works vol. 2 (maxims and precautions live here).

Folkscanomy / Google scan, ABBYY FineReader 11 — same 1864 Lewis edition
as the UofT djvu, without that copy's letter-salad OCR.
"""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = (
    "https://archive.org/download/TheCompleteWorksOfSaintJohnOfTheV2/"
    "TheCompleteWorksOfSaintJohnOfTheV2_djvu.txt"
)


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "lewis_v2_djvu.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
