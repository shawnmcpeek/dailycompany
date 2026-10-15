#!/usr/bin/env python3
"""Shared emit helpers for constructed cycle houses."""

from __future__ import annotations

import json
import re
from pathlib import Path

from cycle_cal import map_modulo, map_unique
from cut import cadence_candidates, cut, write_review_html


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def fill_stub_titles(entries: list[dict]) -> None:
    stub = re.compile(r"^Chapter\s+\d+$", re.I)
    for e in entries:
        if not stub.match(e["chapterTitle"].strip()):
            continue
        sent = re.split(r"(?<=[.?!])\s", e["textEn"].strip(), maxsplit=1)[0]
        sent = sent.strip().rstrip(".")
        if 12 <= len(sent) <= 140:
            e["chapterTitle"] = sent
        elif sent:
            clip = sent[:72].rsplit(" ", 1)[0]
            if clip:
                e["chapterTitle"] = clip


def find_unique_target(parts: list[dict], lo: int = 50, hi: int = 500) -> tuple[int, int]:
    """Return (target_words, n_entries) preferring 366 then 365."""
    for want in (366, 365):
        for candidate in range(lo, hi):
            produced = cut(parts, target_words=candidate)
            if len(produced) == want:
                return candidate, want
    total = sum(words(" ".join(c["paragraphs"])) for p in parts for c in p["chapters"])
    return max(lo, round(total / 366)), 0


def assert_round_trip(entries: list[dict], parts: list[dict]) -> None:
    reconstructed = "\n\n".join(e["textEn"] for e in entries)
    source = "\n\n".join(
        p for part in parts for c in part["chapters"] for p in c["paragraphs"]
    )
    assert norm(reconstructed) == norm(source), "round-trip failed"


def write_cycle_assets(
    *,
    assets: Path,
    review: Path,
    entries: list[dict],
    by_date_common: dict,
    by_date_leap: dict,
    translator: str,
    portal: dict,
    target_words: int,
    daily_entries: int | None = None,
) -> None:
    assets.mkdir(parents=True, exist_ok=True)
    review.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "translator": translator,
        "cadence": portal["spine"],
        "wordsTotal": sum(e["wordCount"] for e in entries),
        "entries": entries,
    }
    if daily_entries is not None:
        payload["dailyEntries"] = daily_entries
    (assets / "entries.json").write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (assets / "calendar.json").write_text(
        json.dumps({
            "version": 1,
            "byDateCommon": by_date_common,
            "byDateLeap": by_date_leap,
        }, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (assets / "portal.json").write_text(
        json.dumps(portal, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_review_html(entries, review / "review.html", target_words)
    print(f"wrote {assets} ({len(entries)} entries)")


def emit_appendix_year(
    *,
    parts: list[dict],
    assets: Path,
    review: Path,
    translator: str,
    portal: dict,
    target_words: int = 280,
) -> list[dict]:
    """Cut the whole corpus; first 366 days are unique, the rest sit off-calendar."""
    print(f"\nappendix year: cut at ~{target_words} words/entry")
    entries = cut(parts, target_words=target_words)
    fill_stub_titles(entries)
    assert_round_trip(entries, parts)
    n = len(entries)
    if n < 366:
        raise SystemExit(f"appendix year expected ≥366 entries, got {n}")
    for e in entries[366:]:
        flags = list(e.get("flags") or [])
        if "appendix" not in flags:
            flags.append("appendix")
        e["flags"] = flags
    daily = 366
    by_date_common, by_date_leap = map_unique(daily)
    note = portal.get("spine", {}).get("note", "")
    extra = (
        f"{daily} readings through the year. "
        f"{n - daily} further readings sit in the index, not on the calendar."
    )
    portal["spine"] = {
        **portal.get("spine", {}),
        "type": "cycle",
        "entries": daily,
        "repeatsPerYear": 1.0,
        "note": (note + " " + extra).strip() if note else extra,
    }
    write_cycle_assets(
        assets=assets,
        review=review,
        entries=entries,
        by_date_common=by_date_common,
        by_date_leap=by_date_leap,
        translator=translator,
        portal=portal,
        target_words=target_words,
        daily_entries=daily,
    )
    print(f"{n} entries ({daily} daily + {n - daily} appendix)")
    return entries


def emit_cut_cycle(
    *,
    parts: list[dict],
    assets: Path,
    review: Path,
    translator: str,
    portal: dict,
    prefer_unique: bool = True,
    modulo_if_thin: bool = True,
    overflow_appendix: bool = False,
) -> list[dict]:
    total_words = sum(
        words(" ".join(c["paragraphs"])) for p in parts for c in p["chapters"]
    )
    print("=== cadence candidates ===")
    cadence_candidates(total_words)

    # A corpus too large for 366×1 at the 150–500 band keeps every paragraph
    # by parking overflow off the calendar (Augustine / John of the Cross).
    if overflow_appendix and total_words / 366 > 500:
        target = max(250, min(400, round(total_words / max(1, round(total_words / 280)))))
        return emit_appendix_year(
            parts=parts,
            assets=assets,
            review=review,
            translator=translator,
            portal=portal,
            target_words=target,
        )

    entries: list[dict]
    target: int
    if prefer_unique and total_words / 366 >= 150:
        target, n = find_unique_target(parts)
        print(f"\ntarget {target} words/entry")
        entries = cut(parts, target_words=target)
        fill_stub_titles(entries)
        assert_round_trip(entries, parts)
        n = len(entries)
        print(f"cutter produced {n} entries")
        if n in (365, 366):
            by_date_common, by_date_leap = map_unique(n)
            portal["spine"] = {
                **portal.get("spine", {}),
                "type": "cycle",
                "entries": n,
                "repeatsPerYear": 1.0,
            }
            write_cycle_assets(
                assets=assets,
                review=review,
                entries=entries,
                by_date_common=by_date_common,
                by_date_leap=by_date_leap,
                translator=translator,
                portal=portal,
                target_words=target,
            )
            return entries
        if overflow_appendix and n > 366:
            print(f"unique year missed ({n}); keeping overflow as appendix")
            return emit_appendix_year(
                parts=parts,
                assets=assets,
                review=review,
                translator=translator,
                portal=portal,
                target_words=target,
            )
        print(f"unique year missed ({n}); falling back to modulo")

    # Thin corpus, or unique-year search missed: pack toward the 150–400 band, then modulo.
    if not modulo_if_thin:
        raise SystemExit(f"corpus too thin for unique year ({total_words} words)")
    target = max(150, min(400, round(total_words / max(1, round(total_words / 280)))))
    # Prefer a target that yields 60–183 entries (repeat rather than pad).
    best: list[dict] | None = None
    best_target = target
    for candidate in range(150, 401):
        produced = cut(parts, target_words=candidate)
        n = len(produced)
        if 60 <= n <= 200:
            best = produced
            best_target = candidate
            if 80 <= n <= 120:
                break
    if best is None:
        best = cut(parts, target_words=target)
        best_target = target
    entries = best
    fill_stub_titles(entries)
    assert_round_trip(entries, parts)
    n = len(entries)
    print(f"thin corpus: {n} entries at ~{best_target} words, modulo through the year")
    by_date_common, by_date_leap = map_modulo(n)
    portal["spine"] = {
        **portal.get("spine", {}),
        "type": "cycle",
        "entries": n,
        "repeatsPerYear": round(366 / n, 2),
    }
    write_cycle_assets(
        assets=assets,
        review=review,
        entries=entries,
        by_date_common=by_date_common,
        by_date_leap=by_date_leap,
        translator=translator,
        portal=portal,
        target_words=best_target,
    )
    return entries
