#!/usr/bin/env python3
"""Parse Delatte/McCann 1921 into chapter blocks for commentary drafting."""

from __future__ import annotations

import json
import re
from pathlib import Path

from common import ROMAN, WORK, RAW, tidy_paragraphs, words

ROOT = Path(__file__).resolve().parent


def parse_delatte(raw: str) -> dict[int, str]:
    # Prefer the body after TOC — first "CHAPTER I OF THE VARIOUS"
    start = raw.find("CHAPTER  I   OF  THE  VARIOUS")
    if start < 0:
        start = raw.find("CHAPTER  I")
    if start < 0:
        raise RuntimeError("Delatte CHAPTER I not found")

    # Include prologue commentary that precedes CHAPTER I if present
    prol = raw.rfind("PROLOGUE", 0, start)
    body_start = prol if prol > 0 else start
    body = raw[body_start:]

    # Cut indexes / end matter
    for marker in ("INDEX", "ALPHABETICAL", "Printed in Great Britain"):
        idx = body.find(marker)
        if idx > len(body) * 0.7:
            body = body[:idx]
            break

    chapter_re = re.compile(r"\n\s*CHAPTER\s+([IVXLC]+)\b", re.M)
    marks: list[tuple[int, int]] = []
    # Prologue: from body start until first CHAPTER
    first = chapter_re.search(body)
    if first:
        marks.append((0, 0))  # prologue at 0
    for m in chapter_re.finditer(body):
        roman = m.group(1)
        if roman not in ROMAN:
            continue
        marks.append((m.start(), ROMAN[roman]))

    # Dedupe by chapter number keeping first occurrence after start
    seen: set[int] = set()
    clean: list[tuple[int, int]] = []
    for pos, ch in marks:
        if ch in seen:
            continue
        seen.add(ch)
        clean.append((pos, ch))
    clean.sort()

    chapters: dict[int, str] = {}
    for i, (pos, ch) in enumerate(clean):
        end = clean[i + 1][0] if i + 1 < len(clean) else len(body)
        chunk = body[pos:end]
        chunk = re.sub(r"\n\s*CHAPTER\s+[IVXLC]+\b[^\n]*", "", chunk, count=1)
        # Collapse OCR spacing artifacts lightly
        chunk = re.sub(r"[ \t]+", " ", chunk)
        chunk = tidy_paragraphs(chunk)
        chapters[ch] = chunk

    if 0 not in chapters:
        # Fallback empty prologue
        chapters[0] = ""
    return chapters


def excerpt_for_portion(chapter_text: str, portion: int, portions: int) -> str:
    if not chapter_text:
        return ""
    if portions <= 1:
        # Cap very long chapters for the model
        w = words(chapter_text)
        if len(w) > 900:
            return " ".join(w[:900])
        return chapter_text
    paras = [p for p in chapter_text.split("\n\n") if p.strip()]
    if not paras:
        w = words(chapter_text)
        n = max(1, len(w) // portions)
        start = (portion - 1) * n
        end = len(w) if portion == portions else start + n
        return " ".join(w[start:end])
    # Ratio split by paragraph word counts
    weights = [max(1, len(words(p))) for p in paras]
    total = sum(weights)
    targets = [total / portions] * portions
    buckets: list[list[str]] = [[] for _ in range(portions)]
    bi = 0
    running = 0
    for p, w in zip(paras, weights):
        buckets[bi].append(p)
        running += w
        if bi < portions - 1 and running >= targets[bi]:
            bi += 1
            running = 0
    text = "\n\n".join(buckets[portion - 1])
    w = words(text)
    if len(w) > 700:
        text = " ".join(w[:700])
    return text


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = (RAW / "delatte_mccann.txt").read_text(encoding="utf-8", errors="replace")
    chapters = parse_delatte(raw)
    readings = json.loads(
        (ROOT.parent.parent / "assets/content/benedict/rule_readings.json").read_text()
    )["readings"]

    packets = []
    for r in readings:
        ch = r["chapter"]
        delatte = excerpt_for_portion(
            chapters.get(ch, ""),
            r["portionInChapter"],
            r["portionsInChapter"],
        )
        packets.append(
            {
                "id": r["id"],
                "chapter": ch,
                "chapterTitle": r["chapterTitle"],
                "portionInChapter": r["portionInChapter"],
                "portionsInChapter": r["portionsInChapter"],
                "textEn": r["textEn"],
                "delatteExcerpt": delatte,
            }
        )

    out = WORK / "commentary_packets.json"
    out.write_text(json.dumps({"packets": packets}, indent=2, ensure_ascii=False) + "\n")
    nonempty = sum(1 for p in packets if p["delatteExcerpt"].strip())
    print(f"wrote {out} ({len(packets)} packets, {nonempty} with Delatte text)")
    print("chapters parsed:", sorted(chapters))


if __name__ == "__main__":
    main()
