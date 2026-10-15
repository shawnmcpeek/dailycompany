#!/usr/bin/env python3
"""Cut Eales sermons (vol III liturgical + vol IV Cantica); emit On Loving God."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402
from emit_shelves import book, part, write_shelf  # noqa: E402

TRANSLATOR = "Samuel J. Eales (1889–96)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Cistercian Order, any Cistercian abbey, "
    "Cistercian Publications, or any shrine or publisher associated with them."
)
TAGLINE = "Love is sufficient of itself."


def shelf_chapters(src: list[dict]) -> list[dict]:
    out = []
    for c in src:
        text = "\n\n".join(p for p in c["paragraphs"] if p).strip()
        if len(text.split()) < 20:
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
        "id": "bernard",
        "displayName": "Bernard of Clairvaux",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through Samuel J. Eales’s English of the "
                "sermons: the Song of Songs (Life and Works vol. IV) and the "
                "liturgical sermons of vol. III. Overflow sits in the index. "
                "The letters sit on the Works shelf, not on the calendar. "
                "On the New Knighthood is not included."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice", "works"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "bernard_companion",
        "sourceNote": (
            "Life and Works of Saint Bernard, Abbot of Clairvaux, trans. "
            "Samuel J. Eales (John Hodges, 1889–96): vol. III, Sermons for "
            "the Ecclesiastical Year; vol. IV, Sermons on the Song of Songs. "
            "On Loving God, translated by Mrs. Patmore, preface by Coventry "
            "Patmore (1881). Letters from Eales vols I–II on the Works shelf. "
            "Not Cistercian Publications. Not the 1953 Scott James Letters. "
            "De Laude Novae Militiae is not shipped."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "bernard",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
        overflow_appendix=True,
    )
    shelf = json.loads((ROOT / "work" / "shelf.json").read_text(encoding="utf-8"))
    love = shelf["loving-god"]
    letters = shelf["letters"]
    write_shelf(
        REPO / "assets" / "content" / "bernard" / "works.json",
        translator="Mrs. Patmore (1881); Samuel J. Eales (1889–96)",
        label="Works",
        intro=(
            "On Loving God, translated by Mrs. Patmore (1881). Letters from "
            "Eales, Life and Works vols I–II (John Hodges, 1889–96). Not the "
            "daily sermons. Not On the New Knighthood."
        ),
        books=[
            book(
                "loving-god",
                love["title"],
                [
                    part(p["part"], p["title"], shelf_chapters(p["chapters"]))
                    for p in love["parts"]
                    if p["chapters"]
                ],
            ),
            book(
                "letters",
                letters["title"],
                [
                    part(p["part"], p["title"], shelf_chapters(p["chapters"]))
                    for p in letters["parts"]
                    if p["chapters"]
                ],
            ),
        ],
    )


if __name__ == "__main__":
    main()
