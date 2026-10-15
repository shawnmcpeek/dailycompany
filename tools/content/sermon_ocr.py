#!/usr/bin/env python3
"""Shared OCR tidy for nineteenth-century sermon scans."""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ocr_clean import clean_ocr_english  # noqa: E402

ROMAN_VALS = [
    ("M", 1000), ("CM", 900), ("D", 500), ("CD", 400), ("C", 100),
    ("XC", 90), ("L", 50), ("XL", 40), ("X", 10), ("IX", 9), ("V", 5),
    ("IV", 4), ("I", 1),
]
ROMAN_FIX = {
    "IIL": "III", "II1": "III", "I11": "III", "111": "III",
    "VIL": "VII", "VL": "VI", "V1": "VI",
    "XIL": "XII", "XTT": "XII", "XTI": "XII", "XIT": "XII",
    "XXL": "XXI", "XX1": "XXI", "XVL": "XVI", "XV1": "XVI",
    "XVIIL": "XVIII", "XXIIL": "XXIII", "XXII1": "XXIII",
    "IIL.": "III", "SEEMON": "SERMON",
}

HEAD_RE = re.compile(
    r"^(?:SERMON|SEEMON|SBRMON|SERM0N|SERMOX|8ERMON|SBRMOX|8ERM0N|"
    r"3ERMON|5ERMON|8BRMON)\s+"
    r"([IVXLCDM1Il]+|\d+)\s*[.,:]?\s*(.*)$",
    re.I,
)
BARE_SERMON = re.compile(
    r"^(?:SERMON|SEEMON|SBRMON|SERM0N|SERMOX|8ERMON)\s*[.]?$",
    re.I,
)
PAGE_ONLY = re.compile(r"^\d{1,4}[a-zA-Z]?$")
DIGITIZED = re.compile(
    r"digitized by|google books|^google$|v\^?roo?qie|archive\.org|"
    r"project gutenberg|this ebook is for the use|www\.gutenberg|"
    r"produced by|e-text prepared|start of (the )?project|"
    r"end of (the )?project|end of this project gutenberg|"
    r"catholic standard library|thomas baker,|soho square",
    re.I,
)
RUNNING = re.compile(
    r"^(sermons on the song|sermons for the|parochial and plain|"
    r"life and works of|contents\.?|page|table of contents)$",
    re.I,
)
INLINE_NOTE = re.compile(r"\[\d{1,4}\]")
FOOTNOTE_LINE = re.compile(r"^\[?\d{1,3}\]\s+\S")
SCRIPTURE = re.compile(
    r"(Gen\.|Exod\.|Lev\.|Num\.|Deut\.|Ps\.|Isa\.|Jer\.|Ezek\.|"
    r"Matt\.|Luke|John|Acts|Rom\.|Cor\.|Gal\.|Eph\.|Phil\.|Col\.|"
    r"Thess\.|Tim\.|Heb\.|Pet\.|Apoc\.|Cant\.|Eccles\.|Wisd\.)",
    re.I,
)


def collapse(line: str) -> str:
    line = line.replace("\u00a0", " ").replace("\ufeff", "")
    return re.sub(r"[ \t]+", " ", line).strip()


def roman_to_int(text: str) -> int | None:
    raw = collapse(text).upper().replace(".", "").replace(" ", "")
    raw = raw.replace("1", "I").replace("L", "L")
    raw = ROMAN_FIX.get(raw, raw)
    if raw.isdigit():
        n = int(raw)
        return n if 1 <= n <= 200 else None
    n, s = 0, raw
    for p, v in ROMAN_VALS:
        while s.startswith(p):
            n += v
            s = s[len(p):]
    if s or n < 1 or n > 200:
        return None
    return n


def is_chrome(line: str) -> bool:
    s = collapse(line)
    if not s:
        return False
    if PAGE_ONLY.match(s):
        return True
    if DIGITIZED.search(s):
        return True
    if RUNNING.match(s):
        return True
    if re.match(r"^https?://", s, re.I):
        return True
    if s.lower() in {"advertisements.", "advertisement.", "index.", "errata."}:
        return True
    if re.match(r"^errata", s, re.I) and len(s) < 80:
        return True
    # Running head: "Future Blessedness. 7"
    if re.match(r"^[A-Z][A-Za-z'’\- ]{2,40}\.\s+\d{1,3}$", s) and " the " not in f" {s.lower()} ":
        return True
    return False


def parse_heading(line: str) -> tuple[int, str] | None:
    s = collapse(line)
    if not s or s.upper().startswith("SERMONS"):
        return None
    m = HEAD_RE.match(s)
    if not m:
        return None
    num = roman_to_int(m.group(1))
    if num is None:
        return None
    rest = collapse(m.group(2) or "")
    rest = re.sub(r"^[\d\s.,;:-]+", "", rest).strip()
    if rest.upper().startswith("ON THE SONG OF") and len(s) < 40:
        return None
    return num, rest


def first_sentence_title(para: str) -> str:
    sent = re.split(r"(?<=[.?!])\s", para.strip(), maxsplit=1)[0]
    sent = sent.strip().rstrip(".")
    if 12 <= len(sent) <= 140:
        return sent
    clip = sent[:72].rsplit(" ", 1)[0]
    return clip or sent or "Sermon"


def title_case(text: str) -> str:
    text = collapse(text).rstrip(".")
    if not text:
        return "Sermon"
    letters = sum(c.isalpha() for c in text)
    caps = sum(c.isupper() for c in text if c.isalpha())
    if letters and caps / letters > 0.55:
        small = {"of", "the", "and", "in", "on", "a", "an", "for", "to", "by", "with", "from"}
        words = text.lower().split()
        out = []
        for i, w in enumerate(words):
            out.append(w if i and w in small else w[:1].upper() + w[1:])
        return " ".join(out)
    return text[0].upper() + text[1:] if text[0].islower() else text


def split_long(text: str, target: int = 90) -> list[str]:
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


def join_hyphens(lines: list[str]) -> list[str]:
    out: list[str] = []
    i = 0
    while i < len(lines):
        s = lines[i]
        if s.endswith("-") and i + 1 < len(lines) and lines[i + 1][:1].islower():
            out.append(s[:-1] + lines[i + 1])
            i += 2
            continue
        out.append(s)
        i += 1
    return out


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = collapse(" ".join(buf))
    text = INLINE_NOTE.sub("", text)
    text = re.sub(r"[ \t]+", " ", text).strip()
    if text:
        text = clean_ocr_english(text)
        dest.extend(split_long(text))
    return []


def body_paragraphs(raw_lines: list[str]) -> list[str]:
    cleaned: list[str] = []
    for line in raw_lines:
        s = collapse(line)
        if not s or is_chrome(line) or FOOTNOTE_LINE.match(s):
            if s == "":
                cleaned.append("")
            continue
        if s in {"SERMONS.", "SERMONS,"}:
            continue
        cleaned.append(s)
    cleaned = join_hyphens(cleaned)
    dest: list[str] = []
    buf: list[str] = []
    for s in cleaned:
        if not s:
            buf = flush_para(buf, dest)
            continue
        buf.append(s)
    flush_para(buf, dest)
    return [p for p in dest if len(re.findall(r"\S+", p)) >= 4]


def find_headings(lines: list[str], start: int = 0, end: int | None = None) -> list[tuple[int, int, str]]:
    stop = len(lines) if end is None else end
    hits: list[tuple[int, int, str]] = []
    i = start
    while i < stop:
        parsed = parse_heading(lines[i])
        if parsed:
            hits.append((i, parsed[0], parsed[1]))
            i += 1
            continue
        if BARE_SERMON.match(collapse(lines[i])) and i + 1 < stop:
            nxt = collapse(lines[i + 1])
            num = roman_to_int(nxt.rstrip(".,:"))
            rest = ""
            if num is None:
                m = re.match(
                    r"^([IVXLCDM1Il]+|\d+)\s*[.,:]?\s*(.*)$",
                    nxt,
                )
                if m:
                    num = roman_to_int(m.group(1))
                    rest = collapse(m.group(2) or "")
            if num is not None:
                hits.append((i, num, rest))
                i += 2
                continue
        i += 1
    return hits


def body_start_index(lines: list[str]) -> int:
    """First SERMON I whose following block is real prose, not a TOC stub."""
    heads = find_headings(lines)
    ones = [h for h in heads if h[1] == 1]
    for i, (idx, _n, _t) in enumerate(ones):
        nxt = heads[heads.index((idx, 1, _t)) + 1][0] if heads.index((idx, 1, _t)) + 1 < len(heads) else min(len(lines), idx + 400)
        words = len(re.findall(r"\S+", " ".join(collapse(l) for l in lines[idx:nxt])))
        if words >= 350:
            return idx
    return ones[-1][0] if ones else 0


def stop_index(lines: list[str], start: int) -> int:
    for i in range(start + 80, len(lines)):
        s = collapse(lines[i])
        low = s.lower()
        if "project gutenberg" in low:
            return i
        if low.startswith("end of vol"):
            return i
        if "please read this before you distribute" in low:
            return i
        if re.match(r"^index(\s+to)?\b", low) and len(s) < 40:
            return i
        if re.match(r"^errata", low) and len(s) < 80:
            return i
        if re.match(r"^advertisements?\.?$", low):
            return i
        if "sermons preached before the university" in low:
            return i
    return len(lines)


def sermons_as_chapters(lines: list[str], *, start: int | None = None) -> list[dict]:
    if start is None:
        start = body_start_index(lines)
    end = stop_index(lines, start)
    heads = find_headings(lines, start, end)
    if not heads:
        raise SystemExit("no sermon headings found")
    chapters: list[dict] = []
    for i, (idx, num, rest) in enumerate(heads):
        nxt = heads[i + 1][0] if i + 1 < len(heads) else end
        block = lines[idx + 1:nxt]
        title = title_case(rest) if rest and len(rest) > 3 else ""
        # Title may sit on the next few short lines.
        if not title:
            taken = 0
            title_parts: list[str] = []
            for line in block:
                s = collapse(line)
                if not s or is_chrome(line):
                    if title_parts:
                        break
                    continue
                if SCRIPTURE.search(s) and taken >= 1:
                    break
                if len(s) > 90 and taken >= 1:
                    break
                letters = sum(c.isalpha() for c in s)
                if letters and len(s) < 90:
                    title_parts.append(s)
                    taken += 1
                    if taken >= 3:
                        break
                    continue
                break
            if title_parts:
                title = title_case(" ".join(title_parts))
                # Drop consumed title lines from the body.
                consumed = 0
                skip = 0
                for line in block:
                    s = collapse(line)
                    if not s or is_chrome(line):
                        skip += 1
                        continue
                    if consumed < len(title_parts) and collapse(title_parts[consumed]) == s:
                        consumed += 1
                        skip += 1
                        continue
                    break
                block = block[skip:]
        paras = body_paragraphs(block)
        if not paras:
            continue
        if not title or re.match(r"^sermon\s+\d+$", title, re.I):
            title = first_sentence_title(paras[0])
        chapters.append({"chapter": num, "title": title, "paragraphs": paras})
    # Sequential chapter numbers; keep first-seen titles.
    for n, c in enumerate(chapters, 1):
        c["chapter"] = n
    return chapters
