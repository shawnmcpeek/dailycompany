#!/usr/bin/env python3
"""Emit Ignatius house JSON: autobiography cycle, 22 rules, 210 Exercises, prayers."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
WORK = ROOT / "work"
REVIEW = ROOT / "review"
ASSETS = REPO / "assets" / "content" / "ignatius"

sys.path.insert(0, str(ROOT.parent))
from emit_lib import emit_cut_cycle  # noqa: E402

AUTO_TRANSLATOR = "J. F. X. O'Conor SJ (1900)"
MULLAN_TRANSLATOR = "Elder Mullan SJ (1914)"
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Society of Jesus, any Jesuit province or house, "
    "or any Ignatian retreat centre or publisher."
)
TAGLINE = "Find God in all things."
DIRECTOR_NOTE = (
    "These Exercises were written to be given by a director, one person to "
    "another. This app can carry the text and keep the days, but it cannot "
    "listen to you. If you find yourself in real desolation, or moving toward "
    "a serious decision, find a spiritual director — many dioceses and "
    "retreat houses will connect you with one at no cost."
)

PART_DAYS = {0: 7, 1: 21, 2: 84, 3: 42, 4: 56}
FORBIDDEN = (
    re.compile(r"\bIHS\b"),
    re.compile(r"\bI\.H\.S\.?\b"),
    re.compile(r"ccel\.org", re.I),
    re.compile(r"file:///"),
    re.compile(r"Project Gutenberg", re.I),
    re.compile(r"This document is from the C"),
)


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def assert_clean(label: str, text: str) -> None:
    for pat in FORBIDDEN:
        if pat.search(text):
            raise SystemExit(f"{label}: forbidden pattern {pat.pattern!r}")


def expand_part(units: list[dict], target: int) -> list[dict]:
    n = len(units)
    if n == 0:
        raise SystemExit("empty part")
    if n > target:
        raise SystemExit(f"{n} units exceed {target} days")
    extra = target - n
    extras_after = [extra // n] * n
    for i in range(extra % n):
        extras_after[i] += 1
    out: list[dict] = []
    for unit, n_extra in zip(units, extras_after):
        out.append({
            "title": unit["title"],
            "textEn": unit["textEn"],
            "isRepetition": bool(unit["isRepetition"]),
        })
        base = unit["title"]
        if base.lower().startswith("repetition:"):
            rep_title = base
        else:
            rep_title = f"Repetition: {base}"
        for _ in range(n_extra):
            out.append({
                "title": rep_title,
                "textEn": unit["textEn"],
                "isRepetition": True,
            })
    if len(out) != target:
        raise SystemExit(f"expand produced {len(out)}, want {target}")
    return out


def part_for_id(entry_id: int) -> int:
    if entry_id <= 7:
        return 0
    if entry_id <= 28:
        return 1
    if entry_id <= 112:
        return 2
    if entry_id <= 154:
        return 3
    return 4


def emit_exercises(units_in: list[dict]) -> list[dict]:
    by_part: dict[int, list[dict]] = {p: [] for p in PART_DAYS}
    for u in units_in:
        by_part[u["part"]].append(u)
    expanded: list[dict] = []
    for part, target in PART_DAYS.items():
        chunk = expand_part(by_part[part], target)
        expanded.extend(chunk)
    if len(expanded) != 210:
        raise SystemExit(f"expected 210 exercises, got {len(expanded)}")

    entries = []
    for i, e in enumerate(expanded, 1):
        assert_clean(f"exercises #{i}", e["textEn"])
        week = (i - 1) // 7 + 1
        day = (i - 1) % 7 + 1
        part = part_for_id(i)
        entries.append({
            "id": i,
            "week": week,
            "day": day,
            "part": part,
            "title": e["title"],
            "textEn": e["textEn"],
            "isRepetition": e["isRepetition"],
        })
    return entries


def main() -> None:
    chapters = json.loads((WORK / "chapters.json").read_text(encoding="utf-8"))
    rules = json.loads((WORK / "rules.json").read_text(encoding="utf-8"))
    units = json.loads((WORK / "exercises_units.json").read_text(encoding="utf-8"))["units"]
    prayers = json.loads((WORK / "prayers.json").read_text(encoding="utf-8"))

    if len(rules["chapters"]) != 22:
        raise SystemExit(f"expected 22 rules, got {len(rules['chapters'])}")
    if [c["chapter"] for c in rules["chapters"]] != list(range(1, 23)):
        raise SystemExit("rules not numbered 1..22")
    weeks = [c["week"] for c in rules["chapters"]]
    if weeks.count(1) != 14 or weeks.count(2) != 8:
        raise SystemExit(f"rule week split {weeks.count(1)}/{weeks.count(2)}")

    portal = {
        "id": "ignatius",
        "displayName": "Ignatius of Loyola",
        "tagline": TAGLINE,
        "provenance": "constructed",
        "spine": {
            "type": "cycle",
            "note": (
                "The Autobiography, cut and cycled — a thin book, repeated, "
                "never padded. The Spiritual Exercises are a 210-day program "
                "(30 weeks × 7), sequential, not mapped onto the calendar."
            ),
        },
        "anchor": "examen",
        "modules": ["today", "practice", "discernment", "exercises"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "ignatius_companion",
        "sourceNote": (
            "Autobiography of St. Ignatius, translated by J. F. X. O'Conor, S.J. "
            "(Benziger Brothers, New York, 1900); Project Gutenberg #24534. "
            "Spiritual Exercises, translated from the Autograph by Elder Mullan, S.J. "
            "(P. J. Kenedy & Sons, New York, 1914). Anima Christi is the traditional "
            "public-domain English; Mullan only names it as a rubric "
            "(\"And with that the Soul of Christ\"). The Prayer for Generosity is "
            "not in the Autograph or in Mullan and is not included. Not Puhl, "
            "Ganss, or Fleming."
        ),
    }

    auto_entries = emit_cut_cycle(
        parts=chapters["parts"],
        assets=ASSETS,
        review=REVIEW,
        translator=AUTO_TRANSLATOR,
        portal=portal,
        prefer_unique=True,
        modulo_if_thin=True,
    )

    exercises = emit_exercises(units)
    n_rep = sum(1 for e in exercises if e["isRepetition"])

    for c in rules["chapters"]:
        assert_clean(f"rule {c['chapter']}", c["textEn"])
    for p in prayers["prayers"]:
        assert_clean(p["id"], p["textEn"])
    for e in auto_entries:
        assert_clean(f"auto {e['id']}", e["textEn"])

    (ASSETS / "rules.json").write_text(
        json.dumps(rules, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "exercises.json").write_text(
        json.dumps({
            "version": 1,
            "translator": MULLAN_TRANSLATOR,
            "directorNote": DIRECTOR_NOTE,
            "entries": exercises,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ASSETS / "prayers.json").write_text(
        json.dumps(prayers, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    REVIEW.mkdir(parents=True, exist_ok=True)
    rows = []
    for e in exercises:
        flag = " class=rep" if e["isRepetition"] else ""
        rows.append(
            f"<tr{flag}><td>{e['id']}</td><td>W{e['week']} D{e['day']}</td>"
            f"<td>p{e['part']}</td><td>{e['title']}</td>"
            f"<td>{words(e['textEn'])}</td></tr>"
        )
    (REVIEW / "exercises.html").write_text(
        "<!doctype html><meta charset=utf-8><title>Ignatius Exercises</title>"
        f"<h1>210 program days — {n_rep} repetitions</h1>"
        "<style>tr.rep{background:#f4eee6} td{padding:4px 8px}</style>"
        "<table border=1 cellpadding=6><tr><th>#</th><th>Week/Day</th>"
        "<th>Part</th><th>Title</th><th>Words</th></tr>"
        + "\n".join(rows)
        + "</table>\n",
        encoding="utf-8",
    )

    auto_words = sum(e["wordCount"] for e in auto_entries)
    print("\n=== SHIP CHECK ===")
    print(f"autobiography {len(auto_entries)} entries, {auto_words} words")
    print("22 rules first-line samples:")
    for c in rules["chapters"]:
        line = c["textEn"].split("\n", 1)[0]
        print(f"  {c['chapter']:2d} [w{c['week']}] {line[:100]}")
    print(f"exercises {len(exercises)} entries, {n_rep} isRepetition")
    print("no IHS, no ccel.org, no Gutenberg license in shipped textEn")
    print(f"wrote {ASSETS}")


if __name__ == "__main__":
    main()
