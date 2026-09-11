#!/usr/bin/env python3
"""Fetch named PD sources for remaining shelves."""

from __future__ import annotations

import urllib.request
from pathlib import Path

UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"
ROOT = Path(__file__).resolve().parent

SOURCES = {
    ROOT / "desales" / "raw" / "conferences_mackey_djvu.txt": (
        "https://archive.org/download/spiritualconfere00franuoft/"
        "spiritualconfere00franuoft_djvu.txt"
    ),
    ROOT / "liguori" / "raw" / "prep_death_grimm_djvu.txt": (
        "https://archive.org/download/preparationforde0000reve/"
        "preparationforde0000reve_djvu.txt"
    ),
    ROOT / "liguori" / "raw" / "way_salvation_grimm_djvu.txt": (
        "https://archive.org/download/thecompleteascet02liguuoft/"
        "thecompleteascet02liguuoft_djvu.txt"
    ),
    ROOT / "ignatius" / "raw" / "letters_1914_djvu.txt": (
        "https://archive.org/download/LettersAndInstructionsOfStIgnatiusV1/"
        "LettersAndInstructionsOfStIgnatiusV1_djvu.txt"
    ),
    ROOT / "teresa-avila" / "raw" / "ccel_life.txt": (
        "https://www.ccel.org/ccel/t/teresa/life/cache/life.txt"
    ),
    ROOT / "augustine" / "raw" / "ccel_npnf107.txt": (
        "https://www.ccel.org/ccel/s/schaff/npnf107/cache/npnf107.txt"
    ),
    ROOT / "augustine" / "raw" / "ccel_npnf106.txt": (
        "https://www.ccel.org/ccel/s/schaff/npnf106/cache/npnf106.txt"
    ),
    ROOT / "gregory" / "raw" / "moralia_v1_djvu.txt": (
        "https://archive.org/download/moralsonbookofj01greg/"
        "moralsonbookofj01greg_djvu.txt"
    ),
    ROOT / "therese" / "raw" / "pg16772_taylor.txt": (
        "https://www.gutenberg.org/cache/epub/16772/pg16772.txt"
    ),
}


def get(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes) from {url}")


def main() -> None:
    errors = []
    for dest, url in SOURCES.items():
        try:
            get(url, dest)
        except Exception as e:
            errors.append(f"{dest.name}: {e}")
            print(f"FAIL {dest}: {e}")
    if errors:
        raise SystemExit("\n".join(errors))


if __name__ == "__main__":
    main()
