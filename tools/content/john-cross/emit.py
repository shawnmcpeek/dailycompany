#!/usr/bin/env python3
"""Emit John of the Cross sayings as a unique year plus index overflow.

Atomic units — one saying a day, never bundled. Leap year maps 1:1 onto
the first 366; extras sit off the calendar.
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
ASSETS = REPO / "assets" / "content" / "john-cross"

sys.path.insert(0, str(ROOT.parent))
from cycle_cal import map_modulo, map_unique  # noqa: E402

TRANSLATOR = "David Lewis (1864)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Discalced Carmelites, any Carmelite "
    "province or house, ICS Publications, or any shrine or publisher "
    "associated with them."
)
TAGLINE = "There is no progress but in the imitation of Christ."


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    parts = data["parts"]

    entries = []
    source_paras: list[str] = []
    for p in parts:
        for c in p["chapters"]:
            text = "\n\n".join(c["paragraphs"])
            source_paras.extend(c["paragraphs"])
            entries.append({
                "id": len(entries) + 1,
                "part": p["part"],
                "partTitle": p["title"],
                "chapter": c["chapter"],
                "chapterTitle": c["title"],
                "portionInChapter": 1,
                "portionsInChapter": 1,
                "wordCount": words(text),
                "flags": [],
                "textEn": text,
            })

    n = len(entries)
    total_words = sum(e["wordCount"] for e in entries)
    daily_n = n if n <= 366 else 366
    print("=== cadence ===")
    print(f"{n} sayings, {total_words} words "
          f"(~{total_words // n} words/entry). "
          f"{daily_n} daily, {max(0, n - daily_n)} appendix.")
    print(f"leap year: {366 / daily_n:.2f} passes of the daily spine.")

    ids = [e["id"] for e in entries]
    assert ids == list(range(1, n + 1)), "entry ids not contiguous 1..N"
    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(source_paras)
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"
    assert all(e["textEn"].strip() for e in entries), "empty saying"

    if n > 366:
        for e in entries[daily_n:]:
            e["flags"] = ["appendix"]
        by_date_common, by_date_leap = map_unique(daily_n)
    elif n in (365, 366):
        by_date_common, by_date_leap = map_unique(n)
        daily_n = n
    else:
        by_date_common, by_date_leap = map_modulo(n)
        daily_n = n
    assert "02-29" not in by_date_common
    assert len(by_date_common) == 365
    assert len(by_date_leap) == 366
    reachable = {i for ids in by_date_leap.values() for i in ids}
    assert reachable == set(range(1, daily_n + 1)), "daily sayings not covering the year"

    precautions = {
        "version": 1,
        "title": "Precautions",
        "chapters": [
            {
                "chapter": c["chapter"],
                "title": c["title"],
                "textEn": "\n\n".join(c["paragraphs"]),
            }
            for c in parts[0]["chapters"]
        ],
    }

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {
                "entries": daily_n,
                "repeatsPerYear": round(366 / daily_n, 2),
            },
            "wordsTotal": total_words,
            "dailyEntries": daily_n,
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
    (ASSETS / "precautions.json").write_text(
        json.dumps(precautions, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "portal.json").write_text(
        json.dumps({
            "id": "john-cross",
            "displayName": "John of the Cross",
            "tagline": TAGLINE,
            "provenance": "constructed",
            "spine": {
                "type": "cycle",
                "entries": daily_n,
                "repeatsPerYear": 1.0 if daily_n in (365, 366) else round(366 / daily_n, 2),
                "note": (
                    f"{daily_n} sayings through the year, one a day. "
                    + (
                        f"{n - daily_n} closing pieces sit in the index, "
                        "not on the calendar. "
                        if n > daily_n else ""
                    )
                    + "The treatises are not the daily cut."
                ),
            },
            "anchor": None,
            "modules": ["today", "precautions", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "john-cross_companion",
            "sourceNote": (
                "The Complete Works of Saint John of the Cross, trans. David "
                "Lewis, vol. 2 (Longman, Green, Longman, Roberts & Green, "
                "1864): Instructions and Cautions, and Spiritual Maxims. "
                "Not the Kavanaugh–Rodriguez ICS edition. Ascent, Dark Night, "
                "Canticle, and Living Flame are a later shelf."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    rows = []
    for e in entries:
        flag = " class=thin" if e["wordCount"] < 40 else ""
        rows.append(
            f"<tr{flag}><td>{e['id']}</td><td>P{e['part']}</td>"
            f"<td>{e['chapterTitle']}</td><td>{e['wordCount']}</td></tr>"
        )
    (REVIEW / "review.html").write_text(
        "<!doctype html><meta charset=utf-8><title>John of the Cross sayings</title>"
        f"<h1>{n} sayings — one a day, not bundled</h1>"
        f"<p>{total_words} words. {daily_n} through the year"
        + (f"; {n - daily_n} in the index." if n > daily_n else ".")
        + "</p>"
        "<style>tr.thin{background:#f8e8d8}</style>"
        "<table border=1 cellpadding=6><tr><th>#</th><th>Part</th>"
        "<th>Title</th><th>Words</th></tr>"
        + "\n".join(rows)
        + "</table>\n",
        encoding="utf-8",
    )
    print(f"wrote {ASSETS}")


if __name__ == "__main__":
    main()
