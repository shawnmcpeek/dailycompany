#!/usr/bin/env python3
"""Parse Robinson's Writings and Heywood's Fioretti.

Writings: Francis's own words only — Robinson's prefaces, footnotes,
appendix, bibliography, and index are dropped.

Fioretti: stories told about him. Front matter (title, contents, Howell
introduction, translator's note) is dropped.

Writes: tools/content/francis/work/chapters.json
        tools/content/francis/work/stories.json
        tools/content/francis/work/canticle.json
"""

from __future__ import annotations

import html as html_lib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW_W = ROOT / "raw" / "writings"
RAW_F = ROOT / "raw" / "fioretti"
WORK = ROOT / "work"

SKIP_WRITINGS = {0, 1, 2, 11, 24, 25, 26}  # title, TOC, intro, part intros, apparatus

CHAPTER_HEAD_RE = re.compile(
    r'(?is)<p\s+align="center">\s*(\d+)\s*[.\u2014\u2013\-—–]+'
    r'\s*(?:<i>(.*?)</i>|(.*?))\s*\.?\s*</p>'
)
HOUR_HEAD_RE = re.compile(
    r'(?is)<p\s+align="center">\s*'
    r'((?:[IVX]+\s*[.\u2014\u2013\-—–]+\s*)?'
    r'(?:(?:HOLY SATURDAY|EASTER SUNDAY|CHRISTMAS DAY)\s+)?'
    r'AT\s+(?:COMPLINE|MATINS|PRIME|TIERCE|SEXT|NONES|VESPERS)'
    r'(?:,\s*SEXT AND NONES)?)'
    r'\s*\.?\s*</p>'
)
H4_RE = re.compile(r'(?is)<h4[^>]*>(.*?)</h4>')
H3_RE = re.compile(r'(?is)<h3[^>]*>(.*?)</h3>')
ADMON_H4_RE = re.compile(
    r'(?is)<h4[^>]*>\s*(\d+)\.\s*(.*?)</h4>'
)
SMALL_CENTER_RE = re.compile(
    r'(?is)<p[^>]*>\s*<small>(.*?)</small>\s*</p>'
)
CHAPTER_BANNER_RE = re.compile(r'(?i)^CHAPTER\s+[IVXLCDM]+\.?$')
FIORETTI_SKIP = {0, 1, 2, 3}  # title, TOC, Howell intro, translator's note


def decode(fragment: str) -> str:
    return html_lib.unescape(fragment.replace('&#8212;', '—').replace('&#8211;', '–'))


def strip_footnote_marks(html: str) -> str:
    html = re.sub(
        r'(?is)(?:&nbsp;|\s)*<A\s+NAME="fr_\d+"></A>\s*'
        r'<A\s+HREF="#fn_\d+"[^>]*>\s*(?:<FONT[^>]*>)?\s*\d+\s*'
        r'(?:</FONT>)?\s*</A>',
        '',
        html,
    )
    return html


TYPOS = (
    (r'\bmay Me Lord\b', 'may the Lord'),
    (r'podestàs\s+,', 'podestàs,'),
    (r'\bL cried\b', 'I cried'),
    (r'Ps\.\s*70:\s*Jo\.', 'Ps. 70: 10.'),
    (r'\bwas I speaking\b', 'was speaking'),
)


def html_to_text(fragment: str) -> str:
    fragment = decode(strip_footnote_marks(fragment))
    text = re.sub(r'(?is)<script[^>]*>.*?</script>', ' ', fragment)
    text = re.sub(r'(?is)<style[^>]*>.*?</style>', ' ', text)
    text = re.sub(r'(?i)<br\s*/?>', '\n', text)
    text = re.sub(r'(?i)</(p|div|h[1-6]|li|tr)>', '\n', text)
    text = re.sub(r'<[^>]+>', ' ', text)
    text = html_lib.unescape(text)
    text = text.replace('\xa0', ' ').replace('\r', '')
    text = re.sub(r'\[paragraph continues\]', '', text, flags=re.I)
    text = re.sub(r'\bp\s*\.\s*\d+\b', '', text)
    text = re.sub(r'(\w)\s+\.', r'\1.', text)
    text = re.sub(r'\[\d+\]', '', text)
    text = re.sub(r'(?<=\w)-\n(?=\w)', '', text)
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r' *\n *', '\n', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = re.sub(r'(\w)-\s+([a-z])', r'\1\2', text)
    for pat, repl in TYPOS:
        text = re.sub(pat, repl, text)
    return text.strip()


def clean_title(raw: str) -> str:
    text = html_to_text(raw)
    text = re.sub(r'\s+', ' ', text).strip(' .')
    text = re.sub(r'\s+\d+$', '', text)  # leftover footnote digits
    return text


def main_html(path: Path) -> str:
    raw = path.read_text(encoding='latin-1')
    m = re.search(
        r'(?is)at sacred-texts.com</FONT></P><HR></p>(.*?)'
        r'(?:<H3 ALIGN="CENTER">Footnotes|<CENTER>\s*<A HREF="[^"]+">Next:)',
        raw,
    )
    html = m.group(1) if m else raw
    return decode(strip_footnote_marks(html))


def _is_heading_echo(para: str, title: str) -> bool:
    def norm(s: str) -> str:
        s = re.sub(r'[\d.:;,—–\-]+', ' ', s)
        return re.sub(r'\s+', ' ', s).strip().lower()
    a, b = norm(para), norm(title)
    if not a or not b:
        return False
    return a == b or a.endswith(b) or (b in a and len(para) < len(title) + 24)


def word_count(paras: list[str]) -> int:
    return len(re.findall(r'\S+', ' '.join(paras)))


def paragraphs(text: str, title: str | None = None) -> list[str]:
    parts = [re.sub(r'\s+', ' ', p).strip() for p in re.split(r'\n\s*\n', text)]
    out = []
    for p in parts:
        if not p or len(p) < 8:
            continue
        if p.lower().startswith('next:'):
            continue
        if title and _is_heading_echo(p, title):
            continue
        if p.startswith('Which St. Francis made and which Pope Innocent'):
            continue
        if p == p.upper() and 12 <= len(p) <= 80 and len(p.split()) <= 14:
            continue
        out.append(p)
    return out


def after_marker(html: str, *markers: str) -> str:
    lower = html.lower()
    best = -1
    for marker in markers:
        i = lower.rfind(marker.lower())
        if i > best:
            best = i + len(marker)
    if best < 0:
        return html
    return html[best:]


def split_rule_chapters(html: str, part_title: str) -> list[dict]:
    html = re.sub(
        r'(?is)(<p\s+align="center">)\s*<i>(.*?)</i>(\s*\.?\s*</p>)',
        r'\1\2\3',
        html,
    )
    starts = list(CHAPTER_HEAD_RE.finditer(html))
    if not starts:
        return []
    chapters = []
    for i, m in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(html)
        title = _title_case(clean_title(m.group(2) or m.group(3) or ''))
        body = html_to_text(html[m.end():end])
        paras = paragraphs(body, title)
        if not paras:
            continue
        chapters.append({
            'chapter': int(m.group(1)),
            'title': title,
            'paragraphs': paras,
        })
    # Preamble before chapter 1 (First Rule) attaches to chapter 1.
    pre = html_to_text(html[:starts[0].start()])
    pre_paras = paragraphs(pre)
    if pre_paras and chapters:
        chapters[0]['paragraphs'] = pre_paras + chapters[0]['paragraphs']
    return chapters


SEASON_TITLES = {
    'passion': 'Office of the Passion — Maundy Thursday',
    'easter': 'Office of the Passion — Easter',
    'feasts': 'Office of the Passion — Sundays and feasts',
    'advent': 'Office of the Passion — Advent',
    'christmas': 'Office of the Passion — Christmas',
}

AS_ABOVE_CUES = (
    ('have mercy on me', 'Have mercy on me, O God, have mercy on me'),
    ('o clap your hands', 'O clap your hands, all ye nations'),
    ('sing ye to the lord', 'Sing ye to the Lord a new canticle'),
    ('shout with joy', 'Shout with joy to God, all the earth'),
    ('may the lord hear thee', 'May the Lord hear thee in the day of tribulation'),
    ('in thee, o lord, have i hoped', 'In Thee, O Lord, have I hoped'),
)

NOTE_START_RE = re.compile(
    r'^(note that|and note|also note|it is said|here begin|on the feast of|'
    r'on the night of)',
    re.I,
)


def _joined(paras: list[str]) -> str:
    return ' '.join(paras).lower()


def _is_psalter_stub(paras: list[str]) -> bool:
    t = _joined(paras)
    if not re.search(r'\bpsalter\b', t):
        return False
    return word_count(paras) < 80


def _is_as_above_stub(paras: list[str]) -> bool:
    if 'as above' not in _joined(paras):
        return False
    return word_count(paras) < 120


def _season_intro_kind(para: str) -> str | None:
    t = para.lower()
    if not t.startswith('here begin'):
        return None
    if 'advent of the lord' in t:
        return 'advent'
    if 'principal festiv' in t:
        return 'feasts'
    return None


def _peel_season_intro(paras: list[str]) -> tuple[list[str], str | None, str | None]:
    kept: list[str] = []
    nxt = None
    intro = None
    for p in paras:
        kind = _season_intro_kind(p)
        if kind:
            nxt = kind
            intro = p
            continue
        kept.append(p)
    return kept, nxt, intro


def _catalog_key_full(paras: list[str]) -> str | None:
    t = _joined(paras)
    for cue, incipit in AS_ABOVE_CUES:
        if incipit.lower() in t:
            return cue
    return None


def _catalog_key_stub(paras: list[str]) -> str | None:
    t = _joined(paras)
    for cue, _incipit in AS_ABOVE_CUES:
        if cue in t:
            return cue
    return None


def _psalm_verses(paras: list[str]) -> list[str]:
    verses: list[str] = []
    for p in paras:
        low = p.lower()
        if low.startswith('ant'):
            continue
        if NOTE_START_RE.match(p.strip()):
            break
        if 'as above' in low:
            continue
        if re.search(r'\bpsalter\b', low):
            continue
        if low.strip() in {'psalm.', 'psalm'}:
            continue
        verses.append(p)
    return verses


def _first_ant(paras: list[str]) -> str | None:
    for p in paras:
        if p.lower().startswith('ant'):
            return p
    return None


def _keep_notes(paras: list[str]) -> list[str]:
    notes: list[str] = []
    for p in paras:
        low = p.lower()
        if low.startswith('ant'):
            continue
        if 'as above' in low:
            continue
        if re.search(r'\bpsalter\b', low) and word_count([p]) < 40:
            continue
        if _season_intro_kind(p):
            notes.append(p)
            continue
        if NOTE_START_RE.match(p.strip()) or 'whole psalm is not said' in low:
            notes.append(p)
    return notes


def _psalter_rubric(paras: list[str]) -> list[str]:
    t = _joined(paras)
    ant = _first_ant(paras) or 'Ant. Holy Mary.'
    psalm = 'Psalm 69, as in the Psalter.'
    if 'how long' in t or 'ps. 12' in t or 'ps 12' in t:
        psalm = 'Psalm 12, as in the Psalter.'
    return [ant, psalm] + _keep_notes(paras)


def _inline_as_above(paras: list[str], catalog: dict[str, list[str]]) -> list[str]:
    key = _catalog_key_stub(paras)
    if not key or key not in catalog:
        return paras
    source = catalog[key]
    ant = _first_ant(paras) or _first_ant(source) or 'Ant. Holy Mary.'
    body = [p for p in source if not p.lower().startswith('ant')]
    return [ant] + body + _keep_notes(paras)


def split_office_hours(html: str) -> list[dict]:
    starts = list(HOUR_HEAD_RE.finditer(html))
    if not starts:
        body = html_to_text(html)
        paras = paragraphs(body)
        return [{'chapter': 1, 'title': 'Office of the Passion', 'paragraphs': paras}] if paras else []

    preamble = [
        p for p in paragraphs(html_to_text(html[:starts[0].start()]))
        if 'here begin' in p.lower()
    ]

    hours = []
    for i, m in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(html)
        body = html_to_text(html[m.end():end])
        paras = paragraphs(body)
        title = re.sub(r'\s+', ' ', m.group(1)).strip(' .')
        title = re.sub(r'^[IVX]+\s*[.\u2014\u2013\-—–]+\s*', '', title)
        hours.append({
            'title': _title_case(title),
            'paragraphs': paras or [],
        })

    catalog: dict[str, list[str]] = {}
    for hour in hours:
        if _is_as_above_stub(hour['paragraphs']) or _is_psalter_stub(hour['paragraphs']):
            continue
        key = _catalog_key_full(hour['paragraphs'])
        if key and key not in catalog:
            verses = _psalm_verses(hour['paragraphs'])
            ant = _first_ant(hour['paragraphs'])
            catalog[key] = ([ant] + verses) if ant else verses

    for hour in hours:
        if _is_psalter_stub(hour['paragraphs']):
            hour['paragraphs'] = _psalter_rubric(hour['paragraphs'])
        elif _is_as_above_stub(hour['paragraphs']):
            hour['paragraphs'] = _inline_as_above(hour['paragraphs'], catalog)

    buckets: dict[str, list[dict]] = {
        'passion': [],
        'easter': [],
        'feasts': [],
        'advent': [],
        'christmas': [],
    }
    season = 'passion'
    season_intros: dict[str, str] = {}
    for hour in hours:
        paras, nxt, intro = _peel_season_intro(hour['paragraphs'])
        hour['paragraphs'] = paras
        tu = hour['title'].upper()
        if 'CHRISTMAS' in tu:
            season = 'christmas'
        elif 'EASTER' in tu or 'HOLY SATURDAY' in tu:
            season = 'easter'
        if hour['paragraphs']:
            buckets[season].append(hour)
        if nxt:
            season = nxt
            if intro:
                season_intros[nxt] = intro

    chapters = []
    for key in ('passion', 'easter', 'feasts', 'advent', 'christmas'):
        group = buckets[key]
        if not group:
            continue
        paras: list[str] = []
        if key == 'passion':
            paras.extend(preamble)
        elif key in season_intros:
            paras.append(season_intros[key])
        for hour in group:
            body = hour['paragraphs']
            if body and body[0] == hour['title']:
                paras.extend(body)
            else:
                paras.append(hour['title'])
                paras.extend(body)
        paras = [p for p in paras if p]
        if not paras:
            continue
        chapters.append({
            'chapter': len(chapters) + 1,
            'title': SEASON_TITLES[key],
            'paragraphs': paras,
        })

    blob = '\n'.join(p for ch in chapters for p in ch['paragraphs']).lower()
    assert 'as above' not in blob, 'Office still has as-above stubs'
    assert all(';' not in ch['title'] for ch in chapters), 'Office titles still mashed'
    assert len(chapters) == 5, f'expected 5 Office seasons, got {len(chapters)}'
    return chapters


def _title_case(text: str) -> str:
    text = re.sub(r'^\d+\.\s*', '', text)
    text = re.sub(r'\s+', ' ', text).strip(' .')
    small = {'of', 'the', 'and', 'in', 'on', 'a', 'for', 'to', 'at', 'with'}
    words = text.split()
    out = []
    for i, w in enumerate(words):
        low = w.lower()
        if i > 0 and low in small:
            out.append(low)
        elif w.isupper() or w.islower() or w[:1].islower():
            out.append(w[:1].upper() + w[1:].lower() if w.isupper() else (
                w[:1].upper() + w[1:] if i == 0 else w
            ))
        else:
            out.append(w)
    return ' '.join(out)


def opuscule_from_h4(html: str, fallback_title: str) -> list[dict]:
    """One or more h4-marked Francis texts in a file."""
    matches = list(H4_RE.finditer(html))
    if not matches:
        # Last-ditch: take everything after common Robinson wrap-ups.
        body_html = after_marker(
            html,
            'as follows:',
            'as follows:—',
            'here it is:—',
            'now follows the',
            'now follow',
            'which now follow:',
            'here translated',
        )
        paras = paragraphs(html_to_text(body_html))
        return [{'chapter': 1, 'title': fallback_title, 'paragraphs': paras}] if paras else []

    # If the first h4 is near the start of Francis's text, each h4 is a unit.
    chapters = []
    for i, m in enumerate(matches):
        title = _title_case(clean_title(m.group(1)))
        if not title or title.upper() in {'I.', 'II.', 'III.', 'IV.', 'V.', 'VI.', 'VII.'}:
            continue
        end = matches[i + 1].start() if i + 1 < len(matches) else len(html)
        paras = paragraphs(html_to_text(html[m.end():end]), title)
        if not paras:
            continue
        chapters.append({
            'chapter': len(chapters) + 1,
            'title': title,
            'paragraphs': paras,
        })
    if chapters:
        return chapters
    paras = paragraphs(html_to_text(html[matches[-1].end():]))
    return [{'chapter': 1, 'title': fallback_title, 'paragraphs': paras}] if paras else []


def parse_admonitions(html: str) -> list[dict]:
    starts = list(ADMON_H4_RE.finditer(html))
    chapters = []
    for i, m in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(html)
        title = _title_case(clean_title(m.group(2)))
        paras = paragraphs(html_to_text(html[m.end():end]), title)
        if not paras:
            continue
        chapters.append({
            'chapter': int(m.group(1)),
            'title': title,
            'paragraphs': paras,
        })
    return chapters


def parse_canticle(html: str) -> list[str]:
    # Drop Robinson's essay; keep from the traditional incipit.
    text = html_to_text(html)
    m = re.search(
        r'HERE BEGIN THE PRAISES OF THE CREATURES.*',
        text,
        flags=re.S,
    )
    body = m.group(0) if m else text
    paras = paragraphs(body)
    # Drop trailing "Next:" leftovers already handled; drop a lone source line.
    return [p for p in paras if not p.lower().startswith('the text of the canticle')]


def parse_writings() -> tuple[list[dict], list[str]]:
    parts: list[dict] = []
    canticle_paras: list[str] = []

    def add_part(n: int, title: str, chapters: list[dict]) -> None:
        if not chapters:
            return
        # re-number if the source numbering is already correct, keep it
        parts.append({'part': n, 'title': title, 'chapters': chapters})

    admon = parse_admonitions(main_html(RAW_W / 'wosf03.htm'))
    add_part(1, 'Admonitions', admon)

    other: list[dict] = []
    other_files = [
        (4, 'Salutation of the Virtues'),
        (5, 'On Reverence for the Lord’s Body'),
        (8, 'Fragments for Clare'),
        (9, 'Testament'),
        (10, 'Of Living Religiously in a Hermitage'),
    ]
    for num, title in other_files:
        html = main_html(RAW_W / f'wosf{num:02d}.htm')
        for ch in opuscule_from_h4(html, title):
            other.append({
                'chapter': len(other) + 1,
                'title': ch['title'],
                'paragraphs': ch['paragraphs'],
            })
    add_part(2, 'Other Writings', other)

    first_html = main_html(RAW_W / 'wosf06.htm')
    cut = re.search(r'(?is)<h4[^>]*>\s*FIRST RULE OF THE FRIARS MINOR', first_html)
    if cut:
        first_html = first_html[cut.start():]
    first_rule = split_rule_chapters(first_html, 'First Rule')
    add_part(3, 'First Rule of the Friars Minor', first_rule)

    second_rule = split_rule_chapters(main_html(RAW_W / 'wosf07.htm'), 'Second Rule')
    add_part(4, 'Second Rule of the Friars Minor', second_rule)

    letters: list[dict] = []
    letter_files = [
        (12, 'Letter to All the Faithful'),
        (13, 'Letter to All the Friars'),
        (14, 'To a Certain Minister'),
        (15, 'To the Rulers of the People'),
        (16, 'To All the Custodes'),
        (17, 'To Brother Leo'),
    ]
    for num, title in letter_files:
        html = main_html(RAW_W / f'wosf{num:02d}.htm')
        # Prefer the last h3/h4 that repeats the letter title (Francis's text).
        chunk = opuscule_from_h4(html, title)
        if not chunk:
            # Letter to all the faithful uses an h3, not h4.
            h3s = list(H3_RE.finditer(html))
            if h3s:
                last = h3s[-1]
                paras = paragraphs(html_to_text(html[last.end():]))
                if paras:
                    chunk = [{'chapter': 1, 'title': title, 'paragraphs': paras}]
        if chunk:
            letters.append({
                'chapter': len(letters) + 1,
                'title': chunk[0]['title'] if chunk[0]['title'] else title,
                'paragraphs': chunk[0]['paragraphs'],
            })
    add_part(5, 'Letters', letters)

    prayers: list[dict] = []
    prayer_files = [
        (18, 'The Praises'),
        (19, 'Salutation of the Blessed Virgin'),
        (20, 'Prayer to Obtain Divine Love'),
        (21, 'The Sheet for Brother Leo'),
    ]
    for num, title in prayer_files:
        html = main_html(RAW_W / f'wosf{num:02d}.htm')
        for ch in opuscule_from_h4(html, title):
            prayers.append({
                'chapter': len(prayers) + 1,
                'title': ch['title'],
                'paragraphs': ch['paragraphs'],
            })
    canticle_html = main_html(RAW_W / 'wosf22.htm')
    canticle_paras = parse_canticle(canticle_html)
    if canticle_paras:
        prayers.append({
            'chapter': len(prayers) + 1,
            'title': 'The Canticle of the Sun',
            'paragraphs': canticle_paras,
        })
    add_part(6, 'Prayers', prayers)

    office_html = main_html(RAW_W / 'wosf23.htm')
    cut = re.search(r'(?is)<h4[^>]*>\s*OFFICE OF THE PASSION', office_html)
    if cut:
        office_html = office_html[cut.start():]
    office = split_office_hours(office_html)
    add_part(7, 'Office of the Passion', office)

    return parts, canticle_paras


def _fioretti_toc_titles() -> list[str]:
    toc_path = RAW_F / 'lff001.htm'
    if not toc_path.exists():
        return []
    raw = decode(toc_path.read_text(encoding='latin-1'))
    titles: list[str] = []
    for row in re.findall(r'(?is)<tr>(.*?)</tr>', raw):
        tds = re.findall(r'(?is)<td[^>]*>(.*?)</td>', row)
        if len(tds) < 2:
            continue
        num = clean_title(tds[0])
        title = clean_title(tds[1])
        if not re.fullmatch(r'[IVXLCDM]+\.?', num):
            continue
        if not title or title.upper() in {'PAGE', 'CHAP.'}:
            continue
        if title.lower().startswith('p. '):
            continue
        titles.append(title)
    return titles


def _looks_like_story_title(text: str) -> bool:
    low = text.lower()
    return low.startswith((
        'how ', 'of ', 'ensample', 'an ensample', 'in the name',
        'friar ', 'a chapter of',
    ))


def _complete_from_toc(title: str, toc: list[str]) -> str:
    t = re.sub(r'\s+', ' ', title).strip(' .')
    if len(t) < 24:
        return t
    longer = [
        x for x in toc
        if x.lower().startswith(t.lower()) and len(x) > len(t) + 8
    ]
    if len(longer) == 1:
        return longer[0].strip(' .')
    return t


def _heading_candidates(html: str) -> tuple[list[str], list[str], list[str]]:
    smalls = [clean_title(m.group(1)) for m in SMALL_CENTER_RE.finditer(html)]
    smalls = [
        s for s in smalls
        if s and not s.upper().startswith('HERE ENDETH')
        and s.upper() not in {'CHAP.', 'PAGE'}
    ]
    h3s = [clean_title(m.group(1)) for m in H3_RE.finditer(html)]
    h3s = [t for t in h3s if t.upper() not in {'FOOTNOTES', 'CONTENTS', 'INTRODUCTION'}]
    h4s = [clean_title(m.group(1)) for m in H4_RE.finditer(html)]
    return smalls, h3s, h4s


def _fioretti_page_title(html: str, toc: list[str]) -> str:
    smalls, h3s, h4s = _heading_candidates(html)
    for s in smalls:
        if _looks_like_story_title(s):
            return _complete_from_toc(s, toc)
    for s in smalls:
        if len(s) > 20:
            return _complete_from_toc(s, toc)
    if any('STIGMATA' in t.upper() for t in h3s):
        parts = [
            t for t in h3s + h4s
            if 'STIGMATA' in t.upper() or 'CONSIDERATION' in t.upper()
        ]
        return _title_case(' '.join(parts))
    for h in h4s:
        if re.search(r'(?i)(first|second|third|fourth|fifth).+consideration', h):
            return _title_case(h)
    for h in h3s:
        if CHAPTER_BANNER_RE.match(h) or h.upper().startswith('BEGINNETH'):
            continue
        return _title_case(h)
    for h in h4s:
        if len(h) > 12:
            return _title_case(h)
    return ''


FIORETTI_BANNERS = {
    'THE LITTLE FLOWERS OF',
    'ST. FRANCIS',
    'FRIAR JUNIPER',
    'FRIAR GILES',
    'ADDENDA',
    'BEGINNETH THE LIFE',
    'THE COMPANION OF ST. FRANCIS',
    'AND OF THEIR CONSIDERATIONS',
    'OF CERTAIN TEACHINGS AND NOTABLE SAYINGS',
    'THE LITTLE FLOWERS OF ST. FRANCIS',
}


def _is_fioretti_banner(para: str, title: str) -> bool:
    u = para.strip()
    if CHAPTER_BANNER_RE.match(u):
        return True
    if u.upper() in FIORETTI_BANNERS:
        return True
    if u.upper().startswith('HERE ENDETH'):
        return True
    if title and _is_heading_echo(u, title):
        return True
    return False


def parse_fioretti() -> list[dict]:
    files = sorted(RAW_F.glob('lff*.htm'))
    toc = _fioretti_toc_titles()
    stories = []
    for path in files:
        n = int(path.stem.replace('lff', ''))
        if n in FIORETTI_SKIP:
            continue
        html = main_html(path)
        title = _fioretti_page_title(html, toc)
        paras = [
            p for p in paragraphs(html_to_text(html), title)
            if not _is_fioretti_banner(p, title)
        ]
        if not title or not paras:
            continue
        stories.append({
            'chapter': len(stories) + 1,
            'title': title,
            'paragraphs': paras,
        })

    weak = []
    for s in stories:
        t = s['title']
        if CHAPTER_BANNER_RE.match(t) or re.fullmatch(r'Chapter\s+[IVXLCDM]+\.?', t):
            weak.append(t)
        if '. . .' in t or t.endswith('...') or '…' in t:
            weak.append(t)
        if t.lower() in {'introduction', 'contents', "translator's note"}:
            weak.append(t)
        if len(t) < 12:
            weak.append(t)
    assert not weak, f'Fioretti titles still stubs: {weak[:8]}'
    assert len(stories) > 50, f'Fioretti too thin: {len(stories)}'
    return stories


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    parts, canticle = parse_writings()
    stories = parse_fioretti()

    print('=== writings ===')
    total = 0
    n_ch = 0
    for p in parts:
        wc = sum(word_count(c['paragraphs']) for c in p['chapters'])
        total += wc
        n_ch += len(p['chapters'])
        print(f"  Part {p['part']} {p['title']}: {len(p['chapters'])} ch, {wc} words")
        for c in p['chapters']:
            w = word_count(c['paragraphs'])
            print(f"    {c['chapter']:3d} {c['title'][:60]:60s} {w:5d}")
    print(f'total {n_ch} chapters, {total} words')

    print(f'\n=== fioretti {len(stories)} stories, '
          f'{sum(word_count(s["paragraphs"]) for s in stories)} words ===')
    for s in stories[:8]:
        print(f"  {s['chapter']:3d} {s['title'][:70]}")
    print('  ...')
    for s in stories[-4:]:
        print(f"  {s['chapter']:3d} {s['title'][:70]}")

    (WORK / 'chapters.json').write_text(
        json.dumps({'parts': parts}, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8',
    )
    (WORK / 'stories.json').write_text(
        json.dumps({'stories': stories}, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8',
    )
    (WORK / 'canticle.json').write_text(
        json.dumps({
            'title': 'The Canticle of the Sun',
            'paragraphs': canticle,
        }, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8',
    )
    print(f'\nwrote {WORK}')


if __name__ == '__main__':
    main()
