#!/usr/bin/env python3
"""Parse Lewis 1864 treatises into a shelf (not a daily cut).

Ascent + Dark Night from vol. 1; Spiritual Canticle + Living Flame from
vol. 2. Edition is David Lewis 1864. Never Kavanaugh–Rodriguez. Never Peers.

OCR is the same Folkscanomy FineReader dump as the maxims. Lightly cleaned,
not proofread to the Devout Life standard.

Writes: tools/content/john-cross/work/treatises.json
        assets/content/john-cross/treatises.json
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"
ASSETS = ROOT.parent.parent.parent / "assets" / "content" / "john-cross"

sys.path.insert(0, str(ROOT))
import parse as jc  # noqa: E402

CHAPTER_RE = re.compile(r"^CHAPTER(?:\s+([IVXL0-9]+))?\.?\s*$", re.I)
STANZA_RE = re.compile(r"^STANZA(?:\s+([IVXL0-9]+))?\.?\s*$", re.I)
BOOK_RE = re.compile(r"^BOOK(?: THE)?\s+([IVXL]+|FIRST|SECOND|THIRD|L)\.?\s*$", re.I)
PROLOGUE_RE = re.compile(r"^PROLOGUE\.?\s*$", re.I)
PAGE_TAIL = re.compile(r"[\s.]*\d{1,3}\s*$")
RUNNING = re.compile(
    r"^(?:"
    r"(?:THE )?(?:ASCENT OF MOUNT CARMEL|OBSCURE NIGHT(?: OF THE SOUL)?|"
    r"A? ?SPIRITUAL CANTICLE|LIVING FLAME OF LOVE)\.?"
    r"|VOL\.?\s*I{1,3}\.?"
    r"|THE FIRST VOLUME,?"
    r"|CONTENTS? OF"
    r")\s*$",
    re.I,
)


def collapse(line: str) -> str:
    return re.sub(r"[ \t]+", " ", line).strip()


def letters_only(text: str) -> str:
    text = text.upper()
    text = text.replace("THK", "THE").replace("TIIE", "THE")
    text = text.replace("OBSCUKE", "OBSCURE").replace("CHKIST", "CHRIST")
    text = re.sub(r"[^A-Z]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def fingerprint(text: str, words: int = 7) -> str:
    stop = {"THE", "OF", "AND", "IN", "TO", "A", "AN", "FOR", "BY", "ON"}
    toks = [w for w in letters_only(text).split() if w not in stop and len(w) > 1]
    return " ".join(toks[:words])


def title_case(text: str) -> str:
    small = {"of", "the", "and", "in", "on", "a", "an", "for", "to", "by", "with"}
    words = re.sub(r"\s+", " ", text).strip().lower().split()
    out = []
    for i, w in enumerate(words):
        if i == 0 or w not in small:
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return " ".join(out).rstrip(".")


def clean_volume(raw: str) -> list[str]:
    kept: list[str] = []
    for line in raw.splitlines():
        s = collapse(line)
        if jc.GOOGLE_RE.match(s) or jc.PAGE_ONLY_RE.match(s):
            continue
        if RUNNING.match(s):
            continue
        s = jc.tidy_line(s)
        if not s:
            continue
        kept.append(s)
    return kept


def find_span(lines: list[str], start_pred, end_pred, start_at: int = 0) -> tuple[int, int]:
    start = next(i for i in range(start_at, len(lines)) if start_pred(lines[i], i))
    end = next(
        (i for i in range(start + 1, len(lines)) if end_pred(lines[i], i)),
        len(lines),
    )
    return start, end


def parse_toc_v1(lines: list[str]) -> dict[str, list[dict]]:
    """Ascent + Dark Night chapter list from the volume contents."""
    start = next(i for i, s in enumerate(lines) if s.upper() == "CONTENTS")
    end = next(
        i
        for i, s in enumerate(lines)
        if i > start + 80
        and CHAPTER_RE.match(s)
        and any("TWO KINDS OF THIS NIGHT" in letters_only(x) for x in lines[i : i + 4])
    )
    toc = lines[start:end]
    works: dict[str, list[dict]] = {"ascent": [], "dark-night": []}
    work = "ascent"
    book = 0
    book_title = ""
    pending_title: list[str] = []
    chapter_n = 0

    def flush_title() -> str:
        nonlocal pending_title
        text = PAGE_TAIL.sub("", " ".join(pending_title))
        text = re.sub(r"\s+\d{1,3}$", "", text)
        pending_title = []
        return title_case(text)

    def is_book(s: str) -> bool:
        return bool(BOOK_RE.match(s) or re.match(r"^BOOK\s+[LI1]\.?\s*$", s, re.I))

    for s in toc:
        if letters_only(s) in {
            "THE OBSCURE NIGHT OF THE SOUL",
            "OBSCURE NIGHT OF THE SOUL",
        }:
            if pending_title and works[work]:
                works[work][-1]["title"] = flush_title() or works[work][-1]["title"]
            work = "dark-night"
            book = 0
            chapter_n = 0
            pending_title = []
            continue
        if is_book(s):
            if pending_title and works[work]:
                works[work][-1]["title"] = flush_title() or works[work][-1]["title"]
            # Ascent book III is followed by Dark Night book I in the TOC,
            # and the night title is often stripped as a running head.
            if work == "ascent" and book >= 3:
                work = "dark-night"
                book = 0
                chapter_n = 0
            book += 1
            chapter_n = 0
            book_title = ""
            continue
        if CHAPTER_RE.match(s):
            if pending_title and works[work]:
                works[work][-1]["title"] = flush_title() or works[work][-1]["title"]
            chapter_n += 1
            works[work].append({
                "part": max(book, 1),
                "partTitle": book_title or f"Book {max(book, 1)}",
                "chapter": chapter_n,
                "title": "",
            })
            continue
        if re.match(r"^(STANZAS?|PROLOGUE|PAGE|PAOK|CONTENTS|THE FIRST VOLUME)\.?\s*$", s, re.I):
            continue
        if not works[work]:
            if chapter_n == 0 and re.search(r"[A-Za-z]{4,}", s):
                piece = title_case(PAGE_TAIL.sub("", s))
                if piece:
                    book_title = (book_title + " " + piece).strip()
            continue
        if not works[work][-1]["title"] and re.search(r"[A-Za-z]{3,}", s):
            if chapter_n == 0:
                book_title = title_case(PAGE_TAIL.sub("", s)) or book_title
                continue
            pending_title.append(s)

    if pending_title and works[work]:
        works[work][-1]["title"] = flush_title() or works[work][-1]["title"]
    for work_items in works.values():
        for item in work_items:
            if not item["title"]:
                item["title"] = f"Chapter {item['chapter']}"
    return works


def is_book_heading(s: str) -> bool:
    return bool(BOOK_RE.match(s))


def split_v1_body(lines: list[str], toc_items: list[dict]) -> list[dict]:
    """Split on BOOK / CHAPTER headings; name from the TOC in order."""
    titles = list(toc_items)
    title_i = 0
    book = 1
    book_title = titles[0]["partTitle"] if titles else "Book 1"
    chapter_n = 0
    cur: list[str] = []
    cur_title = ""
    chapters: list[dict] = []

    def flush() -> None:
        nonlocal cur, cur_title
        if not cur or chapter_n == 0:
            cur = []
            return
        text = jc.scrub_ocr(jc.dehyphen_join(cur))
        if text:
            chapters.append({
                "part": book,
                "partTitle": book_title,
                "chapter": chapter_n,
                "title": cur_title or f"Chapter {chapter_n}",
                "textEn": text,
            })
        cur = []

    for line in lines:
        if is_book_heading(line) and chapter_n:
            flush()
            book += 1
            chapter_n = 0
            nxt = next((t for t in titles[title_i:] if t["part"] == book), None)
            book_title = nxt["partTitle"] if nxt else f"Book {book}"
            continue
        if CHAPTER_RE.match(line):
            flush()
            chapter_n += 1
            if title_i < len(titles):
                cur_title = titles[title_i]["title"]
                book = titles[title_i]["part"]
                book_title = titles[title_i]["partTitle"]
                title_i += 1
            else:
                cur_title = f"Chapter {chapter_n}"
            continue
        cur.append(line)
    flush()
    return chapters


def split_on_heading(lines: list[str], heading_re: re.Pattern[str], unit: str) -> list[dict]:
    chapters: list[dict] = []
    cur_lines: list[str] = []
    cur_title = ""
    n = 0

    def flush() -> None:
        nonlocal cur_lines, cur_title
        paras: list[str] = []
        buf: list[str] = []
        for l in cur_lines:
            if not l.strip():
                if buf:
                    paras.append(jc.dehyphen_join(buf))
                    buf = []
            else:
                buf.append(l)
        if buf:
            paras.append(jc.dehyphen_join(buf))
        text = jc.scrub_ocr(" ".join(p for p in paras if p))
        if text:
            chapters.append({
                "part": 1,
                "partTitle": unit,
                "chapter": n,
                "title": cur_title or f"{unit} {n}",
                "textEn": text,
            })
        cur_lines = []

    for line in lines:
        if heading_re.match(line) or PROLOGUE_RE.match(line):
            flush()
            n += 1
            if PROLOGUE_RE.match(line):
                cur_title = "Prologue"
            else:
                cur_title = title_case(line.rstrip("."))
            continue
        # stanza title on following caps line
        if not cur_lines and line == line.upper() and 8 < len(line) < 90 and not RUNNING.match(line):
            if n and not chapters:
                cur_title = title_case(line)
                continue
            if n and chapters and chapters[-1]["chapter"] != n and len(line.split()) <= 14:
                cur_title = title_case(line)
                continue
        cur_lines.append(line)
    flush()
    return [c for c in chapters if c["chapter"] > 0]


def pack_to(chapters: list[dict], n: int) -> list[dict]:
    out = [dict(c) for c in chapters]
    while len(out) > n:
        i = min(range(1, len(out)), key=lambda k: len(out[k]["textEn"].split()))
        out[i - 1]["textEn"] = (out[i - 1]["textEn"] + " " + out[i]["textEn"]).strip()
        del out[i]
    by_part: dict[int, int] = {}
    for ch in out:
        by_part[ch["part"]] = by_part.get(ch["part"], 0) + 1
        ch["chapter"] = by_part[ch["part"]]
    return out


def merge_thin(chapters: list[dict], min_words: int = 40) -> list[dict]:
    out: list[dict] = []
    for ch in chapters:
        words = len(ch["textEn"].split())
        if out and words < min_words:
            out[-1]["textEn"] = (out[-1]["textEn"] + " " + ch["textEn"]).strip()
            continue
        out.append(dict(ch))
    by_part: dict[int, int] = {}
    for ch in out:
        by_part[ch["part"]] = by_part.get(ch["part"], 0) + 1
        ch["chapter"] = by_part[ch["part"]]
    return out


def pack_parts(chapters: list[dict]) -> list[dict]:
    parts: dict[int, dict] = {}
    for ch in chapters:
        part = ch["part"]
        slot = parts.setdefault(part, {
            "part": part,
            "title": ch["partTitle"],
            "chapters": [],
        })
        slot["chapters"].append({
            "chapter": ch["chapter"],
            "title": ch["title"],
            "textEn": ch["textEn"],
        })
    return [parts[k] for k in sorted(parts)]


def body_blob(lines: list[str]) -> str:
    return " ".join(lines)


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    v1_raw = (RAW / "lewis_v1_djvu.txt").read_text(encoding="utf-8", errors="replace")
    v2_raw = (RAW / "lewis_v2_djvu.txt").read_text(encoding="utf-8", errors="replace")
    v1 = clean_volume(v1_raw)
    v2 = clean_volume(v2_raw)

    toc = parse_toc_v1(v1)
    if len(toc["ascent"]) < 70:
        raise SystemExit(f"ascent TOC too short: {len(toc['ascent'])}")
    if len(toc["dark-night"]) < 30:
        raise SystemExit(f"dark night TOC too short: {len(toc['dark-night'])}")

    ascent_start = next(
        i
        for i, s in enumerate(v1)
        if i > 1400
        and CHAPTER_RE.match(s)
        and any("TWO KINDS" in letters_only(x) for x in v1[i : i + 6])
    )
    night_start = next(
        i
        for i, s in enumerate(v1)
        if i > ascent_start + 200
        and (
            "I BEGIN THIS BOOK WITH THE STANZAS" in letters_only(s)
            or letters_only(s) in {
                "OBSCURE NIGHT OF THE SOUL",
                "THE OBSCURE NIGHT OF THE SOUL",
            }
            or letters_only(s) == "OBSCUKE NIGHT OF THE SOUL"
        )
    )
    ascent_body = body_blob(v1[ascent_start:night_start])
    night_body = body_blob(v1[night_start:])

    ascent_ch = merge_thin(split_v1_body(v1[ascent_start:night_start], toc["ascent"]))
    night_ch = merge_thin(split_v1_body(v1[night_start:], toc["dark-night"]))

    cant_start = next(
        i
        for i, s in enumerate(v2)
        if PROLOGUE_RE.match(s)
        and any("CANTICLE SEEMS TO HAVE BEEN WRITTEN" in letters_only(x) for x in v2[i : i + 4])
    )
    flame_start = next(
        i
        for i, s in enumerate(v2)
        if i > cant_start
        and (
            "IT IS NOT WITHOUT SOME UNWILLINGNESS" in letters_only(s)
            or (STANZA_RE.match(s) and any(PROLOGUE_RE.match(x) for x in v2[i : i + 3]))
        )
    )
    if flame_start > 0 and STANZA_RE.match(v2[flame_start - 1]):
        flame_start -= 1
    flame_end = next(
        (
            i
            for i, s in enumerate(v2)
            if i > flame_start + 40
            and (
                re.search(r"Three cautions to be observed", s, re.I)
                or s.upper() in {"LETTERS.", "LETTERS"}
            )
        ),
        len(v2),
    )
    stanza_num = re.compile(r"^STANZA\s+([IVXL0-9]+)\.?\s*$", re.I)
    canticle = merge_thin(
        split_on_heading(v2[cant_start:flame_start], stanza_num, "Stanza"),
        min_words=120,
    )
    # First unit is the prologue; keep it as chapter 0-become-1, stanzas follow.
    if canticle and canticle[0]["title"] == "Prologue":
        canticle[0]["partTitle"] = "Prologue"
    for c in canticle:
        if c["title"].startswith("Stanza"):
            c["part"] = 1
            c["partTitle"] = "Stanzas"
    flame = pack_to(
        merge_thin(
            split_on_heading(v2[flame_start:flame_end], STANZA_RE, "Stanza"),
            min_words=200,
        ),
        5,
    )
    for c in flame:
        c["part"] = 1
        c["partTitle"] = "Stanzas" if c["title"] != "Prologue" else "Prologue"

    books = [
        {
            "id": "ascent",
            "title": "The Ascent of Mount Carmel",
            "parts": pack_parts(ascent_ch),
        },
        {
            "id": "dark-night",
            "title": "The Obscure Night of the Soul",
            "parts": pack_parts(night_ch),
        },
        {
            "id": "canticle",
            "title": "A Spiritual Canticle",
            "parts": pack_parts(canticle),
        },
        {
            "id": "flame",
            "title": "The Living Flame of Love",
            "parts": pack_parts(flame),
        },
    ]

    for book in books:
        n = sum(len(p["chapters"]) for p in book["parts"])
        words = sum(
            len(c["textEn"].split())
            for p in book["parts"]
            for c in p["chapters"]
        )
        print(f"{book['id']}: {len(book['parts'])} parts, {n} chapters, {words} words")
        if n < 4:
            raise SystemExit(f"{book['id']} too thin")
        empty = [
            f"{book['id']} p{p['part']} c{c['chapter']}"
            for p in book["parts"]
            for c in p["chapters"]
            if len(c["textEn"].split()) < 20
        ]
        if empty:
            raise SystemExit(f"thin chapters: {empty[:8]}")

    out = {
        "translator": "David Lewis (1864)",
        "books": books,
    }
    for dest in (WORK / "treatises.json", ASSETS / "treatises.json"):
        dest.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {dest}")


if __name__ == "__main__":
    main()
