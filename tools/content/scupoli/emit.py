#!/usr/bin/env python3
"""Cut the 1875 Rivingtons Spiritual Combat; unique year if the count supports it."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "Anonymous (Rivingtons, 1875)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Theatines, any shrine, or any publisher of "
    "the Spiritual Combat."
)
TAGLINE = "Distrust yourself, and trust in God."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "scupoli",
        "displayName": "Lorenzo Scupoli",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed cycle through the anonymous 1875 Rivingtons "
                "English of The Spiritual Combat (Library of Spiritual Works "
                "for English Catholics)."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "scupoli_companion",
        "sourceNote": (
            "The Spiritual Combat, together with the Supplement, "
            "translated anonymously (Rivingtons, London, Oxford, "
            "and Cambridge, MDCCCLXXV). A New Translation in the "
            "Library of Spiritual Works for English Catholics — the "
            "same series as the 1876 Devout Life. The Path of Paradise "
            "in this scan is not clean enough to ship. Not a modern "
            "edition."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "scupoli",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
    )


if __name__ == "__main__":
    main()
