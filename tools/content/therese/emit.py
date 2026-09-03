#!/usr/bin/env python3
"""Cut Taylor Story of a Soul to a unique year."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "Thomas N. Taylor (1912)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Discalced Carmelites, any Carmelite "
    "province or house, the shrine at Lisieux, the Office Central de "
    "Lisieux, ICS Publications, or any shrine or publisher associated "
    "with them."
)
TAGLINE = "My vocation is love."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "therese",
        "displayName": "Thérèse of Lisieux",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through Taylor's 1912 English of the "
                "1898 Pauline Histoire d'une Ame — the historically famous "
                "edited text, not the 1956 manuscript restoration."
            ),
        },
        "anchor": "offering",
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "therese_companion",
        "sourceNote": (
            "Story of a Soul, translated by Thomas N. Taylor (Burns, Oates "
            "& Washbourne, 1912; this electronic text is the 8th impression "
            "of that translation). It is Taylor of the 1898 Pauline edited "
            "Histoire d'une Ame, not the 1956 Manuscrits autobiographiques, "
            "not Clarke ICS, and not Knox. Poems in that Gutenberg file are "
            "Susan L. Emery's and are not shipped."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "therese",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
    )


if __name__ == "__main__":
    main()
