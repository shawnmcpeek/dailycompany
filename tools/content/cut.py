#!/usr/bin/env python3
"""Generic content cutter — spec portals-spec.md §12.

Greedy paragraph packing to a target word count, shared by every portal's
content pipeline (not just the one that happens to run it first).

Input shape (JSON): {"parts": [{"part": 1, "title": str, "chapters": [
  {"chapter": 1, "title": str, "paragraphs": [str, ...]}, ...]}, ...]}
Paragraphs must already be clean prose — no footnote markers, no running
heads, no TOC/index material. That's the caller's job (a per-portal parse
script); this module only cuts.

Algorithm:
- Never split a paragraph. One longer than hard_max becomes its own entry,
  flagged 'oversized_paragraph'.
- Prefer to close an entry at a chapter's last paragraph if the entry's
  word count is within +/-35% of target.
- Force a close if the entry would otherwise exceed 1.35x target, if
  adding the next paragraph would pull in a third distinct chapter, or
  if it would cross into a new Part — an entry always belongs to exactly
  one Part, never split across the book's major divisions.
"""

from __future__ import annotations

from pathlib import Path

TARGET_TOLERANCE = 0.35


def cut(
    parts: list[dict],
    target_words: int,
    hard_min: int = 150,
    hard_max: int = 600,
) -> list[dict]:
    lo = target_words * (1 - TARGET_TOLERANCE)
    hi = target_words * (1 + TARGET_TOLERANCE)

    flat: list[tuple[int, str, int, str, int, bool]] = []
    # (part, part_title, chapter, chapter_title, para_index, text, is_last_in_chapter)
    for p in parts:
        for c in p["chapters"]:
            n = len(c["paragraphs"])
            for idx, text in enumerate(c["paragraphs"]):
                flat.append(
                    (
                        p["part"],
                        p["title"],
                        c["chapter"],
                        c["title"],
                        text,
                        idx == n - 1,
                    )
                )

    entries: list[dict] = []
    # each item: (part, part_title, chapter, chapter_title, text, words)
    cur_meta: list[tuple[int, str, int, str, str, int]] = []
    cur_flags: list[str] = []

    def cur_words() -> int:
        return sum(m[5] for m in cur_meta)

    def cur_chapters() -> list[int]:
        seen = []
        for _, _, ch, *_ in cur_meta:
            if ch not in seen:
                seen.append(ch)
        return seen

    def close():
        nonlocal cur_meta, cur_flags
        if not cur_meta:
            return
        first_part, first_part_title = cur_meta[0][0], cur_meta[0][1]
        first_ch, first_title = cur_meta[0][2], cur_meta[0][3]
        wc = cur_words()
        flags = list(cur_flags)
        if wc < hard_min:
            flags.append("under_min")
        if wc > hard_max:
            flags.append("over_max")
        entries.append(
            {
                "id": len(entries) + 1,
                "part": first_part,
                "partTitle": first_part_title,
                "chapter": first_ch,
                "chapterTitle": first_title,
                "spansChapters": sorted(set(m[2] for m in cur_meta)),
                "portionInChapter": None,  # filled in a post-pass below
                "wordCount": wc,
                "flags": flags,
                "textEn": "\n\n".join(m[4] for m in cur_meta),
            }
        )
        cur_meta = []
        cur_flags = []

    for part, part_title, chapter, chapter_title, text, is_last_in_chapter in flat:
        words = len(text.split())

        if words > hard_max:
            close()
            cur_meta = [(part, part_title, chapter, chapter_title, text, words)]
            cur_flags = ["oversized_paragraph"]
            close()
            continue

        would_be_new_part = cur_meta and cur_meta[0][0] != part
        would_be_third_chapter = (
            chapter not in cur_chapters() and len(cur_chapters()) >= 2
        )
        if (
            would_be_new_part
            or would_be_third_chapter
            or (cur_meta and cur_words() + words > hard_max)
        ):
            close()

        cur_meta.append((part, part_title, chapter, chapter_title, text, words))

        wc = cur_words()
        if is_last_in_chapter and lo <= wc <= hi:
            close()
        elif wc >= hi:
            close()

    close()

    # Portion-in-chapter numbering: among consecutive entries sharing the
    # same first chapter, label 1..N.
    by_chapter: dict[int, int] = {}
    counts: dict[int, int] = {}
    for e in entries:
        counts[e["chapter"]] = counts.get(e["chapter"], 0) + 1
    for e in entries:
        by_chapter[e["chapter"]] = by_chapter.get(e["chapter"], 0) + 1
        e["portionInChapter"] = by_chapter[e["chapter"]]
        e["portionsInChapter"] = counts[e["chapter"]]

    return entries


def cadence_candidates(total_words: int, target_lo=150, target_hi=600):
    """Print entries x repeats combinations and resulting words/day."""
    print(f"total words: {total_words}")
    for entries in range(200, 800, 5):
        words_per_entry = total_words / entries
        if not (target_lo <= words_per_entry <= target_hi):
            continue
        repeats = 365 / entries
        print(
            f"  {entries:4d} entries x {repeats:5.2f} repeats/yr "
            f"= {words_per_entry:6.1f} words/entry"
        )


def write_review_html(entries: list[dict], out_path: Path, target_words: int) -> None:
    rows = []
    for e in entries:
        flag_str = ", ".join(e["flags"]) if e["flags"] else ""
        first_line = e["textEn"].split("\n")[0][:80]
        last_line = e["textEn"].strip().split("\n")[-1][-80:]
        boundary = "chapter-end" if e["portionInChapter"] == e["portionsInChapter"] else "mid-chapter"
        row_style = ' style="background:#fdd"' if e["flags"] else ""
        rows.append(
            f"<tr{row_style}><td>{e['id']}</td><td>Part {e['part']} "
            f"Ch.{e['chapter']} ({e['portionInChapter']}/{e['portionsInChapter']})</td>"
            f"<td>{e['wordCount']}</td><td>{boundary}</td><td>{flag_str}</td>"
            f"<td>{first_line}</td><td>{last_line}</td></tr>"
        )
    html = f"""<!doctype html><html><head><meta charset="utf-8">
<title>Content cutter review</title>
<style>body{{font-family:sans-serif;font-size:13px}}
table{{border-collapse:collapse;width:100%}}
td,th{{border:1px solid #ccc;padding:4px 8px;text-align:left}}
</style></head><body>
<h1>Content cutter review</h1>
<p>{len(entries)} entries, target {target_words} words/entry.</p>
<table><tr><th>#</th><th>Chapter</th><th>Words</th><th>Boundary</th>
<th>Flags</th><th>First line</th><th>Last line</th></tr>
{"".join(rows)}
</table></body></html>"""
    out_path.write_text(html, encoding="utf-8")
