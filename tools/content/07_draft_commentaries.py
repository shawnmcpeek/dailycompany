#!/usr/bin/env python3
"""Draft 2–4 sentence commentaries from Delatte excerpts via OpenAI.

Outputs tools/content/work/commentaries_draft.json for human review.
Does NOT treat drafts as final store copy until reviewed.
"""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORK = ROOT / "work"
REPO = ROOT.parent.parent


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


def chat(api_key: str, system: str, user: str) -> str:
    payload = {
        "model": "gpt-4o-mini",
        "temperature": 0.3,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
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
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"].strip()


SYSTEM = """You draft short commentaries for Benedict Daily, a formation app.
Write ORIGINAL glosses (2–4 sentences) grounded ONLY in the provided Delatte/McCann excerpt and the day's Rule portion.
Rules:
- Do not invent history, quotes, or claims absent from the sources.
- Do not copy Delatte verbatim for more than a short phrase; paraphrase in plain modern English.
- Tone: restrained, reverent, practical — not preachy, not wellness-speak, not guilt/streak language.
- Address a lay reader living the Rule's wisdom outside the cloister when the text allows.
- No markdown, no title, no citation apparatus — just the commentary sentences.
- If the Delatte excerpt is empty or useless OCR, write a cautious 2-sentence gloss from the Rule portion alone and prefix with [NEEDS SOURCE].
"""


def main() -> None:
    load_env()
    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("OPENAI_API_KEY missing")

    packets = json.loads((WORK / "commentary_packets.json").read_text())["packets"]
    out_path = WORK / "commentaries_draft.json"
    existing: dict[int, dict] = {}
    if out_path.exists():
        prev = json.loads(out_path.read_text())
        for item in prev.get("commentaries", []):
            existing[item["id"]] = item

    results = []
    for i, p in enumerate(packets, 1):
        rid = p["id"]
        if rid in existing and existing[rid].get("commentary"):
            results.append(existing[rid])
            print(f"[{i}/122] #{rid} cached")
            continue

        user = (
            f"Reading id {rid} · Chapter {p['chapter']} · {p['chapterTitle']} "
            f"(portion {p['portionInChapter']} of {p['portionsInChapter']})\n\n"
            f"RULE PORTION (Verheyen):\n{p['textEn'][:2500]}\n\n"
            f"DELATTE EXCERPT (McCann 1921, research source):\n{p['delatteExcerpt'][:3500]}\n"
        )
        try:
            commentary = chat(api_key, SYSTEM, user)
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            raise SystemExit(f"OpenAI HTTP {e.code}: {body[:300]}") from e

        item = {
            "id": rid,
            "chapter": p["chapter"],
            "chapterTitle": p["chapterTitle"],
            "portionInChapter": p["portionInChapter"],
            "portionsInChapter": p["portionsInChapter"],
            "commentary": commentary,
            "source": "Drafted from Delatte/McCann 1921 excerpt + Verheyen portion",
            "status": "needs_review",
        }
        results.append(item)
        # Checkpoint often
        out_path.write_text(
            json.dumps(
                {
                    "version": 1,
                    "note": "Draft glosses for human review. Do not treat as final until reviewed.",
                    "commentaries": results + [
                        existing[k]
                        for k in sorted(existing)
                        if k not in {r["id"] for r in results}
                    ],
                },
                indent=2,
                ensure_ascii=False,
            )
            + "\n"
        )
        print(f"[{i}/122] #{rid} drafted ({len(commentary.split())} words)")
        time.sleep(0.2)

    # Final sorted write
    results.sort(key=lambda x: x["id"])
    out_path.write_text(
        json.dumps(
            {
                "version": 1,
                "note": "Draft glosses for human review. Do not treat as final until reviewed.",
                "commentaries": results,
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n"
    )
    print(f"wrote {out_path} ({len(results)} commentaries)")


if __name__ == "__main__":
    main()
