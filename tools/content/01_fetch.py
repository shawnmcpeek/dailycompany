#!/usr/bin/env python3
"""Pull raw public-domain sources into tools/content/raw/."""

from __future__ import annotations

import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"

SOURCES = {
    # Doyle — date-table source only (US PD). Never ship as display text.
    "doyle.txt": "https://www.gutenberg.org/ebooks/50040.txt.utf-8",
    # Verheyen 1949 reprint (translator d. 1925) — display English.
    "verheyen.txt": "https://ccel.org/ccel/b/benedict/rule/cache/rule.txt",
    # Latin Regula — The Latin Library.
    "latin.html": "https://www.thelatinlibrary.com/benedict.html",
}

UA = "BenedictDailyContentPipeline/0.1 (local build; Daddoo Dev)"


def fetch(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest.name} ({len(data):,} bytes)")


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for name, url in SOURCES.items():
        fetch(url, RAW / name)


if __name__ == "__main__":
    main()
