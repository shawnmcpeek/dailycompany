#!/usr/bin/env python3
"""Parse the anonymous Rivingtons 1875 Spiritual Combat.

Chapter titles in the body are blackletter OCR garbage. CONTENTS titles
(clean English) are mapped onto CHAPTER I, II, … body text. The Combat
is kept; the Supplement and Path of Paradise are kept only where the
prose is clean.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
from ocr_clean import clean_ocr_english  # noqa: E402
RAW = ROOT / "raw" / "ia_rivingtons_1875.txt"
WORK = ROOT / "work"

ROMAN = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13,
    "XIV": 14, "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19,
    "XX": 20, "XXI": 21, "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25,
    "XXVI": 26, "XXVII": 27, "XXVIII": 28, "XXIX": 29, "XXX": 30,
    "XXXI": 31, "XXXII": 32, "XXXIII": 33, "XXXIV": 34, "XXXV": 35,
    "XXXVI": 36, "XXXVII": 37, "XXXVIII": 38, "XXXIX": 39, "XL": 40,
    "XLI": 41, "XLII": 42, "XLIII": 43, "XLIV": 44, "XLV": 45,
    "XLVI": 46, "XLVII": 47, "XLVIII": 48, "XLIX": 49, "L": 50,
    "LI": 51, "LII": 52, "LIII": 53, "LIV": 54, "LV": 55, "LVI": 56,
    "LVII": 57, "LVIII": 58, "LIX": 59, "LX": 60, "LXI": 61,
    "LXII": 62, "LXIII": 63, "LXIV": 64, "LXV": 65, "LXVI": 66,
}

CHAPTER_RE = re.compile(
    r"^CHAPTER\s+([IVXL]+)[.,:]?\s*.{0,6}$", re.I
)
TOC_ITEM_RE = re.compile(
    r"^([IVXL]+)\.?\s+(.*)$"
)


def join_hyphens(text: str) -> str:
    return re.sub(r"-\n\s*", "", text)


def normalize_ws(text: str) -> str:
    text = text.replace("\u2014", "--").replace("\u2013", "--")
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    dq = '"'
    text = text.replace("\u201c", dq).replace("\u201d", dq)
    text = text.replace("Gk)d", "God").replace("Qt)d", "God")
    text = text.replace("feehngs", "feelings")
    text = text.replace("theu:", "their")
    text = text.replace("tliey", "they")
    text = re.sub(r"\btlie\b", "the", text)
    text = re.sub(r"-\s+(?=[a-z])", "", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s+[|!]+\s*$", "", text)
    return clean_ocr_english(text)


def is_garbled(t: str) -> bool:
    """Blackletter titles OCR'd as mostly-ASCII soup."""
    first = re.sub(r"[^A-Za-z].*$", "", t.split()[0]) if t.split() else ""
    if first.isupper() and len(first) >= 3:
        return False
    words = re.findall(r"[A-Za-z']{3,}", t.lower())
    if len(words) < 3:
        return False
    hits = sum(1 for w in words if w in COMMON)
    return hits / len(words) < 0.30


def is_blackletter(s: str) -> bool:
    t = s.strip()
    if not t:
        return False
    letters = [c for c in t if c.isalpha()]
    if not letters:
        return False
    ascii_l = [c for c in letters if c.isascii()]
    if len(ascii_l) / len(letters) < 0.88:
        return True
    glyph = t.count("^") + t.count("|") + t.count("&") + t.count("§")
    zero_in_word = len(re.findall(r"[A-Za-z]0|0[A-Za-z]", t))
    marked = bool(re.search(r"\|\)|[A-Za-z]\^[A-Za-z]|tl&|€", t))
    looks_marked = marked or glyph >= 2 or zero_in_word >= 2
    if re.search(r"[\\®©]", t) or (t.count("&") >= 1 and t.count(" ") <= 12):
        words = re.findall(r"[A-Za-z']{2,}", t.lower())
        hits = sum(1 for w in words if w in COMMON)
        if hits < 4:
            return True
    if not looks_marked and not re.search(r"[A-Za-z]\^[A-Za-z]", t):
        return False
    # Drop-cap English can carry a caret (`AI^THOUGH I have already said`).
    words = re.findall(r"[A-Za-z']{2,}", t.lower())
    hits = sum(1 for w in words if w in COMMON)
    return hits < 3


def is_running_head(s: str) -> bool:
    t = s.strip(" |")
    if not t:
        return False
    if re.fullmatch(r"\d{1,3}", t):
        return True
    if t in {"T", "j", "i", "I", "1", "|", "\\", "/", "*", "=", "#", "7"}:
        return True
    u = re.sub(r"\s+", " ", t).upper()
    if re.match(r"^\d+\s+[A-Z][A-Z\s']+$", u) and len(u.split()) <= 8:
        return True
    # All-caps running heads only — not mixed-case prose that we uppercased.
    if (
        t == t.upper()
        and re.match(r"^[A-Z][A-Z\s']{10,}\s*\d*$", t)
        and 2 <= len(t.split()) <= 8
    ):
        return True
    if "CONTENTS" in u and len(u) < 24:
        return True
    return False


def is_watermark(s: str) -> bool:
    t = s.strip()
    return t.lower().startswith("digitized") or t.lower() in {"google"}


COMMON = {
    "the", "and", "of", "to", "in", "that", "for", "is", "you", "with",
    "this", "are", "not", "be", "as", "by", "or", "from", "his", "her",
    "god", "soul", "which", "have", "will", "all", "but", "who", "our",
    "your", "must", "may", "can", "one", "them", "they", "their", "been",
    "were", "was", "has", "had", "shall", "upon", "into", "than", "then",
    "when", "what", "there", "these", "those", "such", "more", "most",
    "very", "only", "also", "would", "could", "should", "might", "every",
    "before", "after", "about", "without", "because", "through", "under",
    "over", "between", "among", "christ", "jesus", "lord", "holy", "love",
    "heart", "life", "prayer", "virtue", "grace", "faith", "if", "we",
    "you", "wish", "beloved", "said", "already", "much", "sometimes",
    "against", "higher", "seem", "though",
}


def is_english_prose(s: str) -> bool:
    t = s.strip()
    if len(t) < 10 or " " not in t:
        return False
    if is_blackletter(t) or is_running_head(t) or is_watermark(t):
        return False
    letters = [c for c in t if c.isalpha()]
    if len(letters) < 8:
        return False
    ascii_l = [c for c in letters if c.isascii()]
    if len(ascii_l) / len(letters) < 0.9:
        return False
    words = re.findall(r"[A-Za-z']{2,}", t.lower())
    if len(words) < 3:
        return False
    hits = sum(1 for w in words if w in COMMON)
    first = re.sub(r"[^A-Za-z].*$", "", t.split()[0])
    if first.isupper() and len(first) >= 3:
        return True
    return hits >= 3


def strip_page_num(title: str) -> str:
    title = re.sub(r"[\.\s]+\d+\s*$", "", title)
    title = re.sub(r"[\.\s]+[xvilc]+\s*$", "", title, flags=re.I)
    title = re.sub(r"\s+", " ", title).strip(" .;")
    return title


def parse_toc_block(lines: list[str], start: int, end: int) -> list[str]:
    titles: dict[int, list[str]] = {}
    order: list[int] = []
    cur: int | None = None
    for i in range(start, end):
        s = lines[i].strip()
        if not s or is_running_head(s) or is_watermark(s):
            continue
        m = TOC_ITEM_RE.match(s)
        if m and m.group(1).upper() in ROMAN and (
            m.group(2).strip()[:1].isupper() or m.group(2).strip()[:1].isalpha()
        ):
            # Avoid catching "VI CONTENTS" etc — require some title text.
            rest = m.group(2).strip()
            if rest.upper().startswith("CONTENTS"):
                continue
            num = ROMAN[m.group(1).upper()]
            if num not in titles:
                titles[num] = []
                order.append(num)
            cur = num
            titles[num].append(rest)
            continue
        if cur is not None and not CHAPTER_RE.match(s):
            if s[0].isupper() or s[0].islower():
                titles[cur].append(s)
    out = []
    for n in order:
        title = strip_page_num(normalize_ws(" ".join(titles[n])))
        if title:
            out.append(title)
    return out


def split_body_chapters(lines: list[str], start: int, end: int) -> list[list[str]]:
    chapters: list[list[str]] = []
    cur: list[str] | None = None
    para: list[str] = []
    capturing = False

    def flush() -> None:
        nonlocal para
        if cur is None or not para:
            para = []
            return
        text = normalize_ws(" ".join(para))
        para = []
        if text and is_english_prose(text) and not is_garbled(text):
            cur.append(text)

    i = start
    while i < end:
        s = lines[i].strip()
        if CHAPTER_RE.match(s):
            flush()
            if cur is not None:
                chapters.append(cur)
            cur = []
            capturing = False
            i += 1
            continue
        if cur is None:
            i += 1
            continue
        if not s or is_running_head(s) or is_watermark(s) or is_blackletter(s):
            flush()
            i += 1
            continue
        if not capturing:
            if is_english_prose(s):
                capturing = True
            else:
                i += 1
                continue
        s = re.sub(r"\bAI\^?THOUGH\b", "ALTHOUGH", s)
        s = s.replace("^", "")
        s = re.sub(r"\|\)", "l", s)
        # Trailing margin glyphs from the gutter.
        s = re.sub(r"\s+[|I!\\\\']+\s*$", "", s)
        para.append(s)
        i += 1
    flush()
    if cur is not None:
        chapters.append(cur)
    return [c for c in chapters if c]


def quality_ok(paragraphs: list[str]) -> bool:
    text = " ".join(paragraphs)
    words = re.findall(r"[A-Za-z]{2,}", text)
    if len(words) < 40:
        return False
    # Reject leftover blackletter-heavy chapters.
    odd = sum(1 for c in text if not c.isascii())
    return odd / max(1, len(text)) < 0.02


def merge_wrapped(paras: list[str]) -> list[str]:
    """Join OCR page-wraps: lowercase (or hyphen) continuations."""
    out: list[str] = []
    for p in paras:
        p = p.strip()
        if not p:
            continue
        if out and (p[0].islower() or out[-1].endswith("-")):
            prev = out[-1]
            if prev.endswith("-"):
                out[-1] = normalize_ws(prev[:-1] + p)
            else:
                out[-1] = normalize_ws(prev + " " + p)
        else:
            out.append(p)
    return out


def title_case_if_needed(title: str) -> str:
    letters = sum(c.isalpha() for c in title)
    caps = sum(c.isupper() for c in title if c.isalpha())
    if letters and caps / letters > 0.55:
        small = {"of", "the", "a", "an", "and", "to", "for", "in", "on", "by"}
        words = title.lower().split()
        out = []
        for i, w in enumerate(words):
            if i == 0 or w not in small:
                out.append(w[:1].upper() + w[1:])
            else:
                out.append(w)
        return " ".join(out)
    return title


def build_part(
    part: int,
    title: str,
    toc_titles: list[str],
    bodies: list[list[str]],
) -> dict:
    n = min(len(toc_titles), len(bodies))
    chapters = []
    for i in range(n):
        paras = [p for p in bodies[i] if not is_blackletter(p) and not is_garbled(p)]
        while paras and (is_blackletter(paras[0]) or is_garbled(paras[0])):
            paras = paras[1:]
        if not quality_ok(paras):
            continue
        ch_title = title_case_if_needed(toc_titles[i]) if i < len(toc_titles) else ""
        if not ch_title or ch_title.lower().startswith("chapter "):
            sent = re.split(r"(?<=[.?!])\s", paras[0], maxsplit=1)[0]
            ch_title = sent.strip().rstrip(".")
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": ch_title,
            "paragraphs": merge_wrapped(paras),
        })
    # Extra body chapters beyond TOC — title from first sentence.
    for paras in bodies[n:]:
        if not quality_ok(paras):
            continue
        sent = re.split(r"(?<=[.?!])\s", paras[0], maxsplit=1)[0]
        chapters.append({
            "chapter": len(chapters) + 1,
            "title": sent.strip().rstrip("."),
            "paragraphs": merge_wrapped(paras),
        })
    return {"part": part, "title": title, "chapters": chapters}


# CONTENTS titles (clean English). Body headings are blackletter garbage.
COMBAT_TITLES = [
    "In what Christian Perfection consists; and that the attainment of it involves a struggle, and of four things necessary for this conflict",
    "Of Distrust of ourselves",
    "Of Trust in God",
    "How we may know whether we are acting with self-distrust and Trust in God",
    "Of the mistake of many, who hold Timidity for a Virtue",
    "Further advice as to obtaining this Distrust of self and Trust in God",
    "Of Spiritual Exercise; and first of the Exercise of the Understanding, which must be preserved from Ignorance and Curiosity",
    "Of the Hindrances to a right Discernment of things, and of the course which we should take in order to Judge truly concerning them",
    "Of another thing from which the Understanding must be preserved in order to exercise a Right Judgment",
    "Of the Exercise of the Will, and of the End to which all our Actions, both inward and outward, should be directed",
    "Of some Considerations which may induce the Will to seek in all things the Good Pleasure of God",
    "Of the divers Wills which are in Man, and of the Warfare between them",
    "Of the way to resist the Sensual Impulses, and of the Acts to be performed by the Will, in order to acquire Habits of Virtue",
    "What ought to be done when the higher Will seems to be wholly overcome and stifled by the lower Will, and by its Enemies",
    "Some Suggestions about the manner of Fighting; and especially against what Enemies, and with what Virtues, we should contend",
    "In what way the Soldier of Christ should take the Field early in the Morning",
    "Of the order to be observed in the Conflict with our Evil Passions",
    "Of the way to overcome Sudden Risings of the Passions",
    "How to resist the Lusts of the Flesh",
    "Of the way to overcome Sloth",
    "Of the Guard of the Outward Senses, and how from these we may pass to the Contemplation of the Divinity",
    "How the same things may offer us opportunities of regulating our Senses by passing on to Meditation on the Incarnate Word, in the Mysteries of His Life and Passion",
    "Of other ways of Governing our Senses according to the different occasions which happen",
    "How to rule the Tongue",
    "That the Soldier of Christ, if he would be successful against his Enemies, must, as far as possible, lay aside all Agitation and Anxiety of Mind",
    "What we must do when we are Wounded",
    "Of the order which the Devil observes in his Assaults and Stratagems against those who give themselves to a Holy Life, and against those who are already found in the Bondage of Sin",
    "Of the Assaults and Devices which the Devil employs against those who are held in the Bondage of Sin",
    "Of the Wiles and Delusions by which the Devil holds captive those who are conscious of their Misery, and desire to be free; and how it is our Resolutions are so often fruitless",
    "Of the Delusion of those who imagine that they are going on to Perfection",
    "Of the Devil's Deceits and Struggles to draw us away from the Path of Perfection",
    "Of the last above-named Assault and Stratagem, whereby the Devil tries to make the Virtues we have acquired the Occasions of our Ruin",
    "Of certain Suggestions for overcoming our evil Passions, and gaining new Virtues",
    "That Virtues are to be gained by degrees; by Exercising ourselves in their gradual formation, and that our Attention must first be given to one step, and then to another",
    "Of the means by which Virtues are acquired, and of the way we should Use them, allowing some space of Time to one Virtue only",
    "That in the Exercise of Virtue we must continually Advance with Diligence",
    "That as we must always continue in the Exercise of the Virtues, so we must not shun any opportunity which offers itself for their Attainment",
    "That we ought to regard as precious every Opportunity which is afforded to us for the Acquisition of Virtues; and chiefly those which present the greatest Difficulties",
    "How to avail ourselves of the various Occasions which present themselves for the Exercise of a single Virtue",
    "Of the length of time to be given to the Exercise of each particular Virtue, and of the marks of Spiritual Advancement",
    "That we must not yield to the wish to be rid of the Trials which we are bearing patiently; and how we should rule all our Desires so as to grow in Holiness",
    "How to resist the Devil, when he tries to ensnare us by an indiscreet Zeal",
    "Of the Power of our Evil Inclinations, and of the Way the Devil tempts us to form rash Judgments of our Neighbour, and how to resist him",
    "Of Prayer",
    "What is Mental Prayer",
    "Of Meditation",
    "Of another mode of Praying by way of Meditation",
    "Of a mode of Praying by means of the Blessed Virgin Mary",
    "Of certain Considerations as to Faith and Confidence in the Prayers of the Virgin Mary",
    "Of a way of Meditating and Praying by means of the Angels and of all the Blessed",
    "Of Meditation on the Passion of Christ, in order to excite various Affections",
    "Of the Advantages which may be derived from Meditation on the Crucifixion of our Lord, and of the Imitation of His Virtues",
    "Of the most Holy Sacrament of the Eucharist",
    "Of the way we ought to Receive the most Holy Sacrament of the Eucharist",
    "How we ought to Prepare ourselves for Communion in order to excite within us Love",
    "Of Spiritual Communion",
    "Of returning Thanks",
    "Of Oblation",
    "Of Sensible Devotion and of Dryness",
    "Of the Examination of Conscience",
    "How in this Battle we have need of continuing the Struggle even unto Death",
    "How to prepare ourselves against the Enemies who assault us when we are Dying",
    "Of four Assaults of our Enemies at the time of Dying: and first of the Assault upon Faith, and of the manner of defending ourselves",
    "Of the Assault of Despair, and of its Remedy",
    "Of the Assault of Vain-glory",
    "Of the Assault of Illusions and false Appearances at the Point of Death",
]

SUPPLEMENT_TITLES = [
    "What is the Nature of Christian Perfection",
    "Of the Necessity of a Conflict in order to gain Christian Perfection",
    "Of Three Things which are needful for the Young Soldier of Christ",
    "Of Resistance and Violence, and of the Art of using them",
    "That we have need to Watch continually over our Will, so as to discover the particular Passion to which it inclines",
    "How by removing the first Passion, which is Love of the Creature and of Self, and by giving it to God, all the rest will be well regulated and ordered",
    "That the Human Will stands in need of Succour",
    "How the Will of Man is greatly strengthened by overcoming the World",
    "Of the Second Help to the Will",
    "Of Temptations to Spiritual Pride",
    "Of the Third Help of the Human Will",
    "In what Way a Man may gain the Habit of keeping in the Presence of God, whenever he will",
    "Some Advice about Prayer",
    "Of another way of Praying",
    "Of the Fourth Help of the Human Will",
    "Of Meditation on the Being of God",
    "Of Meditation on the Power of God",
    "Of Meditation on the Wisdom of God",
    "Of Meditation on the Goodness of God",
    "Of Meditation on the Beauty of God",
    "What God has done for Man, and with what love, and what He would further do for him, if needful",
    "What God does every Day for Man",
    "How great is the Goodness of our God in waiting for and bearing with the Sinner",
    "What God will do in another Life, not only for him who has always served Him, but also for the converted Sinner",
    "Of the Fifth Help of the Human Will",
    "In what Way Self-love may be discovered",
    "Of the Sixth Help",
    "Of Sacramental Communion",
    "Of Sacramental Confession",
    "How to overcome the Impure Passion",
    "How many things should be avoided, so as not to fall into the Vice of Impurity",
    "What we should do when we have fallen into this Sin of Impurity",
    "Of some Motives which should lead the Sinner to turn to God without delay",
    "How to obtain the Gift of Tears for our Offences against God, and Conversion",
    "Of some Reasons why Men live without Weeping for their Offences against God, without Virtues, and without Christian Perfection",
    "Of Love towards Enemies",
    "Of Examination of Conscience",
    "Of Two Rules for Living in Peace",
]

PATH_TITLES = [
    "What is the Nature of our Heart, and how it ought to be Governed",
    "Of the Care we should have to preserve a Peaceful Spirit",
    "How this Building of Inward Peace must be gradually constructed",
    "How the Soul must refuse all Consolations, for this is true Humility and poverty of Spirit, by which Interior Peace is acquired",
    "How the Soul should keep herself in a state of inward Solitude, that God may work within her",
    "Of the Prudence which we ought to exercise in the Love of our Neighbour, so as not to disturb this Peace",
    "How the Soul, despoiled of its own Will, must present itself before God",
    "Of the Faith we should have in the most Holy Sacrament of the Altar, and how we should offer ourselves unto the Lord",
    "That we ought not to seek Pleasures, nor the Things which gratify our Tastes; but God Alone",
    "That the Servant of God must not be discouraged, though he feel within himself some Repugnance and Disquiet as to this Peace",
    "Of the Diligence which the Devil employs to disturb this Peace, and how we ought to guard ourselves against his Devices",
    "That the Soul ought not to disquiet itself on account of Inward Trials",
    "That Temptations are sent us by God for our good",
    "Of the Remedy which we ought to use, so as not to be disquieted under Faults and Infirmities",
    "How the Soul, without loss of Time, should recover Calmness, and make Progress",
]


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    raw = RAW.read_text(encoding="utf-8", errors="replace")
    raw = join_hyphens(raw)
    lines = raw.splitlines()

    # Body of the Combat starts at the CHAPTER I followed by "IF you wish".
    combat_body = next(
        i for i, l in enumerate(lines)
        if l.strip().startswith("CHAPTER I")
        and any(
            "IF you wish, beloved in Christ" in lines[j]
            for j in range(i, min(i + 8, len(lines)))
        )
    )
    supplement_i = next(
        i for i, l in enumerate(lines)
        if l.strip() == "SUPPLEMENT" and i > combat_body
    )
    path_i = next(
        i for i, l in enumerate(lines)
        if i > supplement_i
        and (
            "OF INTERIOR PEACE" in l.upper()
            or "pati) to" in l.lower()
            or "PATH TO PARADISE" in l.upper()
            or "PATH OF PARADISE" in l.upper()
        )
    )
    # Path body: first CHAPTER after the Path heading whose next prose
    # starts "YOUR heart was created".
    path_body = next(
        i for i, l in enumerate(lines)
        if i > path_i
        and CHAPTER_RE.match(l.strip())
        and any(
            "YOUR heart was created" in lines[j]
            for j in range(i, min(i + 10, len(lines)))
        )
    )

    combat_toc = COMBAT_TITLES
    supp_toc = SUPPLEMENT_TITLES
    path_toc = PATH_TITLES

    combat_bodies = split_body_chapters(lines, combat_body, supplement_i)
    supp_bodies = split_body_chapters(lines, supplement_i, path_body)
    path_bodies = split_body_chapters(lines, path_body, len(lines))

    print(f"TOC combat={len(combat_toc)} supp={len(supp_toc)} path={len(path_toc)}")
    print(
        f"body combat={len(combat_bodies)} supp={len(supp_bodies)} "
        f"path={len(path_bodies)}"
    )

    combat = build_part(1, "The Spiritual Combat", combat_toc, combat_bodies)
    if len(combat["chapters"]) < 60:
        raise SystemExit(f"Combat chapters too few: {len(combat['chapters'])}")
    first = combat["chapters"][0]["paragraphs"][0]
    if "IF you wish, beloved in Christ" not in first and "If you wish, beloved in Christ" not in first:
        raise SystemExit(f"Combat opening missing: {first[:160]}")

    parts = [combat]
    supplement = build_part(2, "Supplement to the Spiritual Combat", supp_toc, supp_bodies)
    if supplement["chapters"]:
        parts.append(supplement)
        print(f"Supplement kept: {len(supplement['chapters'])} chapters")
    else:
        print("Supplement skipped (prose not clean)")
    path = build_part(3, "The Path of Paradise", path_toc, path_bodies)

    def path_clean(part: dict) -> bool:
        if not part["chapters"]:
            return False
        for c in part["chapters"]:
            if len(c["title"]) < 12 or c["title"].lower().startswith("chapter "):
                return False
            if is_blackletter(c["paragraphs"][0]) or c["paragraphs"][0][:1].islower():
                return False
        return True

    if path_clean(path):
        parts.append(path)
        print(f"Path of Paradise kept: {len(path['chapters'])} chapters")
    else:
        print("Path of Paradise skipped (prose not clean)")

    for p in parts:
        print(
            f"{p['title']}: {len(p['chapters'])} chapters, "
            f"{sum(len(c['paragraphs']) for c in p['chapters'])} paras"
        )

    dest = WORK / "chapters.json"
    dest.write_text(
        json.dumps({
            "translator": "Anonymous (Rivingtons, 1875)",
            "parts": parts,
        }, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    words = sum(
        len(re.findall(r"\S+", " ".join(c["paragraphs"])))
        for p in parts
        for c in p["chapters"]
    )
    print(f"wrote {dest} ({words} words)")
    print("entry-1 start:", first[:220])


if __name__ == "__main__":
    main()
