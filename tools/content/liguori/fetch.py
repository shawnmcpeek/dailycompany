#!/usr/bin/env python3
"""Fetch Grimm's Visits (clean HTML witness of the 1887 Centenary text).

The archive.org Benziger 1887 epub (alphonsusworks06alfouoft) is the
edition of record, but its OCR is unusable as a reading text. These
pages are the same translation — Victorian Grimm diction, confirmed
against the 1887 first Visit — without the line-wrap splits.

Source: catholictradition.org/Eucharist (hosted extract of The Holy
Eucharist). Edition credit stays Grimm / Benziger 1887, not the 1934
reprint imprimatur on the host page.
"""

from __future__ import annotations

import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"

BASE = "https://www.catholictradition.org/Eucharist"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"


def fetch(name: str) -> bytes:
    url = f"{BASE}/{name}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    names = ["blessed-sacrament.htm"]
    names += [f"visit{n}.htm" for n in range(1, 32)]
    names += [f"virgin{n}.htm" for n in range(1, 32)]
    for i, name in enumerate(names):
        dest = RAW / name
        data = fetch(name)
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")
        if i + 1 < len(names):
            time.sleep(0.15)


if __name__ == "__main__":
    main()
