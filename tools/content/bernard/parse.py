#!/usr/bin/env python3
"""Parse Eales liturgical sermons (vol III) + Cantica (vol IV), and Patmore On Loving God."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"
sys.path.insert(0, str(ROOT.parent))
from sermon_ocr import (  # noqa: E402
    body_paragraphs,
    collapse,
    first_sentence_title,
    is_chrome,
    sermons_as_chapters,
    title_case,
)


def title_ok(text: str) -> bool:
    letters = sum(c.isalpha() for c in text)
    if letters < 8:
        return False
    weird = sum(1 for c in text if ord(c) > 127 or c in r"%\^~*")
    return weird <= 3


def sanitize(chapters: list[dict]) -> list[dict]:
    out = []
    for c in chapters:
        title = c["title"]
        if not title_ok(title):
            title = first_sentence_title(c["paragraphs"][0])
        out.append({**c, "title": title})
    return out


def parse_vol3() -> dict:
    lines = (RAW / "eales_vol03.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if "SERMONS FOR THE ECCLESIASTICAL YEAR" in collapse(l).upper()
    )
    chapters = sanitize(sermons_as_chapters(lines, start=start))
    if len(chapters) < 12:
        raise SystemExit(f"vol III: only {len(chapters)} sermons")
    words = sum(len(" ".join(c["paragraphs"]).split()) for c in chapters)
    print(f"Vol III De Tempore: {len(chapters)} sermons, {words} words")
    return {
        "part": 1,
        "title": "Sermons for the Ecclesiastical Year",
        "chapters": chapters,
    }


def parse_vol4() -> dict:
    lines = (RAW / "eales_vol04.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    chapters = sanitize(sermons_as_chapters(lines))
    if len(chapters) < 70:
        raise SystemExit(f"vol IV: expected ~86 Cantica sermons, got {len(chapters)}")
    words = sum(len(" ".join(c["paragraphs"]).split()) for c in chapters)
    print(f"Vol IV Cantica: {len(chapters)} sermons, {words} words")
    return {
        "part": 2,
        "title": "Sermons on the Song of Songs",
        "chapters": chapters,
    }


CHAP = re.compile(r"^CHAPTER\s+([IVXLCDM]+|[0-9]+)\.?\s*$", re.I)
LETTER_HEAD = re.compile(
    r"^LETTER\s+([IVXLCDM]+)\s*[.,:]?\s*(.*)$",
    re.I,
)
ROMAN_LETTER_MAX = 450


def letter_num(token: str) -> int | None:
    raw = collapse(token).upper().replace(".", "").replace(" ", "")
    raw = raw.replace("1", "I")
    n, s = 0, raw
    for p, v in [
        ("M", 1000), ("CM", 900), ("D", 500), ("CD", 400), ("C", 100),
        ("XC", 90), ("L", 50), ("XL", 40), ("X", 10), ("IX", 9), ("V", 5),
        ("IV", 4), ("I", 1),
    ]:
        while s.startswith(p):
            n += v
            s = s[len(p):]
    if s or n < 1 or n > ROMAN_LETTER_MAX:
        return None
    return n


def parse_letters_file(path: Path, start_after: int = 0) -> list[dict]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    hits: list[tuple[int, int, str]] = []
    for i, line in enumerate(lines):
        s = collapse(line)
        m = LETTER_HEAD.match(s)
        if not m:
            continue
        num = letter_num(m.group(1))
        if num is None:
            continue
        rest = collapse(m.group(2) or "")
        if rest.isdigit() and len(rest) <= 4:
            continue
        hits.append((i, num, rest))
    body: list[tuple[int, int, str]] = []
    last = start_after
    for i, (idx, num, rest) in enumerate(hits):
        nxt = hits[i + 1][0] if i + 1 < len(hits) else min(len(lines), idx + 80)
        looks_real = bool(re.search(r"circa|a\.?\s*d\.?|\bto\b", rest, re.I)) or (
            len(re.sub(r"[^a-zA-Z]", "", rest)) >= 8
        )
        if nxt - idx < 12 and not looks_real:
            continue
        words = len(" ".join(collapse(l) for l in lines[idx:nxt]).split())
        if words < 25:
            continue
        if num <= last:
            continue
        if last and num > last + 15 and not looks_real:
            continue
        body.append((idx, num, rest))
        last = num
    chapters = []
    end = next(
        (i for i, l in enumerate(lines[body[-1][0] + 40:], body[-1][0] + 40)
         if re.match(r"^index\b", collapse(l), re.I) and len(collapse(l)) < 40),
        len(lines),
    ) if body else 0
    for i, (idx, num, rest) in enumerate(body):
        nxt = body[i + 1][0] if i + 1 < len(body) else end
        block = lines[idx + 1:nxt]
        title = title_case(rest) if rest and title_ok(rest) else ""
        skip = 0
        if not title:
            for line in block:
                s = collapse(line)
                if not s or is_chrome(line):
                    skip += 1
                    continue
                if len(s) < 90:
                    title = title_case(s)
                    skip += 1
                break
        paras = body_paragraphs(block[skip:])
        if len(" ".join(paras).split()) < 40:
            continue
        if not title or not title_ok(title):
            title = first_sentence_title(paras[0]) if paras else f"Letter {num}"
        chapters.append({
            "chapter": num,
            "title": title,
            "paragraphs": paras,
        })
    return chapters


def parse_letters() -> dict:
    vol1 = parse_letters_file(RAW / "eales_vol01.txt")
    last = vol1[-1]["chapter"] if vol1 else 0
    vol2 = parse_letters_file(RAW / "eales_vol02.txt", start_after=last)
    if len(vol1) + len(vol2) < 80:
        raise SystemExit(f"letters: only {len(vol1)}+{len(vol2)}")
    print(f"Letters: vol I {len(vol1)}, vol II {len(vol2)}")
    return {
        "id": "letters",
        "title": "Letters",
        "parts": [
            {"part": 1, "title": "Letters, Volume I", "chapters": vol1},
            {"part": 2, "title": "Letters, Volume II", "chapters": vol2},
        ],
    }


def parse_patmore() -> dict:
    lines = (RAW / "patmore_loving_god.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    idxs = [i for i, l in enumerate(lines) if CHAP.match(collapse(l))]
    # Prefer the body cluster (after the TOC).
    body = []
    for i, idx in enumerate(idxs):
        nxt = idxs[i + 1] if i + 1 < len(idxs) else min(len(lines), idx + 80)
        words = len(" ".join(collapse(l) for l in lines[idx:nxt]).split())
        if words >= 80:
            body.append(idx)
    if len(body) < 8:
        raise SystemExit(f"On Loving God: only {len(body)} chapters")
    # Use from first substantial CHAPTER through last.
    start = body[0]
    used = [i for i in idxs if i >= start]
    chapters = []
    end = next(
        (i for i, l in enumerate(lines[used[-1] + 40:], used[-1] + 40)
         if re.match(r"^index\b", collapse(l), re.I) and len(collapse(l)) < 40),
        len(lines),
    )
    for n, idx in enumerate(used):
        nxt = used[n + 1] if n + 1 < len(used) else end
        block = lines[idx + 1:nxt]
        title = ""
        skip = 0
        for line in block:
            s = collapse(line)
            if not s or is_chrome(line):
                skip += 1
                continue
            title = title_case(s)
            skip += 1
            break
        paras = body_paragraphs(block[skip:])
        if not paras:
            continue
        if not title_ok(title):
            title = first_sentence_title(paras[0])
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": title,
            "paragraphs": paras,
        })
    print(f"On Loving God: {len(chapters)} chapters")
    return {
        "id": "loving-god",
        "title": "On Loving God",
        "parts": [{"part": 1, "title": "On Loving God", "chapters": chapters}],
    }


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    parts = [parse_vol3(), parse_vol4()]
    (WORK / "chapters.json").write_text(
        json.dumps({
            "translator": "Samuel J. Eales (1889–96)",
            "parts": parts,
        }, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    words = sum(
        len(" ".join(c["paragraphs"]).split())
        for p in parts for c in p["chapters"]
    )
    print(f"wrote chapters.json ({words} words)")
    shelf = {
        "loving-god": parse_patmore(),
        "letters": parse_letters(),
    }
    (WORK / "shelf.json").write_text(
        json.dumps(shelf, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("wrote shelf.json")


if __name__ == "__main__":
    main()
