#!/usr/bin/env python3
"""Run the full content pipeline: parse → align → emit."""

from __future__ import annotations

import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def run(name: str) -> None:
    print(f"\n=== {name} ===")
    runpy.run_path(str(ROOT / name), run_name="__main__")


def main() -> None:
    # 01_fetch is optional if raw/ already populated
    raw = ROOT / "raw"
    needed = ["doyle.txt", "verheyen.txt", "latin.html"]
    if not all((raw / n).exists() for n in needed):
        run("01_fetch.py")
    run("02_parse_dates.py")
    run("03_align.py")
    run("04_emit.py")
    print("\nPipeline complete.")


if __name__ == "__main__":
    main()
