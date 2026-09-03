#!/usr/bin/env python3
"""Parse Faber 1863 True Devotion (Burns & Lambert).

Starts at Montfort's own introduction. Strips Faber's preface, the French
editor's preface, Google watermarks, running heads, and page numbers.
Joins hyphenated line-breaks and collapses doubled spaces. The formula of
consecration is the last chapter. No 33-day program.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
from ocr_clean import clean_ocr_english  # noqa: E402
RAW = ROOT / "raw" / "ia_faber_1863.txt"
WORK = ROOT / "work"

GOD_OCR = re.compile(
    r"\b(?:Gk\)d|Qt\)d|Glt\)d|Gtod|Gted|Qod|Otd|Grod)\b", re.I
)


def join_hyphens(text: str) -> str:
    return re.sub(r"-\n\s*", "", text)


def collapse_spaces(text: str) -> str:
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text


def fix_god(text: str) -> str:
    return GOD_OCR.sub("God", text)


def is_watermark(s: str) -> bool:
    t = re.sub(r"\s+", " ", s).strip()
    if re.match(r"^Digitized by", t, re.I):
        return True
    if t.lower() in {"google", "l.ooqle", "l.oogle"}:
        return True
    if t.lower().startswith("digitized"):
        return True
    return False


def is_running_head(s: str) -> bool:
    t = re.sub(r"\s+", " ", s).strip(" .")
    if not t:
        return False
    if re.fullmatch(r"\d{1,3}", t):
        return True
    if re.fullmatch(r"[A-Za-z|\\/.,:;]{1,2}", t):
        return True
    u = t.upper()
    heads = {
        "TRUE DEVOTION",
        "TRUE DEVOTION TO",
        "TBUE DEVOTION TO",
        "TBUE DEVOTION",
        "TO",
        "THE BLESSED VIRGIN",
        "THE BLESSED YIBGIN",
        "THE BLESSED YIRGIN",
        "THE BLBSSE& VIRGIN",
        "THE BLESSED VIRGIN.",
        "INTRODUCTION",
        "PREFACE",
        "CONTENTS",
        "PAET I",
    }
    if u in heads:
        return True
    if re.match(
        r"^(THE BLESSED (VIRGIN|YIBGIN|YIRGIN|YIBQIN)\.?|"
        r"(TRUE|TBUE) DEVOTION( TO)?)\s*\d*$",
        u,
    ):
        return True
    if re.match(r"^\d+\s+(TRUE|TBUE) DEVOTION", u):
        return True
    return False


def is_ads(s: str) -> bool:
    t = s.strip()
    if t.startswith("I. Life of Henry Dorie"):
        return True
    if t.lower().startswith("burns, oates"):
        return True
    if t == "THE END.":
        return True
    return False


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = GOD_OCR.sub("God", text)
    text = text.replace("felse", "false").replace("Felse", "False")
    text = text.replace("Je3us", "Jesus")
    text = text.replace("PEREECT", "PERFECT")
    text = re.sub(r"\bHo has\b", "He has", text)
    text = text.replace("\xa0", " ")
    text = text.replace("\u2010", "-").replace("\u2011", "-")
    text = re.sub(r"-\s+(?=[a-z])", "", text)
    text = re.sub(r"(?<=\s)0(?=\s)", "O", text)
    text = re.sub(r"^0 ", "O ", text)
    text = text.replace("Wisdom I ", "Wisdom! ")
    text = text.replace("conniption of morals", "corruption of morals")
    text = text.replace("Vo turn", "Votum")
    text = text.replace("Prcedpuum", "Praecipuum")
    text = text.replace("f admits", "facimus")
    text = text.replace("per petuum", "perpetuum")
    text = re.sub(r"(?<=[.!?] )u ", '" ', text)
    text = re.sub(r"[ \t]+", " ", text)
    return clean_ocr_english(text)


def merge_wrapped(paras: list[str]) -> list[str]:
    """Join OCR page-wraps: lowercase (or hyphen) continuations."""
    out: list[str] = []
    for p in paras:
        p = p.strip()
        if not p:
            continue
        if out and (p[0].islower() or out[-1].endswith("-")):
            prev = out[-1]
            if prev.endswith("-"):
                out[-1] = normalize_ws(prev[:-1] + p)
            else:
                out[-1] = normalize_ws(prev + " " + p)
        else:
            out.append(p)
    return out


def flush_para(buf: list[str], dest: list[str]) -> list[str]:
    if not buf:
        return buf
    text = normalize_ws(" ".join(buf))
    text = re.sub(r"^\[The translator thinks it well[^\]]*\]\s*", "", text)
    if text and not text.startswith("* "):
        dest.append(text)
    return []


HEADING_PATTERNS: list[tuple[re.Pattern[str], int, str, str]] = [
    # (regex, part, part_title, chapter_title)
    (
        re.compile(r"^I\.\s+EXCELLENCE AND NECESSITY OF DEVOTION", re.I),
        2,
        "On Devotion to Our Blessed Lady in General",
        "Excellence and necessity of devotion to our Blessed Lady",
    ),
    (
        re.compile(r"^II\.\s+DISCERNMENT OF THE TRUE DEVOTION", re.I),
        2,
        "On Devotion to Our Blessed Lady in General",
        "Discernment of the true devotion to our Blessed Lady",
    ),
    (
        re.compile(r"^(?:1\.|L)\s+On False Devotions", re.I),
        2,
        "On Devotion to Our Blessed Lady in General",
        "On false devotions to our Lady",
    ),
    (
        re.compile(r"^2\.\s+On the Characters of True Devotion", re.I),
        2,
        "On Devotion to Our Blessed Lady in General",
        "On the characters of true devotion to our Blessed Lady",
    ),
    (
        re.compile(r"^PART\s+II\.?\s*$", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "Preliminary observations",
    ),
    (
        re.compile(r"^I\.\s+IN WHAT CONSISTS THE PERFECT CONSECRA", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "In what consists the perfect consecration to Jesus by Mary",
    ),
    (
        re.compile(r"^II\.\s+THE MOTIVES OF THIS PERFECT CONSECRATION", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "The motives of this perfect consecration",
    ),
    (
        re.compile(r"^III\.\s+THE WONDERFUL EFFECTS", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "The wonderful effects of this devotion",
    ),
    (
        re.compile(r"^IV\.\s+PARTICULAR PRACTICES OF THIS", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "Particular practices of this devotion",
    ),
    (
        re.compile(r"^MANNER OF PRACTISING THIS DEVOTION", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "Manner of practising this devotion at Communion",
    ),
    (
        re.compile(r"^CONSECRATION O[PF] OURSELVES TO JESUS CHRIST", re.I),
        3,
        "The Perfect Consecration to Jesus by Mary",
        "Consecration of ourselves to Jesus Christ by the hands of Mary",
    ),
]


def heading_match(s: str) -> tuple[int, str, str] | None:
    for rx, part, ptitle, ctitle in HEADING_PATTERNS:
        if rx.match(s):
            return part, ptitle, ctitle
    return None


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = RAW.read_text(encoding="utf-8", errors="replace")
    raw = join_hyphens(raw)
    raw = collapse_spaces(raw)
    raw = fix_god(raw)
    lines = raw.splitlines()

    start = next(
        i for i, l in enumerate(lines)
        if "It is by the most holy Virgin Mary that Jesus" in re.sub(r"\s+", " ", l)
    )

    parts_by_id: dict[int, dict] = {
        1: {"part": 1, "title": "Introduction", "chapters": []},
        2: {
            "part": 2,
            "title": "On Devotion to Our Blessed Lady in General",
            "chapters": [],
        },
        3: {
            "part": 3,
            "title": "The Perfect Consecration to Jesus by Mary",
            "chapters": [],
        },
    }
    # Introduction is already open.
    cur_part = parts_by_id[1]
    cur_ch: dict = {
        "chapter": 1,
        "title": "It is by Mary that He has to reign in the world",
        "paragraphs": [],
    }
    cur_part["chapters"].append(cur_ch)
    para: list[str] = []
    skip_heading_rest = False

    def open_chapter(part_id: int, ptitle: str, ctitle: str) -> None:
        nonlocal cur_part, cur_ch, para, skip_heading_rest
        para = flush_para(para, cur_ch["paragraphs"])
        cur_part = parts_by_id[part_id]
        cur_part["title"] = ptitle
        n = len(cur_part["chapters"]) + 1
        cur_ch = {"chapter": n, "title": ctitle, "paragraphs": []}
        cur_part["chapters"].append(cur_ch)
        skip_heading_rest = True

    for i in range(start, len(lines)):
        s = lines[i].strip()
        if is_ads(s):
            break
        if is_watermark(s) or is_running_head(s):
            para = flush_para(para, cur_ch["paragraphs"])
            continue
        if not s:
            para = flush_para(para, cur_ch["paragraphs"])
            continue
        # Title-page repeat between intro and Part I.
        if re.match(r"^(TRUE DEVOTION|PAET I\.?|PART I\.?)$", s, re.I):
            para = flush_para(para, cur_ch["paragraphs"])
            skip_heading_rest = True
            continue
        if re.match(r"^ON DEVOTION TO OUR BLESSED LADY IN GENERAL", s, re.I):
            para = flush_para(para, cur_ch["paragraphs"])
            skip_heading_rest = True
            continue
        if re.match(r"^ON THE MOST EXCELLENT DEVOTION", s, re.I):
            para = flush_para(para, cur_ch["paragraphs"])
            skip_heading_rest = True
            continue
        hit = heading_match(s)
        if hit:
            open_chapter(*hit)
            continue
        if skip_heading_rest:
            # Wrapped ALL-CAPS remainder of a heading.
            letters = sum(c.isalpha() for c in s)
            caps = sum(c.isupper() for c in s if c.isalpha())
            if letters and caps / letters > 0.7:
                continue
            skip_heading_rest = False
        if s.startswith("INTRODUCTION"):
            para = flush_para(para, cur_ch["paragraphs"])
            continue
        # Drop Faber's asterisk notes.
        if s.startswith("*") and ("F. W. F" in s or "Boudon" in s):
            para = flush_para(para, cur_ch["paragraphs"])
            continue
        para.append(s)

    flush_para(para, cur_ch["paragraphs"])

    parts = []
    for pid in (1, 2, 3):
        p = parts_by_id[pid]
        p["chapters"] = [c for c in p["chapters"] if c["paragraphs"]]
        for n, c in enumerate(p["chapters"], 1):
            c["chapter"] = n
            c["paragraphs"] = merge_wrapped(c["paragraphs"])
        if not p["chapters"]:
            raise SystemExit(f"empty part: {p['title']}")
        parts.append(p)
        print(
            f"{p['title']}: {len(p['chapters'])} chapters, "
            f"{sum(len(c['paragraphs']) for c in p['chapters'])} paras"
        )

    first = parts[0]["chapters"][0]["paragraphs"][0]
    if "It is by the most holy Virgin Mary" not in first:
        raise SystemExit(f"Montfort opening missing: {first[:160]}")
    last_titles = [c["title"].lower() for c in parts[-1]["chapters"]]
    if not any("consecration of ourselves" in t for t in last_titles):
        raise SystemExit("formula of consecration missing")

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Frederick William Faber (Burns & Lambert, 1863)",
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
    print("entry-1 start:", first[:220])


if __name__ == "__main__":
    main()
