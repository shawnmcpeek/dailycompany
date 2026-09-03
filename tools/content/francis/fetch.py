#!/usr/bin/env python3
"""Fetch Robinson 1905/06 Writings and Heywood 1906 Fioretti.

The live sacred-texts.com frontend is a JS shell. The static HTML lives on
archive.sacred-texts.com.
"""

from __future__ import annotations

import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

WRITINGS = "https://archive.sacred-texts.com/chr/wosf"
FIORETTI = "https://archive.sacred-texts.com/chr/lff"


def get(url: str) -> bytes | None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            if resp.status != 200:
                return None
            return resp.read()
    except Exception as exc:
        print(f"  fail {url}: {exc}")
        return None


def main() -> None:
    wdir = RAW / "writings"
    wdir.mkdir(parents=True, exist_ok=True)
    for i in range(27):
        name = f"wosf{i:02d}.htm"
        dest = wdir / name
        data = get(f"{WRITINGS}/{name}")
        if not data:
            print(f"missing {name}")
            continue
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")
        time.sleep(0.08)

    fdir = RAW / "fioretti"
    fdir.mkdir(parents=True, exist_ok=True)
    misses = 0
    for i in range(0, 200):
        name = f"lff{i:03d}.htm"
        data = get(f"{FIORETTI}/{name}")
        if not data:
            misses += 1
            if i > 5 and misses >= 8:
                break
            continue
        misses = 0
        dest = fdir / name
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes)")
        time.sleep(0.08)


if __name__ == "__main__":
    main()
