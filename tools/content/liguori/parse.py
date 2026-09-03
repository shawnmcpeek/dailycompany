#!/usr/bin/env python3
"""Parse Grimm's 31 Visits into the cut.py chapter shape.

No cutter pass — each Visit is already atomic. One chapter per day:
the Sacrament visit plus that day's visit to Mary (Naples extras dropped).

Reads:  tools/content/liguori/raw/visitN.htm, virginN.htm, blessed-sacrament.htm
Writes: tools/content/liguori/work/chapters.json
        tools/content/liguori/work/manner.json
"""

from __future__ import annotations

import html as html_lib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
WORK = ROOT / "work"

ORDINALS = (
    "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh",
    "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth", "Thirteenth",
    "Fourteenth", "Fifteenth", "Sixteenth", "Seventeenth", "Eighteenth",
    "Nineteenth", "Twentieth", "Twenty-first", "Twenty-second",
    "Twenty-third", "Twenty-fourth", "Twenty-fifth", "Twenty-sixth",
    "Twenty-seventh", "Twenty-eighth", "Twenty-ninth", "Thirtieth",
    "Thirty-first",
)

# Host-page typos that the 1887 Benziger does not have.
TYPOS = (
    (r"\bin tile world\b", "in the world"),
    (r"\bteacheth me\b", "teach me"),  # visit 1 host; Grimm: "teach me"
)


def html_to_text(raw: bytes) -> str:
    text = raw.decode("latin-1")
    text = re.sub(r"(?is)<script[^>]*>.*?</script>", " ", text)
    text = re.sub(r"(?is)<style[^>]*>.*?</style>", " ", text)
    text = re.sub(r"(?i)<br\s*/?>", "\n", text)
    text = re.sub(r"(?i)</(p|div|h[1-6]|li|tr)>", "\n", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = html_lib.unescape(text)
    text = text.replace("\xa0", " ").replace("\r", "")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n[ \t]+", "\n", text)
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def clean_prose(text: str) -> str:
    text = re.sub(r"\[(?:[^\]]{1,160})\]", "", text)
    for pat, repl in TYPOS:
        text = re.sub(pat, repl, text, flags=re.I)
    text = re.sub(r"C\s*ontact\s*U\s*s.*$", "", text, flags=re.I | re.S)
    text = re.sub(r"www\.catholictradition\.org\S*", "", text, flags=re.I)
    text = re.sub(r"HOME\s*[.\-\s]*THE\s*SACRED HEART.*$", "", text, flags=re.I | re.S)
    text = re.sub(r"-{3,}", "—", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", "\n", text)
    # Host pages wrap mid-sentence; keep only true paragraph breaks.
    text = re.sub(r"(?<!\n)\n(?!\n)", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"\s+,", ",", text)
    text = re.sub(r",\s*,", ",", text)
    text = re.sub(r"\s+([.!?])", r"\1", text)
    text = re.sub(r" {2,}", " ", text)
    return text.strip(" \n\"")


def paragraphs(text: str) -> list[str]:
    parts = [clean_prose(p) for p in re.split(r"\n\s*\n", text)]
    return [p for p in parts if p and len(p) > 8]


def slice_between(text: str, start: re.Pattern[str], end: re.Pattern[str] | None) -> str:
    m = start.search(text)
    if not m:
        raise ValueError(f"start not found: {start.pattern}")
    rest = text[m.end() :]
    if end is not None:
        e = end.search(rest)
        if e:
            rest = rest[: e.start()]
    return rest.strip()


def parse_sacrament(n: int) -> str:
    text = html_to_text((RAW / f"visit{n}.htm").read_bytes())
    ordinal = ORDINALS[n - 1].replace("-", r"[-\s]+")
    body = slice_between(
        text,
        re.compile(
            rf"{ordinal}\s+VISIT(?:\s+To the Blessed Sacrament)?",
            re.I,
        ),
        re.compile(
            r"Then follows the SPIRITUAL\s+COMMUNION|"
            r"Visit to the Blessed Virgin Mary,?\s*Click|"
            r"Contact Us",
            re.I,
        ),
    )
    body = re.sub(
        r"^(?:To the Blessed Sacrament\s*)?"
        r"(?:Say the preliminary prayer,?\s*MY LORD JESUS CHRIST,?\s*etc\.?\s*)?",
        "",
        body,
        flags=re.I,
    )
    body = re.split(r"Then follows the SPIRITUAL\s+COMMUNION", body, maxsplit=1, flags=re.I)[0]
    return clean_prose(body)


def parse_virgin(n: int) -> str:
    text = html_to_text((RAW / f"virgin{n}.htm").read_bytes())
    body = slice_between(
        text,
        re.compile(r"Visit to the Blessed Virgin Mary", re.I),
        re.compile(
            r"THE PRAYER TO BE SAID|"
            r"From the Naples\s+Edition|"
            r"NOTE:|"
            r"Contact Us",
            re.I,
        ),
    )
    return clean_prose(body)


def parse_manner() -> dict[str, str]:
    text = html_to_text((RAW / "blessed-sacrament.htm").read_bytes())

    acts = slice_between(
        text,
        re.compile(
            r"ACTS TO BE MADE BEFORE EACH VISIT TO THE\s+MOST BLESSED SACRAMENT",
            re.I,
        ),
        re.compile(r"AN ACT OF SPIRITUAL COMMUNION", re.I),
    )
    # Drop the Pius IX indulgence footnote that follows the acts in some hosts.
    acts = re.split(r"His Holiness,\s*Pius", acts, maxsplit=1)[0]

    spiritual = slice_between(
        text,
        re.compile(r"AN ACT OF SPIRITUAL COMMUNION", re.I),
        re.compile(r"A SHORTER ACT", re.I),
    )
    shorter = slice_between(
        text,
        re.compile(r"A SHORTER ACT", re.I),
        re.compile(
            r"May the burning|After the spiritual Communion|VISIT TO THE BLESSED VIRGIN",
            re.I,
        ),
    )
    mary = slice_between(
        text,
        re.compile(
            r"Most holy Immaculate Virgin and my Mother Mary",
            re.I,
        ),
        re.compile(r"After this prayer|HYMNS|Contact Us|Contents:", re.I),
    )
    if not mary.lower().startswith("most holy"):
        mary = "Most holy Immaculate Virgin and my Mother Mary, " + mary

    return {
        "actsBefore": clean_prose(acts),
        "spiritualCommunion": clean_prose(spiritual),
        "shorterAct": clean_prose(shorter),
        "closingMary": clean_prose(mary),
    }


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    chapters = []
    for n in range(1, 32):
        sacrament = parse_sacrament(n)
        virgin = parse_virgin(n)
        if len(sacrament) < 200:
            raise SystemExit(f"visit {n} sacrament too short ({len(sacrament)})")
        if len(virgin) < 80:
            raise SystemExit(f"visit {n} virgin too short ({len(virgin)})")
        paras = paragraphs(sacrament)
        paras.append("Visit to the Blessed Virgin Mary.")
        paras.extend(paragraphs(virgin))
        chapters.append({
            "chapter": n,
            "title": f"{ORDINALS[n - 1]} Visit",
            "paragraphs": paras,
        })
        print(f"  {n:2d} {ORDINALS[n - 1]:<16} "
              f"{sum(len(p.split()) for p in paras):4d} words")

    manner = parse_manner()
    for key, val in manner.items():
        print(f"  manner.{key}: {len(val.split())} words")
        if len(val) < 40:
            raise SystemExit(f"manner.{key} too short")

    out = {
        "parts": [{
            "part": 1,
            "title": "Visits to the Blessed Sacrament",
            "chapters": chapters,
        }]
    }
    (WORK / "chapters.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (WORK / "manner.json").write_text(
        json.dumps(manner, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    words = sum(len(p.split()) for c in chapters for p in c["paragraphs"])
    print(f"wrote {WORK / 'chapters.json'} ({words} words, 31 visits)")


if __name__ == "__main__":
    main()
