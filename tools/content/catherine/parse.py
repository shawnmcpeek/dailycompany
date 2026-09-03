#!/usr/bin/env python3
"""Parse Thorold 1907 Dialogue (CCEL / Kegan Paul).

Four treatises as parts. Italic argument headings are chapters.
Stops before Barduccio's transit letter and CCEL chrome.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "ccel_thorold.txt"
WORK = ROOT / "work"

DIVIDER = re.compile(r"^_{8,}\s*$")
TREATISES = [
    ("A TREATISE OF DIVINE PROVIDENCE", 1, "Divine Providence"),
    ("A TREATISE OF DISCRETION", 2, "Discretion"),
    ("A TREATISE OF PRAYER", 3, "Prayer"),
    ("A TREATISE OF OBEDIENCE", 4, "Obedience"),
]
STOP_PREFIXES = (
    "Letter of Ser Barduccio",
    "This document is from the C",
)


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def is_stop(line: str) -> bool:
    s = line.strip()
    return any(s.startswith(p) for p in STOP_PREFIXES) or "ccel.org" in s.lower()


def is_treatise(line: str) -> tuple[int, str] | None:
    s = line.strip()
    for title, num, name in TREATISES:
        if s == title:
            return num, name
    return None


def is_heading_line(line: str) -> bool:
    s = line.strip()
    if not s or DIVIDER.match(s) or is_stop(line) or is_treatise(line):
        return False
    return indent(line) >= 6


def title_from_heading(lines: list[str]) -> str:
    text = normalize_ws(" ".join(l.strip() for l in lines))
    if text:
        return text[0].upper() + text[1:] if text[0].islower() else text
    return "Chapter"


def split_long(text: str, target: int = 90) -> list[str]:
    """CCEL often packs a whole section into one paragraph. Split on
    sentences so the cutter can land a unique year without inventing text."""
    n = len(re.findall(r"\S+", text))
    if n <= 110:
        return [text]
    sentences = re.split(r"(?<=[.?!;])\s+(?=[A-Z\"'])", text)
    out: list[str] = []
    buf: list[str] = []
    wc = 0
    for sent in sentences:
        w = len(re.findall(r"\S+", sent))
        if buf and wc + w > target and wc >= 55:
            out.append(" ".join(buf))
            buf = [sent]
            wc = w
        else:
            buf.append(sent)
            wc += w
    if buf:
        out.append(" ".join(buf))
    return [p for p in out if p.strip()]


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    if text:
        dest.extend(split_long(text))
    return []


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

    starts = [i for i, l in enumerate(lines) if l.strip() == "A TREATISE OF DIVINE PROVIDENCE"]
    if len(starts) < 2:
        raise SystemExit("body treatise heading missing (need the one after the TOC)")
    start = starts[1]  # ~line 642, not the TOC

    parts: list[dict] = []
    cur_part: dict | None = None
    cur_ch: dict | None = None
    para: list[str] = []
    heading: list[str] = []

    def close_heading() -> None:
        nonlocal heading, cur_ch, para
        if not heading or cur_part is None:
            heading = []
            return
        para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
        title = title_from_heading(heading)
        heading = []
        n = len(cur_part["chapters"]) + 1
        cur_ch = {"chapter": n, "title": title, "paragraphs": []}
        cur_part["chapters"].append(cur_ch)

    i = start
    while i < len(lines):
        line = lines[i]
        s = line.strip()
        if is_stop(line):
            break
        treatise = is_treatise(line)
        if treatise:
            para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            heading = []
            num, name = treatise
            cur_part = {"part": num, "title": name, "chapters": []}
            parts.append(cur_part)
            cur_ch = None
            i += 1
            continue
        if DIVIDER.match(s) or not s:
            if heading:
                close_heading()
            else:
                para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            i += 1
            continue
        if is_heading_line(line) and cur_part is not None:
            if not heading:
                para = flush_para(para, cur_ch["paragraphs"] if cur_ch else [])
            heading.append(s)
            i += 1
            continue
        if heading:
            close_heading()
        if cur_part is None:
            i += 1
            continue
        if cur_ch is None:
            # Body before the first argument heading — rare; open a chapter.
            cur_ch = {"chapter": 1, "title": "Chapter 1", "paragraphs": []}
            cur_part["chapters"].append(cur_ch)
        para.append(s)
        i += 1

    flush_para(para, cur_ch["paragraphs"] if cur_ch else [])

    for p in parts:
        p["chapters"] = [c for c in p["chapters"] if c["paragraphs"]]
        for n, c in enumerate(p["chapters"], 1):
            c["chapter"] = n
            if re.match(r"^Chapter\s+\d+$", c["title"], re.I):
                c["title"] = first_sentence_title(c["paragraphs"][0])
        if not p["chapters"]:
            raise SystemExit(f"empty treatise: {p['title']}")
        print(
            f"{p['title']}: {len(p['chapters'])} chapters, "
            f"{sum(len(c['paragraphs']) for c in p['chapters'])} paras"
        )

    if [p["part"] for p in parts] != [1, 2, 3, 4]:
        raise SystemExit(f"expected four treatises, got {[p['title'] for p in parts]}")

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Algar Thorold (Kegan Paul, 1907)",
            "parts": parts,
        }, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print(f"wrote {dest} ({words} words)")
    print("entry-1 start:", parts[0]["chapters"][0]["paragraphs"][0][:220])


if __name__ == "__main__":
    main()
