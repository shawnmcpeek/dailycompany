#!/usr/bin/env python3
"""Cut Gibson's Conferences to a unique year if the count supports it."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "Edgar C. S. Gibson, NPNF II.11 (1894)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by any diocese or publisher. Cassian predates the "
    "later religious orders; this app makes no imprimatur claim."
)
TAGLINE = "Purity of heart is the goal."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "cassian",
        "displayName": "John Cassian",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through Edgar C. S. Gibson's 1894 English "
                "of the Conferences (NPNF II.11). The Institutes and the "
                "work against Nestorius are not included. Conferences Gibson "
                "left untranslated are omitted."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "cassian_companion",
        "sourceNote": (
            "The Conferences of John Cassian, translated by Edgar C. S. "
            "Gibson, in Nicene and Post-Nicene Fathers, Second Series, "
            "Vol. 11, ed. Philip Schaff and Henry Wace (Christian Literature "
            "Publishing Co., 1894). Conferences only — not the Institutes, "
            "not On the Incarnation against Nestorius."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "cassian",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
    )


if __name__ == "__main__":
    main()
