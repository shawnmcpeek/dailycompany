#!/usr/bin/env python3
"""Walk all 122 Benedict readings. Lexical repairs only — no recut, no English."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parents[3] / "assets" / "content"
LIVE = ASSETS / "benedict" / "rule_readings.json"
LEGACY = ASSETS / "rule_readings.json"
REPORT = Path(__file__).resolve().parent / "walk_report.txt"

# Phrase / token repairs confirmed against published Latin (Dysinger / IntraText / sense).
PHRASES = [
    ("Non facere futum.", "Non facere furtum."),
    ("una præ beatur", "una præbeatur"),
    ("unuscuiusque", "uniuscuiusque"),
    ("inoboetientibus", "inoboedientibus"),
    ("cursæ suæ", "curæ suæ"),
    ("non p æ niteberis", "non pæniteberis"),
    ("recreare.Nudum", "recreare. Nudum"),
    ("patefacere.Os", "patefacere. Os"),
    ("et:qui", "et: qui"),
    ("sed et desideria", "sed et desideria carnis"),
    ("pastotis", "pastoris"),
    ("delinquentiump", "delinquentium"),
    ("partiendoscilicet", "partiendos scilicet"),
    ("sive una sit refectio sivi prandii", "sive una sit refectio sive prandii"),
    ("eorum.Hanc autem", "eorum. Hanc autem"),
]

FOOTER = re.compile(
    r"\s*Christian Latin The Latin Library The Classics Page\s*$"
)
# Standalone adverb only. Do not touch omnimodo / omnimodis.
OMNIMO = re.compile(r"\bomnimo\b")

BANNED = [
    "futum",
    "pastotis",
    "delinquentiump",
    "præ beatur",
    "unuscuiusque",
    "inoboetientibus",
    "p æ niteberis",
    "recreare.Nudum",
    "patefacere.Os",
    "partiendoscilicet",
    "The Latin Library",
    "Classics Page",
]


def words(text: str) -> list[str]:
    return re.findall(r"[A-Za-zÀ-öø-ÿ0-9']+", text)


def main() -> int:
    data = json.loads(LIVE.read_text(encoding="utf-8"))
    readings = data["readings"]
    if len(readings) != 122:
        raise SystemExit(f"expected 122 readings, got {len(readings)}")

    applied: list[str] = []
    for r in readings:
        after = r["textLa"]
        for bad, good in PHRASES:
            if bad in after:
                after = after.replace(bad, good)
                applied.append(f"id {r['id']:3d}: {bad!r} → {good!r}")
        after = after.replace("desideria carnis carnis", "desideria carnis")
        n = len(OMNIMO.findall(after))
        if n:
            after = OMNIMO.sub("omnino", after)
            applied.append(f"id {r['id']:3d}: omnimo → omnino ({n}×)")
        stripped = FOOTER.sub("", after)
        if stripped != after:
            applied.append(f"id {r['id']:3d}: stripped Latin Library footer")
            after = stripped
        r["textLa"] = after

    flags: list[str] = []
    rows: list[str] = []
    for r in readings:
        en = len(words(r["textEn"]))
        la = len(words(r["textLa"]))
        ratio = la / en if en else 0
        rows.append(f"  {r['id']:3d} ch.{r['chapter']:02d}  La {la:4d}  En {en:4d}  {ratio:.2f}")
        if en and (ratio < 0.45 or ratio > 1.05):
            flags.append(f"RATIO id {r['id']} {ratio:.2f}")
        if r["textLa"].rstrip().endswith("desideria"):
            flags.append(f"STUMP id {r['id']}")
        for bad in BANNED:
            if bad == "futum":
                if re.search(r"\bfutum\b", r["textLa"]):
                    flags.append(f"BANNED id {r['id']}: {bad!r}")
            elif bad in r["textLa"]:
                flags.append(f"BANNED id {r['id']}: {bad!r}")
        if OMNIMO.search(r["textLa"]):
            flags.append(f"OMNIMO id {r['id']}")

    log = [
        f"repairs: {len(applied)}",
        *[f"  {line}" for line in applied],
        "",
        f"flags: {len(flags)}",
        *[f"  {f}" for f in flags],
        "",
        "all 122 La:En",
        *rows,
        "",
    ]
    REPORT.write_text("\n".join(log), encoding="utf-8")
    print("\n".join(log[: 2 + len(applied) + 3 + len(flags)]))

    if flags:
        print("FATAL flags remain", file=sys.stderr)
        return 1

    payload = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    LIVE.write_text(payload, encoding="utf-8")
    LEGACY.write_text(payload, encoding="utf-8")
    print(f"wrote {LIVE}")
    print(f"wrote {LEGACY}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
