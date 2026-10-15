#!/usr/bin/env python3
"""Cut Newman PPS to a unique year plus appendix; emit Meditations and Verses."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402
from emit_shelves import book, part, write_shelf  # noqa: E402

TRANSLATOR = "John Henry Newman (Rivingtons / Longmans)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Birmingham Oratory, the Congregation of the "
    "Oratory, any Newman shrine, or any publisher associated with them."
)
TAGLINE = "Heart speaks to heart."


def shelf_chapters(src: list[dict]) -> list[dict]:
    out = []
    for c in src:
        text = "\n\n".join(p for p in c["paragraphs"] if p).strip()
        if len(text.split()) < 12:
            continue
        out.append({
            "chapter": len(out) + 1,
            "title": c["title"],
            "textEn": text,
        })
    return out


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "newman",
        "displayName": "John Henry Newman",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through Newman’s Parochial and Plain "
                "Sermons, eight volumes, 191 sermons (Rivingtons 1868 and "
                "Longmans reprints; vols VII–VIII from Project Gutenberg). "
                "Overflow sits in the index. The Apologia, the Idea of a "
                "University, the Grammar of Assent, and the Essay on "
                "Development sit on the Works shelf, not on the calendar."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice", "works"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "newman_companion",
        "sourceNote": (
            "Parochial and Plain Sermons, eight volumes, 191 sermons, "
            "Newman’s English (Rivingtons 1868; Longmans reprints of the "
            "same sermons; Gutenberg #24256 and #24284 for vols VII–VIII). "
            "Meditations and Devotions, ed. William P. Neville (Longmans, "
            "1893). Verses on Various Occasions (Burns, Oates, 1868), "
            "including The Pillar of the Cloud (Lead, Kindly Light). "
            "Apologia pro Vita Sua; The Idea of a University; An Essay in "
            "Aid of a Grammar of Assent; An Essay on the Development of "
            "Christian Doctrine — Newman’s English, on the Works shelf. "
            "Not newmanreader.org apparatus."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "newman",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
        overflow_appendix=True,
    )
    shelf = json.loads((ROOT / "work" / "shelf.json").read_text(encoding="utf-8"))

    def as_book(item: dict) -> dict:
        return book(
            item["id"],
            item["title"],
            [
                part(p["part"], p["title"], shelf_chapters(p["chapters"]))
                for p in item["parts"]
                if p["chapters"]
            ],
        )

    order = [
        "meditations",
        "verses",
        "apologia",
        "idea",
        "grammar",
        "development",
    ]
    write_shelf(
        REPO / "assets" / "content" / "newman" / "works.json",
        translator="Newman; William P. Neville, ed. (1893)",
        label="Works",
        intro=(
            "Meditations and Devotions (Longmans, 1893); Verses on Various "
            "Occasions (Burns, Oates, 1868), including Lead, Kindly Light; "
            "Apologia pro Vita Sua; The Idea of a University; An Essay in "
            "Aid of a Grammar of Assent; An Essay on the Development of "
            "Christian Doctrine. Newman’s English. Not the daily sermons."
        ),
        books=[as_book(shelf[key]) for key in order],
    )


if __name__ == "__main__":
    main()
