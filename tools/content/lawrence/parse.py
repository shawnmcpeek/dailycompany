#!/usr/bin/env python3
"""Parse Gutenberg #13871 — conversations and letters.

Strips the editor's biographical preface and Gutenberg chrome.
Keeps the four conversations and the fifteen letters as natural units.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "pg13871.txt"
WORK = ROOT / "work"

CONV_RE = re.compile(
    r"^(FIRST|SECOND|THIRD|FOURTH) CONVERSATION\.?$", re.I
)
LETTER_RE = re.compile(
    r"^(FIRST|SECOND|THIRD|FOURTH|FIFTH|SIXTH|SEVENTH|EIGHTH|"
    r"NINTH|TENTH|ELEVENTH|TWELFTH|THIRTEENTH|FOURTEENTH|FIFTEENTH)"
    r" LETTER\.?$",
    re.I,
)
ORDINAL = {
    "FIRST": 1, "SECOND": 2, "THIRD": 3, "FOURTH": 4, "FIFTH": 5,
    "SIXTH": 6, "SEVENTH": 7, "EIGHTH": 8, "NINTH": 9, "TENTH": 10,
    "ELEVENTH": 11, "TWELFTH": 12, "THIRTEENTH": 13, "FOURTEENTH": 14,
    "FIFTEENTH": 15,
}


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = re.sub(r"_([^_]+)_", r"\1", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    if text:
        dest.append(text)
    return []


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = RAW.read_text(encoding="utf-8")
    end_m = re.search(r"\*\*\* END OF THE PROJECT GUTENBERG", raw)
    if not end_m:
        raise SystemExit("Gutenberg end marker missing")
    lines = raw[: end_m.start()].splitlines()

    start = next(i for i, l in enumerate(lines) if l.strip() == "FIRST CONVERSATION.")
    conversations: list[dict] = []
    letters: list[dict] = []
    cur: dict | None = None
    para: list[str] = []

    def open_unit(kind: str, num: int, title: str) -> None:
        nonlocal cur, para
        para = flush_para(para, cur["paragraphs"] if cur else [])
        cur = {"chapter": num, "title": title, "paragraphs": []}
        (conversations if kind == "conv" else letters).append(cur)

    for i in range(start, len(lines)):
        s = lines[i].strip()
        if not s:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            continue
        if s.startswith("***"):
            break
        m = CONV_RE.match(s)
        if m:
            n = ORDINAL[m.group(1).upper()]
            open_unit("conv", n, f"{m.group(1).title()} conversation")
            continue
        m = LETTER_RE.match(s)
        if m:
            n = ORDINAL[m.group(1).upper()]
            open_unit("letter", n, f"{m.group(1).title()} letter")
            continue
        if s in {"CONVERSATIONS.", "LETTERS.", "PREFACE."}:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            continue
        if cur is None:
            continue
        para.append(s)
    flush_para(para, cur["paragraphs"] if cur else [])

    conversations = [c for c in conversations if c["paragraphs"]]
    letters = [c for c in letters if c["paragraphs"]]
    if len(conversations) != 4:
        raise SystemExit(f"expected 4 conversations, got {len(conversations)}")
    if len(letters) != 15:
        raise SystemExit(f"expected 15 letters, got {len(letters)}")

    parts = [
        {"part": 1, "title": "Conversations", "chapters": conversations},
        {"part": 2, "title": "Letters", "chapters": letters},
    ]
    for p in parts:
        print(
            f"{p['title']}: {len(p['chapters'])} chapters, "
            f"{sum(len(c['paragraphs']) for c in p['chapters'])} paras"
        )

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Translated from the French (Fleming H. Revell)",
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
    print("entry-1 start:", conversations[0]["paragraphs"][0][:220])


if __name__ == "__main__":
    main()
