#!/usr/bin/env python3
"""Parse Newman PPS against the 191-sermon contents, plus the Works shelf."""

from __future__ import annotations

import json
import re
import sys
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT.parent))
from sermon_ocr import (  # noqa: E402
    body_paragraphs,
    collapse,
    find_headings,
    first_sentence_title,
    is_chrome,
    roman_to_int,
    stop_index,
    title_case,
)
from pps_canon import EXPECTED, PPS_TITLES, TOTAL  # noqa: E402

MIN_SERMON_WORDS = 150
MIN_SHELF_WORDS = 40


def letters_only(text: str) -> str:
    return re.sub(r"[^a-z]", "", collapse(text).lower())


def title_ratio(a: str, b: str) -> float:
    la, lb = letters_only(a), letters_only(b)
    if not la or not lb:
        return 0.0
    if min(len(la), len(lb)) < 8:
        return 1.0 if la == lb else 0.0
    if la == lb:
        return 1.0
    short, long_ = (la, lb) if len(la) <= len(lb) else (lb, la)
    if short in long_ and len(short) / len(long_) >= 0.55:
        return 0.94
    return SequenceMatcher(None, la, lb).ratio()


def title_ok(text: str) -> bool:
    letters = sum(c.isalpha() for c in text)
    if letters < 8:
        return False
    if any(c in text for c in r"%\^~*"):
        return False
    weird = sum(1 for c in text if ord(c) > 127)
    if weird > 2:
        return False
    if re.search(r"[0-9]{3,}", text):
        return False
    return True


def vol_files(vol: int) -> list[Path]:
    primary = RAW / f"pps_{vol:02d}.txt"
    alts = sorted(p for p in RAW.glob(f"pps_{vol:02d}_b*.txt") if p != primary)
    out = []
    if primary.exists():
        out.append(primary)
    out.extend(alts)
    return out


def _block_words(lines: list[str], a: int, b: int) -> int:
    return len(re.findall(r"\S+", " ".join(collapse(l) for l in lines[a:b])))


def body_window(lines: list[str], n_expected: int) -> tuple[int, int, list[tuple[int, int, str]]]:
    heads_all = find_headings(lines)
    end_guess = stop_index(lines, heads_all[0][0] if heads_all else 80)
    substantial: list[tuple[int, int, str]] = []
    for i, hit in enumerate(heads_all):
        idx, num, rest = hit
        if num < 1 or num > n_expected:
            continue
        nxt = heads_all[i + 1][0] if i + 1 < len(heads_all) else end_guess
        if nxt - idx < 40:
            continue
        if _block_words(lines, idx, nxt) < 200:
            continue
        substantial.append(hit)
    if not substantial:
        start = heads_all[-1][0] if heads_all else 0
        end = stop_index(lines, start)
        return start, end, []
    start = substantial[0][0]
    if substantial[0][1] != 1:
        toc_end = 0
        for idx, num, rest in heads_all:
            if idx >= start:
                break
            toc_end = idx
        if toc_end:
            start = toc_end
            substantial.insert(0, (start, 1, ""))
    end = stop_index(lines, start)
    ordered: list[tuple[int, int, str]] = []
    last = 0
    for idx, num, rest in substantial:
        if idx < start or idx >= end:
            continue
        if num <= last or num > n_expected:
            continue
        ordered.append((idx, num, rest))
        last = num
    return start, end, ordered


def find_title_line(
    lines: list[str],
    title: str,
    start: int,
    end: int,
    used: set[int],
) -> int | None:
    for i in range(start, end):
        if i in used:
            continue
        s = collapse(lines[i])
        if not s or is_chrome(lines[i]) or len(s) > 88:
            continue
        if len(letters_only(s)) < 8:
            continue
        if s.startswith(("“", '"', "'", "‘")):
            continue
        if title_ratio(s, title) >= 0.82:
            return i
    return None


def fill_missing(
    lines: list[str],
    heads: list[tuple[int, int, str]],
    titles: list[str],
    start: int,
    end: int,
) -> list[tuple[int, int, str]]:
    n_expected = len(titles)
    have = {num: (idx, num, rest) for idx, num, rest in heads}
    used = {idx for idx, _n, _r in heads}
    for n in range(1, n_expected + 1):
        if n in have:
            continue
        prev_idx = start
        for k in range(n - 1, 0, -1):
            if k in have:
                prev_idx = have[k][0] + 1
                break
        next_idx = end
        for k in range(n + 1, n_expected + 1):
            if k in have:
                next_idx = have[k][0]
                break
        found = find_title_line(lines, titles[n - 1], prev_idx, next_idx, used)
        if found is None:
            continue
        have[n] = (found, n, titles[n - 1])
        used.add(found)
    return sorted(have.values(), key=lambda h: h[0])


def extract_chapter(
    lines: list[str],
    idx: int,
    nxt: int,
    number: int,
    title: str,
) -> dict | None:
    block = lines[idx + 1:nxt]
    # Drop a following all-caps title line if it is the canonical title.
    skip = 0
    for line in block:
        s = collapse(line)
        if not s or is_chrome(line):
            skip += 1
            continue
        if title_ratio(s, title) >= 0.82 and len(s) < 90:
            skip += 1
            continue
        break
    paras = body_paragraphs(block[skip:])
    words = len(" ".join(paras).split())
    if words < MIN_SERMON_WORDS:
        return None
    return {"chapter": number, "title": title, "paragraphs": paras}


def chapters_from_file(path: Path, titles: list[str]) -> dict[int, dict]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    n_expected = len(titles)
    start, end, heads = body_window(lines, n_expected)
    heads = fill_missing(lines, heads, titles, start, end)
    by_num: dict[int, dict] = {}
    for i, (idx, num, _rest) in enumerate(heads):
        nxt = heads[i + 1][0] if i + 1 < len(heads) else end
        ch = extract_chapter(lines, idx, nxt, num, titles[num - 1])
        if ch:
            by_num[num] = ch
    return by_num


def parse_pps_volume(vol: int) -> dict:
    titles = PPS_TITLES[vol]
    files = vol_files(vol)
    if not files:
        raise SystemExit(f"PPS vol {vol}: no raw file")
    pooled: dict[int, tuple[int, dict]] = {}
    heading_counts: list[str] = []
    for path in files:
        got = chapters_from_file(path, titles)
        heading_counts.append(f"{path.name}:{len(got)}")
        for n, ch in got.items():
            words = len(" ".join(ch["paragraphs"]).split())
            if n not in pooled or words > pooled[n][0]:
                pooled[n] = (words, ch)
    missing = [n for n in range(1, len(titles) + 1) if n not in pooled]
    if missing:
        raise SystemExit(
            f"PPS vol {vol} missing sermons {missing} "
            f"(compared {', '.join(heading_counts)})"
        )
    chapters = [pooled[n][1] for n in range(1, len(titles) + 1)]
    words = sum(len(" ".join(c["paragraphs"]).split()) for c in chapters)
    print(
        f"PPS vol {vol}: {len(chapters)} sermons, {words} words "
        f"[{'; '.join(heading_counts)}] — {chapters[0]['title']}"
    )
    return {
        "part": vol,
        "title": f"Parochial and Plain Sermons, Volume {vol}",
        "chapters": chapters,
    }


def parse_pps() -> list[dict]:
    parts = [parse_pps_volume(vol) for vol in range(1, 9)]
    n = sum(len(p["chapters"]) for p in parts)
    if n != TOTAL:
        raise SystemExit(f"expected {TOTAL} PPS sermons, got {n}")
    for vol, part in zip(range(1, 9), parts):
        if len(part["chapters"]) != EXPECTED[vol]:
            raise SystemExit(
                f"vol {vol}: expected {EXPECTED[vol]}, got {len(part['chapters'])}"
            )
    return parts


HEADING = re.compile(
    r"^(?:(?:[IVX]+|[0-9]+)\.\s+)?([A-Z][A-Za-z'’:,\- ]{7,70})$"
)


def is_section_heading(line: str) -> bool:
    s = collapse(line)
    if not s or is_chrome(line) or len(s) > 72:
        return False
    if s.lower().startswith(("digitized", "google", "http")):
        return False
    letters = sum(c.isalpha() for c in s)
    caps = sum(c.isupper() for c in s if c.isalpha())
    if letters < 8:
        return False
    if HEADING.match(s) and caps / letters > 0.55:
        return True
    if re.match(r"^[IVX]+\.\s+\S", s) and len(s) < 70:
        return True
    return False


def parse_named_sections(lines: list[str], start: int, end: int) -> list[dict]:
    idxs = [i for i in range(start, end) if is_section_heading(lines[i])]
    chapters = []
    for n, idx in enumerate(idxs):
        nxt = idxs[n + 1] if n + 1 < len(idxs) else end
        paras = body_paragraphs(lines[idx + 1:nxt])
        if len(" ".join(paras).split()) < MIN_SHELF_WORDS:
            continue
        title = title_case(collapse(lines[idx]))
        if not title_ok(title):
            title = first_sentence_title(paras[0])
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": title,
            "paragraphs": paras,
        })
    return chapters


def parse_meditations() -> dict:
    lines = (RAW / "meditations_djvu.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    litany = next(
        i for i, l in enumerate(lines)
        if collapse(l).upper() == "THE LITANY OF LORETTO"
    )
    doctrine_hits = [
        i for i, l in enumerate(lines)
        if collapse(l).upper() == "MEDITATIONS ON CHRISTIAN DOCTRINE"
    ]
    doctrine = doctrine_hits[-1]
    end = next(
        (i for i, l in enumerate(lines[doctrine + 80:], doctrine + 80)
         if re.match(r"^index\b", collapse(l), re.I) and len(collapse(l)) < 40),
        len(lines),
    )
    litany_chs = parse_named_sections(lines, litany, doctrine)
    doctrine_chs = parse_named_sections(lines, doctrine, end)
    print(f"Meditations: litany {len(litany_chs)}, doctrine {len(doctrine_chs)}")
    return {
        "id": "meditations",
        "title": "Meditations and Devotions",
        "parts": [
            {"part": 1, "title": "Litany of Loreto", "chapters": litany_chs},
            {"part": 2, "title": "Christian Doctrine", "chapters": doctrine_chs},
        ],
    }


NUM_LINE = re.compile(r"^[IVXLCDM]+\.\s*$")


def parse_verses() -> dict:
    lines = (RAW / "verses_djvu.txt").read_text(
        encoding="utf-8", errors="replace"
    ).splitlines()
    start = next(
        i for i, l in enumerate(lines)
        if NUM_LINE.match(collapse(l))
    )
    end = next(
        (i for i, l in enumerate(lines[start + 200:], start + 200)
         if re.match(r"^index\b", collapse(l), re.I) and len(collapse(l)) < 40),
        len(lines),
    )
    idxs = [i for i in range(start, end) if NUM_LINE.match(collapse(lines[i]))]
    chapters = []
    for n, idx in enumerate(idxs):
        nxt = idxs[n + 1] if n + 1 < len(idxs) else end
        block = lines[idx + 1:nxt]
        title = ""
        skip = 0
        for line in block:
            s = collapse(line)
            if not s or is_chrome(line):
                skip += 1
                continue
            if re.match(r"^\d{1,3}$", s):
                skip += 1
                continue
            title = title_case(s)
            skip += 1
            break
        paras = body_paragraphs(block[skip:])
        if not paras:
            continue
        text = "\n\n".join(paras)
        if len(text.split()) < 12:
            continue
        if not title_ok(title):
            title = first_sentence_title(paras[0])
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": title,
            "paragraphs": paras,
        })
    names = " ".join(c["title"].lower() for c in chapters)
    if "kindly light" not in names and "pillar of the cloud" not in names:
        raise SystemExit("Lead Kindly Light / Pillar of the Cloud missing from Verses")
    print(f"Verses: {len(chapters)} poems")
    return {
        "id": "verses",
        "title": "Verses on Various Occasions",
        "parts": [{"part": 1, "title": "Verses", "chapters": chapters}],
    }


TREATISE_HEAD = re.compile(
    r"^(?:CHAPTER|DISCOURSE)\s+"
    r"([IVXLCDM]+|\d+)\.?\s*(.*)$",
    re.I,
)
LECTURE_HEAD = re.compile(
    r"^LECTURE\s+([IVXLCDM]+|\d+)\.?\s*(.*)$",
    re.I,
)
PART_HEAD = re.compile(r"^PART\s+([IVX]+|\d+)\.?\s*(.*)$", re.I)

APOLOGIA_TITLES = [
    "Mr. Kingsley's Method of Disputation",
    "True Mode of Meeting Mr. Kingsley",
    "History of My Religious Opinions to 1833",
    "History of My Religious Opinions, 1833–1839",
    "History of My Religious Opinions, 1839–1841",
    "History of My Religious Opinions, 1841–1845",
    "General Answer to Mr. Kingsley",
]


def normalize_treatise_line(line: str) -> str:
    s = collapse(line)
    s = re.sub(r"CHAPTEE", "CHAPTER", s, flags=re.I)
    s = re.sub(r"\bYII\b", "VII", s)
    s = re.sub(r"\bYIII\b", "VIII", s)
    s = re.sub(r"\byill\b", "VIII", s, flags=re.I)
    s = re.sub(r"\bVIL\b", "VII", s)
    return s


def gutenberg_span(lines: list[str]) -> tuple[int, int]:
    start = 0
    pg = False
    for i, line in enumerate(lines):
        u = line.upper()
        if "START OF THE PROJECT GUTENBERG" in u or "START OF THIS PROJECT GUTENBERG" in u:
            start = i + 1
            pg = True
            break
    end = len(lines)
    if pg:
        for i in range(start + 80, len(lines)):
            u = collapse(lines[i]).upper()
            if "END OF THE PROJECT GUTENBERG" in u or "END OF THIS PROJECT GUTENBERG" in u:
                end = i
                break
    else:
        end = stop_index(lines, start if start else 80)
    return start, end


def body_heads(
    lines: list[str],
    start: int,
    end: int,
    pattern: re.Pattern[str],
) -> list[tuple[int, int, str]]:
    hits: list[tuple[int, int, str]] = []
    for i in range(start, end):
        s = normalize_treatise_line(lines[i])
        m = pattern.match(s)
        if not m:
            continue
        num = roman_to_int(m.group(1))
        if num is None:
            continue
        rest = collapse(m.group(2) or "")
        hits.append((i, num, rest))
    if not hits:
        return []
    # Keep the last run of increasing numbers (skip TOC).
    best: list[tuple[int, int, str]] = []
    run: list[tuple[int, int, str]] = []
    last = 0
    for hit in hits:
        num = hit[1]
        if num == 1 and run:
            if len(run) >= len(best):
                best = run
            run = [hit]
            last = 1
            continue
        if num > last:
            run.append(hit)
            last = num
    if len(run) >= len(best):
        best = run
    # Prefer the run whose first chapter has real prose.
    chosen = best
    for candidate in (best, run):
        if not candidate:
            continue
        idx = candidate[0][0]
        nxt = candidate[1][0] if len(candidate) > 1 else min(end, idx + 400)
        words = len(" ".join(collapse(l) for l in lines[idx:nxt]).split())
        if words >= 200:
            chosen = candidate
            break
    return chosen


def chapters_from_heads(
    lines: list[str],
    heads: list[tuple[int, int, str]],
    end: int,
) -> list[dict]:
    chapters = []
    for i, (idx, num, rest) in enumerate(heads):
        nxt = heads[i + 1][0] if i + 1 < len(heads) else end
        block = lines[idx + 1:nxt]
        title = title_case(rest) if rest and len(rest) > 3 else ""
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
        text = " ".join(paras)
        if len(text.split()) < MIN_SHELF_WORDS:
            continue
        if not title or not title_ok(title):
            title = first_sentence_title(paras[0]) if paras else f"Chapter {num}"
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": title,
            "paragraphs": paras,
        })
    return chapters


def parse_treatise(path: Path, book_id: str, title: str, min_chapters: int) -> dict:
    if not path.exists():
        raise SystemExit(f"missing {path}")
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    start, end = gutenberg_span(lines)
    if book_id == "apologia":
        for i in range(start + 400, end):
            low = collapse(lines[i]).lower()
            if "what, then, does dr" in low:
                end = i
                break
    heads = body_heads(lines, start, end, TREATISE_HEAD)
    if len(heads) < min_chapters:
        parts = body_heads(lines, start, end, PART_HEAD)
        if len(parts) > len(heads):
            heads = parts
    parts_out: list[dict] = []
    if book_id == "idea":
        lectures = body_heads(lines, start, end, LECTURE_HEAD)
        disc = chapters_from_heads(lines, heads, lectures[0][0] if lectures else end)
        lect = chapters_from_heads(lines, lectures, end) if lectures else []
        if disc:
            parts_out.append({"part": 1, "title": "University Teaching", "chapters": disc})
        if lect:
            parts_out.append({"part": 2, "title": "University Subjects", "chapters": lect})
    else:
        chs = chapters_from_heads(lines, heads, end)
        if book_id == "apologia" and len(chs) == len(APOLOGIA_TITLES):
            for c, t in zip(chs, APOLOGIA_TITLES):
                c["title"] = t
        if chs:
            parts_out = [{"part": 1, "title": title, "chapters": chs}]
    n = sum(len(p["chapters"]) for p in parts_out)
    if n < min_chapters:
        raise SystemExit(f"{book_id}: only {n} chapters (want ≥{min_chapters})")
    words = sum(
        len(" ".join(c["paragraphs"]).split())
        for p in parts_out
        for c in p["chapters"]
    )
    print(f"{title}: {n} chapters, {words} words")
    return {"id": book_id, "title": title, "parts": parts_out}


def parse_shelf_treatises() -> dict[str, dict]:
    return {
        "apologia": parse_treatise(
            RAW / "apologia.txt",
            "apologia",
            "Apologia pro Vita Sua",
            min_chapters=5,
        ),
        "idea": parse_treatise(
            RAW / "idea.txt",
            "idea",
            "The Idea of a University",
            min_chapters=8,
        ),
        "grammar": parse_treatise(
            RAW / "grammar.txt",
            "grammar",
            "An Essay in Aid of a Grammar of Assent",
            min_chapters=8,
        ),
        "development": parse_treatise(
            RAW / "development.txt",
            "development",
            "An Essay on the Development of Christian Doctrine",
            min_chapters=8,
        ),
    }


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    parts = parse_pps()
    (WORK / "chapters.json").write_text(
        json.dumps({
            "translator": "John Henry Newman (Rivingtons / Longmans)",
            "parts": parts,
        }, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    words = sum(
        len(" ".join(c["paragraphs"]).split())
        for p in parts for c in p["chapters"]
    )
    print(f"wrote chapters.json ({words} words, {sum(len(p['chapters']) for p in parts)} sermons)")
    shelf = {
        "meditations": parse_meditations(),
        "verses": parse_verses(),
        **parse_shelf_treatises(),
    }
    (WORK / "shelf.json").write_text(
        json.dumps(shelf, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("wrote shelf.json")


if __name__ == "__main__":
    main()
