#!/usr/bin/env python3
"""Emit app JSON assets + human review HTML (Doyle cue ‖ Verheyen ‖ Latin)."""

from __future__ import annotations

import html
import json
from collections import defaultdict
from pathlib import Path

from common import ASSETS, REVIEW, WORK


def build_calendar(readings: list[dict]) -> dict:
    by_common: dict[str, list[int]] = defaultdict(list)
    by_leap: dict[str, list[int]] = defaultdict(list)
    for r in readings:
        rid = r["id"]
        for key in r["dateKeysCommon"]:
            if rid not in by_common[key]:
                by_common[key].append(rid)
        for key in r["dateKeysLeap"]:
            if rid not in by_leap[key]:
                by_leap[key].append(rid)
        # Common-year merge: leap-only reading attaches to previous day's keys.
        if r.get("mergeIntoPreviousOnCommon"):
            # Find preceding reading id (rid-1) and attach this id to its Feb key.
            prev = next(x for x in readings if x["id"] == rid - 1)
            # Preceding's February common key is the merge target day.
            feb_keys = [k for k in prev["dateKeysCommon"] if k.startswith("02-")]
            for k in feb_keys:
                if rid not in by_common[k]:
                    by_common[k].append(rid)
    return {
        "byDateCommon": {k: sorted(v) for k, v in sorted(by_common.items())},
        "byDateLeap": {k: sorted(v) for k, v in sorted(by_leap.items())},
    }


def emit_assets(readings: list[dict]) -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    clean = []
    for r in readings:
        clean.append(
            {
                "id": r["id"],
                "chapter": r["chapter"],
                "chapterTitle": r["chapterTitle"],
                "portionInChapter": r["portionInChapter"],
                "portionsInChapter": r["portionsInChapter"],
                "dateKeysCommon": r["dateKeysCommon"],
                "dateKeysLeap": r["dateKeysLeap"],
                "mergeIntoPreviousOnCommon": r["mergeIntoPreviousOnCommon"],
                "textEn": r["textEn"],
                "textLa": r["textLa"],
                "commentary": None,
                "audioKeyEn": None,
            }
        )
    readings_path = ASSETS / "rule_readings.json"
    readings_path.write_text(
        json.dumps({"version": 1, "readings": clean}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    cal = build_calendar(readings)
    cal_path = ASSETS / "reading_calendar.json"
    cal_path.write_text(
        json.dumps({"version": 1, **cal}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {readings_path}")
    print(f"wrote {cal_path}")


def esc(s: str) -> str:
    return html.escape(s or "")


def para_html(text: str) -> str:
    parts = [p.strip() for p in (text or "").split("\n\n") if p.strip()]
    if not parts:
        return "<p class='empty'>(empty)</p>"
    return "\n".join(f"<p>{esc(p)}</p>" for p in parts)


def emit_review(readings: list[dict]) -> Path:
    REVIEW.mkdir(parents=True, exist_ok=True)
    flagged = [
        r
        for r in readings
        if r["portionsInChapter"] > 1
        or "wordcount_skew" in r["flags"]
        or "empty_english" in r["flags"]
        or "empty_latin" in r["flags"]
    ]

    cards = []
    for r in readings:
        needs = r["portionsInChapter"] > 1 or any(
            f in r["flags"] for f in ("wordcount_skew", "empty_english", "empty_latin")
        )
        cls = "card needs-review" if needs else "card"
        flags = ", ".join(r["flags"]) if r["flags"] else "ok"
        dates = (
            f"common: {', '.join(r['dateKeysCommon'])} · "
            f"leap: {', '.join(r['dateKeysLeap'])}"
        )
        cards.append(
            f"""
<article class="{cls}" id="r{r['id']}" data-flags="{esc(flags)}" data-chapter="{r['chapter']}">
  <header>
    <div class="meta">
      <span class="id">#{r['id']:03d}</span>
      <span class="ch">Ch {r['chapter']} · {esc(r['chapterTitle'])}</span>
      <span class="portion">portion {r['portionInChapter']} / {r['portionsInChapter']}</span>
      <span class="conf">confidence {r['confidence']:.2f}</span>
      <span class="flags">{esc(flags)}</span>
    </div>
    <div class="dates">{esc(r['doyleHeader'])}<br><small>{esc(dates)}</small></div>
    <label class="review-mark"><input type="checkbox" data-id="{r['id']}"> reviewed OK</label>
  </header>
  <div class="cols">
    <section>
      <h3>Doyle cue <em>(date-table source — not shipped)</em></h3>
      {para_html(r['doyleText'])}
    </section>
    <section>
      <h3>Verheyen <em>(ships as English)</em></h3>
      {para_html(r['textEn'])}
    </section>
    <section>
      <h3>Latin <em>(ships side-by-side)</em></h3>
      {para_html(r['textLa'])}
    </section>
  </div>
</article>
"""
        )

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Benedict Daily — Rule alignment review</title>
<style>
:root {{
  --bg: #f3ede1;
  --ink: #211d1a;
  --sec: #6e655a;
  --rule: #d9cfbe;
  --gold: #a8802c;
  --warn: #7a3a2c;
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
  background: var(--bg);
  color: var(--ink);
  line-height: 1.5;
}}
header.page {{
  position: sticky; top: 0; z-index: 5;
  background: color-mix(in srgb, var(--bg) 92%, white);
  border-bottom: 1px solid var(--rule);
  padding: 1rem 1.25rem;
  backdrop-filter: blur(8px);
}}
header.page h1 {{
  font-family: "EB Garamond", Georgia, serif;
  font-weight: 500;
  margin: 0 0 .35rem;
  font-size: 1.75rem;
}}
header.page p {{ margin: .2rem 0; color: var(--sec); max-width: 70rem; }}
.toolbar {{ display: flex; flex-wrap: wrap; gap: .75rem; margin-top: .75rem; align-items: center; }}
.toolbar button, .toolbar select {{
  font: inherit; padding: .4rem .7rem; border: 1px solid var(--rule);
  background: #fff8ee; color: var(--ink); cursor: pointer;
}}
.stat {{ color: var(--sec); }}
main {{ padding: 1rem 1.25rem 4rem; display: grid; gap: 1.25rem; }}
.card {{
  border-top: 1px solid var(--rule);
  padding-top: 1rem;
}}
.card.needs-review {{ border-top: 2px solid var(--warn); }}
.card header {{
  display: grid; gap: .35rem; margin-bottom: .75rem;
}}
.meta {{ display: flex; flex-wrap: wrap; gap: .6rem; font-size: .85rem; color: var(--sec); }}
.meta .id {{ color: var(--gold); font-weight: 600; }}
.meta .flags {{ color: var(--warn); }}
.dates {{ font-family: "EB Garamond", Georgia, serif; font-size: 1.05rem; }}
.cols {{
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
}}
.cols section {{
  min-width: 0;
}}
.cols h3 {{
  font-size: .78rem;
  letter-spacing: .08em;
  text-transform: uppercase;
  color: var(--sec);
  font-weight: 600;
  margin: 0 0 .5rem;
  border-bottom: 1px solid var(--rule);
  padding-bottom: .35rem;
}}
.cols h3 em {{ text-transform: none; letter-spacing: 0; font-weight: 400; }}
.cols p {{
  font-family: "EB Garamond", Georgia, serif;
  font-size: 1.02rem;
  line-height: 1.7;
  margin: 0 0 .85rem;
}}
.cols .empty {{ color: var(--warn); font-style: italic; }}
.review-mark {{ font-size: .85rem; color: var(--sec); }}
.card.done {{ opacity: .55; }}
@media (max-width: 1100px) {{
  .cols {{ grid-template-columns: 1fr; }}
}}
</style>
</head>
<body>
<header class="page">
  <h1>Rule alignment review</h1>
  <p>
    Left column is Doyle (date breakpoints only — never shipped).
    Middle is Verheyen (app English). Right is Latin.
    Focus first on cards marked <strong>needs-review</strong>
    ({len(flagged)} of {len(readings)}): intra-chapter breaks and word-count skew.
  </p>
  <div class="toolbar">
    <label>Filter
      <select id="filter">
        <option value="all">All 122</option>
        <option value="needs" selected>Needs review</option>
        <option value="intra">Intra-chapter only</option>
        <option value="skew">Wordcount skew</option>
        <option value="unchecked">Not checked OK</option>
      </select>
    </label>
    <button type="button" id="export">Export checklist JSON</button>
    <span class="stat" id="stat"></span>
  </div>
</header>
<main id="list">
{''.join(cards)}
</main>
<script>
const cards = [...document.querySelectorAll('.card')];
const filter = document.getElementById('filter');
const stat = document.getElementById('stat');
const key = 'benedict-daily-alignment-review-v1';
const saved = JSON.parse(localStorage.getItem(key) || '{{}}');

function applySaved() {{
  cards.forEach(c => {{
    const id = c.id.slice(1);
    const box = c.querySelector('input[type=checkbox]');
    box.checked = !!saved[id];
    c.classList.toggle('done', box.checked);
    box.addEventListener('change', () => {{
      saved[id] = box.checked;
      localStorage.setItem(key, JSON.stringify(saved));
      c.classList.toggle('done', box.checked);
      updateStat();
      applyFilter();
    }});
  }});
}}

function visible(card) {{
  const mode = filter.value;
  const flags = card.dataset.flags;
  const checked = card.querySelector('input').checked;
  if (mode === 'all') return true;
  if (mode === 'needs') return card.classList.contains('needs-review');
  if (mode === 'intra') return flags.includes('intra_chapter_break');
  if (mode === 'skew') return flags.includes('wordcount_skew');
  if (mode === 'unchecked') return !checked;
  return true;
}}

function applyFilter() {{
  let shown = 0;
  cards.forEach(c => {{
    const on = visible(c);
    c.style.display = on ? '' : 'none';
    if (on) shown++;
  }});
  updateStat(shown);
}}

function updateStat(shown) {{
  const done = cards.filter(c => c.querySelector('input').checked).length;
  const needs = cards.filter(c => c.classList.contains('needs-review')).length;
  const base = shown == null ? cards.filter(c => c.style.display !== 'none').length : shown;
  stat.textContent = `showing ${{base}} · reviewed ${{done}}/122 · needs-review ${{needs}}`;
}}

filter.addEventListener('change', applyFilter);
document.getElementById('export').addEventListener('click', () => {{
  const blob = new Blob([JSON.stringify({{reviewed: saved, exportedAt: new Date().toISOString()}}, null, 2)], {{type:'application/json'}});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'alignment-review-checklist.json';
  a.click();
}});

applySaved();
applyFilter();
</script>
</body>
</html>
"""
    path = REVIEW / "alignment_side_by_side.html"
    path.write_text(doc, encoding="utf-8")
    print(f"wrote {path}")
    return path


def main() -> None:
    aligned = json.loads((WORK / "aligned.json").read_text(encoding="utf-8"))
    readings = aligned["readings"]
    emit_assets(readings)
    emit_review(readings)


if __name__ == "__main__":
    main()
