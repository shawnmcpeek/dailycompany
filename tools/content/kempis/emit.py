#!/usr/bin/env python3
"""Cut the parsed Imitation into 366 daily entries and emit app assets.

Reads:  tools/content/kempis/work/chapters.json  (from parse.py)
Writes: assets/content/kempis/entries.json
        assets/content/kempis/calendar.json
        assets/content/kempis/admonitions.json
        assets/content/kempis/portal.json
        tools/content/kempis/review/review.html
"""

from __future__ import annotations

import datetime
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "kempis"

sys.path.insert(0, str(ROOT.parent))
from cut import cadence_candidates, cut, write_review_html  # noqa: E402

TRANSLATOR = "Rev. William Benham (1886)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Canons Regular of St. Augustine, the "
    "Congregation of Windesheim, the Brothers of the Common Life, any "
    "house associated with them, or any shrine or publisher of the Imitation."
)


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

    # Product choice: 366 x 1, unique every calendar day, thin days over a
    # repeat. Search for the target that yields exactly 366, then 365.
    exact_target = None
    exact_n = None
    for want in (366, 365):
        for candidate in range(50, 400):
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

    entries = cut(parts, target_words=target)
    print(f"cutter produced {len(entries)} entries")
    if len(entries) not in (365, 366):
        print("WARNING: no target in range yields exactly 365 or 366; using closest")

    flagged = [e for e in entries if e["flags"]]
    if flagged:
        print(f"{len(flagged)} entries flagged for review:")
        for e in flagged:
            print(f"  #{e['id']} Book {e['part']} Ch.{e['chapter']}: {e['flags']}")

    ids = [e["id"] for e in entries]
    assert ids == list(range(1, len(entries) + 1)), "entry ids not contiguous 1..N"

    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(
        p for part in parts for c in part["chapters"] for p in c["paragraphs"]
    )
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    assert norm(reconstructed) == norm(source), (
        "round-trip failed: cut entries do not reconstruct the source text exactly"
    )
    print("round-trip check: OK (entries reconstruct source exactly, ws-normalized)")

    n = len(entries)

    def mmdd(year: int, ordinal: int) -> str:
        date = datetime.date(year, 1, 1) + datetime.timedelta(days=ordinal - 1)
        return f"{date.month:02d}-{date.day:02d}"

    if n == 366:
        by_date_leap = {mmdd(2024, i + 1): [e["id"]] for i, e in enumerate(entries)}
        by_date_common = {
            mmdd(2025, i + 1): [e["id"]] for i, e in enumerate(entries[:-2])
        }
        by_date_common["12-31"] = [entries[-2]["id"], entries[-1]["id"]]
    elif n == 365:
        by_date_common = {mmdd(2025, i + 1): [e["id"]] for i, e in enumerate(entries)}
        by_date_leap = dict(by_date_common)
        by_date_leap["02-29"] = by_date_common["02-28"]
    else:
        raise SystemExit(
            f"cutter produced {n} entries; date-mapping only handles 365 or 366"
        )

    missing_common = {mmdd(2025, d) for d in range(1, 366)} - set(by_date_common)
    missing_leap = {mmdd(2024, d) for d in range(1, 367)} - set(by_date_leap)
    assert not missing_common, f"common-year days with no entry: {sorted(missing_common)}"
    assert not missing_leap, f"leap-year days with no entry: {sorted(missing_leap)}"
    reachable_common = {i for ids in by_date_common.values() for i in ids}
    reachable_leap = {i for ids in by_date_leap.values() for i in ids}
    assert reachable_common | reachable_leap == set(range(1, n + 1)), (
        "some entry is unreachable in both calendar types"
    )
    print(f"coverage check: OK (every day covered in both year types, {n} entries)")

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    book_i = next(p for p in parts if p["part"] == 1)
    admonitions = {
        "version": 1,
        "book": 1,
        "title": book_i["title"],
        "chapters": [
            {
                "chapter": c["chapter"],
                "title": c["title"],
                "textEn": "\n\n".join(c["paragraphs"]),
            }
            for c in book_i["chapters"]
        ],
    }
    admonitions_path = ASSETS / "admonitions.json"
    admonitions_path.write_text(
        json.dumps(admonitions, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {admonitions_path}")

    entries_out = {
        "version": 1,
        "translator": TRANSLATOR,
        "cadence": {"entries": n, "repeatsPerYear": 1.0},
        "wordsTotal": total_words,
        "entries": entries,
    }
    entries_path = ASSETS / "entries.json"
    entries_path.write_text(
        json.dumps(entries_out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {entries_path}")

    calendar_out = {
        "version": 1,
        "byDateCommon": by_date_common,
        "byDateLeap": by_date_leap,
    }
    calendar_path = ASSETS / "calendar.json"
    calendar_path.write_text(
        json.dumps(calendar_out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {calendar_path}")

    portal = {
        "id": "kempis",
        "displayName": "Thomas à Kempis",
        "tagline": "Love God, and serve Him only.",
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "entries": n,
            "repeatsPerYear": 1.0,
            "note": (
                "366 x 1 — unique passage every calendar day. Maps 1:1 onto a "
                "leap year; common years merge the last two entries onto Dec 31."
            ),
        },
        "anchor": "cell",
        "modules": ["today", "admonitions", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "kempis_companion",
        "sourceNote": (
            "The Imitation of Christ, trans. Rev. William Benham (1886). "
            "Project Gutenberg #1653. Benham d. 1910 — public domain. "
            "All four books, including Book IV (the Sacrament)."
        ),
    }
    portal_path = ASSETS / "portal.json"
    portal_path.write_text(
        json.dumps(portal, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {portal_path}")

    review_path = REVIEW / "review.html"
    write_review_html(entries, review_path, target)
    print(f"wrote {review_path}")


if __name__ == "__main__":
    main()
