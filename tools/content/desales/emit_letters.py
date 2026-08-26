#!/usr/bin/env python3
"""Verify and emit "Letters to Persons in the World" (Mackey trans.) as a
committed asset. Unlike the daily-cycle cutter, letters are already
discrete units in the source — no portioning needed, just verification
and a shape matching meditations.json (join paragraphs into textEn).

Reads:  tools/content/desales/work/letters.json  (see parse_letters.py)
Writes: assets/content/desales/letters.json
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORK = ROOT / "work"
ASSETS = ROOT.parent.parent.parent / "assets" / "content" / "desales"

EXPECTED_BOOK_COUNT = 7
EXPECTED_LETTER_COUNT = 183


def main() -> None:
    data = json.loads((WORK / "letters.json").read_text(encoding="utf-8"))
    books_in = data["books"]

    assert len(books_in) == EXPECTED_BOOK_COUNT, (
        f"expected {EXPECTED_BOOK_COUNT} books, got {len(books_in)}"
    )
    assert [b["book"] for b in books_in] == list(range(1, EXPECTED_BOOK_COUNT + 1))

    books_out = []
    total_letters = 0
    total_words = 0
    for b in books_in:
        letters_out = []
        expected_num = 0
        for l in b["letters"]:
            expected_num += 1
            assert l["letter"] == expected_num, (
                f"Book {b['book']}: expected sequential letter {expected_num}, "
                f"got {l['letter']}"
            )
            assert l["paragraphs"], f"Book {b['book']} Letter {l['letter']}: no body"
            text_en = "\n\n".join(l["paragraphs"])
            total_words += len(re.findall(r"\S+", text_en))
            letters_out.append(
                {
                    "letter": l["letter"],
                    "description": l["description"],
                    "textEn": text_en,
                }
            )
        total_letters += len(letters_out)
        books_out.append(
            {
                "book": b["book"],
                "title": b["title"],
                "letters": letters_out,
            }
        )

    assert total_letters == EXPECTED_LETTER_COUNT, (
        f"expected {EXPECTED_LETTER_COUNT} letters, got {total_letters}"
    )

    ASSETS.mkdir(parents=True, exist_ok=True)
    out = ASSETS / "letters.json"
    out.write_text(
        json.dumps({"version": 1, "books": books_out}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out}")
    print(f"books: {len(books_out)}  letters: {total_letters}  words: {total_words}")
    for b in books_out:
        print(f"  Book {b['book']} ({b['title']}): {len(b['letters'])} letters")


if __name__ == "__main__":
    main()
