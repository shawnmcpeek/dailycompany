#!/usr/bin/env python3
"""Cut Mackey Treatise on the Love of God into a year-2 cycle.

Reads:  tools/content/desales/work/treatise_chapters.json
Writes: assets/content/desales/treatise_entries.json
        assets/content/desales/treatise_calendar.json
        tools/content/desales/review/treatise_review.html

Does not overwrite Devout Life entries.json / calendar.json / portal.json.
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
    data = json.loads((WORK / "treatise_chapters.json").read_text(encoding="utf-8"))
    parts = data["parts"]

    total_words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )

    print("=== cadence candidates ===")
    cadence_candidates(total_words)

    # Long paragraphs and book boundaries refuse the default 600-word
    # hard max, so search a slightly higher cap until 366 (then 365) lands.
    exact_target = None
    hard_max = 600
    for want in (366, 365):
        for hm in range(700, 850, 5):
            for candidate in range(390, 630, 5):
                if len(cut(parts, target_words=candidate, hard_max=hm)) == want:
                    exact_target = candidate
                    hard_max = hm
                    break
            if exact_target is not None:
                break
        if exact_target is not None:
            break
    target = exact_target if exact_target is not None else round(total_words / 366)
    print(f"\ntarget {target} words/entry hard_max {hard_max} (366 then 365)")

    entries = cut(parts, target_words=target, hard_max=hard_max)
    print(f"cutter produced {len(entries)} entries")
    for e in entries:
        if e["chapterTitle"].strip():
            continue
        sent = re.split(r"(?<=[.?!])\s", e["textEn"].strip(), maxsplit=1)[0]
        sent = sent.strip().rstrip(".")
        if 12 <= len(sent) <= 140:
            e["chapterTitle"] = sent
        elif sent:
            clip = sent[:72].rsplit(" ", 1)
            e["chapterTitle"] = clip[0] if clip[0] else sent[:72]
    if len(entries) not in (365, 366):
        print("WARNING: no target in range yields exactly 365 or 366; using closest")

    flagged = [e for e in entries if e["flags"]]
    if flagged:
        print(f"{len(flagged)} entries flagged for review:")
        for e in flagged[:20]:
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
    print("round-trip check: OK")

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
    print(f"coverage check: OK ({n} entries)")

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)

    entries_out = {
        "version": 1,
        "translator": "Dom Henry Benedict Mackey (1884)",
        "cadence": {"entries": n, "repeatsPerYear": 1.0},
        "wordsTotal": total_words,
        "entries": entries,
    }
    entries_path = ASSETS / "treatise_entries.json"
    entries_path.write_text(
        json.dumps(entries_out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {entries_path}")

    calendar_path = ASSETS / "treatise_calendar.json"
    calendar_path.write_text(
        json.dumps({
            "version": 1,
            "byDateCommon": by_date_common,
            "byDateLeap": by_date_leap,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {calendar_path}")

    review_path = REVIEW / "treatise_review.html"
    write_review_html(entries, review_path, target)
    print(f"wrote {review_path}")


if __name__ == "__main__":
    main()
