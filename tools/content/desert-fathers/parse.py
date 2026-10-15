#!/usr/bin/env python3
"""Parse Budge, The Paradise or Garden of the Holy Fathers (1907).

Keeps the named edition after Budge's introduction: Life of Anthony,
Palladius, the Rule of Pachomius, Jerome's histories, and the Sayings.
Drops IA fronts, Syriac facsimiles, the scholarly introduction, and indexes.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"
sys.path.insert(0, str(ROOT.parent))
from sermon_ocr import collapse  # noqa: E402

PAGE_RE = re.compile(r"^[ivxlc]+$|^\d{1,3}[a-z]?-?[a-z]?$", re.I)
SAYING_RE = re.compile(r"^(\d+)\.\s+(\S.*)$")
CHAPTER_RE = re.compile(r"^chapter\b", re.I)
INDEX_RE = re.compile(r"^INDEX\b")
ENGLISH = re.compile(
    r"\b(the|and|of|to|in|that|he|was|for|with|his|they|said|"
    r"unto|which|from|this|not|had|him|her|she|who|were|have|"
    r"been|one|man|god|lord|abba|monk|desert|brother|brethren)\b",
    re.I,
)
HEADERISH = re.compile(
    r"^(the paradise|tbe paradise|ttbe paradise|xlhc |xbe |zhe |"
    r"che paradise|the sayings|tbe savings|ttbe savings|"
    r"digitized by|https?://|from the story of|published at london|"
    r"chatto|division$|sectio)",
    re.I,
)
GARBLED = re.compile(
    r"\b(tbe|tfatbers|ibol|parabise|parabtee|xlhc|flbonks|"
    r"jfatbers|hbba|criumpb|ibistor|ipacbom|hpoloos)\b",
    re.I,
)


ABBA_KEEP = {"ot", "ey", "ess"}
ABBA_RE = re.compile(r"\bAbb(\S{0,3})(?!\S)", re.I)


OCR_WORDS = {
    "tbe": "the",
    "tbat": "that",
    "tbey": "they",
    "tbis": "this",
    "tben": "then",
    "tban": "than",
    "tbee": "thee",
    "tbou": "thou",
    "tby": "thy",
    "tbem": "them",
    "tbeir": "their",
    "tbere": "there",
    "tbus": "thus",
    "tbing": "thing",
    "tbings": "things",
    "tlie": "the",
    "witb": "with",
    "wbicb": "which",
    "wbat": "what",
    "wben": "when",
    "wbere": "where",
    "wbile": "while",
    "wbo": "who",
    "wbom": "whom",
    "wbose": "whose",
    "otber": "other",
    "anotber": "another",
}


def _ocr_word(m: re.Match[str]) -> str:
    w = m.group(0)
    key = w.lower()
    if key not in OCR_WORDS:
        return w
    fix = OCR_WORDS[key]
    if w.isupper():
        return fix.upper()
    if w[0].isupper():
        return fix[:1].upper() + fix[1:]
    return fix


def repair_dropcap(text: str) -> str:
    """Restore letters eaten by drop-caps: ND→AND, BBA→ABBA, AN D→AND."""
    text = re.sub(r"\bND\b", "AND", text)
    text = re.sub(r"\bBBA\b", "ABBA", text)
    text = re.sub(r"\bAN\s+D\b", "AND", text)
    text = re.sub(r'\bN["\'.\s]+O\s*W\b', "NOW", text)
    text = re.sub(r"^HERE (was|were)\b", r"THERE \1", text, flags=re.M)
    text = re.sub(r"^HEY used\b", "THEY used", text, flags=re.M)
    text = re.sub(
        r"^OW (therefore|when|on)\b", r"NOW \1", text, flags=re.M | re.I
    )
    return text


def repair_abba(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        if m.group(1).lower() in ABBA_KEEP:
            return m.group(0)
        return "ABBA" if m.group(0).isupper() else "Abba"

    text = ABBA_RE.sub(repl, text)
    text = re.sub(r"\bRabb[d&]\b", "Rabba", text)
    return text


def is_garbled_heading(s: str) -> bool:
    if not s or CHAPTER_RE.match(s):
        return True
    letters = [c for c in s if c.isalpha()]
    if letters:
        ascii_n = sum(1 for c in letters if ord(c) < 128)
        if ascii_n / len(letters) < 0.85:
            return True
    if len(s) < 160 and GARBLED.search(s):
        return True
    if len(s) < 120 and re.search(r"[/©^]", s):
        return True
    return False


def normalize(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = text.replace("\u00a3", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\b[A-Za-z]+\b", _ocr_word, text)
    text = repair_abba(text)
    text = repair_dropcap(text)
    return text.strip()


def is_page(s: str) -> bool:
    return bool(PAGE_RE.fullmatch(s))


def is_header(s: str) -> bool:
    if not s or is_page(s):
        return True
    if CHAPTER_RE.match(s) or SAYING_RE.match(s):
        return False
    if HEADERISH.match(s):
        return True
    if len(s) < 100 and GARBLED.search(s) and len(ENGLISH.findall(s)) < 2:
        return True
    return False


def is_prose(s: str) -> bool:
    if len(s) < 24:
        return False
    if is_header(s):
        return False
    return len(ENGLISH.findall(s)) >= 2 or (s[0].isupper() and s.count(" ") >= 8)


def first_sentence_title(para: str) -> str:
    para = re.sub(r"^[A-Z0-9]{1,4}\.\s+", "", para.strip())
    parts = re.split(r"(?<=[.?!])\s", para)
    for sent in parts:
        sent = sent.strip().rstrip(".")
        if not sent or re.fullmatch(r"\d+", sent):
            continue
        if is_garbled_heading(sent):
            continue
        if sum(c.isalpha() for c in sent) < 12:
            continue
        if 12 <= len(sent) <= 140:
            return sent
        clip = sent[:72].rsplit(" ", 1)[0]
        if clip and sum(c.isalpha() for c in clip) >= 12:
            return clip
    return ""


def title_from(paragraphs: list[str]) -> str:
    for p in paragraphs:
        if is_garbled_heading(p):
            continue
        t = first_sentence_title(p)
        if t:
            return t
    return "A word"


def join_lines(lines: list[str]) -> list[str]:
    """Join hyphenated OCR wraps; drop headers and page numbers.

    Empty lines become paragraph breaks (empty strings in the result).
    """
    out: list[str] = []
    buf = ""
    for raw in lines:
        s = collapse(raw)
        if INDEX_RE.match(s):
            break
        if not s or is_header(s):
            if buf:
                out.append(buf)
                buf = ""
            if not s:
                out.append("")
            continue
        if buf.endswith("-"):
            buf = buf[:-1] + s
            continue
        if buf:
            out.append(buf)
        buf = s
    if buf:
        out.append(buf)
    return out


def paras_from(lines: list[str]) -> list[str]:
    paras: list[str] = []
    cur: list[str] = []

    def flush() -> None:
        nonlocal cur
        if not cur:
            return
        text = normalize(" ".join(cur))
        cur = []
        if text:
            paras.append(text)

    for s in join_lines(lines):
        if not s:
            flush()
            continue
        if SAYING_RE.match(s) or CHAPTER_RE.match(s):
            flush()
            paras.append(s if CHAPTER_RE.match(s) else normalize(s))
            continue
        cur.append(s)
    flush()
    return paras


def split_long(paragraphs: list[str], min_words: int = 700) -> list[list[str]]:
    groups: list[list[str]] = []
    cur: list[str] = []
    n = 0
    for p in paragraphs:
        w = len(p.split())
        if cur and n >= min_words and w > 40:
            groups.append(cur)
            cur = []
            n = 0
        cur.append(p)
        n += w
    if cur:
        groups.append(cur)
    return groups or [[]]


def chapter(n: int, paragraphs: list[str], title: str | None = None) -> dict | None:
    body = [p for p in paragraphs if p and not CHAPTER_RE.match(p) and not is_header(p)]
    body = [
        p
        for p in body
        if (is_prose(p) or SAYING_RE.match(p)) and not is_garbled_heading(p)
    ]
    if not body:
        return None
    words = sum(len(p.split()) for p in body)
    if words < 20:
        return None
    return {
        "chapter": n,
        "title": title or title_from(body),
        "paragraphs": body,
    }


def parse_vol1() -> list[dict]:
    lines = (RAW / "budge_vol01.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if "MARVELLOUS care and the loving urging" in collapse(l)
    )
    palladius = next(
        i for i, l in enumerate(lines)
        if i > start and collapse(l).startswith("PALLADIUS the Bishop to Lausus")
    )
    pachomius = next(
        i for i, l in enumerate(lines)
        if i > palladius
        and ("IRule of ipac" in collapse(l) or "Rule of Pachomius" in collapse(l))
    )
    jerome = next(
        i for i, l in enumerate(lines)
        if i > pachomius and "Jerome" in collapse(l) and "Hpolo" in collapse(l)
    )

    def by_chapter(chunk: list[str], part: int, title: str) -> dict:
        paras = paras_from(chunk)
        chapters: list[dict] = []
        cur: list[str] = []
        for p in paras:
            if CHAPTER_RE.match(p) and cur:
                ch = chapter(len(chapters) + 1, cur)
                if ch:
                    chapters.append(ch)
                cur = []
                continue
            if CHAPTER_RE.match(p):
                continue
            cur.append(p)
        if cur:
            ch = chapter(len(chapters) + 1, cur)
            if ch:
                chapters.append(ch)
        if not chapters:
            raise SystemExit(f"no chapters in {title}")
        return {"part": part, "title": title, "chapters": chapters}

    life_paras = [p for p in paras_from(lines[start:palladius]) if is_prose(p)]
    life_groups = split_long(life_paras, 800)
    life_chapters = []
    for i, g in enumerate(life_groups, 1):
        ch = chapter(i, g)
        if ch:
            life_chapters.append(ch)
    if not life_chapters:
        raise SystemExit("Life of Anthony empty")

    return [
        {"part": 1, "title": "The Life of Saint Anthony", "chapters": life_chapters},
        by_chapter(lines[palladius:pachomius], 2, "The Paradise of Palladius"),
        by_chapter(lines[pachomius:jerome], 3, "The Rule of Pachomius"),
        by_chapter(lines[jerome:], 4, "The Histories of Jerome"),
    ]


def parse_vol2() -> list[dict]:
    lines = (RAW / "budge_vol02.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if collapse(l).startswith("WHEN Abba Arsenius was in the palace")
    )
    paras = paras_from(lines[start:])
    parts: list[dict] = []
    part_title = "Of flight from men"
    chapters: list[dict] = []
    cur: list[str] = []

    def flush_chapter() -> None:
        nonlocal cur
        ch = chapter(len(chapters) + 1, cur)
        if ch:
            chapters.append(ch)
        cur = []

    def flush_part() -> None:
        nonlocal chapters, cur
        flush_chapter()
        if chapters:
            parts.append({
                "part": 4 + len(parts) + 1,
                "title": part_title,
                "chapters": chapters,
            })
        chapters = []

    for p in paras:
        if CHAPTER_RE.match(p):
            flush_part()
            rest = re.sub(r"^chapter\b[^.]*\.?\s*", "", p, flags=re.I)
            guess = first_sentence_title(rest) if is_prose(rest) else ""
            part_title = (
                guess
                if guess and not GARBLED.search(guess) and guess.isascii()
                else f"Sayings {len(parts) + 1}"
            )
            continue
        m = SAYING_RE.match(p)
        if m:
            flush_chapter()
            rest = m.group(2)
            cur = [p if is_prose(p) else rest]
            continue
        cur.append(p)
    flush_part()
    if not parts:
        raise SystemExit("vol2 empty")
    return parts


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    parts = parse_vol1() + parse_vol2()
    n_ch = sum(len(p["chapters"]) for p in parts)
    n_w = sum(
        len(para.split())
        for p in parts
        for c in p["chapters"]
        for para in c["paragraphs"]
    )
    sample = " ".join(
        c["paragraphs"][0] for p in parts for c in p["chapters"][:1]
    ).lower()
    for must in ("anthony", "palladius", "arsenius", "pachomius"):
        if must not in sample and must not in json.dumps(parts).lower():
            raise SystemExit(f"missing {must}")
    out = {"parts": parts}
    (WORK / "chapters.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"desert-fathers parse: {len(parts)} parts, {n_ch} chapters, {n_w:,} words")
    for p in parts:
        w = sum(len(x.split()) for c in p["chapters"] for x in c["paragraphs"])
        print(f"  part {p['part']} {p['title']}: {len(p['chapters'])} ch, {w:,} w")


if __name__ == "__main__":
    main()
