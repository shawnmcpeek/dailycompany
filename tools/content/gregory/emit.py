#!/usr/bin/env python3
"""Cut the Pastoral Rule targeting 183 entries (twice a year)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "gregory"

sys.path.insert(0, str(ROOT.parent))
from cycle_cal import map_modulo  # noqa: E402
from cut import cadence_candidates, cut, write_review_html  # noqa: E402

TRANSLATOR = "James Barmby, NPNF II.12 (1895)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by any diocese, papal household, or publisher "
    "associated with Gregory the Great."
)
TAGLINE = "The government of souls is the art of arts."


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    parts = data["parts"]
    total_words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print("=== cadence candidates ===")
    cadence_candidates(total_words)

    exact_target = None
    exact_n = None
    for want in (183, 182, 184, 180, 186):
        for candidate in range(80, 550):
            if len(cut(parts, target_words=candidate)) == want:
                exact_target = candidate
                exact_n = want
                break
        if exact_target is not None:
            break
    target = exact_target if exact_target is not None else round(total_words / 183)
    print(f"\ntarget {target} words/entry (searched for 183, then nearby)")
    if exact_n:
        print(f"matched {exact_n} entries")

    entries = cut(parts, target_words=target)
    n = len(entries)
    print(f"cutter produced {n} entries")
    flagged = [e for e in entries if e["flags"]]
    if flagged:
        print(f"{len(flagged)} entries flagged:")
        for e in flagged[:20]:
            print(f"  #{e['id']} Book {e['part']} Ch.{e['chapter']}: {e['flags']}")

    ids = [e["id"] for e in entries]
    assert ids == list(range(1, n + 1))
    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(
        p for part in parts for c in part["chapters"] for p in c["paragraphs"]
    )
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"

    by_date_common, by_date_leap = map_modulo(n)
    reachable = {i for ids in by_date_leap.values() for i in ids}
    assert reachable == set(range(1, n + 1))

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    total = sum(e["wordCount"] for e in entries)
    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {"entries": n, "repeatsPerYear": round(366 / n, 2)},
            "wordsTotal": total,
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
            "id": "gregory",
            "displayName": "Gregory the Great",
            "tagline": TAGLINE,
            "provenance": "constructed",
            "spine": {
                "type": "cycle",
                "entries": n,
                "repeatsPerYear": round(366 / n, 2),
                "note": (
                    f"{n} readings, twice a year. Thin days over padding. "
                    "Dialogues Book II already ships as Benedict's Life — "
                    "not recut here."
                ),
            },
            "anchor": None,
            "modules": ["today", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "gregory_companion",
            "sourceNote": (
                "The Book of Pastoral Rule, trans. James Barmby, in Nicene "
                "and Post-Nicene Fathers, Second Series, Vol. 12, ed. Philip "
                "Schaff and Henry Wace (Christian Literature Publishing Co., "
                "1895). Dialogues Book II is not duplicated; it already ships "
                "as the Life of Benedict."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_review_html(entries, REVIEW / "review.html", target)
    print(f"wrote {ASSETS} ({n} x {366 / n:.2f})")


if __name__ == "__main__":
    main()
