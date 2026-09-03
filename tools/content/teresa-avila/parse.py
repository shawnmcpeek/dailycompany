#!/usr/bin/env python3
"""Parse Stanbrook/Zimmerman Way of Perfection + Interior Castle.

Way is one part. The Castle's seven mansions are seven parts so the
cutter can never split a dwelling across an entry.
Strips Zimmerman's introduction, footnotes, and the index.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"

CHAPTER_WAY_RE = re.compile(r"^CHAPTER\s+(\d+)\s*$")
CHAPTER_CASTLE_RE = re.compile(r"^CHAPTER ([IVXL]+)\.\s*$")
ONLY_CHAPTER_RE = re.compile(r"^ONLY CHAPTER\.?\s*$")
MANSION_RE = re.compile(r"^THE (FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH) MANSIONS?\s*$")
FOOTNOTE_RE = re.compile(r"^\[\d+\]")
INLINE_NOTE_RE = re.compile(r"\[\d+\]")
RULE_RE = re.compile(r"^_+$")

ORDINAL = {
    "FIRST": 1, "SECOND": 2, "THIRD": 3, "FOURTH": 4,
    "FIFTH": 5, "SIXTH": 6, "SEVENTH": 7,
}
ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11,
}


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


def title_from_argument(lines: list[str]) -> str:
    text = normalize_ws(" ".join(lines))
    text = re.sub(r"\s+", " ", text)
    # First sentence of the ALL-CAPS argument, clipped.
    sent = re.split(r"(?<=[.])\s", text, maxsplit=1)[0]
    sent = sent.strip().rstrip(".")
    if len(sent) > 140:
        sent = sent[:137].rsplit(" ", 1)[0] + "..."
    if not sent:
        return "Chapter"
    letters = sum(c.isalpha() for c in sent)
    caps = sum(c.isupper() for c in sent if c.isalpha())
    if letters and caps / letters > 0.55:
        sent = sent[0].upper() + sent[1:].lower()
    else:
        sent = sent[0].upper() + sent[1:]
    return sent


def fill_stub_titles(chapters: list[dict]) -> None:
    stub = re.compile(r"^Chapter\s+\d+$", re.I)
    for c in chapters:
        paras = []
        for p in c["paragraphs"]:
            p = re.sub(r"\s*HERE ENDS?.*$", "", p, flags=re.I | re.S).strip()
            p = re.sub(
                r"\s*This document is from the C.*$", "", p, flags=re.I | re.S
            ).strip()
            if p:
                paras.append(p)
        c["paragraphs"] = paras
        if stub.match(c["title"].strip()) and paras:
            sent = re.split(r"(?<=[.?!])\s", paras[0], maxsplit=1)[0].strip()
            sent = sent.rstrip(".")
            if 12 <= len(sent) <= 140:
                c["title"] = sent


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    if text and not FOOTNOTE_RE.match(text):
        dest.append(text)
    return []


def parse_way(raw: str) -> dict:
    lines = raw.splitlines()
    start = next(i for i, l in enumerate(lines) if l.strip() == "PROLOGUE")
    chapters: list[dict] = []
    cur = None
    arg_buf: list[str] = []
    para: list[str] = []
    in_arg = False
    in_notes = False

    def new_chapter(num: int, pending_arg: list[str]) -> dict:
        title = title_from_argument(pending_arg) if pending_arg else (
            "Prologue" if num == 0 else f"Chapter {num}"
        )
        return {"chapter": num if num else 1, "title": title, "paragraphs": []}

    i = start
    n = len(lines)
    while i < n:
        s = lines[i].strip()
        if s.startswith("This document is from the C"):
            break
        if is_rule(lines[i]):
            in_notes = False
            i += 1
            continue
        if s.startswith("INTRODUCTORY NOTE"):
            in_notes = True
            i += 1
            continue
        if in_notes and (CHAPTER_WAY_RE.match(s) or s == "PROLOGUE"):
            in_notes = False
        if in_notes:
            i += 1
            continue
        if FOOTNOTE_RE.match(s):
            in_notes = True
            i += 1
            continue
        if s == "PROLOGUE" and cur is None:
            cur = {"chapter": 1, "title": "Prologue", "paragraphs": []}
            chapters.append(cur)
            arg_buf = []
            in_arg = False
            i += 1
            continue
        m = CHAPTER_WAY_RE.match(s)
        if m:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            num = int(m.group(1))
            # Argument is the following indented/title lines until a body para.
            arg_buf = []
            i += 1
            while i < n:
                nxt = lines[i].strip()
                if not nxt or is_rule(lines[i]) or FOOTNOTE_RE.match(nxt):
                    i += 1
                    continue
                if CHAPTER_WAY_RE.match(nxt):
                    break
                # Body starts at a sentence that isn't ALL CAPS argument.
                letters = sum(c.isalpha() for c in nxt)
                caps = sum(c.isupper() for c in nxt if c.isalpha())
                if letters and caps / max(letters, 1) > 0.6 and not nxt[0].isdigit():
                    arg_buf.append(nxt)
                    i += 1
                    continue
                break
            cur = new_chapter(num + 1, arg_buf)  # +1 because prologue is ch.1
            cur["chapter"] = num + 1
            chapters.append(cur)
            continue
        if not s:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            i += 1
            continue
        if cur is None:
            i += 1
            continue
        # Skip numbered contents lists ("1. Souls in the…") when they are
        # a run of short numbered labels before the chapter body.
        para.append(s)
        i += 1
    flush_para(para, cur["paragraphs"] if cur else [])
    # Drop trailing empty
    chapters = [c for c in chapters if c["paragraphs"]]
    if len(chapters) < 40:
        raise SystemExit(f"Way of Perfection: expected ~43 chapters, got {len(chapters)}")
    fill_stub_titles(chapters)
    return {
        "part": 1,
        "title": "The Way of Perfection",
        "chapters": chapters,
    }


def parse_castle(raw: str) -> list[dict]:
    lines = raw.splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if "THIS TREATISE, STYLED THE INTERIOR CASTLE" in l
    )
    # Stop at the index: a second "OR THE MANSIONS" after the seventh mansion
    # conclusion, or an "INDEX" heading.
    parts: dict[int, dict] = {}
    mansion = 1
    parts[1] = {
        "part": 2,
        "title": "Interior Castle — First Mansions",
        "chapters": [],
    }
    cur = {
        "chapter": 1,
        "title": "This treatise",
        "paragraphs": [],
    }
    parts[1]["chapters"].append(cur)
    para: list[str] = []
    in_notes = False
    in_index = False
    i = start
    n = len(lines)
    while i < n:
        s = lines[i].strip()
        if s.startswith("This document is from the C"):
            break
        if in_index:
            break
        if s in {"INDEX", "Indexes"}:
            break
        if s == "OR THE MANSIONS" and mansion >= 7 and cur["paragraphs"]:
            # Index reprint of the title page.
            break
        if is_rule(lines[i]):
            in_notes = False
            i += 1
            continue
        if s.startswith("INTRODUCTORY NOTE"):
            in_notes = True
            i += 1
            continue
        if FOOTNOTE_RE.match(s):
            in_notes = True
            i += 1
            continue
        if in_notes:
            i += 1
            continue
        m_man = MANSION_RE.match(s)
        if m_man:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            mansion = ORDINAL[m_man.group(1)]
            part_n = mansion + 1  # Way is part 1; mansions 1–7 are parts 2–8
            if mansion not in parts:
                parts[mansion] = {
                    "part": part_n,
                    "title": f"Interior Castle — {m_man.group(1).title()} Mansions",
                    "chapters": [],
                }
            else:
                parts[mansion]["title"] = (
                    f"Interior Castle — {m_man.group(1).title()} Mansions"
                )
            cur = None
            i += 1
            continue
        m_ch = CHAPTER_CASTLE_RE.match(s)
        only = ONLY_CHAPTER_RE.match(s)
        if m_ch or only:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            num = 1 if only else ROMAN[m_ch.group(1)]
            arg_buf: list[str] = []
            i += 1
            while i < n:
                nxt = lines[i].strip()
                if not nxt or is_rule(lines[i]) or FOOTNOTE_RE.match(nxt):
                    i += 1
                    continue
                if CHAPTER_CASTLE_RE.match(nxt) or ONLY_CHAPTER_RE.match(nxt) or MANSION_RE.match(nxt):
                    break
                letters = sum(c.isalpha() for c in nxt)
                caps = sum(c.isupper() for c in nxt if c.isalpha())
                if letters and caps / max(letters, 1) > 0.55 and not nxt[:1].isdigit():
                    arg_buf.append(nxt)
                    i += 1
                    continue
                # Skip "1. Souls in the first mansion. 2. …" contents lines
                if re.match(r"^\d+\.\s+\S+", nxt) and len(nxt) < 90:
                    # contents run — skip until a longer numbered body
                    # Teresa's body also starts "1. Now let us…" which is longer.
                    if len(nxt) < 70 and "." in nxt[3:]:
                        arg_buf.append(nxt)
                        i += 1
                        continue
                break
            cur = {
                "chapter": num,
                "title": title_from_argument(arg_buf) if arg_buf else f"Chapter {num}",
                "paragraphs": [],
            }
            if mansion not in parts:
                parts[mansion] = {
                    "part": mansion + 1,
                    "title": f"Interior Castle — Mansion {mansion}",
                    "chapters": [],
                }
            parts[mansion]["chapters"].append(cur)
            continue
        if not s:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            i += 1
            continue
        if cur is None:
            i += 1
            continue
        para.append(s)
        i += 1
    flush_para(para, cur["paragraphs"] if cur else [])

    ordered = []
    for m in range(1, 8):
        if m not in parts or not parts[m]["chapters"]:
            raise SystemExit(f"Castle mansion {m} missing")
        # Drop empty
        parts[m]["chapters"] = [c for c in parts[m]["chapters"] if c["paragraphs"]]
        fill_stub_titles(parts[m]["chapters"])
        print(f"Mansion {m}: {len(parts[m]['chapters'])} chapters")
        ordered.append(parts[m])
    return ordered


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    way = parse_way((RAW / "ccel_way.txt").read_text(encoding="utf-8"))
    print(f"Way of Perfection: {len(way['chapters'])} chapters")
    castle = parse_castle((RAW / "ccel_castle.txt").read_text(encoding="utf-8"))
    parts = [way] + castle
    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Benedictines of Stanbrook / Benedict Zimmerman (1911–12)",
            "parts": parts,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {dest}")


if __name__ == "__main__":
    main()
