#!/usr/bin/env python3
"""Parse Taylor 1912 Story of a Soul (Gutenberg #16772).

Keeps her autobiography (I–XI), counsels, letters, and prayers from this
edition. Strips Gutenberg chrome, the editor's epilogue of her death,
favors/shrine material, and the poems (Susan L. Emery, not Taylor).
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "pg16772_taylor.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11,
}

CHAPTER_RE = re.compile(r"^CHAPTER ([IVX]+)(?:\s+(.*))?$")
INLINE_NOTE_RE = re.compile(r"\[\d+\]")
FOOTNOTE_LINE_RE = re.compile(r"^\[\d+\]")
RULE_RE = re.compile(r"^[_—–-]{5,}$")


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    dq = '"'
    text = text.replace("\u201c", dq).replace("\u201d", dq)
    text = re.sub(r"_([^_]+)_", r"\1", text)
    text = INLINE_NOTE_RE.sub("", text)
    text = re.sub(r"\[Ed\.\]", "", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def is_editor_leftover(s: str) -> bool:
    t = s.strip().strip('"')
    if t.startswith("This Prayer was found after the death"):
        return True
    if t.startswith("MY DAYS OF GRACE"):
        return True
    if "ENTRY INTO HEAVEN" in t:
        return True
    if re.match(
        r"^(Birthday|Baptism|The Smile of Our Lady|First Communion|"
        r"Confirmation|Conversion\.?|Audience with Leo|Entry into the Carmel|"
        r"Clothing|Profession\.?|Taking of the Veil|Act of Oblation)\b",
        t,
    ):
        return True
    return False


def is_chrome(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    if RULE_RE.match(s) or s.startswith("_____"):
        return True
    if s.startswith("***"):
        return True
    if FOOTNOTE_LINE_RE.match(s):
        return True
    if s.startswith("This document is from the C"):
        return True
    if "PROJECT GUTENBERG" in s.upper():
        return True
    if s.startswith("http://") or s.startswith("https://"):
        return True
    if "ccel.org" in s.lower():
        return True
    return False


def title_case(text: str) -> str:
    text = normalize_ws(text)
    if not text:
        return "Chapter"
    letters = sum(c.isalpha() for c in text)
    caps = sum(c.isupper() for c in text if c.isalpha())
    if letters and caps / letters > 0.55:
        small = {"of", "the", "a", "an", "and", "to", "for", "in", "on"}
        words = text.lower().split()
        out = []
        for i, w in enumerate(words):
            if i == 0 or w not in small:
                out.append(w[:1].upper() + w[1:])
            else:
                out.append(w)
        return " ".join(out)
    return text[0].upper() + text[1:]


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    text = re.sub(r"\s*HERE ENDS?.*$", "", text, flags=re.I | re.S).strip()
    if text.lower().startswith("this prayer was found after the death"):
        return []
    if text and not FOOTNOTE_LINE_RE.match(text):
        dest.append(text)
    return []


def parse_range(lines: list[str], start: int, end: int, stop_at: set[str]) -> tuple[list[dict], int]:
    chapters: list[dict] = []
    cur: dict | None = None
    para: list[str] = []
    in_notes = False
    i = start
    while i < end:
        s = lines[i].strip()
        if s in stop_at:
            break
        if s.startswith("SELECTED POEMS"):
            break
        if FOOTNOTE_LINE_RE.match(s) or s.startswith("[Ed.]"):
            para = flush_para(para, cur["paragraphs"] if cur else [])
            in_notes = True
            i += 1
            continue
        if in_notes:
            if not s:
                in_notes = False
            i += 1
            continue
        if is_chrome(lines[i]) or not s:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            i += 1
            continue
        m = CHAPTER_RE.match(s)
        if m:
            para = flush_para(para, cur["paragraphs"] if cur else [])
            num = ROMAN[m.group(1)]
            rest = (m.group(2) or "").strip()
            title = title_case(rest) if rest else f"Chapter {num}"
            cur = {"chapter": num, "title": title, "paragraphs": []}
            chapters.append(cur)
            i += 1
            # Optional ALL-CAPS argument line(s)
            while i < end:
                nxt = lines[i].strip()
                if not nxt or is_chrome(lines[i]):
                    i += 1
                    continue
                letters = sum(c.isalpha() for c in nxt)
                caps = sum(c.isupper() for c in nxt if c.isalpha())
                if letters and caps / letters > 0.7 and not CHAPTER_RE.match(nxt):
                    if cur["title"].startswith("Chapter "):
                        cur["title"] = title_case(nxt)
                    i += 1
                    continue
                break
            continue
        if cur is None:
            i += 1
            continue
        if is_editor_leftover(s):
            i += 1
            continue
        para.append(s)
        i += 1
    flush_para(para, cur["paragraphs"] if cur else [])
    return [c for c in chapters if c["paragraphs"]], i


def parse_named_sections(
    lines: list[str], start: int, end: int, headings: list[tuple[str, str]]
) -> list[dict]:
    """Split a range on exact heading lines into chapters."""
    indexes = []
    for i in range(start, end):
        s = lines[i].strip()
        for key, title in headings:
            if s.startswith(key):
                indexes.append((i, title))
                break
    chapters = []
    for n, (idx, title) in enumerate(indexes):
        stop = indexes[n + 1][0] if n + 1 < len(indexes) else end
        paras: list[str] = []
        buf: list[str] = []
        in_notes = False
        for j in range(idx + 1, stop):
            s = lines[j].strip()
            if FOOTNOTE_LINE_RE.match(s) or s.startswith("[Ed.]"):
                buf = flush_para(buf, paras)
                in_notes = True
                continue
            if in_notes:
                if not s:
                    in_notes = False
                continue
            if is_chrome(lines[j]) or not s:
                buf = flush_para(buf, paras)
                continue
            if s.startswith("SELECTED POEMS"):
                break
            if is_editor_leftover(s):
                continue
            if (
                s.startswith("MY DAYS OF GRACE")
                or s.startswith("[ENTRY INTO HEAVEN")
                or s.startswith("Birthday .")
            ):
                continue
            buf.append(s)
        flush_para(buf, paras)
        if paras:
            chapters.append({
                "chapter": n + 1,
                "title": title,
                "paragraphs": paras,
            })
    return chapters


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = RAW.read_text(encoding="utf-8")
    end_m = re.search(r"\*\*\* END OF THE PROJECT GUTENBERG", raw)
    if not end_m:
        raise SystemExit("Gutenberg end marker missing")
    lines = raw[: end_m.start()].splitlines()

    start = next(
        i for i, l in enumerate(lines)
        if l.strip() == "CHAPTER I" and i + 1 < len(lines)
        and "EARLIEST" in lines[i + 1]
    )
    auto_end = next(i for i, l in enumerate(lines) if l.strip() == "END OF THE AUTOBIOGRAPHY")
    auto_chapters, _ = parse_range(lines, start, auto_end, {"END OF THE AUTOBIOGRAPHY", "EPILOGUE: A VICTIM OF DIVINE LOVE"})
    if len(auto_chapters) != 11:
        raise SystemExit(f"expected 11 autobiography chapters, got {len(auto_chapters)}")
    # Fill remaining stub titles from first sentence
    for c in auto_chapters:
        if c["title"].startswith("Chapter "):
            sent = re.split(r"(?<=[.?!])\s", c["paragraphs"][0], maxsplit=1)[0]
            sent = sent.strip().rstrip(".")
            if 12 <= len(sent) <= 140:
                c["title"] = sent

    counsel_i = next(
        i for i, l in enumerate(lines)
        if l.strip().startswith("COUNSELS AND REMINISCENCES")
        and i > auto_end
    )
    letters_i = next(
        i for i, l in enumerate(lines)
        if i > counsel_i and (
            l.strip().startswith("LETTERS OF SOEUR")
            or l.strip().startswith("LETTERS TO MOTHER")
            or l.strip().startswith("LETTERS TO SISTER")
            or l.strip().startswith("LETTERS TO HER")
        )
    )
    prayers_i = next(
        i for i, l in enumerate(lines)
        if i > counsel_i and l.strip().startswith("PRAYERS OF SOEUR")
    )
    poems_i = next(
        i for i, l in enumerate(lines)
        if i > counsel_i and l.strip().startswith("SELECTED POEMS")
    )

    counsel_chapters = parse_named_sections(
        lines, counsel_i, letters_i,
        [("COUNSELS AND REMINISCENCES", "Counsels and reminiscences")],
    )
    letter_heads = [
        ("LETTERS OF SOEUR", "Letters to Céline"),
        ("LETTERS TO MOTHER AGNES", "Letters to Mother Agnes of Jesus"),
        ("LETTERS TO SISTER MARY", "Letters to Sister Mary of the Sacred Heart"),
        ("LETTERS TO HER COUSIN", "Letters to Marie Guérin"),
        ("LETTERS TO HER BROTHER MISSIONARIES", "Letters to her brother missionaries"),
    ]
    letter_chapters = parse_named_sections(lines, letters_i, prayers_i, letter_heads)
    prayer_heads = [
        ("AN ACT OF OBLATION AS A VICTIM OF DIVINE LOVE", "Act of oblation"),
        ("A MORNING PRAYER", "A morning prayer"),
        ("AN ACT OF CONSECRATION TO THE HOLY FACE", "Consecration to the Holy Face"),
        ("VARIOUS PRAYERS", "Various prayers"),
        ("PRAYER TO THE HOLY CHILD", "Prayer to the Holy Child"),
        ("PRAYER TO THE HOLY FACE", "Prayer to the Holy Face"),
        ("PRAYER TO OBTAIN HUMILITY", "Prayer to obtain humility"),
        ("MOTTO OF THE LITTLE FLOWER", "Motto"),
    ]
    prayer_chapters = parse_named_sections(lines, prayers_i, poems_i, prayer_heads)
    for c in prayer_chapters:
        if c["title"] != "Motto":
            continue
        c["paragraphs"] = [
            p for p in c["paragraphs"]
            if "1873" not in p and "MY DAYS OF GRACE" not in p
        ]

    parts = [
        {"part": 1, "title": "Story of a Soul", "chapters": auto_chapters},
        {"part": 2, "title": "Counsels", "chapters": counsel_chapters},
        {"part": 3, "title": "Letters", "chapters": letter_chapters},
        {"part": 4, "title": "Prayers", "chapters": prayer_chapters},
    ]
    for p in parts:
        if not p["chapters"]:
            raise SystemExit(f"empty part: {p['title']}")
        print(f"{p['title']}: {len(p['chapters'])} chapters, "
              f"{sum(len(c['paragraphs']) for c in p['chapters'])} paras")

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Thomas N. Taylor (1912)",
            "parts": parts,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {dest}")


if __name__ == "__main__":
    main()
