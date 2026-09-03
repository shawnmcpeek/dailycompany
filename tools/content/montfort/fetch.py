#!/usr/bin/env python3
"""Fetch Faber 1863 True Devotion (Burns & Lambert, second edition).

The Google scan of the same 1863 printing is letter-salad in places and
repeats middle pages. This Internet Archive copy is that edition with
cleaner OCR.
"""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
URL = (
    "https://archive.org/download/TreatiseTrueDevotionBlessedVirgin/"
    "TreatiseTrueDevotionBlessedVirgin_djvu.txt"
)


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "ia_faber_1863.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
