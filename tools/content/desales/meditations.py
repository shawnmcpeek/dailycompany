#!/usr/bin/env python3
"""Extract Part I's ten meditations (chapters 9-18) as standalone,
uncut readings — spec §8.4: "self-contained... the 'begin here'".

Unlike the daily cycle, these are shown whole, one screen per meditation,
not portioned by the cutter — Part I Ch.9 ("FIRST MEDITATION") through
Ch.18 ("TENTH MEDITATION"). Each chapter's first paragraph is a short
topic line (e.g. "Of Creation.") which becomes the meditation's subtitle;
the rest is the body.

Reads:  tools/content/desales/work/chapters.json
Writes: assets/content/desales/meditations.json
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORK = ROOT / "work"
ASSETS = ROOT.parent.parent.parent / "assets" / "content" / "desales"

ORDINALS = [
    "First", "Second", "Third", "Fourth", "Fifth",
    "Sixth", "Seventh", "Eighth", "Ninth", "Tenth",
]


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    part1 = data["parts"][0]
    assert part1["part"] == 1

    meditations = []
    for c in part1["chapters"]:
        if not 9 <= c["chapter"] <= 18:
            continue
        order = c["chapter"] - 8  # 1..10
        topic = c["paragraphs"][0].rstrip(".")
        body = "\n\n".join(c["paragraphs"][1:])
        meditations.append(
            {
                "order": order,
                "title": f"{ORDINALS[order - 1]} Meditation",
                "topic": topic,
                "textEn": body,
            }
        )

    assert len(meditations) == 10, f"expected 10, got {len(meditations)}"
    assert [m["order"] for m in meditations] == list(range(1, 11))

    ASSETS.mkdir(parents=True, exist_ok=True)
    out = ASSETS / "meditations.json"
    out.write_text(
        json.dumps({"version": 1, "meditations": meditations}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")
    for m in meditations:
        print(f"  {m['order']:2d}. {m['title']} — {m['topic']} ({len(m['textEn'].split())}w)")


if __name__ == "__main__":
    main()
