#!/usr/bin/env python3
"""Fetch O'Conor Autobiography (Gutenberg #24534) and Mullan Exercises (CCEL)."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

SOURCES = (
    (
        "https://www.gutenberg.org/cache/epub/24534/pg24534.txt",
        "pg24534_oconor.txt",
    ),
    (
        "https://www.ccel.org/ccel/i/ignatius/exercises/cache/exercises.txt",
        "ccel_mullan.txt",
    ),
)


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for url, name in SOURCES:
        dest = RAW / name
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=90) as resp:
            data = resp.read()
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")


if __name__ == "__main__":
    main()
