#!/usr/bin/env python3
"""Emit Brother Lawrence as natural units, modulo through the year.

Each conversation and each letter is one entry. Do not pad to 365.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from cycle_cal import map_modulo  # noqa: E402
from emit_lib import words, write_cycle_assets  # noqa: E402

TRANSLATOR = "Translated from the French (Fleming H. Revell)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Discalced Carmelites, any Carmelite "
    "province or house, or any shrine or publisher associated with them."
)
TAGLINE = "Practice the presence of God."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    parts = data["parts"]
    entries = []
    source_paras: list[str] = []
    for p in parts:
        for c in p["chapters"]:
            text = "\n\n".join(c["paragraphs"])
            source_paras.extend(c["paragraphs"])
            entries.append({
                "id": len(entries) + 1,
                "part": p["part"],
                "partTitle": p["title"],
                "chapter": c["chapter"],
                "chapterTitle": c["title"],
                "portionInChapter": 1,
                "portionsInChapter": 1,
                "wordCount": words(text),
                "flags": [],
                "textEn": text,
            })

    n = len(entries)
    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(source_paras)
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"
    assert [e["id"] for e in entries] == list(range(1, n + 1))

    total = sum(e["wordCount"] for e in entries)
    print(f"natural units: {n} entries, {total} words, modulo through the year")
    by_date_common, by_date_leap = map_modulo(n)
    portal = {
        "id": "lawrence",
        "displayName": "Brother Lawrence",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "entries": n,
            "repeatsPerYear": round(366 / n, 2),
            "note": (
                f"{n} conversations and letters, cycled — the book is short, "
                "so the units repeat rather than being padded out."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "lawrence_companion",
        "sourceNote": (
            "The Practice of the Presence of God: the Best Rule of a Holy "
            "Life, being Conversations and Letters of Nicholas Herman of "
            "Lorraine (Brother Lawrence). Translated from the French. "
            "Fleming H. Revell Company. Project Gutenberg #13871. Anonymous "
            "nineteenth-century English."
        ),
    }
    write_cycle_assets(
        assets=REPO / "assets" / "content" / "lawrence",
        review=ROOT / "review",
        entries=entries,
        by_date_common=by_date_common,
        by_date_leap=by_date_leap,
        translator=TRANSLATOR,
        portal=portal,
        target_words=max(1, round(total / n)),
    )


if __name__ == "__main__":
    main()
