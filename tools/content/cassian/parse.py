#!/usr/bin/env python3
"""Parse Gibson NPNF II.11 — The Conferences only.

Starts at Cassian's Conferences / I. First Conference of Abbot Moses.
Stops before The Seven Books on the Incarnation. Institutes are not kept.
Conferences Gibson marked 'Not translated' / 'omitted' are dropped.
Footnotes like [1087] are stripped.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "ccel_npnf211.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13,
    "XIV": 14, "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19,
    "XX": 20, "XXI": 21, "XXII": 22, "XXIII": 23, "XXIV": 24,
    "XXV": 25, "XXVI": 26, "XXVII": 27, "XXVIII": 28, "XXIX": 29,
    "XXX": 30, "XXXI": 31, "XXXII": 32, "XXXIII": 33, "XXXIV": 34,
    "XXXV": 35, "XXXVI": 36, "XXXVII": 37, "XXXVIII": 38, "XXXIX": 39,
    "XL": 40,
}

DIVIDER = re.compile(r"^_{8,}\s*$")
CONF_RE = re.compile(
    r"^\s*(XXIV|XXIII|XXII|XXI|XX|XIX|XVIII|XVII|XVI|XV|XIV|XIII|"
    r"XII|XI|X|IX|VIII|VII|VI|V|IV|III|II|I)\.\s+"
    r"((?:The\s+)?(?:First|Second|Third)\s+)?Conference of Abbot\b(.*)$",
    re.I,
)
CHAPTER_RE = re.compile(r"^\s*Chapter\s+([IVXL]+)\.\s*$")
NOTE_RE = re.compile(r"\[\d+\]")
FOOTNOTE_LINE = re.compile(r"^\s*\[\d+\]")
STOP = "THE SEVEN BOOKS OF JOHN CASSIAN"


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = NOTE_RE.sub("", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    if text and not FOOTNOTE_LINE.match(text):
        dest.append(text)
    return []


def is_omitted(text: str) -> bool:
    t = text.lower()
    return "not translated" in t or "this conference is omitted" in t


def first_sentence_title(para: str) -> str:
    sent = re.split(r"(?<=[.?!])\s", para.strip(), maxsplit=1)[0]
    sent = sent.strip().rstrip(".")
    if 12 <= len(sent) <= 140:
        return sent
    clip = sent[:72].rsplit(" ", 1)[0]
    return clip or sent or "Chapter"


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    lines = RAW.read_text(encoding="utf-8").splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if l.strip() == "I. First Conference of Abbot Moses."
    )
    end = next(
        i for i, l in enumerate(lines)
        if l.strip() == STOP and i > start
    )

    parts: list[dict] = []
    cur_part: dict | None = None
    cur_ch: dict | None = None
    para: list[str] = []
    title_buf: list[str] = []
    in_footnote = False

    def close_chapter_title() -> None:
        nonlocal title_buf
        if cur_ch is None or not title_buf:
            title_buf = []
            return
        title = normalize_ws(" ".join(title_buf))
        title_buf = []
        if title:
            cur_ch["title"] = title[0].upper() + title[1:] if title[0].islower() else title

    i = start
    while i < end:
        line = lines[i]
        s = line.strip()
        if DIVIDER.match(s):
            if title_buf:
                close_chapter_title()
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            in_footnote = False
            i += 1
            continue
        if FOOTNOTE_LINE.match(s):
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            in_footnote = True
            i += 1
            continue
        if in_footnote:
            if not s:
                in_footnote = False
            i += 1
            continue
        cm = CONF_RE.match(s)
        if cm:
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            title_buf = []
            num = ROMAN[cm.group(1).upper()]
            rest = normalize_ws(
                ((cm.group(2) or "") + "Conference of Abbot" + cm.group(3)).strip()
            )
            rest = NOTE_RE.sub("", rest).strip()
            cur_part = {
                "part": num,
                "title": rest.rstrip("."),
                "chapters": [],
            }
            parts.append(cur_part)
            cur_ch = None
            i += 1
            continue
        ch = CHAPTER_RE.match(s)
        if ch and cur_part is not None:
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            close_chapter_title()
            n = ROMAN[ch.group(1).upper()]
            cur_ch = {"chapter": n, "title": f"Chapter {n}", "paragraphs": []}
            cur_part["chapters"].append(cur_ch)
            title_buf = []
            i += 1
            continue
        if not s:
            if title_buf:
                close_chapter_title()
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            i += 1
            continue
        if s.startswith("This document is from the C") or "ccel.org" in s.lower():
            break
        if cur_part is None:
            i += 1
            continue
        if cur_ch is None:
            # Theme line ("On Chastity.") or "Not translated."
            if is_omitted(s):
                cur_part["_omit"] = True
            elif s.lower() not in {"on chastity.", "on nocturnal illusions."}:
                # Keep a real theme as part of the title when present.
                extra = normalize_ws(NOTE_RE.sub("", s))
                if extra and extra.lower() not in {"not translated.", "this conference is omitted."}:
                    if extra[0].isupper() and len(extra) < 80:
                        cur_part["title"] = f"{cur_part['title']} — {extra.rstrip('.')}"
            i += 1
            continue
        if cur_ch["title"].startswith("Chapter ") and not cur_ch["paragraphs"] and not para:
            # Argument heading under Chapter N.
            title_buf.append(s)
            i += 1
            continue
        if title_buf:
            # Continuation of a wrapped argument, or the first body line.
            letters = sum(c.isalpha() for c in s)
            caps = sum(c.isupper() for c in s if c.isalpha())
            if letters and caps / letters > 0.55:
                title_buf.append(s)
                i += 1
                continue
            close_chapter_title()
        para.append(s)
        i += 1

    flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
    close_chapter_title()

    kept: list[dict] = []
    for p in parts:
        if p.get("_omit"):
            print(f"skip omitted: {p['title']}")
            continue
        chapters = [c for c in p["chapters"] if c["paragraphs"]]
        if not chapters:
            print(f"skip empty: {p['title']}")
            continue
        for c in chapters:
            if re.match(r"^Chapter\s+\d+$", c["title"], re.I):
                c["title"] = first_sentence_title(c["paragraphs"][0])
        p["chapters"] = chapters
        p.pop("_omit", None)
        kept.append(p)
        print(
            f"Conf. {p['part']}: {len(chapters)} chapters, "
            f"{sum(len(c['paragraphs']) for c in chapters)} paras — {p['title']}"
        )

    if len(kept) < 20:
        raise SystemExit(f"expected ~22 translated conferences, got {len(kept)}")

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Edgar C. S. Gibson, NPNF II.11 (1894)",
            "parts": kept,
        }, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in kept
        for c in p["chapters"]
    )
    print(f"wrote {dest} ({words} words, {len(kept)} conferences)")
    print("entry-1 start:", kept[0]["chapters"][0]["paragraphs"][0][:220])


if __name__ == "__main__":
    main()
