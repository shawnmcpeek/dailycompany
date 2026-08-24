#!/usr/bin/env python3
"""Extract Douay-Rheims (Challoner) psalms for Benedict Daily hours.

Source: tools/content/raw/douay_psalms.txt
  = THE BOOK OF PSALMS slice from Project Gutenberg ebook 1581
  (Holy Bible, Douay-Rheims Version, Challoner Revision).

Writes:
  assets/content/benedict/psalms.json
  assets/content/benedict/hours.json
"""

from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

from common import ASSETS, RAW

GUTENBERG_1581 = "https://www.gutenberg.org/files/1581/1581-0.txt"
UA = "BenedictDailyContentPipeline/0.1 (local build; Daddoo Dev)"

# Compline (required) + short-office placeholders.
WANTED = [4, 50, 66, 69, 90, 116, 119, 129, 133, 140]

CHAPTER_RE = re.compile(
    r"^Psalms Chapter (\d+)\n(.*?)(?=^Psalms Chapter \d+\n|\Z)",
    re.M | re.S,
)
VERSE_START_RE = re.compile(r"^(\d+):(\d+)\.\s*(.*)$")

OPENING = {
    "latin": "Deus, in adiutorium meum intende.",
    "english": "O God, come to my assistance.",
}
RESPONSE = {
    "latin": "Domine, ad adiuvandum me festina.",
    "english": "O Lord, make haste to help me.",
}
GLORY_BE = {
    "latin": (
        "Gloria Patri, et Filio, et Spiritui Sancto. "
        "Sicut erat in principio, et nunc, et semper, "
        "et in saecula saeculorum. Amen."
    ),
    "english": (
        "Glory be to the Father, and to the Son, and to the Holy Spirit. "
        "As it was in the beginning, is now, and ever shall be, "
        "world without end. Amen."
    ),
}


def ensure_raw_psalms(dest: Path) -> None:
    if dest.is_file() and dest.stat().st_size > 0:
        return
    print(f"fetching Gutenberg 1581 into {dest} ...")
    req = urllib.request.Request(GUTENBERG_1581, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=180) as resp:
        text = resp.read().decode("utf-8", errors="replace")
    start = text.find("THE BOOK OF PSALMS")
    if start < 0:
        raise SystemExit("THE BOOK OF PSALMS not found in Gutenberg 1581")
    end = text.find("THE BOOK OF PROVERBS", start)
    if end < 0:
        raise SystemExit("THE BOOK OF PROVERBS not found after Psalms")
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(text[start:end], encoding="utf-8")
    print(f"wrote {dest.name} ({dest.stat().st_size:,} bytes)")


def _normalize_ws(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def parse_chapter(number: int, body: str) -> dict | None:
    lines = body.splitlines()
    # Drop leading blanks; first line is Latin incipit/title.
    i = 0
    while i < len(lines) and not lines[i].strip():
        i += 1
    if i >= len(lines):
        return None
    title = lines[i].strip().rstrip(".")
    i += 1

    verses: list[dict] = []
    current: dict | None = None
    in_note = False

    while i < len(lines):
        raw = lines[i]
        line = raw.strip()
        i += 1
        if not line:
            continue

        m = VERSE_START_RE.match(line)
        if m:
            chap, vn, rest = int(m.group(1)), int(m.group(2)), m.group(3)
            if chap != number:
                # Defensive: stop if numbering drifts into another chapter.
                break
            if current is not None:
                current["text"] = _normalize_ws(current["text"])
                verses.append(current)
            current = {"n": vn, "text": rest}
            in_note = False
            continue

        # Preamble / Challoner notes are not verse text.
        if current is None:
            continue
        if "...." in line or "—Ibid" in line or line.startswith("Ibid"):
            in_note = True
            continue
        if in_note:
            continue

        # Soft-wrapped continuation of the current verse.
        current["text"] += " " + line

    if current is not None:
        current["text"] = _normalize_ws(current["text"])
        verses.append(current)

    if not verses:
        return None
    return {"number": number, "title": title, "verses": verses}


def extract_psalms(raw_text: str, wanted: list[int]) -> list[dict]:
    by_num: dict[int, dict] = {}
    for m in CHAPTER_RE.finditer(raw_text):
        num = int(m.group(1))
        if num not in wanted:
            continue
        parsed = parse_chapter(num, m.group(2))
        if parsed:
            by_num[num] = parsed
    missing = [n for n in wanted if n not in by_num]
    if missing:
        raise SystemExit(f"failed to extract psalms: {missing}")
    return [by_num[n] for n in wanted]


def build_hours(available: set[int]) -> dict:
    terce_psalm = 119 if 119 in available else 116
    offices = [
        {
            "id": "compline",
            "label": "Compline",
            "defaultTime": "21:00",
            "haptic": "compline",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [4, 90, 133],
            "closing": {
                "latin": (
                    "Noctem quietam et finem perfectum "
                    "concedat nobis Dominus omnipotens. Amen."
                ),
                "english": (
                    "May the all-powerful Lord grant us a restful night "
                    "and a perfect end. Amen."
                ),
            },
        },
        {
            "id": "lauds",
            "label": "Lauds",
            "defaultTime": "07:00",
            "haptic": "major",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [66],
            "closing": {
                "latin": "Benedicamus Domino.",
                "english": "Let us bless the Lord.",
            },
        },
        {
            "id": "terce",
            "label": "Terce",
            "defaultTime": "09:00",
            "haptic": "little",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [terce_psalm],
            "closing": {
                "latin": "Benedicamus Domino.",
                "english": "Let us bless the Lord.",
            },
        },
        {
            "id": "sext",
            "label": "Sext",
            "defaultTime": "12:00",
            "haptic": "little",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [50],
            "closing": {
                "latin": "Benedicamus Domino.",
                "english": "Let us bless the Lord.",
            },
        },
        {
            "id": "none",
            "label": "None",
            "defaultTime": "15:00",
            "haptic": "little",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [129],
            "closing": {
                "latin": "Benedicamus Domino.",
                "english": "Let us bless the Lord.",
            },
        },
        {
            "id": "vespers",
            "label": "Vespers",
            "defaultTime": "18:00",
            "haptic": "major",
            "opening": OPENING,
            "response": RESPONSE,
            "gloryBe": GLORY_BE,
            "psalmNumbers": [140],
            "closing": {
                "latin": "Benedicamus Domino.",
                "english": "Let us bless the Lord.",
            },
        },
    ]
    return {
        "version": 1,
        "psalterNote": (
            "Psalm numbers follow the Vulgate (Douay-Rheims). "
            "RB's Psalm 90 is modern Psalm 91."
        ),
        "offices": offices,
    }


def main() -> None:
    raw_path = RAW / "douay_psalms.txt"
    ensure_raw_psalms(raw_path)
    raw_text = raw_path.read_text(encoding="utf-8")
    psalms = extract_psalms(raw_text, WANTED)
    available = {p["number"] for p in psalms}
    hours = build_hours(available)

    ASSETS.mkdir(parents=True, exist_ok=True)
    psalms_path = ASSETS / "psalms.json"
    hours_path = ASSETS / "hours.json"
    psalms_path.write_text(
        json.dumps({"version": 1, "psalms": psalms}, ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )
    hours_path.write_text(
        json.dumps(hours, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"wrote {psalms_path.relative_to(ASSETS.parent.parent)}")
    print(f"wrote {hours_path.relative_to(ASSETS.parent.parent)}")
    print("extracted:")
    for p in psalms:
        print(f"  Psalm {p['number']:3d}  {p['title']:<24}  {len(p['verses'])} verses")


if __name__ == "__main__":
    main()
