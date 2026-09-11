#!/usr/bin/env python3
"""Emit remaining named-PD shelves as WorkShelf JSON."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT.parent.parent / "assets" / "content"
sys.path.insert(0, str(ROOT))
from ocr_clean import clean_ocr_english  # noqa: E402

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8,
    "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14, "XV": 15,
    "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
    "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26, "XXVII": 27,
    "XXVIII": 28, "XXIX": 29, "XXX": 30, "XXXI": 31, "XXXII": 32,
    "XXXIII": 33, "XXXIV": 34, "XXXV": 35, "XXXVI": 36, "XXXVII": 37,
    "XXXVIII": 38, "XXXIX": 39, "XL": 40, "XLI": 41, "XLII": 42,
    "XLIII": 43, "XLIV": 44, "XLV": 45, "XLVI": 46, "XLVII": 47,
    "XLVIII": 48, "XLIX": 49, "L": 50, "LI": 51, "LII": 52, "LIII": 53,
    "LIV": 54, "LV": 55, "LVI": 56, "LVII": 57, "LVIII": 58, "LIX": 59,
    "LX": 60, "LXI": 61, "LXII": 62, "LXIII": 63, "LXIV": 64, "LXV": 65,
    "LXVI": 66, "LXVII": 67, "LXVIII": 68, "LXIX": 69, "LXX": 70,
    "LXXI": 71, "LXXII": 72, "LXXIII": 73, "LXXIV": 74, "LXXV": 75,
    "LXXVI": 76, "LXXVII": 77, "LXXVIII": 78, "LXXIX": 79, "LXXX": 80,
    "LXXXI": 81, "LXXXII": 82, "LXXXIII": 83, "LXXXIV": 84, "LXXXV": 85,
    "LXXXVI": 86, "LXXXVII": 87, "LXXXVIII": 88, "LXXXIX": 89, "XC": 90,
    "XCI": 91, "XCII": 92, "XCIII": 93, "XCIV": 94, "XCV": 95,
    "XCVI": 96, "XCVII": 97, "XCVIII": 98, "XCIX": 99, "C": 100,
}

GARBLE_HEAD = re.compile(
    r"Qorirait|Dalue of Gime|Jreparing|Wisgrace|Donrnep|Mlercp|"
    r"Micans|Shoriness|Weath of the Iust|Eternity of spell|"
    r"folip of the|Ginner|Gappp|F.jolp|Honr of Death|Ireparing",
    re.I,
)
INLINE_NOTE = re.compile(r"\s*\[\d{1,4}\]")
FOOTNOTE_LINE = re.compile(r"^\[\d{1,4}\]")
PAGE_ONLY = re.compile(r"^\d{1,4}[a-z]?$")
SIG = re.compile(r"^[A-Z]$")
URL = re.compile(r"^https?://", re.I)
LATIN_CITE = re.compile(
    r"(Col\.|Eph\.|Apoc\.|Matt\.|Luke|John,|Rom\.|Heb\.|Ps\.|"
    r"i Kings|Isa\.|Jer\.|Prov\.|Gal\.|Acts)",
    re.I,
)


def collapse(line: str) -> str:
    return re.sub(r"[ \t]+", " ", line.replace("\u00a0", " ")).strip()


def lines_of(path: Path) -> list[str]:
    return [collapse(l) for l in path.read_text(encoding="utf-8", errors="replace").splitlines()]


def title_case(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip().rstrip(".")
    if not text:
        return "Chapter"
    letters = sum(c.isalpha() for c in text)
    caps = sum(c.isupper() for c in text if c.isalpha())
    if letters and caps / letters > 0.55:
        small = {"of", "the", "and", "in", "on", "a", "an", "for", "to", "by", "with"}
        words = text.lower().split()
        out = []
        for i, w in enumerate(words):
            out.append(w if i and w in small else w[:1].upper() + w[1:])
        return " ".join(out)
    return text[0].upper() + text[1:]


def is_chrome(s: str) -> bool:
    if not s:
        return False
    u = s.upper()
    if "DIGITIZED BY" in u or "GOOGLE" == u:
        return True
    if "PROJECT GUTENBERG" in u:
        return True
    if "THIS DOCUMENT IS FROM THE C" in u:
        return True
    if "CCEL.ORG" in u:
        return True
    if URL.match(s):
        return True
    if PAGE_ONLY.match(s) or SIG.match(s):
        return True
    if s.startswith("_____"):
        return True
    if re.fullmatch(r"[_—–-]{5,}", s):
        return True
    if re.fullmatch(r"[IJ]H[IU]S\.?", u):
        return True
    if u in {"IJIUS", "IJIUS.", "IFTIGO", "IGO.", "IGO"}:
        return True
    if len(s) < 110 and GARBLE_HEAD.search(s):
        return True
    return False


def is_running_head(s: str) -> bool:
    if not s:
        return False
    u = s.upper()
    if "LETTERS AND INSTRUCTIONS" in u:
        return True
    if u.startswith("OF ST. IGNATIUS") or u.startswith("OF ST IGNATIUS"):
        return True
    if "SPIRITUAL TREATISES" in u:
        return True
    if "PREPARATION FOR DEATH" in u and len(s) < 80:
        return True
    if "LEGATION BY MONKS" in u:
        return True
    if re.match(r"^\d+\s+ST\.?\s+GREGORY\b", u):
        return True
    if re.match(r"^BX\s+\d", u):
        return True
    if re.match(r"^\d[-.]?\d{0,2}\s+CONFERENCE\b", u):
        return True
    if len(s) > 70:
        return False
    if re.match(r"^.+\s+\d{1,3}$", s) and not s.endswith("."):
        return True
    if re.match(r"^\d{1,3}\s+.+$", s) and len(s) < 50:
        return True
    return False


def is_footnote_line(s: str) -> bool:
    if not s:
        return False
    if FOOTNOTE_LINE.match(s):
        return True
    if s[0] in "■†‡§" or s.startswith("» "):
        return True
    if s.startswith("* ") and len(s) < 400:
        return True
    if re.match(r"^\d+\s+[\"“]", s) and LATIN_CITE.search(s):
        return True
    if s.startswith('"') and LATIN_CITE.search(s) and len(s) < 220:
        return True
    if s.startswith("—") and LATIN_CITE.search(s):
        return True
    if re.search(
        r"\b(Baronius|Bingham Antiq|vide\s*Du\s*Cange|Du Cange|"
        r"Act\. Sanct|Hist\. Lit|"
        r"Boll\. Act|Codex Regularum|Isidoriana)\b",
        s,
        re.I,
    ):
        return True
    if re.search(r"\bBar\.\s+an\.", s):
        return True
    return False


_SIDENOTE_PREFIX = re.compile(r"^[»*^]\s*[A-Za-z]{1,16}[,]?\s+")


_NOTE_BLOB = re.compile(
    r"Codex Regularum|Mozarabic Missal|Isidoriana|Bollaud|"
    r"brother-in-law to Theodoric|Council of Toledo|"
    r"locally honoured as|sister Florentina|"
    r"Apocrisiarius|Du Cange|Gibbon|Herminigild was deposed|"
    r"Cardinal Deacons|Gregory of Tours|"
    r"ancient Roman Breviary|Biographer places|"
    r"Pro confirmandis|fifth General Council|"
    r"Herminigild was unsuccessful|stock of the Cross",
    re.I,
)


def is_note_para(p: str) -> bool:
    if not p:
        return True
    if p[0] in "■»*^†‡§«":
        return True
    if _NOTE_BLOB.search(p):
        return True
    cites = len(re.findall(r"\b(Ep\.|Lib\.|Bar\.|vid\.|cf\.|tom\.)\b", p))
    return cites >= 3


def stitch_sentences(paras: list[str]) -> list[str]:
    """Put page-break fragments back into the sentence they belong to."""
    out: list[str] = []
    for p in paras:
        p = p.strip()
        if not p:
            continue
        p = re.sub(r"^Ep\.\s+to\s+", "", p)
        p = re.sub(r"^(Leand,|pref\.?|BOOK|Reg-\s*S\.)\s+", "", p, flags=re.I)
        p = re.sub(r"^'[A-Za-z]{2,10}-", "", p)
        peeled = _SIDENOTE_PREFIX.sub("", p, count=1)
        if peeled != p and peeled[:1].islower() and len(peeled.split()) > 8:
            p = peeled
        if is_note_para(p):
            continue
        if out and (p[0].islower() or p[0] in ",;:"):
            out[-1] = out[-1] + " " + p
        else:
            out.append(p)
    return out


def dehyphen(buf: list[str]) -> str:
    out: list[str] = []
    for line in buf:
        if out and out[-1].endswith("-") and line[:1].isalpha():
            out[-1] = out[-1][:-1] + line
        else:
            out.append(line)
    text = " ".join(out)
    text = INLINE_NOTE.sub("", text)
    text = re.sub(r"\s+", " ", text).strip()
    return clean_ocr_english(text)


def join_lines(raw: list[str]) -> str:
    paras: list[str] = []
    buf: list[str] = []
    skipping_note = False
    for s in raw:
        if is_chrome(s) or is_running_head(s):
            continue
        if is_footnote_line(s) or (
            skipping_note and s and (s[0].islower() or s[0] in "■»*^†‡§")
        ):
            skipping_note = True
            continue
        skipping_note = False
        if not s:
            if buf and buf[-1].endswith("-"):
                continue
            if buf:
                paras.append(dehyphen(buf))
                buf = []
            continue
        buf.append(s)
    if buf:
        paras.append(dehyphen(buf))
    paras = stitch_sentences(paras)
    return "\n\n".join(p for p in paras if len(p.split()) >= 3)


def roman(token: str) -> int:
    t = re.sub(r"[^IVXL]", "", token.upper())
    if t not in ROMAN:
        raise SystemExit(f"unknown roman {token!r}")
    return ROMAN[t]


def chapter(n: int, title: str, text: str) -> dict:
    text = text.strip()
    if len(text.split()) < 20:
        raise SystemExit(f"thin chapter {n} {title!r}")
    return {"chapter": n, "title": title_case(title) if title else f"Chapter {n}", "textEn": text}


def book(id_: str, title: str, parts: list[dict]) -> dict:
    return {"id": id_, "title": title, "parts": parts}


def part(n: int, title: str, chapters: list[dict]) -> dict:
    return {"part": n, "title": title, "chapters": chapters}


def write_shelf(dest: Path, *, translator: str, label: str, intro: str, books: list[dict]) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "translator": translator,
        "label": label,
        "intro": intro,
        "books": books,
    }
    dest.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    n = sum(len(p["chapters"]) for b in books for p in b["parts"])
    words = sum(
        len(c["textEn"].split())
        for b in books
        for p in b["parts"]
        for c in p["chapters"]
    )
    print(f"wrote {dest} ({len(books)} works, {n} chapters, {words:,} words)")


CONF_TITLES = {
    1: "Obligation of the Constitutions",
    2: "On Confidence",
    3: "On Constancy",
    4: "On Cordiality",
    5: "On Generosity",
    6: "On Hope",
    7: "Three Spiritual Laws",
    8: "On Self-Renouncement",
    9: "On Religious Modesty",
    10: "On Obedience",
    11: "The Virtue of Obedience",
    12: "On Simplicity and Religious Prudence",
    13: "On the Rules and the Spirit of the Visitation",
    14: "On Private Judgment",
    15: "The Will of God",
    16: "On Antipathies",
    17: "On Voting in a Community",
    18: "The Sacraments and Divine Office",
    19: "On the Virtues of St. Joseph",
    20: "Why We Should Become Religious",
    21: "On Asking for Nothing and Refusing Nothing",
}

PREP_TITLES = {
    1: "Portrait of a Man Who Has Recently Gone into the Other World",
    2: "With Death All Ends",
    3: "Shortness of Life",
    4: "The Certainty of Death",
    5: "Uncertainty of the Hour of Death",
    6: "The Death of the Sinner",
    7: "Sentiments of a Dying Christian, Who Has Been Careless About the Duties of Religion",
    8: "The Death of the Just",
    9: "Peace of the Just at the Hour of Death",
    10: "Means of Preparing for Death",
    11: "Value of Time",
    12: "The Importance of Salvation",
    13: "The Vanity of the World",
    14: "Life Is a Journey to Eternity",
    15: "The Malice of Mortal Sin",
    16: "The Mercy of God",
    17: "Abuse of Divine Mercy",
    18: "The Number of Sins",
    19: "The State of Grace and of Disgrace with God",
    20: "The Folly of the Sinner",
    21: "Unhappy Life of the Sinner: and Happy Life of Him Who Loves God",
    22: "The Habit of Sin",
    23: "The Delusions which the Devil Puts into the Minds of Sinners",
    24: "The Particular Judgment",
    25: "The General Judgment",
    26: "The Pains of Hell",
    27: "The Eternity of Hell",
    28: "The Remorse of the Damned",
    29: "Heaven",
    30: "Prayer",
    31: "Perseverance",
    32: "Confidence in the Patronage of Mary",
    33: "The Love of God",
    34: "Holy Communion",
    35: "Dwelling of Jesus on Our Altars",
    36: "The Conformity to the Will of God",
}

IGNATIUS_LETTER_TITLES = {
    1: "To Ines Pascual",
    2: "To Ines Pascual",
    3: "To Martin Garcia de Onaz",
    4: "To Jacobo Cazador",
    5: "To Teresa Rejadella",
    6: "To Teresa Rejadella",
    7: "To Giovanni Pietro Caraffa",
    8: "To Father Juan de Verdolay",
    9: "To Pietro Contarini",
    10: "To the Citizens of Azpeitia",
    11: "To Magdalena de Loyola",
    12: "To Fathers Broet and Salmeron",
    13: "Further Instructions to the Same Legates",
    14: "To Fathers Broet and Salmeron",
    15: "To Father Giovanni Battista Viola",
    16: "To Teresa Rejadella",
    17: "To a Man Tempted",
    18: "To the Jesuits Banished from Cologne",
    19: "To Francis Borgia",
    20: "To the Society at Trent",
    21: "To Father Bartholomew Ferronius",
    22: "To Francis Borgia, Duke of Gandia",
    23: "To Father Juan de Polanco",
    24: "To the Fathers and Brothers at Coimbra",
}


def conf_num(s: str) -> int | None:
    t = re.sub(r"[^A-Za-z0-9 ]", "", s).upper()
    t = (
        t.replace("CONFEEENCE", "CONFERENCE")
        .replace("CONFEKENCE", "CONFERENCE")
        .replace("CONFERENOE", "CONFERENCE")
        .replace("CONFER ENCE", "CONFERENCE")
    )
    m = re.match(r"^CONFERENCE ([IVXL]+)\b", t)
    if not m:
        return None
    return roman(m.group(1))


def emit_conferences() -> None:
    ls = lines_of(ROOT / "desales" / "raw" / "conferences_mackey_djvu.txt")
    start = next(i for i, s in enumerate(ls) if s == "CONFERENCES OF")
    heads: list[tuple[int, int]] = []
    for i, s in enumerate(ls[start:], start=start):
        n = conf_num(s)
        if n and (not heads or n == heads[-1][1] + 1 or n > heads[-1][1]):
            if heads and n <= heads[-1][1]:
                continue
            heads.append((i, n))
    if [n for _, n in heads] != list(range(1, 22)):
        raise SystemExit(f"conferences heads {[n for _, n in heads]}")
    chapters = []
    for i, (idx, n) in enumerate(heads):
        end = heads[i + 1][0] if i + 1 < len(heads) else len(ls)
        body = ls[idx + 1 : end]
        title = CONF_TITLES[n]
        text = join_lines(body)
        chapters.append(chapter(n, title, text))
    write_shelf(
        ASSETS / "desales" / "conferences.json",
        translator="Abbot Gasquet and Canon Mackey (1906)",
        label="Conferences",
        intro="The Spiritual Conferences, translated from the Annecy text of 1895 under the supervision of Abbot Gasquet and Canon Mackey. Burns & Oates, 1906.",
        books=[book("conferences", "The Spiritual Conferences", [part(1, "Conferences", chapters)])],
    )


def emit_liguori() -> None:
    way = lines_of(ROOT / "liguori" / "raw" / "way_salvation_grimm_djvu.txt")
    start = next(i for i, s in enumerate(way) if s.startswith("III. CONFORMITY TO THE WILL OF GOD") and i > 10000)
    end = next(i for i, s in enumerate(way) if i > start and s.startswith("IV. THE WA"))
    sections = [
        (re.compile(r"^Excellence of this Virtue\.?$", re.I), "Excellence of this virtue"),
        (re.compile(r"^Conformity in All Things\.?$", re.I), "Conformity in all things"),
        (re.compile(r"^Happiness obtained from Perfect Conformity\.?$", re.I), "Happiness obtained from perfect conformity"),
        (re.compile(r"^God Wishes Only Our Good\.?$", re.I), "God wishes only our good"),
        (re.compile(r"^Special Practices of this Conformity\.?$", re.I), "Special practices of this conformity"),
    ]
    idxs = []
    for pat, title in sections:
        idxs.append((next(i for i, s in enumerate(way) if i > start and pat.match(s)), title))
    uni = []
    for i, (idx, title) in enumerate(idxs):
        stop = idxs[i + 1][0] if i + 1 < len(idxs) else end
        # Drop the closing hymn if it appears in the last section.
        chunk = way[idx + 1 : stop]
        hymn = next((j for j, s in enumerate(chunk) if s.startswith("How Amiable is the Will of God")), None)
        if hymn is not None:
            chunk = chunk[:hymn]
        uni.append(chapter(i + 1, title, join_lines(chunk)))

    death = lines_of(ROOT / "liguori" / "raw" / "prep_death_grimm_djvu.txt")
    cons: list[tuple[int, int]] = []
    for i, s in enumerate(death):
        m = re.match(r"^CONSIDERATION\s+(.+)$", s, re.I)
        if not m:
            continue
        if i < 1300:
            continue
        cons.append((i, len(cons) + 1))
    if len(cons) != 36:
        raise SystemExit(f"expected 36 considerations, got {len(cons)}")
    prep = []
    for i, (idx, n) in enumerate(cons):
        end = cons[i + 1][0] if i + 1 < len(cons) else next(
            (j for j, s in enumerate(death) if j > idx + 20 and s.upper().startswith("MAXIMS OF ETERNITY")),
            len(death),
        )
        body = death[idx + 1 : end]
        title = PREP_TITLES[n]
        text = join_lines(body)
        prep.append(chapter(n, title, text))

    write_shelf(
        ASSETS / "liguori" / "works.json",
        translator="Eugene Grimm, CSsR (Centenary Edition)",
        label="Works",
        intro="Uniformity with God's Will (here titled Conformity to the Will of God) and Preparation for Death, from Grimm's Complete Ascetical Works. Not the daily Visits.",
        books=[
            book("uniformity", "Conformity to the Will of God", [part(1, "Treatise", uni)]),
            book("preparation", "Preparation for Death", [part(1, "Considerations", prep)]),
        ],
    )


def emit_moralia() -> None:
    ls = lines_of(ROOT / "gregory" / "raw" / "moralia_v1_djvu.txt")
    ep_i = next(i for i, s in enumerate(ls) if s.startswith("THE EPISTLE") and i > 300)
    books: list[tuple[int, int, str]] = []
    for i, s in enumerate(ls):
        m = re.match(r"^BOOK\s+(I{1,3}|IV|V|VI|11)\.?$", s, re.I)
        if not m or i < ep_i:
            continue
        token = m.group(1).upper().replace("11", "II")
        n = roman(token) if token != "II" or m.group(1) != "11" else 2
        if token == "11":
            n = 2
        else:
            n = roman(token)
        if n > 6:
            break
        if books and n <= books[-1][1]:
            continue
        books.append((i, n, s))
    # Keep epistle + I–V. Book VI starts the rest.
    books = [(i, n, s) for i, n, s in books if n <= 6]
    if [n for _, n, _ in books][:6] != [1, 2, 3, 4, 5, 6]:
        raise SystemExit(f"moralia books {[n for _, n, _ in books]}")
    parts = []
    ep_end = books[0][0]
    parts.append(part(0, "Prefatory epistle", [chapter(1, "To Leander", join_lines(ls[ep_i + 1 : ep_end]))]))
    for i, (idx, n, _) in enumerate(books):
        if n == 6:
            break
        end = books[i + 1][0]
        chunk = ls[idx + 1 : end]
        # Split on numbered sections; merge thin ones.
        cuts = [0]
        for j, s in enumerate(chunk):
            if j < 8:
                continue
            if re.match(r"^\d{1,2}\.\s+\S", s) and len(s) > 20:
                cuts.append(j)
        cuts.append(len(chunk))
        chs = []
        buf_start = cuts[0]
        buf_title = "Opening"
        pending: list[str] = []
        for a, b in zip(cuts, cuts[1:]):
            piece = chunk[a:b]
            if not piece:
                continue
            title = re.sub(r"^\d+\.\s*", "", piece[0])[:120]
            title = re.sub(r"\s*[ivxlc]{1,7}[,.]?$", "", title, flags=re.I)
            title = clean_ocr_english(title).strip(" -–,")
            if (
                not title
                or title.lower() in {"chapter", "opening", "book"}
                or re.match(r"^[XILV]+\.\s*\(", title)
                or "sqq" in title.lower()
            ):
                title = "Opening"
            pending.extend(piece)
            text = join_lines(pending)
            if len(text.split()) < 400 and b != cuts[-1]:
                continue
            if title == "Opening":
                first = re.split(r"(?<=[.?!])\s+", text, maxsplit=1)[0]
                title = first[:110].rstrip(" ,;:")
            chs.append(chapter(len(chs) + 1, title_case(title)[:140], text))
            pending = []
        if pending:
            text = join_lines(pending)
            if len(text.split()) >= 20:
                chs.append(chapter(len(chs) + 1, "Close", text))
        if len(chs) < 3:
            raise SystemExit(f"moralia book {n} only {len(chs)} chapters")
        parts.append(part(n, f"Book {n}", chs))
    write_shelf(
        ASSETS / "gregory" / "moralia.json",
        translator="Library of the Fathers (Bliss / Marriott, 1844)",
        label="Moralia",
        intro="Morals on the Book of Job: the prefatory epistle to Leander and Books I–V. An editorial opening, not the thirty-five books.",
        books=[book("moralia", "Morals on the Book of Job", parts)],
    )


def ccel_split(ls: list[str], start: int, end: int, head_re: re.Pattern[str]) -> list[dict]:
    idxs = [(i, s) for i, s in enumerate(ls) if start <= i < end and head_re.match(s)]
    out = []
    for i, (idx, s) in enumerate(idxs):
        stop = idxs[i + 1][0] if i + 1 < len(idxs) else end
        m = head_re.match(s)
        assert m
        token = m.group(1)
        n = int(token) if token.isdigit() else roman(token)
        body = ls[idx + 1 : stop]
        title = next((x for x in body[:6] if x and not is_chrome(x) and not x.startswith("_____")), f"Chapter {n}")
        # Skip scripture-range-only titles that are just the pericope line.
        text = join_lines(body)
        out.append(chapter(n, title, text))
    return out


def emit_augustine() -> None:
    john = lines_of(ROOT / "augustine" / "raw" / "ccel_npnf107.txt")
    h_start = next(i for i, s in enumerate(john) if s == "Homily I." and i > 30000)
    ten = ccel_split(john, h_start, len(john), re.compile(r"^Homily ([IVX]+)\.\s*$"))
    ten = ten[:10]
    if len(ten) != 10:
        raise SystemExit(f"1 John homilies {len(ten)}")

    sermons_ls = lines_of(ROOT / "augustine" / "raw" / "ccel_npnf106.txt")
    s_start = next(i for i, s in enumerate(sermons_ls) if s == "Sermon I." and i > 20000)
    sermons = ccel_split(
        sermons_ls,
        s_start,
        len(sermons_ls),
        re.compile(r"^Sermon ([IVXL]+)\.\s*$"),
    )
    if len(sermons) < 40:
        raise SystemExit(f"too few sermons {len(sermons)}")
    write_shelf(
        ASSETS / "augustine" / "homilies.json",
        translator="H. Browne (NPNF I.7, 1888) and R. G. MacMullen (NPNF I.6, 1888)",
        label="Homilies",
        intro="Ten Homilies on the First Epistle of John (Browne) and the Sermons on Selected Lessons of the New Testament (MacMullen).",
        books=[
            book("1-john", "Homilies on the First Epistle of John", [part(1, "Ten homilies", ten)]),
            book("sermons", "Sermons on Selected Lessons", [part(1, "Sermons", sermons)]),
        ],
    )


def emit_life() -> None:
    ls = lines_of(ROOT / "teresa-avila" / "raw" / "ccel_life.txt")
    pro_i = next(i for i, s in enumerate(ls) if s == "Prologue." and i > 1800)
    ch_heads = [(i, roman(m.group(1))) for i, s in enumerate(ls) if (m := re.match(r"^Chapter ([IVXL]+)\.\s*$", s)) and i > pro_i]
    if [n for _, n in ch_heads] != list(range(1, 41)):
        raise SystemExit(f"life chapters {[n for _, n in ch_heads]}")
    prologue = join_lines(ls[pro_i + 1 : ch_heads[0][0]])
    chapters = [chapter(1, "Prologue", prologue)]
    # Keep prologue as chapter 1 of part 0; Life 1–40 keep their numbers in part 1.
    life_chs = []
    for i, (idx, n) in enumerate(ch_heads):
        end = ch_heads[i + 1][0] if i + 1 < len(ch_heads) else next(
            (j for j, s in enumerate(ls) if j > idx and s.startswith("This document is from the C")),
            len(ls),
        )
        body = ls[idx + 1 : end]
        title = next((s for s in body if s and not is_chrome(s) and not s.startswith("[")), f"Chapter {n}")
        life_chs.append(chapter(n, title, join_lines(body)))
    write_shelf(
        ASSETS / "teresa-avila" / "life.json",
        translator="David Lewis (1870; 1904 Baker impression)",
        label="Life",
        intro="The Life of Teresa of Jesus, translated by David Lewis. A shelf of the book as written — not recut into the Way and Castle year.",
        books=[book("life", "The Life", [
            part(0, "Prologue", chapters),
            part(1, "The Life", life_chs),
        ])],
    )


def emit_ignatius_letters() -> None:
    ls = lines_of(ROOT / "ignatius" / "raw" / "letters_1914_djvu.txt")
    start = next(i for i, s in enumerate(ls) if "TO INES PASCUAL" in s.upper() and i > 330)
    heads: list[tuple[int, int]] = [(start, 1)]
    for i, s in enumerate(ls[start + 1 :], start=start + 1):
        m = re.match(r"^([IVXL]+)\.\s*$", s)
        if not m:
            continue
        n = roman(m.group(1))
        if n == heads[-1][1] + 1:
            heads.append((i, n))
    chapters = []
    for i, (idx, n) in enumerate(heads):
        end = heads[i + 1][0] if i + 1 < len(heads) else len(ls)
        body = ls[idx:end]
        title = IGNATIUS_LETTER_TITLES.get(n, f"Letter {n}")
        chapters.append(chapter(n, title, join_lines(body)))
    if len(chapters) < 20:
        raise SystemExit(f"ignatius letters {len(chapters)}")
    write_shelf(
        ASSETS / "ignatius" / "letters.json",
        translator="D. F. O'Leary, selected by A. Goodier (Manresa Press / Herder, 1914)",
        label="Letters",
        intro="Letters and Instructions of Ignatius Loyola, volume I (1524–1547). O'Leary's English, selected and edited by Alban Goodier. The 1914 letters book in hand.",
        books=[book("letters", "Letters and Instructions", [part(1, "Volume I", chapters)])],
    )


def emit_therese_letters() -> None:
    sys.path.insert(0, str(ROOT / "therese"))
    import parse as therese_parse  # noqa: E402

    therese_parse.main()
    data = json.loads((ROOT / "therese" / "work" / "chapters.json").read_text(encoding="utf-8"))
    parts_src = {p["title"]: p["chapters"] for p in data["parts"]}
    def to_chs(src: list[dict]) -> list[dict]:
        out: list[dict] = []
        for c in src:
            text = "\n\n".join(p for p in c["paragraphs"] if p).strip()
            if out and c["title"] == out[-1]["title"]:
                out[-1]["textEn"] = (out[-1]["textEn"] + "\n\n" + text).strip()
                continue
            if len(text.split()) < 20 and c["title"] != "Motto":
                continue
            out.append({
                "chapter": 0,
                "title": c["title"],
                "textEn": text,
            })
        for i, c in enumerate(out, start=1):
            c["chapter"] = i
            if len(c["textEn"].split()) < 8:
                raise SystemExit(f"thin therese {c['title']!r}")
        return out
    letters = to_chs(parts_src["Letters"])
    prayers = to_chs(parts_src["Prayers"])
    write_shelf(
        ASSETS / "therese" / "letters.json",
        translator="Thomas N. Taylor (1912)",
        label="Letters",
        intro="Letters and prayers from Taylor's 1912 Story of a Soul. The poems in that file are Susan L. Emery's and are not shipped.",
        books=[
            book("letters", "Letters", [part(1, "Letters", letters)]),
            book("prayers", "Prayers", [part(1, "Prayers", prayers)]),
        ],
    )


def main() -> None:
    emit_conferences()
    emit_liguori()
    emit_moralia()
    emit_augustine()
    emit_life()
    emit_ignatius_letters()
    emit_therese_letters()


if __name__ == "__main__":
    main()
