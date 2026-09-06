#!/usr/bin/env python3
"""Parse Mackey 1884 Treatise on the Love of God into structured books.

Source: tools/content/desales/raw/mackey_love.txt
  = plain-text export of https://www.ccel.org/ccel/desales/love
  Edition: Dom Henry Benedict Mackey, 1884. Not Ryan 1950.

Same stripping as parse.py: running heads/TOC, inline [N] footnote
markers, and the footnote blocks themselves.

Writes: tools/content/desales/work/treatise_chapters.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "mackey_love.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8,
    "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14, "XV": 15,
    "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
    "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26, "XXVII": 27,
    "XXVIII": 28, "XXIX": 29, "XXX": 30, "XXXI": 31, "XXXII": 32,
}

DIVIDER = re.compile(r"^ {0,8}_{10,}\s*$")
BOOK_RE = re.compile(r"^BOOK\s+([IVXL]+)\.\s*$")
SECOND_BOOK_RE = re.compile(r"^THE SECOND BOOK\.\s*$")
CHAPTER_RE = re.compile(r"^\s*CHAPTER\s+([IVXL]+)\.\s*$")
END_RE = re.compile(r"^\s*\d+\.\s+file:")
FOOTNOTE_LINE = re.compile(r"^\s*\[\d{1,4}\]")


def normalize_ws(text: str) -> str:
    text = text.replace("—", "--").replace("’", "'")
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def join_paragraph(lines: list[str]) -> str:
    return normalize_ws(" ".join(l.strip() for l in lines))


def strip_footnote_markers(text: str) -> str:
    return re.sub(r"\s*\[\d{1,4}\]", "", text)


def title_case_heading(text: str) -> str:
    small = {"of", "the", "and", "in", "on", "a", "an", "for", "to", "but"}
    words = text.lower().split()
    out = []
    for i, w in enumerate(words):
        if i == 0 or w not in small:
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return " ".join(out)


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw_lines = RAW.read_text(encoding="utf-8").splitlines()

    start = next(
        i
        for i, l in enumerate(raw_lines)
        if BOOK_RE.match(l)
        and i >= 2
        and "THE LOVE OF GOD." in raw_lines[max(0, i - 8) : i]
    )
    end = next(
        (i for i, l in enumerate(raw_lines) if END_RE.match(l)),
        len(raw_lines),
    )
    lines = raw_lines[start:end]

    parts: list[dict] = []
    cur_part = None
    cur_chapter = None
    cur_para: list[str] = []
    in_footnotes = False

    def flush_para() -> None:
        nonlocal cur_para
        if cur_para and cur_chapter is not None and not in_footnotes:
            text = strip_footnote_markers(join_paragraph(cur_para))
            if text and not FOOTNOTE_LINE.match(text):
                cur_chapter["paragraphs"].append(text)
        cur_para = []

    def book_number(line: str) -> int | None:
        if SECOND_BOOK_RE.match(line):
            return 2
        m = BOOK_RE.match(line)
        if m:
            return ROMAN[m.group(1)]
        return None

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if END_RE.match(line):
            break

        book_n = book_number(line)
        if book_n is not None:
            flush_para()
            title_lines: list[str] = []
            i += 1
            while i < n and not CHAPTER_RE.match(lines[i]) and book_number(lines[i]) is None:
                if DIVIDER.match(lines[i]) or END_RE.match(lines[i]):
                    break
                if lines[i].strip() and not FOOTNOTE_LINE.match(lines[i]):
                    title_lines.append(lines[i])
                i += 1
            cur_part = {
                "part": book_n,
                "title": title_case_heading(
                    normalize_ws(" ".join(title_lines)).rstrip(".")
                ) or f"Book {book_n}",
                "chapters": [],
            }
            parts.append(cur_part)
            cur_chapter = None
            in_footnotes = False
            continue

        m_ch = CHAPTER_RE.match(line)
        if m_ch:
            flush_para()
            title_lines = []
            i += 1
            while i < n and not lines[i].strip():
                i += 1
            while i < n and lines[i].strip():
                if CHAPTER_RE.match(lines[i]) or book_number(lines[i]) is not None:
                    break
                if DIVIDER.match(lines[i]) or END_RE.match(lines[i]):
                    break
                if FOOTNOTE_LINE.match(lines[i]):
                    break
                letters = re.sub(r"[^A-Za-z]", "", lines[i])
                if letters and letters == letters.upper():
                    title_lines.append(lines[i])
                    i += 1
                    continue
                break
            cur_chapter = {
                "chapter": ROMAN[m_ch.group(1)],
                "title": title_case_heading(
                    normalize_ws(" ".join(title_lines)).rstrip(".")
                ),
                "paragraphs": [],
            }
            if cur_part is None:
                raise SystemExit("chapter before first book")
            cur_part["chapters"].append(cur_chapter)
            in_footnotes = False
            continue

        if DIVIDER.match(line):
            flush_para()
            in_footnotes = True
            i += 1
            continue

        if not line.strip():
            flush_para()
            i += 1
            continue

        if in_footnotes:
            i += 1
            continue

        cur_para.append(line)
        i += 1

    flush_para()

    if [p["part"] for p in parts] != list(range(1, 13)):
        raise SystemExit(f"expected books 1-12, got {[p['part'] for p in parts]}")

    empty = [
        f"B{p['part']} ch {c['chapter']}"
        for p in parts
        for c in p["chapters"]
        if not any(x.strip() for x in c["paragraphs"])
    ]
    if empty:
        raise SystemExit(f"empty chapters: {empty[:8]}")

    total_chapters = sum(len(p["chapters"]) for p in parts)
    total_words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print(f"books: {len(parts)}")
    print(f"chapters: {total_chapters}")
    print(f"words: {total_words}")
    for p in parts:
        print(f"  Book {p['part']}: {len(p['chapters'])} ch — {p['title']}")

    out = WORK / "treatise_chapters.json"
    out.write_text(
        json.dumps({"parts": parts}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
