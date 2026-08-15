#!/usr/bin/env python3
"""Parse Doyle Gutenberg #50040 into date_table.json (122 readings × date keys).

Doyle text is retained only under tools/content/work/ for alignment review.
It is never written into assets/content/.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from common import (
    WORK,
    RAW,
    DoylePortion,
    DateKeys,
    mmdd,
    parse_simple_date,
    tidy_paragraphs,
)


DATE_LINE = re.compile(
    r"^\s*((?:\(?Feb\.|Jan\.|Mar\.|Apr\.|May|June|July|Aug\.|Sept\.|Oct\.|Nov\.|Dec\.).*?)\s*$",
    re.M,
)
CHAPTER_LINE = re.compile(r"^\s*CHAPTER\s+(\d+)\s*$", re.M)
PROLOGUE_LINE = re.compile(r"^\s*PROLOGUE\s*$", re.M)


def parse_date_header(header: str) -> DateKeys:
    header = header.strip()
    parts = [p.strip() for p in header.split("—")]

    # Special: leap-only Feb 24; common year merges into preceding day.
    if header.startswith("(Feb. 24 in leap year"):
        # "(Feb. 24 in leap year; otherwise added to the preceding)—June 25—Oct. 25"
        rest = parts[1:]
        summer = parse_simple_date(rest[0])
        autumn = parse_simple_date(rest[1])
        return DateKeys(
            keys_common=[mmdd(*summer), mmdd(*autumn)],
            keys_leap=[mmdd(2, 24), mmdd(*summer), mmdd(*autumn)],
            merge_into_previous_on_common=True,
            raw_header=header,
        )

    # Shifted February forms: "Feb. 24 (25)—June 26—Oct. 26"
    shifted = re.match(
        r"(Feb)\.\s+(\d+)\s+\((\d+)\)\s*$",
        parts[0].replace("Feb.", "Feb."),
    )
    # Normalize: parts[0] like "Feb. 24 (25)"
    shifted = re.match(r"Feb\.\s+(\d+)\s+\((\d+)\)\s*$", parts[0])
    if shifted:
        common_day = int(shifted.group(1))
        leap_day = int(shifted.group(2))
        summer = parse_simple_date(parts[1])
        autumn = parse_simple_date(parts[2])
        return DateKeys(
            keys_common=[mmdd(2, common_day), mmdd(*summer), mmdd(*autumn)],
            keys_leap=[mmdd(2, leap_day), mmdd(*summer), mmdd(*autumn)],
            raw_header=header,
        )

    # Ordinary triple: "Jan. 1—May 2—Sept. 1"
    if len(parts) != 3:
        raise ValueError(f"unexpected date header: {header!r}")
    d1 = parse_simple_date(parts[0])
    d2 = parse_simple_date(parts[1])
    d3 = parse_simple_date(parts[2])
    keys = [mmdd(*d1), mmdd(*d2), mmdd(*d3)]
    return DateKeys(keys_common=keys, keys_leap=list(keys), raw_header=header)


def extract_doyle_body(raw: str) -> str:
    start = raw.find("*** START OF THE PROJECT GUTENBERG EBOOK")
    end = raw.find("*** END OF THE PROJECT GUTENBERG EBOOK")
    if start < 0 or end < 0:
        raise RuntimeError("Doyle Gutenberg markers missing")
    body = raw[start:end]
    # Prefer the second PROLOGUE (after TOC) if present.
    hits = list(PROLOGUE_LINE.finditer(body))
    if len(hits) >= 2:
        body = body[hits[1].start() :]
    elif hits:
        body = body[hits[0].start() :]
    return body


def chapter_at(pos: int, chapter_marks: list[tuple[int, int]]) -> int:
    current = 0
    for mark_pos, ch in chapter_marks:
        if mark_pos <= pos:
            current = ch
        else:
            break
    return current


def cue(text: str, which: str) -> str:
    paras = [p for p in text.split("\n\n") if p.strip()]
    if not paras:
        return ""
    target = paras[0] if which == "start" else paras[-1]
    words = target.split()
    if len(words) <= 28:
        return target
    if which == "start":
        return " ".join(words[:28]) + "…"
    return "…" + " ".join(words[-28:])


def parse_portions(body: str) -> list[DoylePortion]:
    chapter_marks: list[tuple[int, int]] = [(0, 0)]
    for m in CHAPTER_LINE.finditer(body):
        chapter_marks.append((m.start(), int(m.group(1))))

    date_matches = list(DATE_LINE.finditer(body))
    if len(date_matches) != 122:
        raise RuntimeError(f"expected 122 date headers, got {len(date_matches)}")

    portions: list[DoylePortion] = []
    for i, m in enumerate(date_matches):
        header = m.group(1).strip()
        text_start = m.end()
        text_end = date_matches[i + 1].start() if i + 1 < len(date_matches) else len(body)
        chunk = body[text_start:text_end]
        # Strip following CHAPTER banners from portion text.
        chunk = CHAPTER_LINE.sub("", chunk)
        chunk = PROLOGUE_LINE.sub("", chunk)
        text = tidy_paragraphs(chunk)
        # Drop Gutenberg page furniture.
        text = re.sub(r"^\s*ST\. BENEDICT.?S RULE.*$", "", text, flags=re.M)
        text = tidy_paragraphs(text)
        ch = chapter_at(m.start(), chapter_marks)
        dk = parse_date_header(header)
        portions.append(
            DoylePortion(
                id=i + 1,
                raw_header=header,
                chapter=ch,
                date_keys=dk,
                text=text,
                cue_start=cue(text, "start"),
                cue_end=cue(text, "end"),
            )
        )
    return portions


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = (RAW / "doyle.txt").read_text(encoding="utf-8")
    body = extract_doyle_body(raw)
    portions = parse_portions(body)

    payload = {
        "source": "Project Gutenberg #50040 (Doyle) — date table + portion cues only",
        "reading_count": len(portions),
        "readings": [
            {
                "id": p.id,
                "chapter": p.chapter,
                "header": p.raw_header,
                "date_keys_common": p.date_keys.keys_common,
                "date_keys_leap": p.date_keys.keys_leap,
                "merge_into_previous_on_common": p.date_keys.merge_into_previous_on_common,
                "word_count": len(p.text.split()),
                "cue_start": p.cue_start,
                "cue_end": p.cue_end,
                "text": p.text,
            }
            for p in portions
        ],
    }
    out = WORK / "date_table.json"
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {out} ({len(portions)} readings)")
    by_ch: dict[int, int] = {}
    for p in portions:
        by_ch[p.chapter] = by_ch.get(p.chapter, 0) + 1
    multi = {k: v for k, v in by_ch.items() if v > 1}
    print(f"chapters with intra-chapter breaks: {len(multi)}")


if __name__ == "__main__":
    main()
