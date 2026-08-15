#!/usr/bin/env python3
"""Align Doyle portion breakpoints onto Verheyen English + Latin.

Strategy:
  1. Chapter boundaries are identical across editions — hard-align by chapter.
  2. Intra-chapter breaks use Doyle word-count ratios to slice Verheyen/Latin
     paragraphs, snapping to paragraph boundaries.
  3. Confidence = ratio similarity + paragraph-count sanity. Flag for review
     when portions_in_chapter > 1 or confidence is weak.
"""

from __future__ import annotations

import html as html_lib
import json
import re
from pathlib import Path

from common import (
    ASSETS,
    RAW,
    REVIEW,
    ROMAN,
    WORK,
    AlignedReading,
    ChapterText,
    normalize_ws,
    tidy_paragraphs,
    words,
)


SCRIPTURE_PARENS = re.compile(
    r"\((?:cf\s+)?[A-Za-z][A-Za-z0-9 .]*\d+[A-Za-z0-9\[\]:\-;, ]*\)"
)
HTML_TAG = re.compile(r"<[^>]+>")


def strip_scripture_refs(text: str) -> str:
    # Keep numbered instrument markers like (1), (72); drop biblical refs only.
    return SCRIPTURE_PARENS.sub("", text)



def paragraphs_from_plain(text: str) -> list[str]:
    text = tidy_paragraphs(text)
    return [p.strip() for p in text.split("\n\n") if p.strip()]


def parse_verheyen(raw: str) -> dict[int, ChapterText]:
    # Drop CCEL header
    start = raw.find("PROLOGUE")
    if start < 0:
        raise RuntimeError("Verheyen PROLOGUE not found")
    body = raw[start:]
    # Cut CCEL indexes / trailing apparatus before chapter split.
    cut_points = []
    for marker in (
        "Index of Scripture References",
        "Indexes",
        "This document is from the Christian Classics",
        "file:///",
    ):
        idx = body.find(marker)
        if idx > 0:
            cut_points.append(idx)
    if cut_points:
        body = body[: min(cut_points)]

    chapter_re = re.compile(r"^\s*CHAPTER\s+([IVXLCDM]+)\s*$", re.M)
    marks: list[tuple[int, int, str]] = [(0, 0, "Prologue")]
    for m in chapter_re.finditer(body):
        roman = m.group(1)
        if roman not in ROMAN:
            raise RuntimeError(f"unknown roman chapter: {roman}")
        marks.append((m.start(), ROMAN[roman], m.group(0).strip()))

    chapters: dict[int, ChapterText] = {}
    for i, (pos, ch, _banner) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(body)
        chunk = body[pos:end]
        # Remove chapter banner line
        chunk = re.sub(r"^\s*PROLOGUE\s*$", "", chunk, count=1, flags=re.M)
        chunk = re.sub(r"^\s*CHAPTER\s+[IVXLCDM]+\s*$", "", chunk, count=1, flags=re.M)
        paras = paragraphs_from_plain(chunk)
        title = "Prologue"
        body_paras = paras
        if ch == 0:
            title = "Prologue"
        elif paras:
            # First short paragraph is usually the title.
            if len(paras[0].split()) <= 18 and not paras[0].endswith("."):
                title = paras[0].rstrip(".")
                body_paras = paras[1:]
            else:
                title = f"Chapter {ch}"
        text = "\n\n".join(body_paras)
        text = strip_scripture_refs(text)
        text = tidy_paragraphs(text)
        chapters[ch] = ChapterText(
            chapter=ch,
            title=title,
            text=text,
            paragraphs=paragraphs_from_plain(text),
        )
    if set(chapters) != set(range(74)):
        missing = sorted(set(range(74)) - set(chapters))
        raise RuntimeError(f"Verheyen missing chapters: {missing}")
    return chapters


def decode_latin_entities(s: str) -> str:
    s = html_lib.unescape(s)
    # Latin Library uses &aelig; etc already handled by unescape
    return s


def parse_latin(raw: str) -> dict[int, ChapterText]:
    raw = decode_latin_entities(raw)
    text = re.sub(r"(?is)<script.*?</script>", "", raw)
    text = re.sub(r"(?is)<style.*?</style>", "", text)
    # Preserve paragraph breaks, then strip tags.
    text = re.sub(r"(?i)</p\s*>", "\n\n", text)
    text = re.sub(r"(?i)<br\s*/?>", "\n", text)
    text = HTML_TAG.sub(" ", text)
    text = normalize_ws(text)

    # Latin Library markup is messy; match bare "Caput N: title" anywhere.
    caput_re = re.compile(r"Caput\s+(\d+)\s*:\s*([^\n]+)", re.I)
    marks = list(caput_re.finditer(text))
    if len(marks) < 70:
        raise RuntimeError(f"expected ~73 Caput headers, got {len(marks)}")

    chapters: dict[int, ChapterText] = {}
    prologue = text[: marks[0].start()]
    prologue = re.sub(r"(?is)^.*?REGULA.*?(?=Obsculta)", "", prologue, count=1)
    prologue = re.sub(r"(?is)Incipit prologus", "", prologue)
    prologue = tidy_paragraphs(prologue)
    chapters[0] = ChapterText(
        chapter=0,
        title="Prologus",
        text=prologue,
        paragraphs=paragraphs_from_plain(prologue),
    )

    for i, m in enumerate(marks):
        n = int(m.group(1))
        title = normalize_ws(m.group(2)).strip(" .")
        end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
        body = tidy_paragraphs(text[m.end() : end])
        chapters[n] = ChapterText(
            chapter=n,
            title=title or f"Caput {n}",
            text=body,
            paragraphs=paragraphs_from_plain(body),
        )

    if set(chapters) != set(range(74)):
        missing = sorted(set(range(74)) - set(chapters))
        extra = sorted(set(chapters) - set(range(74)))
        raise RuntimeError(f"Latin chapters missing={missing} extra={extra}")
    return chapters


def split_by_ratios(paragraphs: list[str], ratios: list[float]) -> list[list[str]]:
    """Assign paragraphs to N buckets matching target word-count ratios."""
    return _split_dp(paragraphs, ratios)


def _split_dp(paragraphs: list[str], ratios: list[float]) -> list[list[str]]:
    n = len(ratios)
    m = len(paragraphs)
    if n == 1:
        return [paragraphs]
    if m == 0:
        return [[] for _ in range(n)]
    if m < n:
        # Not enough paragraphs — pack early, empty later filled by merging chars
        # Fall back: split by character proportion inside joined text.
        joined = "\n\n".join(paragraphs)
        return _split_text_chars(joined, ratios)

    weights = [max(1, len(words(p))) for p in paragraphs]
    total = sum(weights)
    targets = [r / sum(ratios) * total for r in ratios]

    # Greedy left-to-right with look-ahead: choose cut points minimizing
    # squared error of bucket word counts, ensuring each bucket >= 1 para.
    cuts = []
    start = 0
    for bi in range(n - 1):
        remaining_buckets = n - bi
        remaining_paras = m - start
        max_end = m - (remaining_buckets - 1)  # leave 1 each for rest
        best_end = start + 1
        best_err = float("inf")
        running = 0
        for end in range(start + 1, max_end + 1):
            running = sum(weights[start:end])
            err = (running - targets[bi]) ** 2
            if err < best_err:
                best_err = err
                best_end = end
        cuts.append(best_end)
        start = best_end
    cuts.append(m)

    buckets: list[list[str]] = []
    prev = 0
    for cut in cuts:
        buckets.append(paragraphs[prev:cut])
        prev = cut
    return buckets


def _split_text_chars(text: str, ratios: list[float]) -> list[list[str]]:
    n = len(ratios)
    if n == 1:
        return [[text]] if text else [[]]
    total = max(1, len(text))
    norms = [r / sum(ratios) for r in ratios]
    out: list[list[str]] = []
    pos = 0
    for i, frac in enumerate(norms):
        if i == n - 1:
            chunk = text[pos:]
        else:
            target = pos + int(round(frac * total))
            # snap to nearest sentence end
            window = text[pos: max(pos + 1, min(len(text), target + 80))]
            snap = target
            for punct in (". ", "? ", "! ", "; "):
                idx = text.rfind(punct, pos + 20, min(len(text), target + 120))
                if idx >= pos:
                    snap = idx + 1
                    break
            chunk = text[pos:snap].strip()
            pos = snap
        out.append([chunk] if chunk else [])
    return out


def _norm_phrase(s: str) -> str:
    s = s.lower()
    s = re.sub(r"[^a-z0-9\s]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


_STOP = {
    "a",
    "an",
    "the",
    "to",
    "of",
    "and",
    "or",
    "in",
    "on",
    "for",
    "with",
    "one",
    "ones",
    "one's",
    "his",
    "her",
    "their",
    "be",
    "is",
    "not",
    "by",
}


def _cue_tokens(text: str, limit: int = 10) -> set[str]:
    toks = [
        t
        for t in _norm_phrase(re.sub(r"^\d+\.\s*", "", text.strip())).split()
        if t not in _STOP and len(t) > 2
    ]
    return set(toks[:limit])


def _best_cue_index(haystack: str, cue_text: str) -> int:
    """Find start index in haystack whose local window best matches cue tokens."""
    # Exact-ish short fragment first.
    raw = re.sub(r"^\d+\.\s*", "", cue_text.strip())
    words = raw.split()
    for n in range(min(7, len(words)), 3, -1):
        frag = re.sub(r"[“”\"']", "", " ".join(words[:n]))
        idx = haystack.lower().find(frag.lower())
        if idx >= 0:
            return idx

    cue = _cue_tokens(cue_text)
    if len(cue) < 3:
        return -1

    # Candidate starts: tool markers, sentence starts, or paragraph starts.
    candidates = {0}
    for m in re.finditer(r"\((\d+)\)|[.!?]\s+|[A-Z]", haystack):
        candidates.add(m.start())
    best_i = -1
    best_score = 0.0
    h_norm_words = _norm_phrase(haystack).split()
    # Build approximate char index map from normalized word index.
    # Simpler: score each regex candidate by overlapping next 18 words in original.
    for i in sorted(candidates):
        window = _norm_phrase(haystack[i : i + 180]).split()[:18]
        wset = {t for t in window if t not in _STOP and len(t) > 2}
        if not wset:
            continue
        overlap = len(cue & wset)
        score = overlap / len(cue)
        # Prefer earlier of near-ties only if score strong
        if score > best_score or (score == best_score and score >= 0.5 and (best_i < 0 or i < best_i)):
            if score >= 0.45:
                best_score = score
                best_i = i
    return best_i


def split_verheyen_by_doyle_cues(
    text: str, portions: list[dict]
) -> list[list[str]] | None:
    """Snap Verheyen cuts to phrases that open each Doyle portion."""
    positions: list[int] = []
    for i, p in enumerate(portions):
        idx = _best_cue_index(text, p["text"])
        if idx < 0:
            return None
        if i > 0 and idx <= positions[-1]:
            return None
        positions.append(idx)

    buckets: list[list[str]] = []
    for i, pos in enumerate(positions):
        end = positions[i + 1] if i + 1 < len(positions) else len(text)
        chunk = text[pos:end].strip()
        if i == 0 and pos > 0:
            chunk = (text[:pos].strip() + "\n\n" + chunk).strip()
        buckets.append([chunk] if chunk else [])
    return buckets


def align_chapter(
    chapter: int,
    title: str,
    doyle_portions: list[dict],
    ver: ChapterText,
    lat: ChapterText,
) -> list[AlignedReading]:
    n = len(doyle_portions)
    doyle_words = [max(1, len(words(p["text"]))) for p in doyle_portions]
    ratios = [w / sum(doyle_words) for w in doyle_words]

    ver_buckets = None
    if n > 1:
        cue_buckets = split_verheyen_by_doyle_cues(ver.text, doyle_portions)
        if cue_buckets is not None:
            # Accept cue split only if no bucket is absurdly short vs Doyle.
            ok = True
            for i, bucket in enumerate(cue_buckets):
                ew = len(words(" ".join(bucket)))
                dw = doyle_words[i]
                if ew < max(12, int(dw * 0.25)):
                    ok = False
                    break
            if ok:
                ver_buckets = cue_buckets
    if ver_buckets is None:
        ver_buckets = split_by_ratios(ver.paragraphs, ratios)
    lat_buckets = split_by_ratios(lat.paragraphs, ratios)

    readings: list[AlignedReading] = []
    for i, dp in enumerate(doyle_portions):
        en = tidy_paragraphs("\n\n".join(ver_buckets[i]))
        la = tidy_paragraphs("\n\n".join(lat_buckets[i]))
        dw = doyle_words[i]
        ew = max(1, len(words(en)))
        # Confidence: English word count within ~45% of Doyle portion ratio share
        # of chapter; also penalize empty.
        flags: list[str] = []
        if not en:
            flags.append("empty_english")
        if not la:
            flags.append("empty_latin")
        ratio_err = abs(ew - dw) / max(dw, ew)
        confidence = max(0.0, 1.0 - ratio_err)
        if n > 1:
            flags.append("intra_chapter_break")
            if ratio_err > 0.35:
                flags.append("wordcount_skew")
                confidence *= 0.7
        if n == 1:
            confidence = min(1.0, confidence + 0.15)
        readings.append(
            AlignedReading(
                id=dp["id"],
                chapter=chapter,
                chapter_title=title,
                portion_in_chapter=i + 1,
                portions_in_chapter=n,
                date_keys_common=dp["date_keys_common"],
                date_keys_leap=dp["date_keys_leap"],
                merge_into_previous_on_common=dp["merge_into_previous_on_common"],
                text_en=en,
                text_la=la,
                doyle_text=dp["text"],
                doyle_header=dp["header"],
                confidence=round(confidence, 3),
                flags=flags,
            )
        )
    return readings


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    date_table = json.loads((WORK / "date_table.json").read_text(encoding="utf-8"))
    ver = parse_verheyen((RAW / "verheyen.txt").read_text(encoding="utf-8"))
    lat = parse_latin((RAW / "latin.html").read_text(encoding="utf-8", errors="replace"))

    by_chapter: dict[int, list[dict]] = {}
    for r in date_table["readings"]:
        by_chapter.setdefault(r["chapter"], []).append(r)

    aligned: list[AlignedReading] = []
    for ch in sorted(by_chapter):
        if ch not in ver or ch not in lat:
            raise RuntimeError(f"missing chapter {ch}")
        aligned.extend(
            align_chapter(ch, ver[ch].title, by_chapter[ch], ver[ch], lat[ch])
        )

    aligned.sort(key=lambda r: r.id)
    if len(aligned) != 122:
        raise RuntimeError(f"expected 122 aligned readings, got {len(aligned)}")

    out = {
        "readings": [
            {
                "id": r.id,
                "chapter": r.chapter,
                "chapterTitle": r.chapter_title,
                "portionInChapter": r.portion_in_chapter,
                "portionsInChapter": r.portions_in_chapter,
                "dateKeysCommon": r.date_keys_common,
                "dateKeysLeap": r.date_keys_leap,
                "mergeIntoPreviousOnCommon": r.merge_into_previous_on_common,
                "textEn": r.text_en,
                "textLa": r.text_la,
                "doyleHeader": r.doyle_header,
                "doyleText": r.doyle_text,
                "confidence": r.confidence,
                "flags": r.flags,
            }
            for r in aligned
        ]
    }
    path = WORK / "aligned.json"
    path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    flagged = sum(1 for r in aligned if "wordcount_skew" in r.flags or "empty_english" in r.flags)
    print(f"wrote {path}")
    print(f"aligned {len(aligned)}; flagged for close review: {flagged}")


if __name__ == "__main__":
    main()
