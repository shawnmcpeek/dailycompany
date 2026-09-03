#!/usr/bin/env python3
"""Cut Faber's True Devotion; unique year if the count supports it."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "Frederick William Faber (Burns & Lambert, 1863)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Company of Mary, the Montfort Missionaries, "
    "the Daughters of Wisdom, any shrine or publisher associated with them."
)
TAGLINE = "It is by Mary that He has to reign in the world."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "montfort",
        "displayName": "Louis de Montfort",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed cycle through Faber's 1863 English of True "
                "Devotion to the Blessed Virgin. Not a 33-day consecration "
                "program."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "montfort_companion",
        "sourceNote": (
            "A Treatise on the True Devotion to the Blessed Virgin, "
            "translated by Frederick William Faber, D.D. (Burns & Lambert, "
            "London, 1863; second edition). Not a modern Montfort translation."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "montfort",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
    )


if __name__ == "__main__":
    main()
