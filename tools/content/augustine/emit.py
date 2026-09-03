#!/usr/bin/env python3
"""Cut Confessions I–X to a unique year; append XI–XIII as Read Through only."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "augustine"

sys.path.insert(0, str(ROOT.parent))
from cycle_cal import map_unique  # noqa: E402
from cut import cadence_candidates, cut, write_review_html  # noqa: E402

TRANSLATOR = "E. B. Pusey (1838)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Saint Augustine, any Augustinian "
    "province or house, or any shrine or publisher associated with them."
)
TAGLINE = "Our heart is restless, until it repose in Thee."


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    appendix_in = json.loads((WORK / "appendix.json").read_text(encoding="utf-8"))
    parts = data["parts"]

    total_words = sum(
        words(" ".join(c["paragraphs"]))
        for p in parts
        for c in p["chapters"]
    )
    print("=== cadence candidates (Books I–X) ===")
    cadence_candidates(total_words)

    exact_target = None
    exact_n = None
    for want in (366, 365):
        for candidate in range(50, 500):
            if len(cut(parts, target_words=candidate)) == want:
                exact_target = candidate
                exact_n = want
                break
        if exact_target is not None:
            break
    target = exact_target if exact_target is not None else round(total_words / 366)
    print(f"\ntarget {target} words/entry (searched for exactly 366, then 365)")
    if exact_n:
        print(f"matched {exact_n} entries")

    daily = cut(parts, target_words=target)
    n_daily = len(daily)
    print(f"cutter produced {n_daily} daily entries")
    if n_daily not in (365, 366):
        print("WARNING: no target yields 365 or 366")

    reconstructed = "\n\n".join(e["textEn"] for e in daily)
    source = "\n\n".join(
        p for part in parts for c in part["chapters"] for p in c["paragraphs"]
    )
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "I–X round-trip failed"

    appendix_entries = []
    for p in appendix_in["parts"]:
        for c in p["chapters"]:
            text = "\n\n".join(c["paragraphs"])
            appendix_entries.append({
                "id": 0,
                "part": p["part"],
                "partTitle": p["title"],
                "chapter": c["chapter"],
                "chapterTitle": c["title"],
                "portionInChapter": 1,
                "portionsInChapter": 1,
                "wordCount": words(text),
                "flags": ["appendix"],
                "textEn": text,
            })
    for i, e in enumerate(daily):
        e["id"] = i + 1
    for i, e in enumerate(appendix_entries):
        e["id"] = n_daily + i + 1
    entries = daily + appendix_entries

    by_date_common, by_date_leap = map_unique(n_daily)
    reachable = {i for ids in by_date_leap.values() for i in ids}
    assert reachable == set(range(1, n_daily + 1)), "daily entries not covering the year"

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {"entries": n_daily, "repeatsPerYear": 1.0},
            "wordsTotal": sum(e["wordCount"] for e in daily),
            "dailyEntries": n_daily,
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
    (ASSETS / "appendix.json").write_text(
        json.dumps({
            "version": 1,
            "title": "Books XI–XIII",
            "note": "Not the daily year. Reachable from the index and Read Through.",
            "chapters": [
                {
                    "part": e["part"],
                    "chapter": e["chapter"],
                    "title": e["chapterTitle"],
                    "textEn": e["textEn"],
                }
                for e in appendix_entries
            ],
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "portal.json").write_text(
        json.dumps({
            "id": "augustine",
            "displayName": "Augustine of Hippo",
            "tagline": TAGLINE,
            "provenance": "constructed",
            "spine": {
                "type": "cycle",
                "entries": n_daily,
                "repeatsPerYear": 1.0,
                "note": (
                    f"Books I–X in {n_daily} readings. Books XI–XIII are an "
                    "appendix, reachable from the index and Read Through, "
                    "not mapped onto the calendar."
                ),
            },
            "anchor": "evening",
            "modules": ["today", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "augustine_companion",
            "sourceNote": (
                "The Confessions of Saint Augustine, trans. E. B. Pusey "
                "(1838). Daily year is Books I–X. Books XI–XIII remain as "
                "an appendix. Not City of God."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_review_html(daily, REVIEW / "review.html", target)
    print(f"wrote {ASSETS} ({n_daily} daily + {len(appendix_entries)} appendix)")


if __name__ == "__main__":
    main()
