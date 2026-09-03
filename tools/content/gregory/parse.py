#!/usr/bin/env python3
"""Parse Barmby's Pastoral Rule (NPNF II.12 via New Advent) into cut.py shape.

Keeps Gregory's own address to John of Ravenna and the four books.
Strips Barmby's preface, New Advent ads, encyclopedia links, and the
About-this-page colophon.
"""

from __future__ import annotations

import html as html_lib
import json
import re
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "newadvent"
WORK = ROOT / "work"

BOOKS = [
    (1, "36011.htm", "Book I — The qualifications of those who come to rule"),
    (2, "36012.htm", "Book II — The life of the pastor"),
    (3, "36013.htm", "Book III — How the ruler ought to teach"),
    (4, "36014.htm", "Book IV — How the preacher should return to himself"),
]


class _BookParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.skip_depth = 0
        self.in_h2 = False
        self.in_h1 = False
        self.in_strong = False
        self.capture = False
        self.buf: list[str] = []
        self.sections: list[tuple[str, list[str]]] = []
        self.cur_heading = ""
        self.cur_paras: list[str] = []
        self.pending_title = ""

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        ad = dict(attrs)
        cls = ad.get("class") or ""
        ident = ad.get("id") or ""
        if tag in {"script", "style", "nav"}:
            self.skip_depth += 1
            return
        if "catholicadnet" in cls or cls.startswith("CMtag") or "ad" in ident:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return
        if tag == "h1":
            self.in_h1 = True
        if tag == "h2":
            self._flush_para()
            self._flush_section()
            self.in_h2 = True
            self.buf = []
        if tag == "strong":
            self.in_strong = True
            self.buf = []
        if tag == "p" and self.capture:
            self._flush_para()
            self.buf = []
        if tag == "br" and self.capture:
            self.buf.append(" ")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "nav"} and self.skip_depth:
            self.skip_depth -= 1
            return
        if self.skip_depth:
            if tag in {"div", "aside"}:
                self.skip_depth = max(0, self.skip_depth - 1)
            return
        if tag == "h1":
            self.in_h1 = False
        if tag == "h2":
            heading = normalize_ws("".join(self.buf))
            self.in_h2 = False
            self.buf = []
            if heading.lower() == "preface":
                self.capture = False
                return
            if heading.lower() == "about this page":
                self.capture = False
                return
            self.capture = True
            self.cur_heading = heading
            return
        if tag == "strong":
            self.in_strong = False
            text = normalize_ws("".join(self.buf))
            self.buf = []
            if self.capture and text and not self.cur_paras:
                self.pending_title = text
            elif self.capture and text:
                self.buf.append(text)
            return
        if tag == "p" and self.capture:
            self._flush_para()

    def handle_data(self, data: str) -> None:
        if self.skip_depth:
            return
        if self.in_h1:
            return
        if "Please help support the mission of New Advent" in data:
            return
        if self.in_h2 or self.in_strong or self.capture:
            self.buf.append(data)

    def _flush_para(self) -> None:
        text = normalize_ws("".join(self.buf))
        self.buf = []
        if not text:
            return
        if text.startswith("Please help support"):
            return
        if text.startswith("Source. Translated by James Barmby"):
            return
        self.cur_paras.append(text)

    def _flush_section(self) -> None:
        if not self.capture:
            self.cur_heading = ""
            self.cur_paras = []
            self.pending_title = ""
            return
        if self.cur_heading or self.cur_paras:
            title = self.pending_title or self.cur_heading
            self.sections.append((title, list(self.cur_paras)))
        self.cur_heading = ""
        self.cur_paras = []
        self.pending_title = ""

    def finish(self) -> list[tuple[str, list[str]]]:
        self._flush_para()
        self._flush_section()
        return self.sections


def normalize_ws(text: str) -> str:
    text = html_lib.unescape(text)
    text = text.replace("\xa0", " ")
    text = text.replace("—", "--").replace("–", "--")
    text = text.replace("’", "'").replace("‘", "'")
    text = text.replace("“", '"').replace("”", '"')
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def split_long(text: str, target: int = 110) -> list[str]:
    """New Advent often ships a whole chapter as one <p>. Split on
    sentence boundaries so the cutter has units, without inventing
    content."""
    words = text.split()
    if len(words) <= 180:
        return [text]
    sentences = re.split(r"(?<=[.?;])\s+", text)
    paras: list[str] = []
    buf: list[str] = []
    count = 0
    for s in sentences:
        w = len(s.split())
        if buf and count + w > target:
            paras.append(" ".join(buf))
            buf = [s]
            count = w
        else:
            buf.append(s)
            count += w
    if buf:
        paras.append(" ".join(buf))
    return [p for p in paras if p.strip()]


def parse_unheaded_book(html: str) -> list[tuple[str, list[str]]]:
    """Book IV: small-caps title, then body paragraphs, no Chapter headings."""
    html = re.sub(r"<script[\s\S]*?</script>", " ", html, flags=re.I)
    html = re.sub(r"<div class='catholicadnet[\s\S]*?</div>", " ", html, flags=re.I)
    html = re.sub(r"<div class=\"CMtag[\s\S]*?</div>", " ", html, flags=re.I)
    html = re.sub(r"<div class=\"pub\"[\s\S]*", " ", html, flags=re.I)
    paras: list[str] = []
    title = "How the preacher should return to himself"
    for m in re.finditer(r"<p\b[^>]*>([\s\S]*?)</p>", html, re.I):
        inner = m.group(1)
        if "Please help support" in inner:
            continue
        text = re.sub(r"<[^>]+>", " ", inner)
        text = normalize_ws(text)
        if not text:
            continue
        sc = re.search(r'class="sc">(.*?)</span>', inner, re.S | re.I)
        if sc:
            title = normalize_ws(re.sub(r"<[^>]+>", " ", sc.group(1)))
            continue
        paras.append(text)
    if not paras:
        return []
    return [(title, paras)]


def chapter_num(heading: str, fallback: int) -> int:
    m = re.match(r"Chapter\s+(\d+)", heading, re.I)
    return int(m.group(1)) if m else fallback


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    parts = []
    for part, fname, part_title in BOOKS:
        html = (RAW / fname).read_text(encoding="utf-8", errors="replace")
        parser = _BookParser()
        parser.feed(html)
        sections = parser.finish()
        if not sections:
            # Book IV is a single untitled book: a small-caps heading and
            # two long paragraphs, no Chapter N headings.
            sections = parse_unheaded_book(html)
        chapters = []
        for title, paras in sections:
            paras = [p for p in paras if p]
            if not paras:
                continue
            n = chapter_num(title, len(chapters) + 1)
            # Introduction is Gregory's own address — keep as chapter 0-equivalent 1.
            if title.lower() in {"introduction", "preface"}:
                display = "To John, Bishop of Ravenna"
                n = 0 if title.lower() == "introduction" else n
            else:
                display = title
                if display.lower().startswith("chapter"):
                    # Prefer the strong title already stored; if the heading
                    # is just "Chapter N", use the first paragraph if short.
                    if paras and len(paras[0]) < 160 and paras[0][0].isupper():
                        display = paras[0].rstrip(".")
                        # That first para is the title, not body, when it came
                        # from <strong>. Keep it in body too — it's Gregory.
                display = re.sub(r"^Chapter\s+\d+\.?\s*", "", display, flags=re.I)
            display = display.strip() or f"Chapter {n if n else len(chapters) + 1}"
            chapters.append({
                "chapter": n if n else len(chapters) + 1,
                "title": display[:140],
                "paragraphs": [
                    q for p in paras for q in split_long(p)
                ],
            })
        # Renumber contiguous 1..N within the book.
        for i, ch in enumerate(chapters, start=1):
            ch["chapter"] = i
        if not chapters:
            raise SystemExit(f"no chapters in {fname}")
        parts.append({"part": part, "title": part_title, "chapters": chapters})
        print(f"Book {part}: {len(chapters)} chapters, "
              f"{sum(len(c['paragraphs']) for c in chapters)} paras")

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({"translator": "James Barmby (1895)", "parts": parts},
                   indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {dest}")


if __name__ == "__main__":
    main()
