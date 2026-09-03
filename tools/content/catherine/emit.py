#!/usr/bin/env python3
"""Cut Thorold's Dialogue to a unique year if the count supports it."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

TRANSLATOR = "Algar Thorold (Kegan Paul, 1907)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Dominican Order, the Order of Preachers, "
    "any Dominican province or house, or any shrine or publisher "
    "associated with them."
)
TAGLINE = "Remain in the cell of self-knowledge."


def main() -> None:
    data = json.loads((ROOT / "work" / "chapters.json").read_text(encoding="utf-8"))
    portal = {
        "id": "catherine",
        "displayName": "Catherine of Siena",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "A constructed year through Algar Thorold's 1907 English of "
                "the Dialogue — four treatises: Divine Providence, Discretion, "
                "Prayer, and Obedience."
            ),
        },
        "anchor": None,
        "modules": ["today", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "catherine_companion",
        "sourceNote": (
            "The Dialogue of Saint Catherine of Siena, translated by Algar "
            "Thorold (Kegan Paul, Trench, Trubner & Co., 1907). CCEL text of "
            "that edition. Not a modern critical translation."
        ),
    }
    emit_cut_cycle(
        parts=data["parts"],
        assets=REPO / "assets" / "content" / "catherine",
        review=ROOT / "review",
        translator=TRANSLATOR,
        portal=portal,
        prefer_unique=True,
    )


if __name__ == "__main__":
    main()
