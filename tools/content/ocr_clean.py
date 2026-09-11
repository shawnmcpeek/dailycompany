#!/usr/bin/env python3
"""Conservative OCR tidy for nineteenth-century English scans."""

from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

_PREFIXES = {
    "ab", "ac", "ad", "ban", "be", "cir", "circum", "co", "col", "com", "con",
    "conse", "contra", "cor", "crea", "da", "de", "di", "dis", "em", "en",
    "eter", "ex", "experi", "extra", "for", "il", "im", "in", "inter", "ir",
    "mis", "na", "non", "num", "ob", "oc", "op", "out", "over", "para", "pen",
    "per", "pos", "pre", "prepara", "pro", "re", "remem", "salva", "semi",
    "senti", "spir", "sub", "suc", "sud", "suf", "suffi", "sug", "sup", "sur",
    "sus", "tempta", "thor", "tor", "trans", "un", "under", "volun",
}

_STOP_FIRST = {
    "a", "an", "the", "of", "to", "on", "at", "by", "or", "and", "but",
    "not", "as", "if", "is", "be", "he", "we", "ye", "it", "no", "so", "do",
    "go", "up", "my", "me", "us", "our", "thy", "his", "her", "she",
    "him", "you", "who", "all", "any", "one", "two", "may", "can",
    "was", "are", "had", "has", "have", "this", "that", "with", "from",
    "into", "upon", "than", "then", "them", "they", "their", "when",
    "which", "what", "will", "shall", "would", "could", "should",
    "been", "were", "also", "only", "such", "more", "most", "some",
    "each", "both", "after", "before", "between", "through", "these",
    "those", "your", "thou", "thee", "hath", "doth", "dost", "art",
    "unto", "even", "very", "own", "nor", "yet", "off", "via",
    "st", "tu", "et", "la", "le", "el", "al", "au", "ou", "il",
}

_FALSE_JOINS = {
    "tuquoque", "stagne", "inthe", "andthe", "ofthe", "tothe", "godin",
    "forbecause", "bestill", "hefound", "htwrote", "inbearing", "forhow",
    "beclothed", "puton", "prefview", "insimplicity", "inunderstanding",
    "ingiving", "inhell",
}

_RELIGIOUS = """
conformity divine thoroughly practice indeed eternity accomplish perfect
circumstances understand wherever whatsoever whoever nevertheless therefore
wherefore amongst shew shewed connexion labour honour saviour baptised
wilfully wilful succour neighbour neighbours favour favoured portrait
consideration considerations epistle oblation consolation contentment
importance adversity contrary temptation consequence experienced eternal
persecution poverty understood accomplished satisfaction reservation
confidence desolation communion rejected suffering spiritual tormented
sufficient frequently determined guidance penance paradise preparation
despised suddenly remembrance creature salvation banished communicate
conferred provided pardoned numbered refraining renounce voluntary
""".split()


def _cased(repl: str):
    def sub(m: re.Match[str]) -> str:
        src = m.group(0)
        if src.isupper():
            return repl.upper()
        if src[:1].isupper():
            return repl[:1].upper() + repl[1:]
        return repl

    return sub


_WORD_FIXES: tuple[tuple[re.Pattern[str], object], ...] = (
    (re.compile(r"\btliey\b", re.I), _cased("they")),
    (re.compile(r"\btlie\b", re.I), _cased("the")),
    (re.compile(r"\btbe\b", re.I), _cased("the")),
    (re.compile(r"\bthb\b", re.I), _cased("the")),
    (re.compile(r"\btub\b", re.I), _cased("the")),
    (re.compile(r"\bwbicb\b", re.I), _cased("which")),
    (re.compile(r"\bwitb\b", re.I), _cased("with")),
    (re.compile(r"\bivith", re.I), _cased("with")),
    (re.compile(r"\bivom\b", re.I), _cased("from")),
    (re.compile(r"\bdaked\b", re.I), _cased("naked")),
    (re.compile(r"\bwiih\b", re.I), _cased("with")),
    (re.compile(r"\bvith\b", re.I), _cased("with")),
    (re.compile(r"\bvri\\?h\b", re.I), _cased("with")),
    (re.compile(r"\bheauty\b", re.I), _cased("beauty")),
    (re.compile(r"\bfeehngs\b", re.I), _cased("feelings")),
    (re.compile(r"\bfeehng\b", re.I), _cased("feeling")),
    (re.compile(r"\bgatliered\b", re.I), _cased("gathered")),
    (re.compile(r"\bchurcli\b", re.I), _cased("church")),
    (re.compile(r"\bfatjier\b", re.I), _cased("father")),
    (re.compile(r"\bfatlier\b", re.I), _cased("father")),
    (re.compile(r"\bkeligious\b", re.I), _cased("religious")),
    (re.compile(r"\bashed\b", re.I), _cased("asked")),
    (re.compile(r"\blaivs\b", re.I), _cased("laws")),
    (re.compile(r"\bdomiaus\b", re.I), _cased("dominus")),
    (re.compile(r"\bjoan\b(?=\s*,)"), "John"),
    (re.compile(r"\bjoans\b"), "John's"),
    (re.compile(r"\bGk\)d\b"), "God"),
    (re.compile(r"\bQt\)d\b"), "God"),
    (re.compile(r"\bti\.ie\b", re.I), _cased("the")),
    (re.compile(r"<\s*i\b"), "of"),
    (re.compile(r"\bpurj\^ose\b", re.I), _cased("purpose")),
    (re.compile(r"\bniyht\b", re.I), _cased("night")),
    (re.compile(r"\bhorroi'\b", re.I), _cased("horror")),
    (re.compile(r"\bchafrer\b", re.I), _cased("chapter")),
    (re.compile(r"\bvas the\b", re.I), "was the"),
    (re.compile(r"\btha-\s+"), "that "),
    (re.compile(r"\bHut\b"), "But"),
    (re.compile(r"\bArid\b"), "And"),
    (re.compile(r"\bTMiereas\b"), "Whereas"),
    (re.compile(r"\bJoAn\b"), "John"),
    (re.compile(r"\bAVhat\b"), "What"),
    (re.compile(r"\bicas\b"), "was"),
    (re.compile(r"\baud\b", re.I), _cased("and")),
    (re.compile(r"\bGea\."), "Gen."),
    (re.compile(r"\bConsIDER\b"), "Consider"),
    (re.compile(r"([A-Za-z])\^s\b"), r"\1's"),
    (re.compile(r"\bthis may he\b", re.I), _cased("this may be")),
    (re.compile(r"\bmay he;"), "may be;"),
    (re.compile(r"(?<![0-9])0 (Lord|God|my|that|Thou|Jesus)\b"), r"O \1"),
    (re.compile(r"\bive should\b", re.I), _cased("we should")),
    (re.compile(r"\bive can\b", re.I), _cased("we can")),
    (re.compile(r"\bive must\b", re.I), _cased("we must")),
    (re.compile(r"\bive are\b", re.I), _cased("we are")),
    (re.compile(r"\bive have\b", re.I), _cased("we have")),
    (re.compile(r"\bive will\b", re.I), _cased("we will")),
    (re.compile(r"\bIust\b"), "Just"),
    (re.compile(r"\bTust\b"), "Just"),
    (re.compile(r"\bWevil\b"), "Devil"),
    (re.compile(r"\bWeath\b"), "Death"),
    (re.compile(r"\bMeath\b"), "Death"),
    (re.compile(r"\bIndgment\b"), "Judgment"),
    (re.compile(r"\bHeil\b"), "Hell"),
    (re.compile(r"\bMarp\b"), "Mary"),
    (re.compile(r"\bBod\b"), "God"),
    (re.compile(r"\bGhe\b"), "The"),
    (re.compile(r"\bChe\b"), "The"),
    (re.compile(r"\bMith\b"), "With"),
    (re.compile(r"\bJoly\b"), "Holy"),
    (re.compile(r"\bforbecause\b", re.I), _cased("for because")),
    (re.compile(r"\bbestill\b", re.I), _cased("be still")),
    (re.compile(r"\b1 had\b"), "I had"),
    (re.compile(r"\b1 learnt\b"), "I learnt"),
    (re.compile(r"\b1 now\b"), "I now"),
    (re.compile(r"\b1 should\b"), "I should"),
    (re.compile(r"\b1 came\b"), "I came"),
    (re.compile(r"% T then"), ". I then"),
    (re.compile(r"\bS\. Grtg\b"), "S. Greg"),
    (re.compile(r"\bon counts touching\b"), "on accounts touching"),
    (re.compile(r"\bIperceive\b"), "I perceive"),
    (re.compile(r"\binsimplicity\b"), "in simplicity"),
    (re.compile(r"\binunderstanding\b"), "in understanding"),
    (re.compile(r"\bingiving\b"), "in giving"),
    (re.compile(r"\binhell\b"), "in hell"),
    (re.compile(r"\bhe ye children\b"), "be ye children"),
    (re.compile(r"\bB\.om\."), "Rom."),
    (re.compile(r",([A-Za-z])"), r", \1"),
    (re.compile(r"\bhefound\b", re.I), _cased("he found")),
    (re.compile(r"Htwrote"), "He wrote"),
    (re.compile(r"\ba\?id\b", re.I), _cased("and")),
    (re.compile(r"\binbearing\b", re.I), _cased("in bearing")),
    (re.compile(r"\bforhow\b", re.I), _cased("for how")),
    (re.compile(r"\bbeclothed\b", re.I), _cased("be clothed")),
    (re.compile(r"\bputon\b", re.I), _cased("put on")),
    (re.compile(r"\bprefview\b", re.I), _cased("preview")),
    (re.compile(r"\bouther\b", re.I), "out her"),
    (re.compile(r"\bwa8\b"), "was"),
    (re.compile(r"\bChu-ch\b"), "Church"),
    (re.compile(r"\ba\?id\b"), "and"),
    (re.compile(r"\bA\?id\b"), "And"),
    (re.compile(r"\bi\?i\b"), "in"),
    (re.compile(r"\bthe\?-e\b"), "there"),
    (re.compile(r"\b7nan\b"), "man"),
    (re.compile(r"\b3Iy\b"), "My"),
    (re.compile(r"\bl\)y\b"), "by"),
    (re.compile(r"\bhe/ore\b"), "before"),
    (re.compile(r"\bx4nd\b"), "And"),
    (re.compile(r"\bJuda[3?]a\b"), "Judaea"),
    (re.compile(r"\bArianiMm\b"), "Arianism"),
    (re.compile(r"\bTJuvigild\b"), "Liuvigild"),
    (re.compile(r"\btpistles\b"), "epistles"),
    (re.compile(r"\bray most\b"), "my most"),
    (re.compile(r"\bkin\.j\b"), "king"),
    (re.compile(r"\bpui\*pose\b"), "purpose"),
    (re.compile(r"\bintei\*pretation\b"), "interpretation"),
    (re.compile(r"\bincaniation\b"), "incarnation"),
    (re.compile(r"\bwisdoin\b"), "wisdom"),
    (re.compile(r"\bhcliu\b", re.I), "Elihu"),
    (re.compile(r"\bwere horn to\b"), "were born to"),
    (re.compile(r"\bbrother in Uw\b", re.I), "brother-in-law"),
    (re.compile(r"\bHi' took\b"), "He took"),
    (re.compile(r"\bru'e\b"), "rule"),
    (re.compile(r"\b51\)5\b"), "595"),
    (re.compile(r"\b17y7\b"), "1797"),
    (re.compile(r"\bFir rentina\b"), "Florentina"),
    (re.compile(r"\bSe\\ille\b"), "Seville"),
    (re.compile(r"\bHis/kilis\b"), "Hispalis"),
    (re.compile(r"\bbis assistance\b"), "his assistance"),
    (re.compile(r"\bi\*petually\b"), "perpetually"),
    (re.compile(r"\bi\*print\b"), "imprint"),
    (re.compile(r"\bw\^e\b", re.I), _cased("we")),
    (re.compile(r"\bw\^ith\b", re.I), _cased("with")),
    (re.compile(r"\bw\^hich\b", re.I), _cased("which")),
    (re.compile(r"\bev\^en\b", re.I), _cased("even")),
    (re.compile(r"\bi\^or\b"), "For"),
)


_HEAD_INLINE = (
    re.compile(
        r"\b\d{1,4}O?\s+Spiritual Treatises\.?\s*\[PART[^\]]*\]\.?",
        re.I,
    ),
    re.compile(
        r"\b[A-Z]?\d{2,4}\s+Preparation for Death\.?\s*\([^)]*\)\.?",
        re.I,
    ),
    re.compile(r"\b\d[-.]?\d{0,2}\s+Conference [IVXL]+\b", re.I),
    re.compile(r"\bBX\s+\d[\d.]+\S*", re.I),
    re.compile(r"\bLetters and Instructions\b", re.I),
    re.compile(r"\bOF ST\.? IGNATIUS LOYOLA\b", re.I),
)


@lru_cache(maxsize=1)
def _words() -> set[str]:
    out = {w.lower() for w in _RELIGIOUS if w}
    path = Path("/usr/share/dict/words")
    if path.exists():
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            w = line.strip().lower()
            if w.isalpha() and len(w) >= 3:
                out.add(w)
    return out


def _join_hyphen_space(text: str) -> str:
    return re.sub(r"([A-Za-z]{2,})-\s+([a-z]{2,})", r"\1\2", text)


def _join_split_words(text: str) -> str:
    words = _words()
    toks = re.findall(r"[A-Za-z]+|[^A-Za-z]+", text)
    out: list[str] = []
    i = 0
    while i < len(toks):
        a = toks[i]
        if (
            a.isalpha()
            and i + 2 < len(toks)
            and toks[i + 2].isalpha()
            and toks[i + 2][:1].islower()
            and i + 1 < len(toks)
            and toks[i + 1].isspace()
            and len(a) >= 2
            and len(toks[i + 2]) >= 3
        ):
            b = toks[i + 2]
            al, bl = a.lower(), b.lower()
            joined = al + bl
            if (
                al not in _STOP_FIRST
                and joined not in _FALSE_JOINS
                and len(joined) >= 5
                and joined in words
                and (bl not in words or al in _PREFIXES)
            ):
                out.append(joined[:1].upper() + joined[1:] if a[:1].isupper() else joined)
                i += 3
                continue
        out.append(a)
        i += 1
    return "".join(out)


def clean_ocr_english(text: str) -> str:
    for pat, repl in _WORD_FIXES:
        text = pat.sub(repl, text)
    for pat in _HEAD_INLINE:
        text = pat.sub(" ", text)
    # Footnote carets and broken letters sitting inside words.
    text = re.sub(r"(?<=[A-Za-z])\^(?=[A-Za-z])", "", text)
    text = re.sub(r"(?<=[A-Za-z])\^", "", text)
    text = re.sub(r"\?id\b", "nd", text)
    text = re.sub(r"([a-z]) For because\b", r"\1. For because", text)
    text = _join_hyphen_space(text)
    text = _join_split_words(text)
    # Collapse OCR space-before-punctuation. Leave ellipses (" . . .") alone.
    text = re.sub(r" +([,;:!])", r"\1", text)
    text = re.sub(r"(?<![.])\s+\.(?!\s*\.)", ".", text)
    text = re.sub(r"\s+,", ",", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    text = re.sub(r" ?\n\n ?", "\n\n", text)
    return text.strip()
