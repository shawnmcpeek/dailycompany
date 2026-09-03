#!/usr/bin/env python3
"""Parse O'Conor Autobiography and Mullan Spiritual Exercises.

Writes:
  tools/content/ignatius/work/chapters.json
  tools/content/ignatius/work/rules.json
  tools/content/ignatius/work/exercises_units.json
  tools/content/ignatius/work/prayers.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8,
}

ORDINAL_RULE = re.compile(
    r"^(First|Second|Third|Fourth|Fifth|Sixth|Seventh|Eighth|Ninth|Tenth|"
    r"Eleventh|Twelfth|Thirteenth|Fourteenth)\s+Rule\."
)
ORDINAL_NUM = {
    "First": 1, "Second": 2, "Third": 3, "Fourth": 4, "Fifth": 5,
    "Sixth": 6, "Seventh": 7, "Eighth": 8, "Ninth": 9, "Tenth": 10,
    "Eleventh": 11, "Twelfth": 12, "Thirteenth": 13, "Fourteenth": 14,
}
CHAPTER_RE = re.compile(r"^CHAPTER ([IVX]+)$")
RULE_LINE_RE = re.compile(r"^[_—–\-]{5,}$")
FOOTNOTE_START_RE = re.compile(r"^\[\d+\]")
PAGE_REF_RE = re.compile(r"\(\s*[Pp]\.?\s*\d+\s*\)")
# Translator footnotes are [n]; verse citations sit after a chapter number
# ("Chapter 16 [9]") and must be kept.
INLINE_NOTE_RE = re.compile(r"(?<!\d )\[\d+\]")
IHS_LINE_RE = re.compile(r"^I\.?H\.?S\.?$", re.I)
IHS_TOKEN_RE = re.compile(r"\bI\.H\.S\.?\b|\bIHS\b")


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def keyify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9 ]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def title_case(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip(" .")
    if not text:
        return ""
    small = {
        "of", "the", "a", "an", "and", "to", "for", "in", "on", "at", "by",
        "or", "as", "from", "with", "into", "our",
    }
    parts = re.split(r"(--)", text)
    out: list[str] = []
    for part in parts:
        if part == "--":
            out.append(" — ")
            continue
        words_ = part.split()
        built = []
        for i, w in enumerate(words_):
            low = w.lower()
            if i > 0 and low in small:
                built.append(low)
            elif w.isupper() or (w[:1].islower() and i == 0):
                built.append(w[:1].upper() + w[1:].lower())
            else:
                built.append(w[:1].upper() + w[1:] if w[:1].islower() else w)
        out.append(" ".join(built))
    return re.sub(r"\s+", " ", "".join(out)).strip(" —")


def is_heading_line(s: str) -> bool:
    if not s or len(s) > 140:
        return False
    letters = [c for c in s if c.isalpha()]
    if len(letters) < 3:
        return False
    caps = sum(c.isupper() for c in letters)
    return caps / len(letters) >= 0.82


def is_chrome_line(s: str) -> bool:
    if not s:
        return False
    if RULE_LINE_RE.match(s) or s.startswith("_____"):
        return True
    if IHS_LINE_RE.match(s):
        return True
    if s.startswith("This document is from the C"):
        return True
    if "ccel.org" in s.lower() or s.startswith("file:///"):
        return True
    if "PROJECT GUTENBERG" in s.upper():
        return True
    if s.startswith("http://") or s.startswith("https://"):
        return True
    if s.startswith("[Illustration"):
        return True
    if s in {"G", "G-------"}:
        return True
    return False


def clean_prose(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = re.sub(r"_([^_]+)_", r"\1", text)
    text = PAGE_REF_RE.sub("", text)
    text = INLINE_NOTE_RE.sub("", text)
    text = IHS_TOKEN_RE.sub("", text)
    text = re.sub(r"\(\s*;", "(", text)
    text = re.sub(r"\(\s*\)", "", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s+,", ",", text)
    text = re.sub(r"\s+\.", ".", text)
    text = re.sub(r" +;", ";", text)
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)
    text = re.sub(r"^;\s*", "", text)
    text = re.sub(r"\blbidem\b", "Ibidem", text)
    text = re.sub(r"\bLbidem\b", "Ibidem", text)
    return text.strip()


def join_heading_run(paras: list[str], i: int) -> tuple[str, int]:
    """Join consecutive all-caps heading paras into one title; return (title, next_i)."""
    parts = [paras[i]]
    j = i + 1
    while j < len(paras) and is_heading_line(paras[j]) and len(paras[j]) < 90:
        parts.append(paras[j])
        j += 1
    return clean_prose(" ".join(parts)), j


def find_para(paras: list[str], needle: str, start: int = 0) -> int:
    n = keyify(needle)
    for i in range(start, len(paras)):
        if keyify(paras[i]) == n:
            return i
    return -1


def find_para_contains(paras: list[str], needle: str, start: int = 0) -> int:
    n = keyify(needle)
    for i in range(start, len(paras)):
        if n in keyify(paras[i]) and is_heading_line(paras[i]):
            return i
    return -1


def find_starts(paras: list[str], needle: str, start: int = 0) -> int:
    n = keyify(needle)
    for i in range(start, len(paras)):
        if keyify(paras[i]).startswith(n):
            return i
    return -1


def slice_body(paras: list[str], start: int, end: int, skip_headings: int = 1) -> list[str]:
    """Take paras[start:end], skipping the first skip_headings heading paras."""
    i = start
    skipped = 0
    while i < end and skipped < skip_headings and is_heading_line(paras[i]):
        _, nxt = join_heading_run(paras, i)
        skipped += 1
        i = nxt
    body = [p for p in paras[i:end] if p]
    # Drop trailing heading-only leftovers.
    return body


def unit(title: str, paras: list[str], *, part: int, repetition: bool = False) -> dict:
    text = "\n\n".join(p for p in paras if p)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    if not text:
        raise SystemExit(f"empty unit: {title}")
    return {
        "title": title,
        "part": part,
        "isRepetition": repetition,
        "textEn": text,
        "wordCount": words(text),
    }


# ---------------------------------------------------------------------------
# Autobiography
# ---------------------------------------------------------------------------

def parse_autobiography() -> list[dict]:
    raw = (RAW / "pg24534_oconor.txt").read_text(encoding="utf-8")
    end_m = re.search(r"\*\*\* END OF THE PROJECT GUTENBERG", raw)
    if not end_m:
        raise SystemExit("Gutenberg end marker missing")
    lines = raw[: end_m.start()].splitlines()

    start = None
    for i, line in enumerate(lines):
        if line.strip() != "CHAPTER I":
            continue
        nxt = ""
        for j in range(i + 1, min(i + 6, len(lines))):
            if lines[j].strip():
                nxt = lines[j].strip()
                break
        if "MILITARY" in nxt.upper():
            start = i
    if start is None:
        raise SystemExit("CHAPTER I body start not found")

    end = None
    for i in range(start + 1, len(lines)):
        if lines[i].strip() == "APPENDIX":
            end = i
            break
    if end is None:
        raise SystemExit("APPENDIX end of autobiography not found")

    chapters: list[dict] = []
    cur: dict | None = None
    para: list[str] = []
    collecting_title = False
    title_buf: list[str] = []

    def flush() -> None:
        nonlocal para
        if cur is None or not para:
            para = []
            return
        text = clean_prose(" ".join(para))
        para = []
        if not text or text.startswith("[Illustration"):
            return
        cur["paragraphs"].append(text)

    i = start
    while i < end:
        s = lines[i].strip()
        if is_chrome_line(s) or s.startswith("[Illustration"):
            flush()
            # Skip wrapped illustration caption.
            if s.startswith("[Illustration") and "]" not in s:
                i += 1
                while i < end and "]" not in lines[i]:
                    i += 1
            i += 1
            continue
        m = CHAPTER_RE.match(s)
        if m:
            flush()
            collecting_title = True
            title_buf = []
            cur = {
                "chapter": ROMAN[m.group(1)],
                "title": f"Chapter {ROMAN[m.group(1)]}",
                "paragraphs": [],
            }
            chapters.append(cur)
            i += 1
            continue
        if not s:
            if collecting_title and title_buf and cur is not None:
                cur["title"] = title_case(" ".join(title_buf))
                collecting_title = False
                title_buf = []
            else:
                flush()
            i += 1
            continue
        if collecting_title:
            title_buf.append(s)
            i += 1
            continue
        if cur is None:
            i += 1
            continue
        para.append(s)
        i += 1
    flush()

    chapters = [c for c in chapters if c["paragraphs"]]
    if len(chapters) != 8:
        raise SystemExit(f"expected 8 autobiography chapters, got {len(chapters)}")
    if not chapters[0]["paragraphs"][0].startswith("Up to his twenty-sixth year"):
        raise SystemExit("CHAPTER I does not start at the twenty-sixth year")
    return chapters


# ---------------------------------------------------------------------------
# Mullan
# ---------------------------------------------------------------------------

def mullan_body_lines() -> list[str]:
    raw = (RAW / "ccel_mullan.txt").read_text(encoding="utf-8")
    lines = raw.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip() == "ANNOTATIONS":
            start = i
            break
    if start is None:
        raise SystemExit("ANNOTATIONS heading missing")
    end = None
    for i in range(start + 1, len(lines)):
        if lines[i].strip() == "GENERAL INDEX":
            end = i
            break
    if end is None:
        raise SystemExit("GENERAL INDEX missing")
    return lines[start:end]


def mullan_paras() -> list[str]:
    return paras_from_lines(mullan_body_lines(), 0, None)  # type: ignore[arg-type]


def paras_from_lines(lines: list[str], start: int, end: int | None) -> list[str]:
    if end is None:
        end = len(lines)
    out: list[str] = []
    buf: list[str] = []
    skipping_fn = False

    def flush() -> None:
        nonlocal buf, skipping_fn
        if skipping_fn:
            buf = []
            skipping_fn = False
            return
        if not buf:
            return
        text = clean_prose(" ".join(buf))
        buf = []
        if not text or len(text) < 2:
            return
        if text in {"G"} or re.fullmatch(r"G[-—–]*", text):
            return
        if IHS_LINE_RE.match(text):
            return
        out.append(text)

    i = start
    while i < end:
        s = lines[i].strip()
        if is_chrome_line(s):
            flush()
            i += 1
            continue
        if not s:
            flush()
            i += 1
            continue
        if not buf and FOOTNOTE_START_RE.match(s):
            skipping_fn = True
            i += 1
            continue
        if skipping_fn:
            i += 1
            continue
        buf.append(s)
        i += 1
    flush()
    return out


def parse_rules(paras: list[str]) -> dict:
    i1 = find_para_contains(paras, "FOR PERCEIVING AND KNOWING IN SOME MANNER")
    if i1 < 0:
        i1 = find_para_contains(paras, "PERCEIVING AND KNOWING IN SOME MANNER")
    i2 = find_para_contains(paras, "RULES FOR THE SAME EFFECT WITH GREATER DISCERNMENT")
    i3 = find_para_contains(paras, "IN THE MINISTRY OF DISTRIBUTING ALMS")
    if i1 < 0 or i2 < 0 or i3 < 0:
        raise SystemExit(f"discernment rule headings missing: {i1} {i2} {i3}")

    def split_set(block: list[str], week: int, expect: int) -> list[dict]:
        chapters: list[dict] = []
        cur: dict | None = None
        body: list[str] = []
        for p in block:
            m = ORDINAL_RULE.match(p)
            if m:
                if cur is not None:
                    cur["textEn"] = "\n\n".join(body).strip()
                    if not cur["textEn"]:
                        raise SystemExit(f"empty rule {cur['title']}")
                    chapters.append(cur)
                num = ORDINAL_NUM[m.group(1)]
                title = f"{m.group(1)} Rule"
                # Keep Ignatius's own subject line when he names one.
                sub = re.match(
                    r"^(?:First|Second|Third|Fourth|Fifth|Sixth|Seventh|"
                    r"Eighth|Ninth|Tenth|Eleventh|Twelfth|Thirteenth|"
                    r"Fourteenth)\s+Rule\.\s+The\s+\w+:\s+Of\s+([^.]{4,80})",
                    p,
                )
                if sub:
                    title = f"{m.group(1)} Rule — Of {sub.group(1).strip()}"
                cur = {"chapter": num, "week": week, "title": title}
                body = [p]
                continue
            if cur is not None and not is_heading_line(p):
                body.append(p)
        if cur is not None:
            cur["textEn"] = "\n\n".join(body).strip()
            chapters.append(cur)
        if len(chapters) != expect:
            raise SystemExit(
                f"week {week}: expected {expect} rules, got {len(chapters)} "
                f"{[c['title'] for c in chapters]}"
            )
        for n, c in enumerate(chapters, 1):
            if c["chapter"] != n:
                raise SystemExit(f"week {week} rule numbering: {c}")
        return chapters

    week1 = split_set(paras[i1:i2], 1, 14)
    week2 = split_set(paras[i2:i3], 2, 8)
    chapters = []
    for c in week1 + week2:
        chapters.append({
            "chapter": len(chapters) + 1,
            "week": c["week"],
            "title": c["title"],
            "textEn": c["textEn"],
        })
    # Global 1..22; keep week-local ordinal in the title already.
    # Re-number continuously as specified (chapter 1..22).
    return {
        "title": (
            "Rules for perceiving and knowing in some manner the different "
            "movements which are caused in the soul"
        ),
        "translator": "Elder Mullan SJ (1914)",
        "chapters": chapters,
    }


def parse_mysteries(paras: list[str]) -> list[dict]:
    start = find_para_contains(paras, "THE MYSTERIES OF THE LIFE OF CHRIST")
    end = find_para(paras, "RULES", start + 1)
    if end < 0:
        end = find_para_contains(paras, "FOR PERCEIVING AND KNOWING")
    if start < 0 or end < 0:
        raise SystemExit(f"mysteries block missing: {start} {end}")
    block = paras[start + 1:end]
    # Drop the note about parentheses / Gospel words — keep it on the first
    # mystery by attaching if it is not a heading.
    items: list[dict] = []
    i = 0
    preamble: list[str] = []
    while i < len(block):
        p = block[i]
        if is_heading_line(p) and (
            p.upper().startswith("OF ")
            or p.upper().startswith("PALM ")
            or "APPARITION" in p.upper()
            or p.upper().startswith("THE SEVENTH")
            or p.upper().startswith("THE MYSTERIES")
        ):
            title, j = join_heading_run(block, i)
            body: list[str] = []
            k = j
            while k < len(block):
                q = block[k]
                if is_heading_line(q) and (
                    q.upper().startswith("OF ")
                    or q.upper().startswith("PALM ")
                    or "APPARITION" in q.upper()
                    or q.upper().startswith("THE SEVENTH")
                ):
                    break
                body.append(q)
                k += 1
            if not body:
                i = k
                continue
            items.append({"title": title_case(title), "key": keyify(title), "paragraphs": body})
            i = k
            continue
        preamble.append(p)
        i += 1
    if not items:
        raise SystemExit("no mysteries parsed")
    return items


def mystery(items: list[dict], *needles: str) -> list[str]:
    for needle in needles:
        n = keyify(needle)
        hits = [m for m in items if n in m["key"] or m["key"] in n]
        if len(hits) == 1:
            return hits[0]["paragraphs"]
        if len(hits) > 1:
            # Prefer the longest key match.
            hits.sort(key=lambda m: abs(len(m["key"]) - len(n)))
            return hits[0]["paragraphs"]
    raise SystemExit(f"mystery not found: {needles}")


def heading_end(paras: list[str], i: int) -> int:
    _, j = join_heading_run(paras, i)
    return j


def take_until(paras: list[str], start: int, *end_needles: str) -> tuple[list[str], int]:
    end = len(paras)
    for needle in end_needles:
        j = find_para(paras, needle, start)
        if j < 0:
            j = find_para_contains(paras, needle, start)
        if 0 <= j < end:
            end = j
    return paras[start:end], end


def parse_exercise_units(paras: list[str], mysteries: list[dict]) -> list[dict]:
    units: list[dict] = []

    def add(title: str, body: list[str], part: int, repetition: bool = False) -> None:
        # Drop leftover all-caps banners that duplicate the title.
        kept = []
        tkey = keyify(title)
        keep_heads = {"thought", "word", "act", "in part 2"}
        for p in body:
            k = keyify(p)
            if is_heading_line(p) and (k == tkey or k in tkey):
                continue
            if re.match(r"^and it contains the Preparatory Prayer", p, re.I):
                continue
            if is_heading_line(p) and k not in keep_heads:
                # Leftover banners (FIRST WEEK, IT IS ON, AND CONTAINS …).
                continue
            if k in keep_heads:
                p = title_case(p)
            kept.append(p)
        if kept and kept[0][:1].islower():
            kept[0] = kept[0][:1].upper() + kept[0][1:]
        units.append(unit(title, kept, part=part, repetition=repetition))

    def body_after(heading: str, *until: str) -> list[str]:
        i = find_para(paras, heading)
        if i < 0:
            i = find_para_contains(paras, heading)
        if i < 0:
            raise SystemExit(f"heading missing: {heading}")
        start = heading_end(paras, i)
        chunk, _ = take_until(paras, start, *until)
        return chunk

    # --- part 0: disposition ---
    motto_i = find_para(paras, "SPIRITUAL EXERCISES")
    pre_i = find_para(paras, "PRESUPPOSITION")
    pf_i = find_para(paras, "PRINCIPLE AND FOUNDATION")
    pe_i = find_para(paras, "PARTICULAR AND DAILY EXAMEN")
    fa_i = find_para(paras, "FOUR ADDITIONS")
    if fa_i < 0:
        fa_i = find_para_contains(paras, "FOLLOW TO RID ONESELF SOONER")
    ge_i = find_para(paras, "GENERAL EXAMEN OF CONSCIENCE")
    method_i = find_para(paras, "METHOD FOR MAKING THE GENERAL EXAMEN")
    gc_i = find_para(paras, "GENERAL CONFESSION WITH COMMUNION")
    first_ex = find_para(paras, "FIRST EXERCISE")

    presup = paras[heading_end(paras, pre_i):pf_i]
    if motto_i >= 0 and motto_i < pre_i:
        motto = paras[heading_end(paras, motto_i):pre_i]
        motto = [p for p in motto if not is_heading_line(p) or "conquer" in p.lower()]
        presup = motto + presup
    add("Presupposition", presup, 0)
    add("Principle and Foundation", paras[heading_end(paras, pf_i):pe_i], 0)
    add(
        "Particular and Daily Examen",
        paras[heading_end(paras, pe_i):fa_i],
        0,
    )
    add("Four Additions", paras[heading_end(paras, fa_i):ge_i], 0)
    add(
        "General Examen of Conscience",
        paras[heading_end(paras, ge_i):method_i],
        0,
    )
    add(
        "Method for Making the General Examen",
        paras[heading_end(paras, method_i):gc_i],
        0,
    )
    add(
        "General Confession with Communion",
        paras[heading_end(paras, gc_i):first_ex],
        0,
    )

    # --- part 1: First Week ---
    second_ex = find_para(paras, "SECOND EXERCISE")
    third_ex = find_para(paras, "THIRD EXERCISE")
    fourth_ex = find_para(paras, "FOURTH EXERCISE")
    fifth_ex = find_para(paras, "FIFTH EXERCISE")
    adds_i = find_para(paras, "ADDITIONS", fifth_ex)
    # The Additions after Hell, not the Four Additions already used.
    week2_i = find_para(paras, "SECOND WEEK")
    add("First Exercise", paras[heading_end(paras, first_ex):second_ex], 1)
    add("Second Exercise", paras[heading_end(paras, second_ex):third_ex], 1)
    add(
        "Third Exercise",
        paras[heading_end(paras, third_ex):fourth_ex],
        1,
        repetition=True,
    )
    add(
        "Fourth Exercise",
        paras[heading_end(paras, fourth_ex):fifth_ex],
        1,
        repetition=True,
    )
    add("Fifth Exercise", paras[heading_end(paras, fifth_ex):adds_i], 1)
    add(
        "Additions — To Make the Exercises Better",
        paras[heading_end(paras, adds_i):week2_i],
        1,
    )

    # --- part 2: Second Week ---
    king_i = find_para_contains(paras, "THE CALL OF THE TEMPORAL KING")
    inc_i = find_para(paras, "THE INCARNATION")
    if inc_i < 0:
        inc_i = find_para_contains(paras, "THE FIRST DAY AND FIRST CONTEMPLATION")
    nat_i = find_para(paras, "THE NATIVITY")
    third_c = find_para(paras, "THE THIRD CONTEMPLATION")
    fourth_c = find_para(paras, "THE FOURTH CONTEMPLATION")
    fifth_c = find_para(paras, "THE FIFTH CONTEMPLATION")
    day2_i = find_para(paras, "THE SECOND DAY")
    day3_i = find_para(paras, "THE THIRD DAY")
    preamble_i = find_para(paras, "PREAMBLE TO CONSIDER STATES")
    standards_i = find_para(paras, "TWO STANDARDS")
    pairs_i = find_para(paras, "THREE PAIRS OF MEN")
    day5_i = find_para(paras, "THE FIFTH DAY")
    day6_i = find_para(paras, "THE SIXTH DAY")
    day7_i = find_para(paras, "THE SEVENTH DAY")
    day8_i = find_para(paras, "THE EIGHTH DAY")
    day9_i = find_para(paras, "THE NINTH DAY")
    day10_i = find_para(paras, "THE TENTH DAY")
    day11_i = find_para(paras, "THE ELEVENTH DAY")
    day12_i = find_para(paras, "THE TWELFTH DAY")
    election_i = find_para(paras, "PRELUDE FOR MAKING ELECTION")
    three_note = find_starts(paras, "Third Note. The third: Before entering on the Elections")
    if three_note < 0:
        three_note = find_starts(paras, "First Humility.")
    matters_i = find_para_contains(paras, "TO GET KNOWLEDGE AS TO WHAT MATTERS")
    times_i = find_para(paras, "THREE TIMES")
    first_way = find_para(paras, "THE FIRST WAY")
    second_way = find_para(paras, "THE SECOND WAY")
    amend_i = find_para_contains(paras, "TO AMEND AND REFORM ONE'S OWN LIFE")
    third_week = find_para(paras, "THIRD WEEK")

    add("The Call of the Temporal King", paras[heading_end(paras, king_i):inc_i], 2)
    add("The Incarnation", paras[heading_end(paras, inc_i):nat_i], 2)
    add("The Nativity", paras[heading_end(paras, nat_i):third_c], 2)
    add(
        "Third Contemplation — Repetition of the Incarnation and Nativity",
        paras[heading_end(paras, third_c):fourth_c],
        2,
        repetition=True,
    )
    add(
        "Fourth Contemplation — Repetition of the Incarnation and Nativity",
        paras[heading_end(paras, fourth_c):fifth_c],
        2,
        repetition=True,
    )
    add(
        "Fifth Contemplation — Application of the Senses",
        paras[heading_end(paras, fifth_c):day2_i],
        2,
    )

    def day_with_mystery(title: str, heading_i: int, until_i: int, *needles: str) -> None:
        intro = paras[heading_end(paras, heading_i):until_i]
        intro = [p for p in intro if not (is_heading_line(p) and len(p) < 40)]
        pts = mystery(mysteries, *needles)
        add(title, intro + pts, 2)

    # Lengthening mysteries Ignatius names after the first day.
    add("The Visitation", mystery(mysteries, "visitation of our lady"), 2)
    add("The Shepherds", mystery(mysteries, "of the shepherds"), 2)
    add("The Circumcision", mystery(mysteries, "of the circumcision"), 2)
    add("The Three Magi Kings", mystery(mysteries, "three magi"), 2)

    day_with_mystery(
        "The Presentation in the Temple",
        day2_i,
        day3_i,
        "purification of our lady and presentation",
    )
    # Flight is the second contemplation of day 2; give it its own day.
    add("The Flight into Egypt", mystery(mysteries, "flight to egypt"), 2)
    add("The Return from Egypt", mystery(mysteries, "returned from egypt"), 2)
    add(
        "The Hidden Life at Nazareth",
        mystery(mysteries, "from twelve to thirty"),
        2,
    )
    add(
        "The Child Jesus in the Temple",
        mystery(mysteries, "coming of christ to the temple"),
        2,
    )
    add(
        "Preamble to Consider States",
        paras[heading_end(paras, preamble_i):standards_i],
        2,
    )
    add("Two Standards", paras[heading_end(paras, standards_i):pairs_i], 2)
    add("Three Pairs of Men", paras[heading_end(paras, pairs_i):day5_i], 2)

    day_with_mystery("The Baptism of Christ", day5_i, day6_i, "christ was baptized")
    day_with_mystery("The Temptation in the Desert", day6_i, day7_i, "christ was tempted")
    day_with_mystery("The Call of the Apostles", day7_i, day8_i, "call of the apostles")
    add("The Marriage at Cana", mystery(mysteries, "marriage of cana"), 2)
    add(
        "Christ Casts the Sellers from the Temple",
        mystery(mysteries, "cast out of the temple"),
        2,
    )
    day_with_mystery(
        "The Sermon on the Mount",
        day8_i,
        day9_i,
        "sermon which christ made on the mount",
    )
    add("The Tempest Calmed", mystery(mysteries, "tempest of the sea"), 2)
    day_with_mystery(
        "Christ Walks on the Sea",
        day9_i,
        day10_i,
        "walked on the sea",
    )
    add(
        "The Apostles Are Sent to Preach",
        mystery(mysteries, "apostles were sent to preach"),
        2,
    )
    add("The Conversion of Magdalen", mystery(mysteries, "conversion of magdalen"), 2)
    add(
        "The Feeding of the Five Thousand",
        mystery(mysteries, "five thousand"),
        2,
    )
    add("The Transfiguration", mystery(mysteries, "transfiguration of christ"), 2)
    day_with_mystery(
        "The Raising of Lazarus",
        day11_i,
        day12_i,
        "resurrection of lazarus",
    )
    add("The Supper at Bethany", mystery(mysteries, "supper at bethany"), 2)
    day_with_mystery(
        "The Preaching in the Temple",
        day10_i,
        day11_i,
        "preaching in the temple",
    )
    day_with_mystery("Palm Sunday", day12_i, three_note if three_note > 0 else election_i, "palm sunday")

    if three_note < 0:
        raise SystemExit("Three Manners of Humility missing")
    add(
        "Three Manners of Humility",
        paras[three_note:election_i],
        2,
    )
    add(
        "Prelude for Making Election",
        paras[heading_end(paras, election_i):matters_i],
        2,
    )
    add(
        "What Matters an Election Ought to Be Made About",
        paras[heading_end(paras, matters_i):times_i],
        2,
    )
    add(
        "Three Times for Making a Sound and Good Election",
        paras[heading_end(paras, times_i):first_way],
        2,
    )
    add(
        "The First Way to Make a Sound and Good Election",
        paras[heading_end(paras, first_way):second_way],
        2,
    )
    add(
        "The Second Way to Make a Good and Sound Election",
        paras[heading_end(paras, second_way):amend_i],
        2,
    )
    add(
        "To Amend and Reform One's Own Life and State",
        paras[heading_end(paras, amend_i):third_week],
        2,
    )

    # --- part 3: Third Week ---
    supper_i = find_para_contains(paras, "HOW CHRIST OUR LORD WENT FROM BETHANY")
    garden_i = find_para_contains(paras, "FROM THE SUPPER TO THE")
    tw_day2 = find_para(paras, "SECOND DAY", third_week)
    eat_i = find_para_contains(paras, "RULES TO PUT ONESELF IN ORDER FOR THE FUTURE")
    fourth_week = find_para(paras, "FOURTH WEEK")
    stub_annas = find_starts(paras, "Second Day. The second day at midnight", third_week)

    add(
        "The Last Supper",
        paras[heading_end(paras, supper_i):tw_day2],
        3,
    )
    add(
        "From the Supper to the Garden",
        paras[heading_end(paras, garden_i):stub_annas],
        3,
    )

    def passion_day(title: str, stub_prefix: str, *needles: str) -> None:
        s = find_starts(paras, stub_prefix, third_week)
        intro = [paras[s]] if s >= 0 else []
        add(title, intro + mystery(mysteries, *needles), 3)

    passion_day(
        "From the Garden to the House of Annas",
        "Second Day. The second day at midnight",
        "garden to the house of annas",
    )
    add(
        "From the House of Annas to the House of Caiphas",
        mystery(mysteries, "annas to the house of caiphas"),
        3,
    )
    add(
        "From the House of Caiphas to that of Pilate",
        mystery(mysteries, "caiphas to that of pilate"),
        3,
    )
    add(
        "From the House of Pilate to that of Herod",
        mystery(mysteries, "pilate to that of herod"),
        3,
    )
    add(
        "From the House of Herod to that of Pilate",
        mystery(mysteries, "herod to that of pilate"),
        3,
    )
    add(
        "From the House of Pilate to the Cross",
        mystery(mysteries, "pilate to the cross"),
        3,
    )
    add("The Mysteries on the Cross", mystery(mysteries, "mysteries on the cross"), 3)
    add(
        "From the Cross to the Sepulchre",
        mystery(mysteries, "cross to the sepulchre"),
        3,
    )
    # Seventh Day — the whole Passion together (Mullan's prose, not a mystery dump).
    seventh = None
    for i, p in enumerate(paras):
        if i > third_week and p.startswith("Seventh Day."):
            seventh = i
            break
    if seventh is None:
        raise SystemExit("Third Week seventh day missing")
    note_i = seventh + 1
    while note_i < eat_i and not paras[note_i].startswith("Note."):
        note_i += 1
    add("The Whole Passion Together", paras[seventh:eat_i], 3)

    # --- part 4: Fourth Week ---
    appear_i = find_para_contains(paras, "HOW CHRIST OUR LORD APPEARED")
    love_i = find_para(paras, "CONTEMPLATION TO GAIN LOVE")
    methods_i = find_para(paras, "THREE METHODS OF PRAYER")
    myst_head = find_para_contains(paras, "THE MYSTERIES OF THE LIFE OF CHRIST")

    add(
        "How Christ Our Lord Appeared to Our Lady",
        paras[heading_end(paras, appear_i):love_i],
        4,
    )
    for n, label in [
        (2, "The Second Apparition"),
        (3, "The Third Apparition"),
        (4, "The Fourth Apparition"),
        (5, "The Fifth Apparition"),
        (6, "The Sixth Apparition"),
        (7, "The Seventh Apparition"),
        (8, "The Eighth Apparition"),
        (9, "The Ninth Apparition"),
        (10, "The Tenth Apparition"),
        (11, "The Eleventh Apparition"),
        (12, "The Twelfth Apparition"),
        (13, "The Thirteenth Apparition"),
    ]:
        add(label, mystery(mysteries, f"the {label.lower().replace('the ', '')}", f"{label.lower()}"), 4)
    add("The Ascension of Christ Our Lord", mystery(mysteries, "ascension of christ"), 4)
    add(
        "Contemplation to Gain Love",
        paras[heading_end(paras, love_i):methods_i],
        4,
    )

    first_method = find_para(paras, "FIRST METHOD", methods_i)
    cmd_i = -1
    for i, p in enumerate(paras):
        if i > methods_i and p.strip() in {"I. The Ten Commandments", "I. The Ten Commandments."}:
            cmd_i = i
            break
        if i > methods_i and keyify(p) == "i the ten commandments":
            cmd_i = i
            break
    deadly_i = -1
    powers_i = -1
    senses_i = -1
    second_m = find_para(paras, "SECOND METHOD OF PRAYER")
    third_m = find_para(paras, "THIRD METHOD OF PRAYER")
    for i, p in enumerate(paras):
        k = keyify(p)
        if i <= methods_i:
            continue
        if k.startswith("ii on deadly sins"):
            deadly_i = i
        elif k.startswith("iii on the powers"):
            powers_i = i
        elif k.startswith("iv on the bodily senses"):
            senses_i = i
    add(
        "First Method of Prayer — The Ten Commandments",
        paras[heading_end(paras, methods_i):deadly_i],
        4,
    )
    add(
        "First Method of Prayer — The Deadly Sins",
        paras[deadly_i:powers_i],
        4,
    )
    add(
        "First Method of Prayer — The Powers of the Soul",
        paras[powers_i:senses_i],
        4,
    )
    add(
        "First Method of Prayer — The Bodily Senses",
        paras[senses_i:second_m],
        4,
    )
    add(
        "Second Method of Prayer",
        paras[heading_end(paras, second_m):third_m],
        4,
    )
    add(
        "Third Method of Prayer",
        paras[heading_end(paras, third_m):myst_head],
        4,
    )

    by_part = {}
    for u in units:
        by_part.setdefault(u["part"], 0)
        by_part[u["part"]] += 1
    print("exercise units by part:", by_part, "total", len(units))
    return units


def extract_suscipe(units: list[dict]) -> str:
    for u in units:
        if u["title"] == "Contemplation to Gain Love":
            m = re.search(
                r"Take, Lord, and receive all my liberty.*?(?:enough for me\.?)",
                u["textEn"],
                flags=re.S,
            )
            if not m:
                raise SystemExit("Suscipe not found in Contemplation to Gain Love")
            text = clean_prose(re.sub(r"\s+", " ", m.group(0)))
            return text
    raise SystemExit("Contemplation to Gain Love missing")


ANIMA_CHRISTI = (
    "Soul of Christ, sanctify me.\n"
    "Body of Christ, save me.\n"
    "Blood of Christ, inebriate me.\n"
    "Water from the side of Christ, wash me.\n"
    "Passion of Christ, strengthen me.\n"
    "O good Jesus, hear me.\n"
    "Within Thy wounds hide me.\n"
    "Suffer me not to be separated from Thee.\n"
    "From the malignant enemy defend me.\n"
    "In the hour of my death call me.\n"
    "And bid me come unto Thee,\n"
    "That with Thy saints I may praise Thee\n"
    "Forever and ever. Amen."
)


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    auto = parse_autobiography()
    total = sum(words(" ".join(c["paragraphs"])) for c in auto)
    print("=== autobiography ===")
    for c in auto:
        wc = words(" ".join(c["paragraphs"]))
        print(f"  {c['chapter']} {c['title'][:70]:70s} {wc:5d}")
    print(f"8 chapters, {total} words")

    paras = paras_from_lines(mullan_body_lines(), 0, None)
    # Drop remaining CCEL/index leftovers
    paras = [
        p for p in paras
        if "ccel.org" not in p.lower()
        and not p.startswith("file:///")
        and "This document is from the C" not in p
    ]
    rules = parse_rules(paras)
    print("=== rules ===")
    for c in rules["chapters"]:
        first = c["textEn"].split("\n", 1)[0][:90]
        print(f"  {c['chapter']:2d} w{c['week']} {c['title'][:40]:40s} {first}")

    mysteries = parse_mysteries(paras)
    print(f"=== mysteries {len(mysteries)} ===")
    units = parse_exercise_units(paras, mysteries)
    suscipe = extract_suscipe(units)
    prayers = {
        "prayers": [
            {"id": "anima-christi", "title": "Anima Christi", "textEn": ANIMA_CHRISTI},
            {"id": "suscipe", "title": "Take, Lord", "textEn": suscipe},
        ]
    }

    (WORK / "chapters.json").write_text(
        json.dumps({
            "translator": "J. F. X. O'Conor SJ (1900)",
            "parts": [{
                "part": 1,
                "title": "The Autobiography of St. Ignatius",
                "chapters": auto,
            }],
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (WORK / "rules.json").write_text(
        json.dumps(rules, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (WORK / "exercises_units.json").write_text(
        json.dumps({"units": units}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (WORK / "prayers.json").write_text(
        json.dumps(prayers, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {WORK}")


if __name__ == "__main__":
    main()
