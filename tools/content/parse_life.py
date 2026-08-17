#!/usr/bin/env python3
"""Parse Dialogues Book II + emit life_episodes, tools_of_good_works, medal JSON."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from bs4 import BeautifulSoup

from common import ASSETS, RAW

DIALOGUES_HTML = RAW / "dialogues_bk2.html"
LIFE_OUT = ASSETS / "life_episodes.json"
TOOLS_OUT = ASSETS / "tools_of_good_works.json"
MEDAL_OUT = ASSETS / "medal.json"
RULE_READINGS = ASSETS / "rule_readings.json"

WORD_NUM = {
    "ONE": 1,
    "TWO": 2,
    "THREE": 3,
    "FOUR": 4,
    "FIVE": 5,
    "SIX": 6,
    "SEVEN": 7,
    "EIGHT": 8,
    "NINE": 9,
    "TEN": 10,
    "ELEVEN": 11,
    "TWELVE": 12,
    "THIRTEEN": 13,
    "FOURTEEN": 14,
    "FIFTEEN": 15,
    "SIXTEEN": 16,
    "SEVENTEEN": 17,
    "EIGHTEEN": 18,
    "NINETEEN": 19,
    "TWENTY": 20,
    "TWENTY-ONE": 21,
    "TWENTY-TWO": 22,
    "TWENTY-THREE": 23,
    "TWENTY-FOUR": 24,
    "TWENTY-FIVE": 25,
    "TWENTY-SIX": 26,
    "TWENTY-SEVEN": 27,
    "TWENTY-EIGHT": 28,
    "TWENTY-NINE": 29,
    "THIRTY": 30,
    "THIRTY-ONE": 31,
    "THIRTY-TWO": 32,
    "THIRTY-THREE": 33,
    "THIRTY-FOUR": 34,
    "THIRTY-FIVE": 35,
    "THIRTY-SIX": 36,
    "THIRTY-SEVEN": 37,
    "THIRTY-EIGHT": 38,
}

CHAPTER_RE = re.compile(
    r"^\s*CHAPTER\s+([A-Z\-]+)\s*:\s*(.+?)\s*$",
    re.IGNORECASE | re.DOTALL,
)
PROLOGUE_RE = re.compile(r"^\s*PROLOGUE\b", re.IGNORECASE)
FOOTNOTE_RE = re.compile(r"\[\d+\]")
END_MARKERS = (
    "the end of the second book",
    "the st. pachomius orthodox library",
    "this text is presented here as part of the",
)


def clean_inline(text: str) -> str:
    text = text.replace("\xa0", " ").replace("\r", "")
    text = FOOTNOTE_RE.sub("", text)
    text = html_unescape_quotes(text)
    return re.sub(r"\s+", " ", text).strip()


def normalize_ws(text: str) -> str:
    """Collapse HTML line-wrap noise; keep blank-line paragraph breaks only."""
    # Prefer explicit paragraph markers we insert; also accept true blank lines.
    parts = re.split(r"\n\s*\n", text.replace("\r", ""))
    paras = []
    for block in parts:
        line = clean_inline(block)
        if line:
            paras.append(line)
    return "\n\n".join(paras)


def html_unescape_quotes(text: str) -> str:
    return (
        text.replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2018", "'")
        .replace("\u2019", "'")
    )


def title_case_heading(raw: str) -> str:
    raw = re.sub(r"\s+", " ", raw).strip(" .:;")
    # Keep short all-caps headings readable without shouting.
    if raw.isupper() or sum(1 for c in raw if c.isupper()) > len(raw) * 0.6:
        words = raw.lower().split()
        small = {
            "a",
            "an",
            "the",
            "of",
            "to",
            "in",
            "on",
            "by",
            "for",
            "and",
            "or",
            "from",
            "with",
            "at",
            "as",
            "his",
            "her",
            "their",
            "that",
            "which",
            "upon",
            "after",
            "not",
        }
        out = []
        for i, w in enumerate(words):
            if i > 0 and w in small:
                out.append(w)
            else:
                out.append(w[:1].upper() + w[1:] if w else w)
        return " ".join(out)
    return raw


def is_chrome_text(text: str) -> bool:
    t = text.strip().lower()
    if not t or t == "\xa0":
        return True
    for m in END_MARKERS:
        if t.startswith(m):
            return True
    chrome_bits = (
        "internet medieval sourcebook",
        "fordham",
        "paul halsall",
        "unless otherwise indicated",
        "permission is granted for electronic",
        "have mercy, o lord, on thy servants",
        "the end, and to god be the glory",
        "site concept and design",
        "home |",
        "medieval sourcebook:",
        "the saint pachomius",
    )
    return any(b in t for b in chrome_bits)


def parse_dialogues(html_path: Path) -> list[dict]:
    soup = BeautifulSoup(html_path.read_text(encoding="utf-8", errors="replace"), "html.parser")

    # Prefer the main content column if present.
    root = soup.find(id="tbl_rightnav") or soup.body or soup

    episodes: dict[int, dict] = {}
    current: int | None = None
    buf: list[str] = []

    def flush() -> None:
        nonlocal buf, current
        if current is None:
            buf = []
            return
        text = normalize_ws("\n\n".join(buf))
        buf = []
        if not text:
            return
        # Trim trailing end-of-book dialogue already kept; strip post-book chrome lines.
        lines = []
        for para in text.split("\n\n"):
            low = para.lower().strip()
            if low.startswith("the end of the second book"):
                break
            if is_chrome_text(para):
                continue
            lines.append(para)
        text = "\n\n".join(lines).strip()
        if current in episodes:
            prev = episodes[current]["textEn"]
            episodes[current]["textEn"] = normalize_ws(prev + "\n\n" + text) if prev else text
        else:
            episodes[current]["textEn"] = text

    heading_tags = ("h3", "h4", "p", "span")
    for el in root.find_all(heading_tags):
        classes = " ".join(el.get("class") or [])
        raw = el.get_text(" ", strip=True)
        raw_compact = re.sub(r"\s+", " ", raw).strip()

        is_subtitle = "H_Subitle" in classes or "H_Subtitle" in classes
        if is_subtitle or (
            el.name in ("h3", "h4", "p") and CHAPTER_RE.match(raw_compact)
        ) or (is_subtitle and PROLOGUE_RE.match(raw_compact)):
            if PROLOGUE_RE.match(raw_compact):
                flush()
                current = 0
                episodes[0] = {"chapter": 0, "title": "Prologue", "textEn": ""}
                continue
            m = CHAPTER_RE.match(raw_compact)
            if m:
                flush()
                word = m.group(1).upper().replace(" ", "")
                # Normalize TWENTY ONE -> TWENTY-ONE if spaced
                word = word.replace("TWENTYONE", "TWENTY-ONE")
                num = WORD_NUM.get(word)
                if num is None:
                    # try inserting hyphen for TWENTYONE style already handled
                    raise SystemExit(f"Unknown chapter word: {word!r} in {raw_compact!r}")
                title = title_case_heading(m.group(2))
                current = num
                episodes[num] = {"chapter": num, "title": title, "textEn": ""}
                continue

        # Body collection
        if current is None:
            continue
        if el.name not in ("p", "span", "pre"):
            continue
        if "H_body_text" not in classes and el.name == "span":
            continue
        if el.name == "p" and "H_Subitle" in classes:
            continue
        # Skip nested body spans that duplicate parent p text
        if el.name == "span" and el.find_parent("p", class_=re.compile(r"H_body_text")):
            continue
        text = el.get_text(" ", strip=True)
        if is_chrome_text(text):
            # Stop collecting after book end chrome
            if text.lower().startswith("the end of the second book") or any(
                text.lower().startswith(m) for m in END_MARKERS
            ):
                flush()
                current = None
            continue
        if not text.strip() or text.strip() == "\xa0":
            continue
        buf.append(clean_inline(text))

    flush()

    # Ordered prologue + 1..38
    out = []
    if 0 in episodes:
        out.append(episodes[0])
    for n in range(1, 39):
        if n not in episodes:
            raise SystemExit(f"Missing chapter {n}")
        out.append(episodes[n])
    return out


def write_life(episodes: list[dict]) -> tuple[int, int]:
    ASSETS.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "source": (
            "Gregory the Great, Dialogues Book II, trans. P.W. 1608, "
            "re-edited Edmund G. Gardner 1911"
        ),
        "episodes": episodes,
    }
    LIFE_OUT.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    words = sum(len(e["textEn"].split()) for e in episodes)
    return len(episodes), words


def extract_tools() -> list[dict]:
    data = json.loads(RULE_READINGS.read_text(encoding="utf-8"))
    readings = data.get("readings", data if isinstance(data, list) else [])
    parts = sorted(
        [r for r in readings if r.get("chapter") == 4],
        key=lambda r: r.get("portionInChapter", 0),
    )
    if not parts:
        raise SystemExit("No chapter 4 readings found in rule_readings.json")
    full = "\n".join(r.get("textEn") or "" for r in parts)
    # Drop workshop coda after the instruments list.
    full = re.split(
        r"Behold,\s*these are the instruments",
        full,
        maxsplit=1,
        flags=re.IGNORECASE,
    )[0]

    matches = list(re.finditer(r"\((\d+)\)", full))
    if not matches:
        raise SystemExit("No numbered instruments found in chapter 4 textEn")

    by_num: dict[int, str] = {}
    for i, m in enumerate(matches):
        n = int(m.group(1))
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(full)
        chunk = full[start:end]
        chunk = re.sub(r"\s+", " ", chunk).strip()
        chunk = chunk.strip(" .;:")
        if chunk:
            # Prefer sentence-final period
            if not chunk.endswith((".", "!", "?")):
                chunk = chunk + "."
            by_num[n] = chunk

    # Verheyen alignment sometimes numbers through (73); traditional set is 72,
    # ending with never despair of God's mercy. Merge 72+73 when present.
    tools: list[dict] = []
    max_n = max(by_num)
    if max_n >= 73 and 72 in by_num and 73 in by_num:
        for n in range(1, 72):
            if n not in by_num:
                raise SystemExit(f"Missing instrument ({n})")
            tools.append({"number": n, "text": by_num[n], "gloss": None})
        merged = by_num[72].rstrip(".") + ". " + by_num[73]
        if not merged.endswith("."):
            merged += "."
        tools.append({"number": 72, "text": merged, "gloss": None})
    else:
        for n in range(1, 73):
            if n not in by_num:
                raise SystemExit(f"Missing instrument ({n})")
            tools.append({"number": n, "text": by_num[n], "gloss": None})
    return tools


_TOOL_NOTES = ("gloss", "scripture", "citation")


def _existing_tool_notes() -> dict[int, dict]:
    if not TOOLS_OUT.is_file():
        return {}
    data = json.loads(TOOLS_OUT.read_text(encoding="utf-8"))
    notes: dict[int, dict] = {}
    for t in data.get("tools", []):
        n = t.get("number")
        if not n:
            continue
        kept = {k: t[k] for k in _TOOL_NOTES if t.get(k)}
        if kept:
            notes[int(n)] = kept
    return notes


def write_tools(tools: list[dict]) -> int:
    notes = _existing_tool_notes()
    for t in tools:
        t.update(notes.get(t["number"], {}))
        if not t.get("gloss"):
            t["gloss"] = None
    payload = {
        "version": 1,
        "source": "Rule of St. Benedict, ch. 4 (Verheyen), from rule_readings.json",
        "tools": tools,
    }
    TOOLS_OUT.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return len(tools)


def write_medal() -> None:
    payload = {
        "version": 1,
        "regions": [
            {
                "id": "pax",
                "face": "reverse",
                "label": "PAX",
                "expansion": "Pax",
                "meaning": "Peace.",
            },
            {
                "id": "cssml",
                "face": "reverse",
                "label": "C S S M L",
                "expansion": "Crux Sacra Sit Mihi Lux",
                "meaning": "May the Holy Cross be my light.",
            },
            {
                "id": "ndsmd",
                "face": "reverse",
                "label": "N D S M D",
                "expansion": "Non Draco Sit Mihi Dux",
                "meaning": "Let not the dragon be my guide.",
            },
            {
                "id": "cspb",
                "face": "reverse",
                "label": "C S P B",
                "expansion": "Crux Sancti Patris Benedicti",
                "meaning": "The Cross of the Holy Father Benedict.",
            },
            {
                "id": "vrsnsmv_smqlivb",
                "face": "reverse",
                "label": "V R S N S M V · S M Q L I V B",
                "expansion": (
                    "Vade Retro Satana, Nunquam Suade Mihi Vana; "
                    "Sunt Mala Quae Libas, Ipse Venena Bibas"
                ),
                "meaning": (
                    "Begone, Satan! Never tempt me with your vanities. "
                    "What you offer is evil; drink your own poison."
                ),
            },
            {
                "id": "benedict",
                "face": "obverse",
                "label": "Saint Benedict",
                "expansion": "S. Benedictus",
                "meaning": (
                    "Benedict holds the cross in his right hand "
                    "and the Rule in his left."
                ),
            },
            {
                "id": "cup",
                "face": "obverse",
                "label": "CRUX S. PATRIS",
                "expansion": "Crux Sancti Patris",
                "meaning": (
                    "The poisoned cup that shattered when he signed "
                    "the cross over it."
                ),
            },
            {
                "id": "raven",
                "face": "obverse",
                "label": "BENEDICTI",
                "expansion": "Benedicti",
                "meaning": "The raven that carried off a loaf meant to poison him.",
            },
            {
                "id": "casino",
                "face": "obverse",
                "label": "EX S M CASINO MDCCCLXXX",
                "expansion": "Ex Sacro Monte Casino, 1880",
                "meaning": (
                    "Struck at Monte Cassino for the fourteenth "
                    "centenary of Benedict's birth."
                ),
            },
            {
                "id": "obitu",
                "face": "obverse",
                "label": "EIUS IN OBITU NRO PRAESENTIA MUNIAMUR",
                "expansion": "Eius in obitu nostro praesentia muniamur",
                "meaning": (
                    "May we be strengthened by his presence "
                    "in the hour of our death."
                ),
            },
        ],
        "blessing": {
            "latin": (
                "V. Adjutorium nostrum in nomine Domini.\n"
                "R. Qui fecit caelum et terram.\n\n"
                "V. Dominus vobiscum.\n"
                "R. Et cum spiritu tuo.\n\n"
                "Oremus.\n"
                "Omnipotens sempiterne Deus, qui B. Benedicti famuli tui "
                "meritis atque pietate innumerabilia in nos contulisti "
                "beneficia: concede propitius; ut quicumque haec sancta "
                "numismata, B. Benedicti nominis et imaginis impressione "
                "signata, secum gestaverint, omnes diaboli tentationes et "
                "fraudes a se repellant, et in tua sancta gratia perseverantes, "
                "vitae aeternae mereantur esse participes. Per Christum "
                "Dominum nostrum. Amen.\n\n"
                "(Sacerdos aspergit numismata aqua benedicta.)"
            ),
            "english": (
                "V. Our help is in the name of the Lord.\n"
                "R. Who made heaven and earth.\n\n"
                "V. The Lord be with you.\n"
                "R. And with your spirit.\n\n"
                "Let us pray.\n"
                "O Almighty God, the giver of all good things, we humbly "
                "beseech You that through the intercession of St. Benedict "
                "You would pour out Your blessing upon these medals. May "
                "all who wear them with devotion be strengthened against "
                "the snares of the enemy, protected in danger, and grow in "
                "holiness. Through Christ our Lord. Amen.\n\n"
                "(The priest sprinkles the medals with holy water.)"
            ),
            "note": "Reserved to a priest.",
        },
        "litany": [
            {"invocation": "Lord, have mercy on us.", "response": "Christ, have mercy on us."},
            {"invocation": "Christ, hear us.", "response": "Christ, graciously hear us."},
            {"invocation": "God the Father of Heaven,", "response": "Have mercy on us."},
            {"invocation": "God the Son, Redeemer of the world,", "response": "Have mercy on us."},
            {"invocation": "God the Holy Spirit,", "response": "Have mercy on us."},
            {"invocation": "Holy Trinity, one God,", "response": "Have mercy on us."},
            {"invocation": "Holy Mary,", "response": "Pray for us."},
            {"invocation": "Holy Mother of God,", "response": "Pray for us."},
            {"invocation": "Holy Virgin of virgins,", "response": "Pray for us."},
            {"invocation": "Holy Father Benedict,", "response": "Pray for us."},
            {"invocation": "Father of monks and nuns,", "response": "Pray for us."},
            {"invocation": "Patriarch of Western monasticism,", "response": "Pray for us."},
            {"invocation": "Mirror of abstinence,", "response": "Pray for us."},
            {"invocation": "Star of chastity,", "response": "Pray for us."},
            {"invocation": "Vessel of holy poverty,", "response": "Pray for us."},
            {"invocation": "Example of obedience,", "response": "Pray for us."},
            {"invocation": "Light of discretion,", "response": "Pray for us."},
            {"invocation": "Master of the Rule,", "response": "Pray for us."},
            {"invocation": "Terror of evil spirits,", "response": "Pray for us."},
            {"invocation": "Comfort of the dying,", "response": "Pray for us."},
            {"invocation": "Lamb of God, who takes away the sins of the world,", "response": "Spare us, O Lord."},
            {"invocation": "Lamb of God, who takes away the sins of the world,", "response": "Graciously hear us, O Lord."},
            {"invocation": "Lamb of God, who takes away the sins of the world,", "response": "Have mercy on us."},
        ],
        "history": (
            "The medal associated with St. Benedict grew from older cross and "
            "formula traditions used for protection and blessing. Its best-known "
            "form is the Jubilee Medal struck in 1880 for the fourteenth "
            "centenary of Benedict's birth, prepared at Monte Cassino. That "
            "design fixed the familiar arrangement: the cross with the letters "
            "C S P B, the circular petition Crux Sacra Sit Mihi Lux / Non Draco "
            "Sit Mihi Dux, the Vade Retro Satana verse on the rim, and PAX above. "
            "Earlier medals and manuscript charms carried related initials; the "
            "1880 type became the standard visual reference thereafter."
        ),
    }
    MEDAL_OUT.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    if not DIALOGUES_HTML.is_file():
        print(f"missing {DIALOGUES_HTML}", file=sys.stderr)
        return 1

    episodes = parse_dialogues(DIALOGUES_HTML)
    n_ep, words = write_life(episodes)
    print(f"wrote {LIFE_OUT}")
    print(f"episodes: {n_ep}")
    print(f"word_count: {words}")

    tools = extract_tools()
    n_tools = write_tools(tools)
    print(f"wrote {TOOLS_OUT}")
    print(f"tools: {n_tools}")

    write_medal()
    print(f"wrote {MEDAL_OUT}")
    print(f"medal regions: 5; litany: {len(json.loads(MEDAL_OUT.read_text())['litany'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
