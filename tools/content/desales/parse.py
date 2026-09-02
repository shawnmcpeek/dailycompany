#!/usr/bin/env python3
"""Parse the CCEL "Introduction to the Devout Life" text into structured
chapters: part number/title, chapter number/title, and clean paragraphs.

Source: tools/content/desales/raw/ccel_devout_life.txt
  = plain-text export of https://www.ccel.org/ccel/desales/devout_life
  Edition: anonymous 1876 Rivingtons "Library of Spiritual Works for
  English Catholics." Not Mackey. See portal.json sourceNote.

Strips: running heads/TOC/indices outside the five Parts, inline [N]
footnote markers, and the footnote blocks themselves (Scripture
citations and French-original quotations — apparatus, not the text).

Writes: tools/content/desales/work/chapters.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "ccel_devout_life.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8,
    "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14, "XV": 15,
    "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
    "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26, "XXVII": 27,
    "XXVIII": 28, "XXIX": 29, "XXX": 30, "XXXI": 31, "XXXII": 32,
    "XXXIII": 33, "XXXIV": 34, "XXXV": 35, "XXXVI": 36, "XXXVII": 37,
    "XXXVIII": 38, "XXXIX": 39, "XL": 40, "XLI": 41,
}

DIVIDER = re.compile(r"^ {0,8}_{10,}\s*$")
PART_RE = re.compile(r"^\s*PART\s+([IVXL]+)\.\s*(.*)$")
CHAPTER_RE = re.compile(r"^CHAPTER\s+([IVXL]+)\.\s*(.*)$")


def normalize_ws(text: str) -> str:
    text = text.replace("—", "--").replace("’", "'")
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def join_paragraph(lines: list[str]) -> str:
    return normalize_ws(" ".join(l.strip() for l in lines))


def strip_footnote_markers(text: str) -> str:
    return re.sub(r"\s*\[\d{1,3}\]", "", text)


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw_lines = RAW.read_text(encoding="utf-8").splitlines()

    # A real Part heading is preceded by "<divider>\n<blank>\n"; the table
    # of contents also contains bare "PART III."-style lines with neither,
    # so that distinguishes a heading from a false positive in the TOC.
    def is_real_part_heading(i: int) -> bool:
        return (
            i >= 2
            and not raw_lines[i - 1].strip()
            and DIVIDER.match(raw_lines[i - 2])
        )

    start = next(
        i
        for i, l in enumerate(raw_lines)
        if PART_RE.match(l) and is_real_part_heading(i)
    )
    end = next(i for i, l in enumerate(raw_lines) if l.strip() == "INDEX.")
    lines = raw_lines[start:end]

    parts: list[dict] = []
    cur_part = None
    cur_chapter = None
    cur_para: list[str] = []
    in_footnotes = False

    def flush_para():
        nonlocal cur_para
        if cur_para and cur_chapter is not None and not in_footnotes:
            text = strip_footnote_markers(join_paragraph(cur_para))
            if text:
                cur_chapter["paragraphs"].append(text)
        cur_para = []

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]

        m_part = PART_RE.match(line)
        if m_part:
            flush_para()
            title_lines = [m_part.group(2)]
            i += 1
            while i < n and lines[i].strip() and not DIVIDER.match(lines[i]):
                title_lines.append(lines[i])
                i += 1
            cur_part = {
                "part": ROMAN[m_part.group(1)],
                "title": normalize_ws(" ".join(title_lines)).rstrip("."),
                "chapters": [],
            }
            parts.append(cur_part)
            cur_chapter = None
            in_footnotes = False
            i += 1
            continue

        m_ch = CHAPTER_RE.match(line)
        if m_ch:
            flush_para()
            title_lines = [m_ch.group(2)]
            i += 1
            while i < n and lines[i].strip():
                title_lines.append(lines[i])
                i += 1
            cur_chapter = {
                "chapter": ROMAN[m_ch.group(1)],
                "title": normalize_ws(" ".join(title_lines)).rstrip("."),
                "paragraphs": [],
            }
            cur_part["chapters"].append(cur_chapter)
            in_footnotes = False
            i += 1
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

        cur_para.append(line)
        i += 1

    flush_para()

    total_chapters = sum(len(p["chapters"]) for p in parts)
    total_words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print(f"parts: {len(parts)}")
    print(f"chapters: {total_chapters}")
    print(f"words: {total_words}")

    out = WORK / "chapters.json"
    out.write_text(
        json.dumps({"parts": parts}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
