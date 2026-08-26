#!/usr/bin/env python3
"""Parse "Letters to Persons in the World" (Mackey trans., 1894) into
structured letters: book number/title, letter number, a short
descriptive line (recipient + subject, however the original phrases
it — this varies more than the Devout Life's chapter headers), and
body paragraphs.

Source: tools/content/desales/raw/letters_mackey.txt
  = plain-text OCR export of archive.org item letterstopersons00franuoft
  (Univ. of Toronto / John M. Kelly Library scan). Rougher OCR than the
  CCEL Devout Life source — this pass strips obvious running-header
  page breaks but does not attempt full footnote removal; treat as
  lightly cleaned, not proofread to the same standard.

Writes: tools/content/desales/work/letters.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "letters_mackey.txt"
WORK = ROOT / "work"

ROMAN_RE = r"[IVXLT]+"  # T included: OCR sometimes reads "IV" as "TV"
BOOK_RE = re.compile(rf"^BOOK\s+({ROMAN_RE})\.\s*$")
# Letter numbering is assigned sequentially per book, not parsed from this
# token — OCR misreads a trailing "I." as "L" often enough ("LETTER L" for
# "LETTER I.", "LETTER XL" for "LETTER XI.") that trusting the roman
# numeral itself is less reliable than just counting headers in order.
LETTER_RE = re.compile(r"^LETTER\s+([A-Z]{1,10})\.?\s*$")
# A running header: short line with a page number and "St. Francis" or
# the book title fragment, e.g. "46  St.  Francis,  de  Sales," or
# "Letters  to  Married  Women.  47"
PAGE_HEADER_RE = re.compile(
    r"^\s*(\d{1,4}\s+.{0,40}(St\.?\s*Francis|Letters)|"
    r".{0,40}(St\.?\s*Francis|Letters).{0,40}\s+\d{1,4})\s*$",
    re.IGNORECASE,
)

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "TV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14,
    "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20,
    "XXI": 21, "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26,
    "XXVII": 27, "XXVIII": 28, "XXIX": 29, "XXX": 30,
}

# Editorial titles for the 7 books — the raw OCR headers are inconsistent
# (line wraps, a stray "^" for "N") and Book V/VI share the generic
# "VARIOUS LETTERS" heading in the original, so name them distinctly here.
BOOK_TITLES = {
    1: "Letters to Young Ladies",
    2: "Letters to Married Women",
    3: "Letters to Widows",
    4: "Letters to Men of the World",
    5: "Various Letters I",
    6: "Various Letters II",
    7: "Letters of the Saint about Himself",
}


def normalize_ws(text: str) -> str:
    text = text.replace("—", "--").replace("’", "'")
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def join_wrapped_lines(raw_lines: list[str]) -> str:
    """Join OCR'd physical lines into one block, rejoining words split by
    a line-wrap hyphen (single trailing '-' after a letter) without a
    hyphen or space, and joining everything else with a space."""
    text = ""
    for line in raw_lines:
        piece = line.strip()
        if not piece:
            continue
        if (
            text.endswith("-")
            and not text.endswith("--")
            and len(text) >= 2
            and text[-2].isalpha()
        ):
            text = text[:-1] + piece
        elif text:
            text = text + " " + piece
        else:
            text = piece
    return text


def is_blank(line: str) -> bool:
    return not line.strip()


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw_lines = RAW.read_text(encoding="utf-8", errors="replace").splitlines()

    # The TOC lists all 7 "BOOK <roman>." headers before the real content
    # repeats them — the body starts at the 8th occurrence (index 7).
    book_hits = [i for i, l in enumerate(raw_lines) if BOOK_RE.match(l.strip())]
    assert len(book_hits) == 14, f"expected 14 BOOK markers (7 TOC + 7 real), got {len(book_hits)}"
    start = book_hits[7]

    end = next(
        (i for i, l in enumerate(raw_lines) if l.strip() == "The End."),
        len(raw_lines),
    )
    lines = raw_lines[start:end]
    n = len(lines)

    books: list[dict] = []
    cur_book = None
    cur_letter = None
    para_buf: list[str] = []
    front_buf: list[str] = []
    in_front = False

    def flush_para():
        nonlocal para_buf
        if para_buf and cur_letter is not None:
            text = normalize_ws(join_wrapped_lines(para_buf))
            text = re.sub(r"\*\s*$", "", text).strip()
            if text and len(text.split()) >= 3:
                cur_letter["paragraphs"].append(text)
        para_buf = []

    def flush_front():
        nonlocal front_buf
        if front_buf and cur_letter is not None:
            desc = normalize_ws(join_wrapped_lines(front_buf))
            if desc:
                cur_letter["description"] = desc
        front_buf = []

    i = 0
    while i < n:
        line = lines[i]
        stripped = line.strip()

        if PAGE_HEADER_RE.match(line) and not in_front:
            i += 1
            continue

        m_book = BOOK_RE.match(stripped)
        if m_book:
            flush_para()
            flush_front()
            # Skip the raw OCR'd title line(s) (line-wrapped, inconsistent
            # capitalization/typos) in favour of BOOK_TITLES.
            i += 1
            while i < n and is_blank(lines[i]):
                i += 1
            while i < n and not is_blank(lines[i]):
                i += 1
            book_num = ROMAN.get(m_book.group(1), 0)
            cur_book = {
                "book": book_num,
                "title": BOOK_TITLES.get(book_num, f"Book {m_book.group(1)}"),
                "letters": [],
            }
            books.append(cur_book)
            cur_letter = None
            continue

        m_letter = LETTER_RE.match(stripped)
        if m_letter and cur_book is not None:
            flush_para()
            flush_front()
            cur_letter = {
                "letter": len(cur_book["letters"]) + 1,
                "description": "",
                "paragraphs": [],
            }
            cur_book["letters"].append(cur_letter)
            in_front = True
            i += 1
            continue

        if is_blank(line):
            if in_front:
                flush_front()
                # Look ahead: if the next non-blank block is short (< 3
                # lines), it's still front matter (subject/date); once we
                # hit a block of 3+ lines, treat it as the real body.
                j = i + 1
                while j < n and is_blank(lines[j]):
                    j += 1
                block = []
                k = j
                while k < n and not is_blank(lines[k]) and not BOOK_RE.match(
                    lines[k].strip()
                ) and not LETTER_RE.match(lines[k].strip()):
                    block.append(lines[k])
                    k += 1
                if len(block) >= 3 or re.search(r"[.!?]\s*$", " ".join(block)) and len(block) >= 2:
                    in_front = False
            else:
                flush_para()
            i += 1
            continue

        if in_front:
            front_buf.append(line)
        else:
            para_buf.append(line)
        i += 1

    flush_para()
    flush_front()

    total_letters = sum(len(b["letters"]) for b in books)
    total_words = sum(
        len(re.findall(r"\S+", " ".join(l["paragraphs"])))
        for b in books
        for l in b["letters"]
    )
    print(f"books: {len(books)}")
    print(f"letters: {total_letters}")
    print(f"words: {total_words}")
    for b in books:
        print(f"  Book {b['book']} ({b['title'][:40]!r}): {len(b['letters'])} letters")

    out = WORK / "letters.json"
    out.write_text(
        json.dumps({"books": books}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
