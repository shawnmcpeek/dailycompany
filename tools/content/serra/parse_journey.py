#!/usr/bin/env python3
"""Extract Palóu (Williams 1913) + Portolá (Smith/Teggart 1909) for the 1769 march."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
from ocr_clean import clean_ocr_english  # noqa: E402

RAW = ROOT / "raw"
HEAD_PALOU = re.compile(
    r"^(FRANCISCO PALOU'?S LIFE OF|PADRE FRAY JUN[IÍ]PERO SERRA|"
    r"\d{1,3}|CHAPTER [IVXLCDM]+)\s*$",
    re.I,
)
HEAD_PORTOLA = re.compile(
    r"^(Diary of Gaspar de Portola\.?\s*\d+|Academy of Pacific Coast History|"
    r"Publications of the|\[\d+\]|\d{4})\s*$",
    re.I,
)
RUNNING = re.compile(
    r"\b(?:FRANCISCO PALOU'?S LIFE OF|PADRE FRAY JUN[IÍ]PERO SERRA|"
    r"Diary of Gaspar de Portola\.?\s*\d+|Academy of Pacific Coast History)\b",
    re.I,
)


def collapse(text: str) -> str:
    text = text.replace("\u00ad", "")  # soft hyphen
    text = re.sub(r"-\n\s*", "", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", "\n", text)
    return text


def strip_heads(text: str, head: re.Pattern[str]) -> str:
    keep = []
    for line in text.splitlines():
        s = line.strip()
        if not s:
            keep.append("")
            continue
        if head.match(s):
            continue
        if re.fullmatch(r"\[?\d{1,3}\]?", s):
            continue
        keep.append(s)
    return "\n".join(keep)


def paras(text: str) -> list[str]:
    text = clean_ocr_english(collapse(text))
    text = RUNNING.sub("", text)
    chunks = re.split(r"\n\s*\n", text)
    out = []
    for c in chunks:
        c = re.sub(r"\s+", " ", c).strip()
        c = re.sub(r"\[\s*\d+\s*\]", "", c)
        c = re.sub(r"\s+", " ", c).strip()
        if len(c) < 40:
            continue
        out.append(c)
    return out


def palou_expedition() -> str:
    raw = (RAW / "palou_williams_1913.txt").read_text(encoding="utf-8", errors="replace")
    lines = raw.splitlines()
    start = next(i for i, ln in enumerate(lines) if ln.strip() == "CHAPTER  XIV")
    # body CHAPTER XIV is the second occurrence; TOC is first
    start = next(
        i
        for i, ln in enumerate(lines)
        if i > start and ln.strip() == "CHAPTER  XIV"
    )
    end = next(
        i
        for i, ln in enumerate(lines)
        if i > start and re.match(r"^CHAPTER\s+XVII\b", ln.strip())
    )
    chunk = "\n".join(lines[start:end])
    chunk = strip_heads(chunk, HEAD_PALOU)
    return "\n\n".join(paras(chunk))


def _is_spanish(s: str) -> bool:
    hits = len(
        re.findall(
            r"\b(el|los|las|que|handuvimos|parage|paraje|dia|día|con|por|se|de)\b",
            s,
            re.I,
        )
    )
    eng = len(re.findall(r"\b(the|we|and|of|to|from|proceeded|halted)\b", s, re.I))
    return hits > eng * 1.2 and hits >= 8


def portola_days() -> list[dict]:
    raw = (RAW / "acad_vol1.txt").read_text(encoding="utf-8", errors="replace")
    m = re.search(r"DIARY\s+OF\s+THE\s+JOURNEY\s+THAT\s+DON\s+GASPAR", raw)
    n = re.search(r"THE\s+NARRATIVE\s+OF\s+THE\s+PORTOLA", raw)
    if not m or not n:
        raise SystemExit("Portolá English diary bounds not found")
    sec = raw[m.start() : n.start()]
    sec = strip_heads(sec, HEAD_PORTOLA)
    sec = collapse(sec)
    sec = RUNNING.sub(" ", sec)
    sec = re.sub(r"\[\s*\d+\s*\]", " ", sec)
    sec = re.sub(r"\s+", " ", sec)

    header = re.compile(
        r"(The\s+(?:\d+(?:st|nd|rd|th)(?:\s+day)?(?:\s+of\s+(?:May|June|July))?|"
        r"1st\s+of\s+(?:May|June|July)|"
        r"\d+(?:st|nd|rd|th))\s*,?)",
        re.I,
    )
    parts = header.split(sec)
    # parts: [preamble, header1, body1, header2, body2, ...]
    month = 5
    year_days: list[dict] = []
    for i in range(1, len(parts), 2):
        head = parts[i]
        body = parts[i + 1] if i + 1 < len(parts) else ""
        if _is_spanish(head + " " + body):
            continue
        # drop trailing Spanish if the English page is followed by El N
        cut = re.search(r"\bEl(?:\s+dia)?\s+\d", body)
        if cut:
            body = body[: cut.start()]
        body = re.sub(r"\s+", " ", body).strip()
        body = re.sub(r"\b1769\b", "", body)
        body = re.sub(r"\s+", " ", body).strip()
        # trim running-head leftovers
        body = re.sub(
            r"\b(?:Diary of Gaspar de Portola\.?\s*\d+|Academy of Pacific Coast History)\b",
            " ",
            body,
            flags=re.I,
        )
        body = re.sub(r"\s+", " ", body).strip()
        if len(body) < 20:
            continue
        mo = re.search(r"of\s+(May|June|July)", head, re.I)
        if mo:
            month = {"may": 5, "june": 6, "july": 7}[mo.group(1).lower()]
        day_m = re.search(r"(\d+)", head)
        if not day_m:
            continue
        day = int(day_m.group(1))
        if month == 7 and day > 1:
            break
        if (month, day) < (5, 11):
            continue
        date_key = f"{month:02d}-{day:02d}"
        text = clean_ocr_english(f"{head.strip()} {body}")
        text = re.sub(r"\s+", " ", text).strip()
        loc = _location_from(text)
        year_days.append(
            {
                "dateKey": date_key,
                "location": loc,
                "textEn": text,
                "source": "portola",
            }
        )
        if month == 7 and day == 1:
            break
    # unique by date, keep first
    seen = {}
    for d in year_days:
        seen.setdefault(d["dateKey"], d)
    return list(seen.values())


def _location_from(text: str) -> str:
    m = re.search(
        r"halted at ([^.]{3,80})",
        text,
        re.I,
    )
    if m:
        loc = m.group(1).strip().rstrip(",;")
        loc = re.split(r",\s+(?:a |the |where |having |which )", loc, maxsplit=1)[0]
        return loc[:80].strip()
    m = re.search(
        r"(?:set out from|left) (?:the )?(?:mission |place )?([^.]{3,60})",
        text,
        re.I,
    )
    if m:
        return m.group(1).strip()[:80]
    if re.search(r"San Diego", text, re.I):
        return "San Diego"
    if re.search(r"Velicat", text, re.I):
        return "Velicatá"
    if re.search(r"San Juan de Dios", text, re.I):
        return "San Juan de Dios"
    return "On the road to San Diego"


def main() -> None:
    palou = palou_expedition()
    print("Palóu words", len(palou.split()))
    days = portola_days()
    print("Portolá days", len(days))
    for d in days[:5]:
        print(d["dateKey"], d["location"][:40], len(d["textEn"].split()), "w")
    print("...")
    for d in days[-3:]:
        print(d["dateKey"], d["location"][:40], len(d["textEn"].split()), "w")
    keys = [d["dateKey"] for d in days]
    print("first", keys[0], "last", keys[-1], "unique", len(keys))


if __name__ == "__main__":
    main()
