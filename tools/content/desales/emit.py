#!/usr/bin/env python3
"""Cut the parsed de Sales chapters into daily entries and emit app assets.

Reads:  tools/content/desales/work/chapters.json  (from parse.py)
Writes: assets/content/desales/entries.json
        assets/content/desales/calendar.json
        tools/content/desales/review/review.html
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
ASSETS = REPO / "assets" / "content" / "desales"

sys.path.insert(0, str(ROOT.parent))
from cut import cadence_candidates, cut, write_review_html  # noqa: E402


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

    # A literal 365 x 1 doesn't survive contact with this text's real word
    # count and paragraph lengths (see portals-spec.md discussion — the
    # spec's ~120k-word estimate was off; this text is 78,600). Target the
    # per-entry word count that a clean 365-day spread implies (words /
    # 365); paragraph-atomic overshoot then naturally lands the *actual*
    # average within spec's stated 250-400 words/day band anyway (337
    # here) while keeping entry count close enough to 365 that only a
    # minority of days share an entry with its neighbor.
    target = round(total_words / 365)
    print(f"\ntarget {target} words/entry; entry count and true average TBD")

    entries = cut(parts, target_words=target)
    print(f"cutter produced {len(entries)} entries")

    flagged = [e for e in entries if e["flags"]]
    if flagged:
        print(f"{len(flagged)} entries flagged for review:")
        for e in flagged:
            print(f"  #{e['id']} Part {e['part']} Ch.{e['chapter']}: {e['flags']}")

    # --- Verification ---------------------------------------------------
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

    # --- Date-key mapping: N entries distributed across 365 days --------
    # de Sales's own text has no calendar of its own — this is our
    # construction (.constructed provenance). Entries are spread evenly
    # across the year in reading order; a handful (N < 365) cover two
    # consecutive calendar days rather than splitting a paragraph or
    # padding with filler. 2025 is an arbitrary non-leap reference year,
    # used only to turn a day-of-year ordinal into an "MM-DD" key.
    n = len(entries)
    ref_year = 2025
    by_date_common: dict[str, int] = {}
    for i, e in enumerate(entries):
        start_ordinal = round((i / n) * 365) + 1
        end_ordinal = (
            round(((i + 1) / n) * 365) if i + 1 < n else 365
        )
        end_ordinal = max(end_ordinal, start_ordinal)
        for ordinal in range(start_ordinal, end_ordinal + 1):
            date = datetime.date(ref_year, 1, 1) + datetime.timedelta(
                days=ordinal - 1
            )
            by_date_common[f"{date.month:02d}-{date.day:02d}"] = e["id"]

    missing = {
        f"{(datetime.date(ref_year, 1, 1) + datetime.timedelta(days=d)).month:02d}"
        f"-{(datetime.date(ref_year, 1, 1) + datetime.timedelta(days=d)).day:02d}"
        for d in range(365)
    } - set(by_date_common)
    assert not missing, f"days with no entry: {sorted(missing)}"
    print(f"coverage check: OK (every day 1..365 covered, {n} unique entries)")

    # Leap day shares Feb 28's entry rather than getting unique content,
    # matching Benedict's own precedent of not giving the leap day a
    # standalone slot.
    by_date_leap = dict(by_date_common)
    by_date_leap["02-29"] = by_date_common["02-28"]

    # --- Emit -------------------------------------------------------------
    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    entries_out = {
        "version": 1,
        "translator": "unverified — see review notes before shipping",
        "cadence": {"entries": n, "repeatsPerYear": round(365 / n, 2)},
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

    review_path = REVIEW / "review.html"
    write_review_html(entries, review_path, target)
    print(f"wrote {review_path}")


if __name__ == "__main__":
    main()
