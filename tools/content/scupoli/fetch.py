#!/usr/bin/env python3
"""Fetch the anonymous Rivingtons 1875 Spiritual Combat (MDCCCLXXV)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
# Same 1875 Rivingtons "Library of Spiritual Works for English Catholics"
# printing as the copy already in raw/.
URL = (
    "https://archive.org/download/spiritualcombat00unkngoog/"
    "spiritualcombat00unkngoog_djvu.txt"
)


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    dest = RAW / "ia_rivingtons_1875.txt"
    req = urllib.request.Request(URL, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
