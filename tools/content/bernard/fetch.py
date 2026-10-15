#!/usr/bin/env python3
"""Fetch Eales Life and Works vols III–IV and Patmore On Loving God."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

IA = {
    "eales_vol01.txt": "lifeworksofsaint01bern",
    "eales_vol02.txt": "lifeworksofsaint02bern",
    "eales_vol03.txt": "lifeworksofsaint03bern",
    "eales_vol04.txt": "LifeWorksOfSBernardClairvauxV4",
    "patmore_loving_god.txt": "OnTheLoveOfGod",
}
FALLBACK = {
    "eales_vol01.txt": [
        "LifeWorksOfSBernardClairvauxV1",
        "saintbernardlife00bernuoft",
    ],
    "eales_vol02.txt": [
        "LifeWorksOfSBernardClairvauxV2",
        "saintbernardlife02bernuoft",
    ],
    "eales_vol03.txt": ["lifeworksofsaint03bern", "lifeandworksofsaint03bern"],
    "eales_vol04.txt": [
        "LifeWorksOfSBernardClairvauxV4",
        "lifeworksofsaint04bern",
        "cantica86sermons00bern",
    ],
}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        return resp.read()


def ia_djvu_url(identifier: str) -> str | None:
    meta = json.loads(get(f"https://archive.org/metadata/{identifier}").decode())
    files = meta.get("files") or []
    for f in files:
        name = f.get("name") or ""
        if name.endswith("_djvu.txt"):
            return f"https://archive.org/download/{identifier}/{name}"
    return None


def fetch_id(identifier: str, dest: Path) -> bool:
    try:
        url = ia_djvu_url(identifier)
        if not url:
            print(f"no djvu.txt for {identifier}")
            return False
        data = get(url)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"wrote {dest} ({len(data):,} bytes) from {url}")
        return dest.stat().st_size > 20_000
    except Exception as e:
        print(f"FAIL {identifier}: {e}")
        return False


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    for dest_name, ident in IA.items():
        dest = RAW / dest_name
        ok = fetch_id(ident, dest)
        if not ok:
            for alt in FALLBACK.get(dest_name, []):
                if alt == ident:
                    continue
                print(f"retry {dest_name} as {alt}")
                if fetch_id(alt, dest):
                    ok = True
                    break
        if not ok:
            errors.append(dest_name)
    if errors:
        raise SystemExit("fetch failed: " + ", ".join(errors))
    print("bernard fetch complete")


if __name__ == "__main__":
    main()
