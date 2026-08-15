#!/usr/bin/env python3
"""Shared helpers for the Benedict Daily content pipeline."""

from __future__ import annotations

import html
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = ROOT.parent.parent / "assets" / "content"

MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "June": 6,
    "July": 7,
    "Aug": 8,
    "Sept": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

ROMAN = {
    "I": 1,
    "II": 2,
    "III": 3,
    "IV": 4,
    "V": 5,
    "VI": 6,
    "VII": 7,
    "VIII": 8,
    "IX": 9,
    "X": 10,
    "XI": 11,
    "XII": 12,
    "XIII": 13,
    "XIV": 14,
    "XV": 15,
    "XVI": 16,
    "XVII": 17,
    "XVIII": 18,
    "XIX": 19,
    "XX": 20,
    "XXI": 21,
    "XXII": 22,
    "XXIII": 23,
    "XXIV": 24,
    "XXV": 25,
    "XXVI": 26,
    "XXVII": 27,
    "XXVIII": 28,
    "XXIX": 29,
    "XXX": 30,
    "XXXI": 31,
    "XXXII": 32,
    "XXXIII": 33,
    "XXXIV": 34,
    "XXXV": 35,
    "XXXVI": 36,
    "XXXVII": 37,
    "XXXVIII": 38,
    "XXXIX": 39,
    "XL": 40,
    "XLI": 41,
    "XLII": 42,
    "XLIII": 43,
    "XLIV": 44,
    "XLV": 45,
    "XLVI": 46,
    "XLVII": 47,
    "XLVIII": 48,
    "XLIX": 49,
    "L": 50,
    "LI": 51,
    "LII": 52,
    "LIII": 53,
    "LIV": 54,
    "LV": 55,
    "LVI": 56,
    "LVII": 57,
    "LVIII": 58,
    "LIX": 59,
    "LX": 60,
    "LXI": 61,
    "LXII": 62,
    "LXIII": 63,
    "LXIV": 64,
    "LXV": 65,
    "LXVI": 66,
    "LXVII": 67,
    "LXVIII": 68,
    "LXIX": 69,
    "LXX": 70,
    "LXXI": 71,
    "LXXII": 72,
    "LXXIII": 73,
}


def normalize_ws(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    text = text.replace("\u00a0", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def tidy_paragraphs(text: str) -> str:
    """Collapse hard-wrapped lines into paragraphs."""
    text = normalize_ws(text)
    blocks: list[str] = []
    buf: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if not line or set(line) <= {"_", "-"}:
            if buf:
                blocks.append(" ".join(buf))
                buf = []
            continue
        buf.append(line)
    if buf:
        blocks.append(" ".join(buf))
    # Drop pure chapter-title leftovers that are short all-caps rules.
    cleaned = []
    for b in blocks:
        if re.fullmatch(r"_{3,}", b):
            continue
        cleaned.append(b.strip())
    return "\n\n".join(cleaned)


def words(text: str) -> list[str]:
    return re.findall(r"[A-Za-zÀ-öø-ÿ0-9']+", text)


def mmdd(month: int, day: int) -> str:
    return f"{month:02d}-{day:02d}"


def parse_simple_date(token: str) -> tuple[int, int]:
    token = token.strip().replace(".", "")
    m = re.match(r"(Jan|Feb|Mar|Apr|May|June|July|Aug|Sept|Oct|Nov|Dec)\s+(\d+)", token)
    if not m:
        raise ValueError(f"bad date token: {token!r}")
    return MONTHS[m.group(1)], int(m.group(2))


@dataclass
class DateKeys:
    """Resolved calendar keys for one canonical reading."""

    keys_common: list[str]
    keys_leap: list[str]
    merge_into_previous_on_common: bool = False
    raw_header: str = ""


@dataclass
class DoylePortion:
    id: int
    raw_header: str
    chapter: int
    date_keys: DateKeys
    text: str
    cue_start: str = ""
    cue_end: str = ""


@dataclass
class ChapterText:
    chapter: int
    title: str
    text: str
    paragraphs: list[str] = field(default_factory=list)


@dataclass
class AlignedReading:
    id: int
    chapter: int
    chapter_title: str
    portion_in_chapter: int
    portions_in_chapter: int
    date_keys_common: list[str]
    date_keys_leap: list[str]
    merge_into_previous_on_common: bool
    text_en: str
    text_la: str
    doyle_text: str  # review only — never emit to app assets
    doyle_header: str
    confidence: float
    flags: list[str] = field(default_factory=list)
