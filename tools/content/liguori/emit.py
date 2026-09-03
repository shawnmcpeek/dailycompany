#!/usr/bin/env python3
"""Emit the 31 Visits as app assets. No cutter — one Visit is one entry.

Calendar is day-of-month. Short months omit Visits 29–31; they are never
merged onto the last day of a shorter month. Leap-day is Visit 29.
"""

from __future__ import annotations

import calendar
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "liguori"

TRANSLATOR = "Eugene Grimm, CSsR (Centenary Edition, Benziger, 1887)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Congregation of the Most Holy Redeemer, "
    "Liguori Publications, any Redemptorist province or house, or any "
    "shrine or publisher associated with them."
)


def mmdd(month: int, day: int) -> str:
    return f"{month:02d}-{day:02d}"


def month_map(leap: bool) -> dict[str, list[int]]:
    out: dict[str, list[int]] = {}
    for month in range(1, 13):
        dim = calendar.monthrange(2024 if leap else 2025, month)[1]
        for day in range(1, dim + 1):
            out[mmdd(month, day)] = [day]
    return out


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    manner = json.loads((WORK / "manner.json").read_text(encoding="utf-8"))
    chapters = data["parts"][0]["chapters"]
    assert [c["chapter"] for c in chapters] == list(range(1, 32))

    entries = []
    total_words = 0
    for c in chapters:
        text = "\n\n".join(c["paragraphs"])
        words = len(re.findall(r"\S+", text))
        total_words += words
        entries.append({
            "id": c["chapter"],
            "part": 1,
            "partTitle": "Visits to the Blessed Sacrament",
            "chapter": c["chapter"],
            "chapterTitle": c["title"],
            "portionInChapter": 1,
            "portionsInChapter": 1,
            "wordCount": words,
            "flags": [],
            "textEn": text,
        })

    print("=== cadence ===")
    print(f"{len(entries)} atomic visits, {total_words} words "
          f"(~{total_words // 31} words/visit). Locked at 31 × 12.")

    ids = [e["id"] for e in entries]
    assert ids == list(range(1, 32)), "entry ids not contiguous 1..31"

    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(
        p for c in chapters for p in c["paragraphs"]
    )
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"

    by_date_common = month_map(False)
    by_date_leap = month_map(True)

    assert by_date_common["02-28"] == [28]
    assert "02-29" not in by_date_common
    assert by_date_leap["02-28"] == [28]
    assert by_date_leap["02-29"] == [29]
    assert by_date_common["04-30"] == [30]
    assert by_date_common["01-31"] == [31]
    # Short months must not stack leftover visits.
    assert all(len(v) == 1 for v in by_date_common.values())
    assert all(len(v) == 1 for v in by_date_leap.values())

    missing_common = {
        mmdd(m, d)
        for m in range(1, 13)
        for d in range(1, calendar.monthrange(2025, m)[1] + 1)
    } - set(by_date_common)
    missing_leap = {
        mmdd(m, d)
        for m in range(1, 13)
        for d in range(1, calendar.monthrange(2024, m)[1] + 1)
    } - set(by_date_leap)
    assert not missing_common, missing_common
    assert not missing_leap, missing_leap
    reachable_common = {i for ids in by_date_common.values() for i in ids}
    reachable_leap = {i for ids in by_date_leap.values() for i in ids}
    assert reachable_common == set(range(1, 32))
    assert reachable_leap == set(range(1, 32))
    print("coverage: every calendar day has exactly one Visit; "
          "29–31 are omitted on short months, never merged")

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {"entries": 31, "repeatsPerYear": 12},
            "wordsTotal": total_words,
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
    (ASSETS / "manner.json").write_text(
        json.dumps({"version": 1, **manner}, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    (ASSETS / "portal.json").write_text(
        json.dumps({
            "id": "liguori",
            "displayName": "Alphonsus Liguori",
            "tagline": "My Jesus, I will love Thee only.",
            "provenance": "partlyTraditional",
            "spine": {
                "type": "cycle",
                "entries": 31,
                "repeatsPerYear": 12,
                "note": (
                    "31 × 12 — day of the month is the Visit number. "
                    "Short months omit Visits 29–31; they are never merged."
                ),
            },
            "anchor": "visit",
            "modules": ["today", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "liguori_companion",
            "sourceNote": (
                "Visits to the Blessed Sacrament and to the Blessed Virgin, "
                "Eugene Grimm, CSsR, Centenary Edition (Benziger Brothers, "
                "New York, 1887), from The Holy Eucharist, Volume VI of the "
                "Complete Ascetical Works. Confirmed against archive.org "
                "alphonsusworks06alfouoft. Not a Liguori Publications edition. "
                "1887 — public domain."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    rows = []
    for e in entries:
        rows.append(
            f"<tr><td>{e['id']}</td><td>{e['chapterTitle']}</td>"
            f"<td>{e['wordCount']}</td></tr>"
        )
    (REVIEW / "review.html").write_text(
        "<!doctype html><meta charset=utf-8><title>Liguori visits</title>"
        "<h1>31 Visits — no cutter</h1>"
        f"<p>{total_words} words. Day-of-month calendar. "
        "Short months omit 29–31.</p>"
        "<table border=1 cellpadding=6><tr><th>#</th><th>Visit</th>"
        "<th>Words</th></tr>"
        + "\n".join(rows)
        + "</table>\n",
        encoding="utf-8",
    )
    print(f"wrote {ASSETS}")


if __name__ == "__main__":
    main()
