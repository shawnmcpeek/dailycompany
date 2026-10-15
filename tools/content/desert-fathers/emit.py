#!/usr/bin/env python3
"""Cut Budge's Paradise of the Holy Fathers to a unique year plus appendix."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "E. A. Wallis Budge (Chatto & Windus, 1907)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Coptic Orthodox Church, the monasteries of "
    "Egypt, St Catherine’s Monastery, or any shrine or publisher associated "
    "with them."
)
TAGLINE = "Abba, give me a word."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "desert-fathers",
        "displayName": "Desert Fathers",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through E. A. Wallis Budge’s 1907 English "
                "of The Paradise or Garden of the Holy Fathers, both volumes, "
                "from the Syriac. The whole named edition: the Life of Anthony, "
                "Palladius, the Rule of Pachomius, Jerome’s histories, and the "
                "Sayings. Overflow sits in the index. Not Waddell. Not Ward."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "desert-fathers_companion",
        "sourceNote": (
            "The Paradise or Garden of the Holy Fathers, translated by "
            "E. A. Wallis Budge from the Syriac (Chatto & Windus, 1907), "
            "both volumes. Internet Archive paradiseorgarden01anan and "
            "paradiseorgarden02anan. The whole named edition. Not Helen "
            "Waddell (1936). Not Benedicta Ward (1975)."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "desert-fathers",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
        overflow_appendix=True,
    )


if __name__ == "__main__":
    main()
