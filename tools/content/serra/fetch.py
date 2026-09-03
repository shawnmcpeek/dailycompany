#!/usr/bin/env python3
"""Fetch PD sources for Serra (Palóu/Williams, Engelhardt, Portolá diary)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

# Palóu, Relación Histórica, trans. C. Scott Williams (1913).
# Engelhardt, Missions and Missionaries of California, vol. 2.
# Portolá diary English in Academy of Pacific Coast History vol. 1 (1909).
SOURCES = {
    "palou_williams_1913.txt": (
        "https://archive.org/download/franciscopalousl00palrich/"
        "franciscopalousl00palrich_djvu.txt"
    ),
    "engelhardt_vol2.txt": (
        "https://archive.org/download/missionsmissiona02enge/"
        "missionsmissiona02enge_djvu.txt"
    ),
    "acad_vol1.txt": (
        "https://archive.org/download/publicationsofac01acad/"
        "publicationsofac01acad_djvu.txt"
    ),
}


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for name, url in SOURCES.items():
        dest = RAW / name
        if dest.exists() and dest.stat().st_size > 50_000:
            print(f"keep {dest} ({dest.stat().st_size:,} bytes)")
            continue
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=180) as resp:
            data = resp.read()
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
