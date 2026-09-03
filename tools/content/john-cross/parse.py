#!/usr/bin/env python3
"""Parse Lewis 1864 Spiritual Maxims and Precautions into cut.py shape.

Atomic units: one saying / one caution a day. Do not run the cutter.
Source: tools/content/john-cross/raw/lewis_v2_djvu.txt
  (Complete Works of St. John of the Cross, trans. David Lewis, vol. 2, 1864)

Stops before the letters and novice-training material that follow the
nine Precautions in this volume. Treatises are not the daily cut.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "lewis_v2_djvu.txt"
WORK = ROOT / "work"

HEAD_RE = re.compile(
    r"^(?:"
    r"(?:\d+\s+)?SPIRITUAL MAXIMS\.?.*"
    r"|INSTRUCTIONS AND CAUTIONS(?:\s+ee)?.*"
    r"|Y?OL\.?\s*I{1,3}\.?\s*[A-Z]{0,4}.*"
    r"|VOL\.?\s*I{1,3}\.?\s*[A-Z]{0,4}.*"
    r"|THE END\.?"
    r")\s*$",
    re.I,
)
# Running heads: "TEST AND VALUE OF CHARITY. 353" or "PERFECTION OF LOVE. 357"
RUNNING_TITLE_RE = re.compile(
    r"^[A-Z][A-Z0-9 ,;'’\-:]{8,}\.?\s+\d{2,4}\s*$"
)
PAGE_ONLY_RE = re.compile(r"^\d{2,4}$")
GOOGLE_RE = re.compile(
    r"^Digitized\s+by.*$|"
    r"^Google.*$|"
    r"^Googl\s*$|"
    r"^v\^?\.?oo5Le.*$|"
    r"^[CUALj]+j?OOQle.*$",
    re.I,
)
GOOGLE_INLINE = re.compile(
    r"Digitized\s+by(?:\s+\S+)?|"
    r"v\^?\.oo5Le|"
    r"\bGoogle\b",
    re.I,
)
GARBAGE_RE = re.compile(r"^[\W\d_ivxlcdmIVXLCDM\s.\-,|'\"`*#@$&\\/]+$")
NUM_START_RE = re.compile(r"^(\d+)[.,]\s+(.*)$")
SECTION_ROMAN_RE = re.compile(r"^[IVXL]+\.\s*$")
FOOTNOTE_RE = re.compile(r"^\*\s*[A-Z].*")
SIDENOTE_TAIL = re.compile(r"\s+\d+\.\s+[A-Z][A-Za-z']{2,}\s*$")
OCR_FIXES = (
    (r"\balsé\b", "also"),
    (r"\bEeclesiasticus\b", "Ecclesiasticus"),
    (r"\bpa that is\b", "soul that is"),
    (r"\bjour-\s+ney\b", "journey"),
    (r"\bInall\b", "In all"),
    (r"\bthe ery\b", "the cry"),
    (r"\bIr any\b", "If any"),
    (r"\bTbe\b", "The"),
    (r"\bEeligious\b", "Religious"),
    (r"(?<![0-9])0 my\b", "O my"),
    (r"(?<![0-9])0 Lord\b", "O Lord"),
    (r"\bbom and bred\b", "born and bred"),
    (r"\bThou ait\b", "Thou art"),
    (r"\bEemember\b", "Remember"),
    (r"\bfotmd\b", "found"),
    (r"\bagainBt\b", "against"),
    (r"\bban\^n\b", "barren"),
    (r"wilL\b", "will."),
    (r"(?<![0-9])0 that\b", "O that"),
    (r"the peacej the", "the peace, the"),
    (r"on fire I$", "on fire!"),
    (r"other food 1$", "other food."),
    (r"union of Jove", "union of love"),
    (r"\bfleeh\b", "flesh"),
    (r"neither\s+S\s+a\s*[-–—]\s*denies", "neither denies"),
    (r"contempla\s*Peaks", "contemplation do not apply themselves to"),
    (r"\bHinr\b", "Him"),
    (r"\bim the\b", "in the"),
    (r"keep»", "keep"),
    (r"\bthera\b", "them"),
    (r"to-do good", "to do good"),
    (r"or -- to eagerly", "or too eagerly"),
    (r"or — to eagerly", "or too eagerly"),
    (r"\s+[|§«»]\s+", " "),
    (r"[«»]", ""),
    (r"\s+\|\s*$", ""),
    (r"and Overcomes", "and overcomes"),
    (r"\bimperfec\s+tions\b", "imperfections"),
)
RUNNING_HEAD_INLINE = re.compile(
    r"[A-Z][A-Z0-9 ,;'’\-]{8,}\.\s*\d{2,4}"
)
MASHED_MAXIM_NUM = re.compile(
    r"(?:(?<=[.?!;:])\s+|\s+)(?:Ry\s+)?(\d{2,3})\.\s+(?=[A-Z])"
)
OCR_TAIL = re.compile(
    r"(?:\s*(?:[-~=._|*'\"`\\/]+|\b[a-zA-Z]{1,2}\b)){8,}\s*$"
)


def normalize_ws(text: str) -> str:
    text = text.replace("—", "--").replace("–", "--")
    text = text.replace("’", "'").replace("‘", "'")
    text = text.replace("“", '"').replace("”", '"')
    text = text.replace("_", "")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s+\n", "\n", text)
    return text.strip()


def dehyphen_join(lines: list[str]) -> str:
    out: list[str] = []
    i = 0
    while i < len(lines):
        s = SIDENOTE_TAIL.sub("", lines[i].rstrip())
        while s.endswith("-") and i + 1 < len(lines):
            nxt = lines[i + 1].lstrip()
            if not nxt:
                i += 1
                continue
            if nxt[:1].isupper():
                s = s[:-1]
                break
            s = s[:-1] + nxt
            i += 1
        out.append(s)
        i += 1
    return normalize_ws(" ".join(out))


def is_letter_salad(s: str) -> bool:
    tokens = s.split()
    if len(tokens) < 8:
        return False
    if s[:1].islower():
        return False
    real = 0
    for w in tokens:
        letters = re.sub(r"[^A-Za-z]", "", w)
        if len(letters) >= 3 and re.search(r"[aeiouyAEIOUY]", letters):
            real += 1
    return real / len(tokens) < 0.4


def is_junk(line: str) -> bool:
    s = line.strip()
    if not s:
        return True
    if PAGE_ONLY_RE.match(s):
        return True
    if re.match(r"^[A-Z]\s+[A-Z]\s*\d*\s*$", s):  # "X 2", "B B 2"
        return True
    if re.match(r"^x\s+\d+$", s, re.I):
        return True
    if HEAD_RE.match(s) or RUNNING_TITLE_RE.match(s):
        return True
    if re.match(r"^\d+\s+SPIRITUAL MAXIMS", s, re.I):
        return True
    if s.upper().startswith("SPIRITUAL MAXIMS"):
        return True
    if GARBAGE_RE.match(s) and sum(c.isalpha() for c in s) < 8:
        return True
    if is_letter_salad(s) and len(s) < 80:
        return True
    if len(s) <= 3 and not NUM_START_RE.match(s):
        return True
    if s in {", BAS", "# “F-", "@ SA", "E", "h", "g", "|", "i a ll il", "Pg"}:
        return True
    return False


def tidy_line(line: str) -> str:
    s = re.sub(r"[ \t]+", " ", line).strip()
    s = SIDENOTE_TAIL.sub("", s).strip()
    s = re.sub(r"^[|_`$]+", "", s).strip()
    s = re.sub(r"^[\-—=~]+\s*", "", s)
    return s


def clean_lines(raw: str) -> list[str]:
    kept: list[str] = []
    for line in raw.splitlines():
        s = tidy_line(line)
        if is_junk(s):
            continue
        kept.append(s)
    text = "\n".join(kept)
    for pat, repl in OCR_FIXES:
        text = re.sub(pat, repl, text)
    return text.splitlines()


def find_maxims_span(raw: str) -> tuple[int, int]:
    """Body prologue, not the table of contents and not a running head."""
    start = None
    for m in re.finditer(r"^PROLOGUE\.?\s*$", raw, re.M):
        window = re.sub(r"\s+", " ", raw[m.start() : m.start() + 800])
        if re.search(r"sweetness and joy of my heart", window, re.I):
            start = m.start()
            break
    if start is None:
        raise SystemExit("maxims prologue not found")
    rest = raw[start:]
    poems = list(re.finditer(r"^POEMS\.?\s*$", rest, re.M))
    if not poems:
        raise SystemExit("POEMS marker not found after maxims")
    return start, start + poems[0].start()


def find_cautions_body(raw: str, maxims_start: int) -> str:
    block = raw[:maxims_start]
    needle = re.compile(
        r"If\s+any\s+\w*eligious\s+desires\s+to\s+attain\s+in\s+a\s+short\s+time",
        re.I,
    )
    starts = list(needle.finditer(block))
    if not starts:
        raise SystemExit("Precautions body not found")
    return block[starts[-1].start() :]


def parse_cautions(raw: str, maxims_start: int) -> list[dict]:
    body = find_cautions_body(raw, maxims_start)
    # Letters and novice-training follow the ninth caution — cut there.
    cut = re.search(
        r"LETTERS\.|"
        r"LETTER I\.|"
        r"He gives them some spiritual advice|"
        r"Containing wholesome instructions for the training",
        body,
    )
    if cut:
        body = body[: cut.start()]
    lines = clean_lines(body)

    chapters: list[dict] = []
    cur_title = "To the one who seeks to be a true religious"
    cur_lines: list[str] = []
    caution_n = 0

    def flush() -> None:
        nonlocal cur_lines, cur_title
        paras: list[str] = []
        buf: list[str] = []
        for l in cur_lines:
            if not l.strip():
                if buf:
                    paras.append(dehyphen_join(buf))
                    buf = []
            else:
                buf.append(l)
        if buf:
            paras.append(dehyphen_join(buf))
        paras = [p for p in paras if p and not FOOTNOTE_RE.match(p)]
        if paras:
            chapters.append({
                "chapter": len(chapters) + 1,
                "title": cur_title,
                "paragraphs": paras,
            })
        cur_lines = []

    enemy = None
    heading_re = re.compile(r"^(FIRST|SECOND|THIRD) CAUTION\.?$", re.I)
    body_start_re = re.compile(
        r"^[_ ]*The (first|second|third) caution\b", re.I
    )

    def title_for(ordinal: str) -> str:
        nonlocal caution_n, enemy
        key = ordinal.title()
        # A body-start and a heading for the same caution must not
        # increment twice.
        expected = {1: "First", 2: "Second", 3: "Third",
                    4: "First", 5: "Second", 6: "Third",
                    7: "First", 8: "Second", 9: "Third"}
        if caution_n == 0 or expected.get(caution_n) != key:
            caution_n += 1
        if caution_n <= 3:
            enemy = "the world"
        elif caution_n <= 6:
            enemy = "the devil"
        else:
            enemy = "the flesh"
        return f"Against {enemy} — {key} caution"

    for line in lines:
        s = line.strip()
        if s.upper().startswith("INSTRUCTIONS AND CAUTIONS"):
            continue
        if s.upper().startswith("TO BE CONTINUALLY OBSERVED"):
            continue
        if s.upper().startswith("A TRUE RELIGIOUS"):
            continue
        if re.match(r"^IN REGARD TO THE (WORLD|DEVIL|FLESH)", s, re.I):
            continue
        if s.lower() in {"or", "ptr", "ee"}:
            continue
        if re.match(r"^(against the|fleeh\.?|flesh\.?)$", s, re.I) and len(s.split()) <= 3:
            continue
        m = heading_re.match(s)
        body = body_start_re.match(s)
        if m or body:
            ordinal = (m or body).group(1)
            new_title = title_for(ordinal)
            if cur_title == new_title:
                if body:
                    cur_lines.append(s)
                continue
            flush()
            cur_title = new_title
            if body:
                cur_lines.append(s)
            continue
        if re.search(r"Three cautions to be observed", s, re.I):
            continue
        if re.search(r"^Three cautions against", s, re.I):
            continue
        if re.search(r"master the cunning of the flesh", s, re.I):
            continue
        if re.search(r"would conquer themselves", s, re.I):
            continue
        s = strip_inline_sidenote(s)
        if not s or is_sidenote_line(s):
            continue
        cur_lines.append(s)
    flush()
    if len(chapters) < 10:
        raise SystemExit(f"expected 10 precautions (address + 9 cautions), got {len(chapters)}")
    return polish_cautions(chapters)


def scrub_ocr(text: str) -> str:
    for pat, repl in OCR_FIXES:
        text = re.sub(pat, repl, text)
    text = GOOGLE_INLINE.sub(" ", text)
    text = RUNNING_HEAD_INLINE.sub(" ", text)
    text = text.replace("but]", "but")
    text = re.sub(r"\btoo wreak\b", "too weak", text)
    text = re.sub(r"\*\s*Is\.\s*[ivxlc]+\.\s*\d+\.?", " ", text, flags=re.I)
    text = re.sub(
        r"(recollection of spirit\.)\s+when others do not",
        r"\1 He who goes on a pilgrimage will do well to do so when others do not",
        text,
    )
    text = re.sub(r"trifles I and", "trifles, and", text)
    text = re.sub(r"\*\s*Ruth[^.]+\.", " ", text)
    text = text.replace("Thy feet*", "Thy feet")
    text = text.replace("[If", "If")
    text = re.sub(r"do Thou\s*:\s*inflict", "do Thou inflict", text)
    text = re.sub(r"\[[^\]]{0,80}\]", " ", text)
    text = re.sub(r"\.\s+\d{1,3},\s*\d{1,3}\.\s*$", ".", text)
    text = re.sub(r"\s+\d{1,3},\s*\d{1,3}\.\s*$", "", text)
    text = OCR_TAIL.sub("", text)
    text = re.sub(r"\s+", " ", text).strip(" |")
    text = text.strip()
    # Drop a trailing fragment with no sentence end if it's salad.
    if text and text[-1] not in ".?!":
        cut = max(text.rfind("."), text.rfind("?"), text.rfind("!"))
        if cut > 40:
            tail = text[cut + 1 :]
            if is_letter_salad(tail) or len(tail.split()) < 4:
                text = text[: cut + 1].strip()
    if text and text[-1].isalpha():
        text += "."
    return text


def split_mashed_maxims(text: str) -> list[str]:
    text = scrub_ocr(text)
    if not text:
        return []
    parts = MASHED_MAXIM_NUM.split(text)
    # split() with a capturing group returns [chunk, num, chunk, num, chunk]
    out = [parts[0].strip()]
    i = 1
    while i + 1 < len(parts):
        rest = parts[i + 1].strip()
        if rest:
            out.append(rest)
        i += 2
    return [scrub_ocr(p) for p in out if p and not is_letter_salad(p)]


def polish_maxim_items(
    prologue: str, items: list[tuple[str, list[str]]]
) -> tuple[str, list[tuple[str, list[str]]]]:
    prologue = scrub_ocr(prologue)
    out: list[tuple[str, list[str]]] = []
    for section, paras in items:
        blob = " ".join(paras)
        for piece in split_mashed_maxims(blob):
            # The enamoured-soul prayer is its own unit.
            m = re.search(r"(O Lord God, my Love,)", piece)
            if m and m.start() > 40:
                before = piece[: m.start()].strip()
                if before:
                    out.append((section, [before]))
                out.append(("Prayer of the Enamoured Soul", [piece[m.start():].strip()]))
            else:
                out.append((section, [piece]))
    return prologue, [(s, p) for s, p in out if p and p[0]]


def is_sidenote_line(s: str) -> bool:
    """Margin notes in Lewis: short wrapped labels, not the body."""
    words = s.split()
    if not words:
        return True
    if re.match(r"^(FIRST|SECOND|THIRD) CAUTION", s, re.I):
        return False
    if re.match(r"^[_ ]*The (first|second|third) caution\b", s, re.I):
        return False
    if NUM_START_RE.match(s) and len(words) > 8:
        return False
    if re.match(r"^\d+\.\s+", s) and len(words) <= 8:
        return True
    if len(words) <= 5 and not s.endswith((".", "?", "!", ";", ":")):
        return True
    if len(words) <= 4 and s[0].isupper() and not s.endswith((".", "?", "!")):
        return True
    if re.search(r"[\^«»■]", s) and len(words) <= 6:
        return True
    if is_letter_salad(s) and len(words) <= 12:
        return True
    return False


def strip_inline_sidenote(s: str) -> str:
    # "charitable it 1. Never act" — sidenote starts after the body fragment.
    s = re.sub(r"(?<=[a-z,;:])\s+\d+\.\s+[A-Za-z].*$", "", s)
    s = re.sub(r"\s+[I1]\.\s+[A-Z][a-z].*$", "", s)
    return s.strip()


def polish_cautions(chapters: list[dict]) -> list[dict]:
    out = []
    for ch in chapters:
        text = " ".join(ch["paragraphs"])
        text = re.split(r"\bLETTERS?\b|\bLETTER I\b", text, maxsplit=1)[0]
        text = re.sub(r"\d+\s+INSTRUCTIONS AND CAUTIONS\s+\S*", " ", text)
        text = re.sub(r"^[A-Z]{6,}\.\s+", "", text)
        text = re.sub(r"\bTn all\b", "In all", text)
        text = re.sub(r"\byeur\b", "your", text)
        text = re.sub(r"----s\s+", "", text)
        text = re.sub(r"\s+", " ", text).strip()
        text = re.sub(r"\bee i soe es\b.*$", "", text).strip()
        for pat in (
            r"The second caution against the world",
            r"The third caution is most necessary",
            r"IN REGARD TO THE FLESH",
            r"In order to escape perfectly from the evils which the world",
        ):
            m = re.search(pat, text)
            if m and m.start() > 40:
                text = text[: m.start()].strip()
        text = re.sub(r"seemsto beevil", "seems to be evil", text)
        text = re.sub(r"imper-\s*1\.\s*fections", "imperfections", text)
        text = re.sub(r"temporal ptr\s+goods", "temporal goods", text)
        text = re.sub(r"\bptr\b", "", text)
        text = re.sub(r"to which refers", "to which it refers", text)
        text = re.sub(
            r"great gain and profit, and the neglect\s+(Never look)",
            r"great gain and profit, and the neglect of it loss and ruin. \1",
            text,
        )
        text = re.sub(r"# The\s+observance", "The observance", text)
        text = re.sub(r"\s+■\s+", " ", text)
        text = re.sub(
            r"How to overcome the three spiritual enemies.*?(?=If we do not|In order|$)",
            " ",
            text,
        )
        text = scrub_ocr(text)
        if text.endswith("This then is the"):
            text = text[: -len("This then is the")].strip()
            if text and text[-1] not in ".?!":
                text += "."
        text = re.sub(r"(same proportion)\.\s+enemies\b.*$", r"\1.", text)
        text = re.sub(r"^work\.\s+", "", text)
        text = re.sub(r"\s*\^ap2«?ofy\s*", " ", text)
        text = re.sub(r"\s*diallke8\*\s*", " ", text)
        text = re.sub(r"\s*J\^ons\.\s*", " ", text)
        text = re.sub(
            r"to which it refers\..*?Never look upon your superior",
            "to which it refers. The observance of it brings great gain and profit, "
            "and the neglect of it loss and ruin. Never look upon your superior",
            text,
            flags=re.S,
        )
        text = re.sub(
            r"Never look upon your superior, be.{0,80}?otherwise than if you were looking upon God",
            "Never look upon your superior, be he who he may, otherwise than if you were looking upon God",
            text,
        )
        text = re.sub(r"\s+", " ", text).strip()
        if text and text[0].islower() and out:
            prev_title = out[-1]["title"]
            if prev_title == ch["title"]:
                out[-1]["paragraphs"][0] = (
                    out[-1]["paragraphs"][0].rstrip() + " " + text
                )
                continue
        if not text:
            continue
        out.append({
            "chapter": len(out) + 1,
            "title": ch["title"],
            "paragraphs": [text],
        })
    return out


def parse_maxims(raw: str) -> tuple[str, list[dict]]:
    start, end = find_maxims_span(raw)
    body = raw[start:end]
    lines = clean_lines(body)

    prologue_lines: list[str] = []
    items: list[tuple[str, list[str]]] = []
    section = "Imitation of Christ"
    cur_num_lines: list[str] = []
    last_n = 0
    in_prologue = True

    def flush_item() -> None:
        nonlocal cur_num_lines
        if not cur_num_lines:
            return
        text = dehyphen_join(cur_num_lines)
        text = re.sub(r"\s*\*\s*Eccles\..*$", "", text)
        if text:
            items.append((section, [text]))
        cur_num_lines = []

    for line in lines:
        s = line.strip()
        if s.upper() in {"SPIRITUAL MAXIMS.", "PROLOGUE.", "PROLOGUE"}:
            continue
        if SECTION_ROMAN_RE.match(s):
            continue
        m = NUM_START_RE.match(s)
        if m:
            n = int(m.group(1))
            rest_line = m.group(2)
            # Sub-lists inside a maxim (1. It fatigues it. 2. Torments…)
            if last_n >= 20 and n <= 12 and n != last_n + 1:
                cur_num_lines.append(s)
                continue
            # OCR: 66 for 56, $22 for 322, 4, for 4.
            flush_item()
            in_prologue = False
            last_n = n if n > last_n else last_n + 1
            cur_num_lines = [rest_line]
            continue
        if in_prologue:
            if s.isupper() and 8 < len(s) < 70 and not s.endswith("."):
                section = s.title()
                continue
            prologue_lines.append(s)
            continue
        if s.isupper() and 8 < len(s) < 80 and not NUM_START_RE.match(s):
            if RUNNING_TITLE_RE.match(s) or PAGE_ONLY_RE.match(s):
                continue
            # Running heads are all-caps. If the current saying is
            # unfinished, skip the head; do not flush a truncated maxim.
            if cur_num_lines:
                blob = " ".join(cur_num_lines).rstrip("-–— ")
                if blob and blob[-1] not in ".?!":
                    continue
            title = s.rstrip(".").title()
            if not title[0].isdigit():
                flush_item()
                section = title
            continue
        cur_num_lines.append(s)
    flush_item()

    prologue = dehyphen_join(prologue_lines) if prologue_lines else ""
    prologue, items = polish_maxim_items(prologue, items)
    return prologue, [
        {"title": title, "paragraphs": paras} for title, paras in items
    ]


def title_case(text: str) -> str:
    small = {"of", "the", "and", "in", "on", "a", "for", "to"}
    words = text.lower().split()
    out = []
    for i, w in enumerate(words):
        if i == 0 or w not in small:
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return " ".join(out)


def first_line_title(text: str, fallback: str) -> str:
    sentence = re.split(r"(?<=[.?;])\s", text, maxsplit=1)[0]
    sentence = sentence.strip().rstrip(".")
    if 12 <= len(sentence) <= 80:
        return sentence
    clip = text[:72].rsplit(" ", 1)[0]
    return clip if clip else fallback


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = RAW.read_text(encoding="utf-8")
    maxims_at, _ = find_maxims_span(raw)

    caution_chapters = parse_cautions(raw, maxims_at)
    prologue, maxim_items = parse_maxims(raw)

    parts = [
        {
            "part": 1,
            "title": "Precautions",
            "chapters": caution_chapters,
        },
        {
            "part": 2,
            "title": "Spiritual Maxims",
            "chapters": [],
        },
    ]
    if prologue:
        parts[1]["chapters"].append({
            "chapter": 1,
            "title": "Prologue",
            "paragraphs": [prologue],
        })
    for item in maxim_items:
        parts[1]["chapters"].append({
            "chapter": len(parts[1]["chapters"]) + 1,
            "title": first_line_title(
                item["paragraphs"][0], title_case(item["title"])
            ),
            "paragraphs": item["paragraphs"],
        })

    empty = [
        f"P{p['part']} ch {c['chapter']}"
        for p in parts
        for c in p["chapters"]
        if not any(x.strip() for x in c["paragraphs"])
    ]
    if empty:
        raise SystemExit(f"empty chapters: {empty[:8]}")

    n_maxims = len(parts[1]["chapters"])
    n_caut = len(parts[0]["chapters"])
    if n_maxims < 200:
        raise SystemExit(f"too few maxims: {n_maxims}")
    if n_caut < 10:
        raise SystemExit(f"too few precautions: {n_caut}")

    for part in parts:
        for ch in part["chapters"]:
            ch["paragraphs"] = [scrub_ocr(x) for x in ch["paragraphs"]]

    out = {
        "translator": "David Lewis (1864)",
        "parts": parts,
    }
    dest = WORK / "chapters.json"
    dest.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"precautions: {n_caut}")
    print(f"maxims: {n_maxims} (incl. prologue={bool(prologue)})")
    print(f"wrote {dest}")


if __name__ == "__main__":
    main()
