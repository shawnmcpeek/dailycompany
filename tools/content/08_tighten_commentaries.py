#!/usr/bin/env python3
"""Tighten draft commentaries to 2–3 restrained sentences; merge into app JSON + review HTML."""

from __future__ import annotations

import html
import json
import os
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORK = ROOT / "work"
REPO = ROOT.parent.parent
ASSETS = REPO / "assets" / "content" / "benedict"
REVIEW = ROOT / "review"


def load_env() -> None:
    env_path = REPO / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def chat(api_key: str, text: str) -> str:
    payload = {
        "model": "gpt-4o-mini",
        "temperature": 0.2,
        "messages": [
            {
                "role": "system",
                "content": (
                    "Tighten this Benedict Daily commentary. Output ONLY 2 or 3 short sentences "
                    "(max 60 words total). Tone: restrained, concrete, breviary-like — not soft "
                    "wellness language, not 'journey/path/fulfillment'. Keep the substance; cut fluff. "
                    "Remove any [NEEDS SOURCE] tag."
                ),
            },
            {"role": "user", "content": text},
        ],
    }
    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"].strip()


def emit_review(readings: list[dict], commentaries: dict[int, str]) -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    cards = []
    for r in readings:
        c = commentaries.get(r["id"], "")
        cards.append(
            f"""
<article class="card" id="r{r['id']}">
  <header>
    <span class="id">#{r['id']:03d}</span>
    <span>Ch {r['chapter']} · {html.escape(r['chapterTitle'])} · portion {r['portionInChapter']}/{r['portionsInChapter']}</span>
    <label><input type="checkbox" data-id="{r['id']}"> reviewed OK</label>
  </header>
  <div class="cols">
    <section><h3>Rule (Verheyen)</h3><p>{html.escape(r['textEn'][:900])}{'…' if len(r['textEn'])>900 else ''}</p></section>
    <section><h3>Commentary draft</h3><p>{html.escape(c)}</p></section>
  </div>
</article>"""
        )
    doc = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Commentary review</title>
<style>
body{{font-family:Georgia,serif;background:#f3ede1;color:#211d1a;margin:0;padding:1rem 1.25rem 3rem;line-height:1.55}}
h1{{font-weight:500}} header.page{{position:sticky;top:0;background:#f3ede1ee;padding:.75rem 0;border-bottom:1px solid #d9cfbe}}
.card{{border-top:1px solid #d9cfbe;padding:1rem 0}} .cols{{display:grid;grid-template-columns:1fr 1fr;gap:1rem}}
h3{{font-size:.75rem;letter-spacing:.08em;text-transform:uppercase;color:#6e655a}}
@media(max-width:900px){{.cols{{grid-template-columns:1fr}}}}
.done{{opacity:.55}}
</style></head><body>
<header class="page">
  <h1>Commentary review</h1>
  <p>Drafted from Delatte/McCann 1921 + the day’s Rule portion. Check OK when the gloss is faithful and restrained.</p>
  <button id="export" type="button">Export checklist</button>
  <span id="stat"></span>
</header>
<main>{''.join(cards)}</main>
<script>
const key='benedict-daily-commentary-review-v1';
const saved=JSON.parse(localStorage.getItem(key)||'{{}}');
const cards=[...document.querySelectorAll('.card')];
cards.forEach(c=>{{
  const id=c.id.slice(1); const box=c.querySelector('input');
  box.checked=!!saved[id]; c.classList.toggle('done', box.checked);
  box.onchange=()=>{{saved[id]=box.checked; localStorage.setItem(key, JSON.stringify(saved)); c.classList.toggle('done', box.checked); stat();}};
}});
function stat(){{document.getElementById('stat').textContent=` reviewed ${{Object.values(saved).filter(Boolean).length}}/122`;}}
stat();
document.getElementById('export').onclick=()=>{{
  const a=document.createElement('a');
  a.href=URL.createObjectURL(new Blob([JSON.stringify({{reviewed:saved}},null,2)],{{type:'application/json'}}));
  a.download='commentary-review-checklist.json'; a.click();
}};
</script></body></html>"""
    path = REVIEW / "commentary_side_by_side.html"
    path.write_text(doc, encoding="utf-8")
    print(f"wrote {path}")


def main() -> None:
    load_env()
    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("OPENAI_API_KEY missing")

    draft = json.loads((WORK / "commentaries_draft.json").read_text())
    tight_path = WORK / "commentaries_tight.json"
    existing: dict[int, str] = {}
    if tight_path.exists():
        existing = {
            x["id"]: x["commentary"]
            for x in json.loads(tight_path.read_text()).get("commentaries", [])
        }

    out = []
    for i, item in enumerate(draft["commentaries"], 1):
        rid = item["id"]
        if rid in existing:
            commentary = existing[rid]
            print(f"[{i}/122] #{rid} cached")
        else:
            commentary = chat(api_key, item["commentary"])
            print(f"[{i}/122] #{rid} tightened ({len(commentary.split())}w)")
            time.sleep(0.15)
        out.append({**item, "commentary": commentary, "status": "needs_review"})
        if i % 10 == 0:
            tight_path.write_text(
                json.dumps({"commentaries": out}, indent=2, ensure_ascii=False) + "\n"
            )

    tight_path.write_text(
        json.dumps(
            {
                "version": 1,
                "note": "Tightened drafts for human review.",
                "commentaries": out,
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n"
    )

    # Merge into rule_readings.json
    readings_path = ASSETS / "rule_readings.json"
    readings_doc = json.loads(readings_path.read_text())
    by_id = {c["id"]: c["commentary"] for c in out}
    for r in readings_doc["readings"]:
        r["commentary"] = by_id.get(r["id"])
    readings_path.write_text(
        json.dumps(readings_doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"updated {readings_path}")

    emit_review(readings_doc["readings"], by_id)


if __name__ == "__main__":
    main()
