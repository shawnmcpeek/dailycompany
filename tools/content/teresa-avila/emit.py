#!/usr/bin/env python3
"""Cut Way of Perfection + Interior Castle to a unique year.

Mansions are parts, so the cutter never splits a dwelling across an entry.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "teresa-avila"

sys.path.insert(0, str(ROOT.parent))
from cycle_cal import map_unique  # noqa: E402
from cut import cadence_candidates, cut, write_review_html  # noqa: E402

TRANSLATOR = "Benedictines of Stanbrook / Benedict Zimmerman (1911–12)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Discalced Carmelites, any Carmelite "
    "province or house, ICS Publications, or any shrine or publisher "
    "associated with them."
)
TAGLINE = "Let nothing disturb thee."


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    parts = data["parts"]
    total_words = sum(
        words(" ".join(c["paragraphs"]))
        for p in parts
        for c in p["chapters"]
    )
    print("=== cadence candidates ===")
    cadence_candidates(total_words)

    exact_target = None
    exact_n = None
    for want in (366, 365):
        for candidate in range(50, 500):
            produced = cut(parts, target_words=candidate)
            if len(produced) == want:
                exact_target = candidate
                exact_n = want
                break
        if exact_target is not None:
            break
    target = exact_target if exact_target is not None else round(total_words / 366)
    print(f"\ntarget {target} words/entry")
    if exact_n:
        print(f"matched {exact_n} entries")

    entries = cut(parts, target_words=target)
    n = len(entries)
    print(f"cutter produced {n} entries")
    if n not in (365, 366):
        print("WARNING: no target yields 365 or 366")

    stub = re.compile(r"^Chapter\s+\d+$", re.I)
    for e in entries:
        if stub.match(e["chapterTitle"].strip()):
            sent = re.split(r"(?<=[.?!])\s", e["textEn"].strip(), maxsplit=1)[0]
            sent = sent.strip().rstrip(".")
            if 12 <= len(sent) <= 140:
                e["chapterTitle"] = sent
            elif sent:
                clip = sent[:72].rsplit(" ", 1)[0]
                e["chapterTitle"] = clip if clip else e["chapterTitle"]

    # Never split a mansion: every entry's part is a single dwelling.
    for e in entries:
        assert "spansParts" not in e
    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(
        p for part in parts for c in part["chapters"] for p in c["paragraphs"]
    )
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"

    by_date_common, by_date_leap = map_unique(n)
    reachable = {i for ids in by_date_leap.values() for i in ids}
    assert reachable == set(range(1, n + 1))

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {"entries": n, "repeatsPerYear": 1.0},
            "wordsTotal": sum(e["wordCount"] for e in entries),
            "entries": entries,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "calendar.json").write_text(
        json.dumps({
            "version": 1,
            "byDateCommon": by_date_common,
            "byDateLeap": by_date_leap,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "portal.json").write_text(
        json.dumps({
            "id": "teresa-avila",
            "displayName": "Teresa of Avila",
            "tagline": TAGLINE,
            "provenance": "constructed",
            "spine": {
                "type": "cycle",
                "entries": n,
                "repeatsPerYear": 1.0,
                "note": (
                    f"{n} readings of the Way of Perfection and the Interior "
                    "Castle. A dwelling is never split across a day's entry. "
                    "The seven mansions drive the accent."
                ),
            },
            "anchor": "recollection",
            "modules": ["today", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "teresa-avila_companion",
            "sourceNote": (
                "The Way of Perfection and The Interior Castle, translated "
                "from the autograph by the Benedictines of Stanbrook, "
                "revised with notes by Benedict Zimmerman (Thomas Baker, "
                "1911–12; CCEL text of the 1921 Baker impression of the "
                "same translation). Not Peers. Not ICS Kavanaugh–Rodriguez."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_review_html(entries, REVIEW / "review.html", target)
    print(f"wrote {ASSETS}")


if __name__ == "__main__":
    main()
