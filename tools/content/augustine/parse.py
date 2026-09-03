#!/usr/bin/env python3
"""Parse Pusey's Confessions (CCEL) into cut.py shape.

Books I–X are the daily year. XI–XIII are written to work/appendix.json
and are not fed to the cutter.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "ccel_pusey.txt"
WORK = ROOT / "work"

BOOK_RE = re.compile(r"^Book ([IVX]+)\s*$")
CHAPTER_RE = re.compile(r"^Chapter ([IVXL]+|[0-9]+)\s*$")
RULE_RE = re.compile(r"^_+$|^\s*_{3,}\s*$|^_{10,}")
FOOTNOTE_RE = re.compile(r"^\[\d+\]")
INLINE_NOTE_RE = re.compile(r"\[\d+\]")

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13,
    "XIV": 14, "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19,
    "XX": 20, "XXI": 21, "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25,
    "XXVI": 26, "XXVII": 27, "XXVIII": 28, "XXIX": 29, "XXX": 30,
    "XXXI": 31, "XXXII": 32, "XXXIII": 33, "XXXIV": 34, "XXXV": 35,
    "XXXVI": 36, "XXXVII": 37, "XXXVIII": 38, "XXXIX": 39, "XL": 40,
    "XLI": 41, "XLII": 42, "XLIII": 43, "XLIV": 44, "XLV": 45,
}


def roman(text: str) -> int:
    t = text.strip().upper()
    if t.isdigit():
        return int(t)
    if t not in ROMAN:
        raise SystemExit(f"unknown roman: {text}")
    return ROMAN[t]


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = INLINE_NOTE_RE.sub("", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def is_rule(line: str) -> bool:
    s = line.strip()
    return bool(re.match(r"^_+$", s)) or s.startswith("_____")


def split_long(text: str, target: int = 90) -> list[str]:
    """CCEL often ships a whole chapter as one block. Split on sentences
    so the cutter can land a unique year without inventing wording."""
    if len(text.split()) <= 140:
        return [text]
    sentences = re.split(r"(?<=[.?;])\s+", text)
    paras: list[str] = []
    buf: list[str] = []
    count = 0
    for s in sentences:
        w = len(s.split())
        if buf and count + w > target:
            paras.append(" ".join(buf))
            buf = [s]
            count = w
        else:
            buf.append(s)
            count += w
    if buf:
        paras.append(" ".join(buf))
    return [p for p in paras if p.strip()]


def parse_toc_titles(lines: list[str]) -> dict[tuple[int, int], str]:
    titles: dict[tuple[int, int], str] = {}
    book = 0
    chapter = 0
    buf: list[str] = []
    started = False
    for line in lines:
        s = line.strip()
        if s == "Contents":
            started = True
            continue
        if not started:
            continue
        if BOOK_RE.match(s):
            if book and chapter and buf:
                titles[(book, chapter)] = normalize_ws(" ".join(buf))
                buf = []
            book = roman(BOOK_RE.match(s).group(1))
            chapter = 0
            continue
        m = re.match(r"^Chapter ([IVXL]+)\s*$", s)
        if m:
            if book and chapter and buf:
                titles[(book, chapter)] = normalize_ws(" ".join(buf))
            chapter = roman(m.group(1))
            buf = []
            continue
        # TOC chapter lines look like "* [2]Chapter I"
        m = re.match(r"^\*?\s*\[\d+\]Chapter ([IVXL]+)\s*$", s)
        if m:
            if book and chapter and buf:
                titles[(book, chapter)] = normalize_ws(" ".join(buf))
            chapter = roman(m.group(1))
            buf = []
            continue
        m = re.match(r"^\*?\s*\[\d+\]Book ([IVX]+)\s*$", s)
        if m:
            if book and chapter and buf:
                titles[(book, chapter)] = normalize_ws(" ".join(buf))
                buf = []
            book = roman(m.group(1))
            chapter = 0
            continue
        if s.startswith("Book ") and BOOK_RE.match(s):
            continue
        if started and s and not s.startswith("[") and book:
            # skip the rule that ends TOC
            if is_rule(line) or s.startswith("_____"):
                if book and chapter and buf:
                    titles[(book, chapter)] = normalize_ws(" ".join(buf))
                return titles
            if not s.startswith("*") and not s.startswith("["):
                buf.append(s)
    if book and chapter and buf:
        titles[(book, chapter)] = normalize_ws(" ".join(buf))
    return titles


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    lines = RAW.read_text(encoding="utf-8").splitlines()
    toc = parse_toc_titles(lines)

    start = next(i for i, l in enumerate(lines) if l.strip() == "Book I")
    # First "Book I" in the file is the TOC; body is the later centered one.
    body_starts = [i for i, l in enumerate(lines) if l.strip() == "Book I"]
    start = body_starts[-1]

    parts_all: dict[int, dict] = {}
    cur_part = None
    cur_chapter = None
    cur_para: list[str] = []

    def flush_para() -> None:
        nonlocal cur_para
        if cur_para and cur_chapter is not None:
            text = normalize_ws(" ".join(cur_para))
            if "This document is from the C" in text:
                text = text.split("This document is from the C")[0].strip()
            text = re.sub(r"\s*Gratias Tibi Domine\s*$", "", text).strip()
            if text and not FOOTNOTE_RE.match(text):
                cur_chapter["paragraphs"].extend(split_long(text))
        cur_para = []

    i = start
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if is_rule(line) or stripped.startswith("_____"):
            i += 1
            continue
        m_book = BOOK_RE.match(stripped)
        if m_book:
            flush_para()
            num = roman(m_book.group(1))
            cur_part = {
                "part": num,
                "title": f"Book {m_book.group(1)}",
                "chapters": [],
            }
            parts_all[num] = cur_part
            cur_chapter = None
            i += 1
            continue
        m_ch = CHAPTER_RE.match(stripped)
        if m_ch:
            flush_para()
            num = roman(m_ch.group(1))
            title = toc.get((cur_part["part"] if cur_part else 0, num), "")
            if not title:
                title = f"Chapter {m_ch.group(1)}"
            cur_chapter = {
                "chapter": num,
                "title": title[:160],
                "paragraphs": [],
            }
            if cur_part is not None:
                cur_part["chapters"].append(cur_chapter)
            i += 1
            continue
        if FOOTNOTE_RE.match(stripped):
            i += 1
            continue
        if stripped.startswith("This document is from the CCEL") or (
            stripped.startswith("This document is from the C")
        ):
            break
        if not stripped:
            flush_para()
            i += 1
            continue
        cur_para.append(stripped)
        i += 1
    flush_para()

    daily = [parts_all[k] for k in range(1, 11) if k in parts_all]
    appendix = [parts_all[k] for k in range(11, 14) if k in parts_all]
    if len(daily) != 10:
        raise SystemExit(f"expected books I–X, got { [p['part'] for p in daily] }")
    if len(appendix) != 3:
        raise SystemExit(f"expected books XI–XIII, got { [p['part'] for p in appendix] }")
    for p in daily + appendix:
        if not p["chapters"]:
            raise SystemExit(f"Book {p['part']} has no chapters")
        print(f"Book {p['part']}: {len(p['chapters'])} chapters")

    (WORK / "chapters.json").write_text(
        json.dumps({"translator": "E. B. Pusey (1838)", "parts": daily},
                   indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (WORK / "appendix.json").write_text(
        json.dumps({"translator": "E. B. Pusey (1838)", "parts": appendix},
                   indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {WORK / 'chapters.json'} and appendix.json")


if __name__ == "__main__":
    main()
