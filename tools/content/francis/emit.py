#!/usr/bin/env python3
"""Emit Francis writings as a repeating cycle, plus free Admonitions,
Fioretti stories, and the Canticle.

Natural units, cycled — do not pad to 365. Leap year maps 1:1 onto
366 days via modulo; common years skip Feb 29.
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
ASSETS = REPO / "assets" / "content" / "francis"

TRANSLATOR = "Paschal Robinson, OFM (Dolphin Press, 1905)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Friars Minor, the Capuchins, the "
    "Conventuals, any Franciscan province or house, or any shrine or "
    "publisher associated with them."
)


def mmdd(month: int, day: int) -> str:
    return f"{month:02d}-{day:02d}"


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def main() -> None:
    data = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    stories_in = json.loads((WORK / "stories.json").read_text(encoding="utf-8"))
    canticle_in = json.loads((WORK / "canticle.json").read_text(encoding="utf-8"))
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
    print("=== cadence ===")
    print(f"{n} natural units, {total_words} words "
          f"(~{total_words // n} words/entry). Repeat, do not pad.")
    print(f"leap year: {366 / n:.2f} passes; common year: {365 / n:.2f}")

    ids = [e["id"] for e in entries]
    assert ids == list(range(1, n + 1)), "entry ids not contiguous 1..N"

    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(source_paras)
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), "round-trip failed"
    office = [e for e in entries if e["part"] == 7]
    assert office, "Office of the Passion missing"
    assert all(";" not in e["chapterTitle"] for e in office), "mashed Office titles"
    assert all("as above" not in e["textEn"].lower() for e in entries), "as-above stubs"

    def map_year(leap: bool) -> dict[str, list[int]]:
        year = 2024 if leap else 2025
        out: dict[str, list[int]] = {}
        ordinal = 0
        for month in range(1, 13):
            dim = calendar.monthrange(year, month)[1]
            for day in range(1, dim + 1):
                ordinal += 1
                out[mmdd(month, day)] = [((ordinal - 1) % n) + 1]
        return out

    by_date_common = map_year(False)
    by_date_leap = map_year(True)

    assert "02-29" not in by_date_common
    assert by_date_leap["02-29"] == [((31 + 29 - 1) % n) + 1]
    assert by_date_common["01-01"] == [1]
    assert by_date_leap["01-01"] == [1]
    # Day 366 of a leap year is the last slot of the modulo.
    assert by_date_leap["12-31"] == [((366 - 1) % n) + 1]
    assert by_date_common["12-31"] == [((365 - 1) % n) + 1]
    assert all(len(v) == 1 for v in by_date_common.values())
    assert all(len(v) == 1 for v in by_date_leap.values())
    assert len(by_date_common) == 365
    assert len(by_date_leap) == 366
    reachable = {i for ids in by_date_leap.values() for i in ids}
    assert reachable == set(range(1, n + 1)), "some entry unreachable in leap year"
    print(f"coverage: every calendar day has one writing; the {n} cycle repeats")

    admon_part = next(p for p in parts if p["part"] == 1)
    admonitions = {
        "version": 1,
        "title": "Words of Admonition",
        "chapters": [
            {
                "chapter": c["chapter"],
                "title": c["title"],
                "textEn": "\n\n".join(c["paragraphs"]),
            }
            for c in admon_part["chapters"]
        ],
    }
    assert [c["chapter"] for c in admonitions["chapters"]] == list(range(1, 29))

    stories = {
        "version": 1,
        "translator": "W. Heywood (Methuen, 1906)",
        "label": "Stories told about him",
        "chapters": [
            {
                "chapter": s["chapter"],
                "title": s["title"],
                "textEn": "\n\n".join(s["paragraphs"]),
            }
            for s in stories_in["stories"]
        ],
    }
    canticle = {
        "version": 1,
        "title": canticle_in["title"],
        "textEn": "\n\n".join(canticle_in["paragraphs"]),
    }

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    (ASSETS / "entries.json").write_text(
        json.dumps({
            "version": 1,
            "translator": TRANSLATOR,
            "cadence": {
                "entries": n,
                "repeatsPerYear": round(366 / n, 2),
            },
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
    (ASSETS / "admonitions.json").write_text(
        json.dumps(admonitions, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "stories.json").write_text(
        json.dumps(stories, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "canticle.json").write_text(
        json.dumps(canticle, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "portal.json").write_text(
        json.dumps({
            "id": "francis",
            "displayName": "Francis of Assisi",
            "tagline": "Most high, omnipotent, good Lord.",
            "provenance": "constructed",
            "spine": {
                "type": "cycle",
                "entries": n,
                "repeatsPerYear": round(366 / n, 2),
                "note": (
                    f"{n} authentic writings, cycled — about four times a year. "
                    "The Fioretti are a second shelf of stories told about him, "
                    "never mixed into the daily writings."
                ),
            },
            "anchor": "canticle",
            "modules": ["today", "admonitions", "stories", "practice"],
            "disclaimer": DISCLAIMER,
            "unlockSku": "francis_companion",
            "sourceNote": (
                "The Writings of St. Francis of Assisi, trans. Paschal Robinson, "
                "OFM (The Dolphin Press, Philadelphia, 1905). Robinson died 1948; "
                "the 1905 printing is public domain in the United States. "
                "Fioretti: The Little Flowers of St. Francis, trans. W. Heywood "
                "(Methuen, London, 1906), labeled as stories told about him."
            ),
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    rows = []
    for e in entries:
        flag = " class=thin" if e["wordCount"] < 80 else ""
        rows.append(
            f"<tr{flag}><td>{e['id']}</td><td>P{e['part']}</td>"
            f"<td>{e['chapterTitle']}</td><td>{e['wordCount']}</td></tr>"
        )
    (REVIEW / "review.html").write_text(
        "<!doctype html><meta charset=utf-8><title>Francis writings</title>"
        f"<h1>{n} writings — repeat, not a padded year</h1>"
        f"<p>{total_words} words. {366 / n:.2f} passes in a leap year. "
        f"{len(stories['chapters'])} Fioretti stories on the second shelf.</p>"
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
