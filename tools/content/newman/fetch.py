#!/usr/bin/env python3
"""Fetch Newman PPS (two copies of vols I–VI), Gutenberg VII–VIII, shelf texts."""

from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
UA = "DailyCompanyContentPipeline/0.1 (local build; Daddoo Dev)"

# Newman wrote PPS in English. Prefer the 1868 Rivingtons set; a second
# Longmans/Rivingtons scan of the same sermons is the comparison copy.
PPS = [
    (1, "parochialandp01newmuoft"),
    (2, "parochialandp02newmuoft"),
    (3, "parochialplainse03newmuoft"),
    (4, "nparochialplains04newmuoft"),
    (5, "parochialandp5newmuoft"),
    (6, "newparochialplai06newmuoft"),
]
PPS_FALLBACK = {
    3: [
        "parochiaplainse03newmuoft",
        "a676843003newmuoft",
        "parochialandp03newmuoft",
    ],
    4: [
        "a600455804newmuoft",
        "parochialplainse0004newm",
        "a1261873smrn04newmuoft",
    ],
    6: [
        "nparochialplains06newmuoft",
        "a600426806newmuoft",
        "newparochialplai06newmuoft",
    ],
}
PPS_COMPARE = {
    1: ["parochialplainserm01newmuoft", "a600426801newmuoft", "parochialandplai01newmuoft"],
    2: ["parochialplainserm02newmuoft", "a600426802newmuoft", "parochialandplai02newmuoft"],
    3: ["a676843003newmuoft", "parochialandp03newmuoft", "parochiaplainse03newmuoft"],
    4: ["a600455804newmuoft", "parochialplainse0004newm"],
    5: ["parochialandplai05newmuoft", "a600426805newmuoft", "parochialplainserm05newmuoft"],
    6: ["a600426806newmuoft", "nparochialplains06newmuoft"],
}
GUTENBERG = {
    7: "https://www.gutenberg.org/cache/epub/24256/pg24256.txt",
    8: "https://www.gutenberg.org/cache/epub/24284/pg24284.txt",
}
SHELF = {
    "meditations_djvu.txt": (
        "https://archive.org/download/MeditationsAndDevotionsOf/"
        "MeditationsAndDevotionsOf_djvu.txt"
    ),
    "verses_djvu.txt": (
        "https://archive.org/download/variousoccasions00newmuoft/"
        "variousoccasions00newmuoft_djvu.txt"
    ),
}
# Newman’s own English, lifetime editions. Gutenberg first; IA if PG is absent.
TREATISES = {
    "apologia.txt": {
        "must": "Apologia pro vita sua",
        "gutenberg": [],
        "ia": [
            "apologiaprovita00newm",
            "apologiaprovita00newmuoft",
            "a618043900newmuoft",
        ],
    },
    "idea.txt": {
        "must": "Idea of a University",
        "gutenberg": [
            "https://www.gutenberg.org/cache/epub/24526/pg24526.txt",
        ],
        "ia": [
            "ideaofuniversity00newmuoft",
            "ideaofauniversity00newmuoft",
        ],
    },
    "grammar.txt": {
        "must": "Grammar of Assent",
        "gutenberg": [],
        "ia": [
            "essayinaidgramma00newmiala",
            "grammarofassentA24a187000newmuoft",
            "grammarofassentA24i188500newmuoft",
        ],
    },
    "development.txt": {
        "must": "Development of Christian Doctrine",
        "gutenberg": [
            "https://www.gutenberg.org/cache/epub/35110/pg35110.txt",
        ],
        "ia": [
            "essayondevelopme00newmuoft",
            "anessayonthedeve00newmuoft",
        ],
    },
}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        return resp.read()


def ia_djvu_url(identifier: str) -> str | None:
    meta = json.loads(get(f"https://archive.org/metadata/{identifier}").decode())
    files = meta.get("files") or []
    names = [f.get("name") or "" for f in files]
    for name in names:
        if name.endswith("_djvu.txt"):
            return f"https://archive.org/download/{identifier}/{name}"
    return None


def write(dest: Path, data: bytes, src: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    print(f"wrote {dest} ({len(data):,} bytes) from {src}")


def looks_like_text(data: bytes, dest_name: str, *, must: str | None = None) -> bool:
    if len(data) < 20_000:
        return False
    sample = data[:4000].decode("utf-8", errors="replace").lower()
    if dest_name.startswith("pps_") and "not found" in sample:
        return False
    if "<html" in sample and "gutenberg" not in sample:
        return False
    if must:
        text = data[:200_000].decode("utf-8", errors="replace").lower()
        compact = re.sub(r"[^a-z]+", "", text)
        need = re.sub(r"[^a-z]+", "", must.lower())
        if must.lower() not in text and need not in compact:
            print(f"wrong book for {dest_name} (missing {must!r})")
            return False
    return True


def fetch_volume(vol: int, identifier: str, dest: Path, *, must: str | None = None) -> bool:
    try:
        url = ia_djvu_url(identifier)
        if not url:
            print(f"no djvu.txt for {identifier}")
            return False
        data = get(url)
        if not looks_like_text(data, dest.name, must=must):
            print(f"thin/html {identifier}")
            return False
        write(dest, data, url)
        return True
    except Exception as e:
        print(f"FAIL {identifier}: {e}")
        return False


def fetch_url(url: str, dest: Path, *, must: str | None = None) -> bool:
    try:
        data = get(url)
        if not looks_like_text(data, dest.name, must=must):
            print(f"thin/html {url}")
            return False
        write(dest, data, url)
        return True
    except Exception as e:
        print(f"FAIL {url}: {e}")
        return False


def fetch_treatise(dest_name: str, spec: dict) -> bool:
    dest = RAW / dest_name
    must = spec.get("must")
    for url in spec.get("gutenberg") or []:
        if fetch_url(url, dest, must=must):
            return True
    for ident in spec.get("ia") or []:
        if fetch_volume(0, ident, dest, must=must):
            return True
    return False


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []

    for vol, ident in PPS:
        dest = RAW / f"pps_{vol:02d}.txt"
        ok = fetch_volume(vol, ident, dest)
        if not ok:
            for alt in PPS_FALLBACK.get(vol, []):
                print(f"retry vol {vol} as {alt}")
                if fetch_volume(vol, alt, dest):
                    ok = True
                    break
        if not ok:
            errors.append(f"PPS vol {vol}")
        compare_dest = RAW / f"pps_{vol:02d}_b.txt"
        compared = False
        for alt in PPS_COMPARE.get(vol, []):
            if alt == ident:
                continue
            print(f"compare vol {vol} as {alt}")
            if fetch_volume(vol, alt, compare_dest):
                compared = True
                break
        if not compared:
            print(f"no comparison copy for vol {vol}")

    for vol, url in GUTENBERG.items():
        dest = RAW / f"pps_{vol:02d}.txt"
        if not fetch_url(url, dest):
            errors.append(f"Gutenberg vol {vol}")

    for name, url in SHELF.items():
        if not fetch_url(url, RAW / name):
            errors.append(name)

    for name, spec in TREATISES.items():
        if not fetch_treatise(name, spec):
            errors.append(name)

    if errors:
        raise SystemExit("fetch failed:\n" + "\n".join(errors))
    print("newman fetch complete")


if __name__ == "__main__":
    main()
