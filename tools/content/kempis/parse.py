#!/usr/bin/env python3
"""Parse Benham's Imitation of Christ (PG #1653) into cut.py's chapter shape.

Source: tools/content/kempis/raw/pg1653_benham.txt
Strips Gutenberg header/footer, the introductory note, TOC, inline
footnote markers, and the scripture-citation footnote blocks. Keeps
Kempis's own numbered sections and the Voice of Christ / Disciple labels.

Writes: tools/content/kempis/work/chapters.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "pg1653_benham.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8,
    "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14, "XV": 15,
    "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
    "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26, "XXVII": 27,
    "XXVIII": 28, "XXIX": 29, "XXX": 30, "XXXI": 31, "XXXII": 32,
    "XXXIII": 33, "XXXIV": 34, "XXXV": 35, "XXXVI": 36, "XXXVII": 37,
    "XXXVIII": 38, "XXXIX": 39, "XL": 40, "XLI": 41, "XLII": 42,
    "XLIII": 43, "XLIV": 44, "XLV": 45, "XLVI": 46, "XLVII": 47,
    "XLVIII": 48, "XLIX": 49, "L": 50, "LI": 51, "LII": 52, "LIII": 53,
    "LIV": 54, "LV": 55, "LVI": 56, "LVII": 57, "LVIII": 58, "LIX": 59,
}

ORDINAL = {"FIRST": 1, "SECOND": 2, "THIRD": 3, "FOURTH": 4}

BOOK_RE = re.compile(r"^THE (FIRST|SECOND|THIRD|FOURTH) BOOK\s*$")
CHAPTER_RE = re.compile(r"^CHAPTER ([IVXL]+)\s*$")
END_RE = re.compile(r"^\*\*\* END OF THE PROJECT GUTENBERG")
FOOTNOTE_LINE_RE = re.compile(r"^\(\d+\)")
INLINE_NOTE_RE = re.compile(r"\(\d+\)")
ITALIC_RE = re.compile(r"_([^_]+)_")

EXPECTED_CHAPTERS = {1: 25, 2: 12, 3: 59, 4: 18}


def title_case_book(text: str) -> str:
    small = {"for", "the", "of", "and", "in", "on", "a"}
    words = text.lower().split()
    out = []
    for i, w in enumerate(words):
        if i == 0 or w not in small:
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return " ".join(out)


def normalize_ws(text: str) -> str:
    text = text.replace("—", "--").replace("–", "--")
    text = text.replace("’", "'").replace("‘", "'")
    text = text.replace("“", '"').replace("”", '"')
    text = ITALIC_RE.sub(r"\1", text)
    text = INLINE_NOTE_RE.sub("", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def join_paragraph(lines: list[str]) -> str:
    return normalize_ws(" ".join(l.strip() for l in lines))


def is_footnote_line(line: str) -> bool:
    s = line.strip()
    return bool(FOOTNOTE_LINE_RE.match(s))


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw_lines = RAW.read_text(encoding="utf-8").splitlines()

    start = next(i for i, l in enumerate(raw_lines) if BOOK_RE.match(l.strip()))
    end = next(i for i, l in enumerate(raw_lines) if END_RE.match(l.strip()))
    lines = raw_lines[start:end]

    parts: list[dict] = []
    cur_part = None
    cur_chapter = None
    cur_para: list[str] = []
    pending_title: list[str] = []
    in_footnotes = False
    awaiting_title = False

    def flush_para() -> None:
        nonlocal cur_para
        if cur_para and cur_chapter is not None and not in_footnotes:
            text = join_paragraph(cur_para)
            if text:
                cur_chapter["paragraphs"].append(text)
        cur_para = []

    def attach_pending_to_chapter() -> None:
        """Book-level epigraph (Book IV's Voice of Christ) lands on ch. 1."""
        nonlocal pending_title
        if not pending_title or cur_chapter is None:
            pending_title = []
            return
        text = join_paragraph(pending_title)
        if text:
            cur_chapter["paragraphs"].insert(0, text)
        pending_title = []

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()

        m_book = BOOK_RE.match(stripped)
        if m_book:
            flush_para()
            pending_title = []
            title_lines: list[str] = []
            i += 1
            while i < n and lines[i].strip() and not CHAPTER_RE.match(lines[i].strip()):
                title_lines.append(lines[i].strip())
                i += 1
            cur_part = {
                "part": ORDINAL[m_book.group(1)],
                "title": title_case_book(normalize_ws(" ".join(title_lines)).rstrip(".")),
                "chapters": [],
            }
            parts.append(cur_part)
            cur_chapter = None
            in_footnotes = False
            awaiting_title = False
            continue

        m_ch = CHAPTER_RE.match(stripped)
        if m_ch:
            flush_para()
            in_footnotes = False
            cur_chapter = {
                "chapter": ROMAN[m_ch.group(1)],
                "title": "",
                "paragraphs": [],
            }
            cur_part["chapters"].append(cur_chapter)
            attach_pending_to_chapter()
            awaiting_title = True
            i += 1
            continue

        if is_footnote_line(stripped):
            flush_para()
            in_footnotes = True
            i += 1
            continue

        if not stripped:
            if awaiting_title and cur_chapter is not None and cur_chapter["title"]:
                awaiting_title = False
            flush_para()
            i += 1
            continue

        if in_footnotes:
            i += 1
            continue

        if awaiting_title and cur_chapter is not None and not cur_chapter["title"]:
            title_bits = [stripped]
            i += 1
            while i < n and lines[i].strip() and not CHAPTER_RE.match(lines[i].strip()):
                # Title is the lines immediately after CHAPTER N, until a blank.
                title_bits.append(lines[i].strip())
                i += 1
            cur_chapter["title"] = normalize_ws(" ".join(title_bits)).rstrip(".")
            continue

        if cur_chapter is None:
            # Material between the book heading and chapter 1 (Book IV epigraph).
            pending_title.append(stripped)
            i += 1
            continue

        cur_para.append(stripped)
        i += 1

    flush_para()

    for p in parts:
        expected = EXPECTED_CHAPTERS[p["part"]]
        got = len(p["chapters"])
        if got != expected:
            raise SystemExit(
                f"Book {p['part']} expected {expected} chapters, parsed {got}"
            )
        for c in p["chapters"]:
            if not c["title"]:
                raise SystemExit(
                    f"Book {p['part']} chapter {c['chapter']} has no title"
                )
            if not c["paragraphs"]:
                raise SystemExit(
                    f"Book {p['part']} chapter {c['chapter']} has no paragraphs"
                )

    total_chapters = sum(len(p["chapters"]) for p in parts)
    total_words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print(f"parts: {len(parts)}")
    print(f"chapters: {total_chapters}")
    print(f"words: {total_words}")
    for p in parts:
        print(f"  Book {p['part']} ({p['title']}): {len(p['chapters'])} ch")

    out = WORK / "chapters.json"
    out.write_text(
        json.dumps({"parts": parts}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
