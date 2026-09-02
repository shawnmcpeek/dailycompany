#!/usr/bin/env python3
"""
repair_latin_alignment.py

One-shot repair for the textLa/textEn drift in the Benedict readings file.
Live path: assets/content/benedict/rule_readings.json
(the leftover assets/content/rule_readings.json is the same bytes; tests still load it).

Two drift sites were confirmed by bilingual anchor testing:
  - Chapter 2, records 9-15  (Heli/Silo anchor landed one record late)
  - Chapter 7, records 25-27 (Iacob anchor landed one record late)

At both sites the Latin is complete but mis-segmented: chapter-level word
totals balance against the corpus median La:En ratio of 0.661, so nothing
is missing. The fix concatenates the Latin across each affected run and
re-splits it at the boundaries that match the English portions.

Splits are declared as explicit sentence-index assignments, with two
mid-sentence cuts keyed on literal substrings. Nothing is inferred at
runtime, so the output is reproducible and reviewable.

Usage:
    python3 repair_latin_alignment.py --in rule_readings_rev.json \
                                      --out rule_readings_rev.fixed.json \
                                      --report repair_report.txt
"""

import argparse
import json
import re
import sys

MEDIAN_RATIO = 0.661  # corpus-wide La:En word ratio for the Verheyen/Latin pair

# --- OCR corrections in the Latin source (verified against the standard text) ---
OCR_FIXES = [
    ("pastotis", "pastoris"),
    ("delinquentiump", "delinquentium"),
]

# --- Mid-sentence cut points, keyed on literal substrings ---
# Each entry splits one sentence into two parts at the given marker.
MID_CUTS = {
    "ch2_s2": ", memor semper abbas quia",
    "ch7_s9": ", æstimet se homo de cælis",
}

# --- Re-split plans -----------------------------------------------------------
# Each plan maps a record id to the sentence indices (of the concatenated,
# mid-cut-expanded sentence list) that belong to it.
PLANS = [
    {
        "label": "CH2",
        "ids": [9, 10, 11, 12, 13, 14, 15],
        "mid_cut": ("ch2_s2", 2),  # split sentence index 2 before re-indexing
        "assign": {
            9:  [0, 1, 2],           # 2 == first half of original s2
            10: [3, 4, 5],           # 3 == second half of original s2
            11: [6, 7, 8],
            12: [9, 10, 11, 12, 13, 14],
            13: [15, 16, 17],
            14: [18, 19],
            15: [20, 21, 22, 23, 24],
        },
    },
    {
        "label": "CH7",
        "ids": [25, 26, 27],
        "mid_cut": ("ch7_s9", 9),
        "assign": {
            25: [0, 1, 2, 3, 4, 5, 6, 7],
            26: [8, 9],              # 9 == first half of original s9
            27: [10, 11, 12],        # 10 == second half of original s9
        },
    },
]


def sentences(text):
    text = re.sub(r"\s+", " ", text).strip()
    return [s.strip() for s in re.split(r"(?<=[.?!])\s+", text) if s.strip()]


def apply_mid_cut(sents, marker, index):
    """Split sents[index] into two at `marker`, which begins the second part."""
    target = sents[index]
    pos = target.find(marker)
    if pos == -1:
        raise SystemExit(
            f"FATAL: mid-cut marker not found in sentence {index}: {marker!r}\n"
            f"  sentence was: {target[:160]}..."
        )
    head = target[:pos].strip()
    tail = target[pos:].lstrip(", ").strip()
    if not head or not tail:
        raise SystemExit(f"FATAL: mid-cut at {index} produced an empty part")
    return sents[:index] + [head, tail] + sents[index + 1:]


def words(s):
    return len(s.split())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="src", required=True)
    ap.add_argument("--out", dest="dst", required=True)
    ap.add_argument("--report", dest="report", default=None)
    args = ap.parse_args()

    data = json.load(open(args.src, encoding="utf-8"))
    readings = data["readings"]
    by_id = {r["id"]: r for r in readings}
    log = []

    # 1. OCR corrections across the whole corpus
    ocr_count = 0
    for r in readings:
        for bad, good in OCR_FIXES:
            if bad in r["textLa"]:
                r["textLa"] = r["textLa"].replace(bad, good)
                ocr_count += 1
                log.append(f"OCR   id {r['id']:3d}: {bad!r} -> {good!r}")

    # 2. Re-split each drift site
    for plan in PLANS:
        ids = plan["ids"]
        joined = " ".join(by_id[i]["textLa"].strip() for i in ids)
        sents = sentences(joined)
        marker_key, marker_index = plan["mid_cut"]
        sents = apply_mid_cut(sents, MID_CUTS[marker_key], marker_index)

        assign = plan["assign"]
        used = sorted(i for v in assign.values() for i in v)
        if used != list(range(len(sents))):
            raise SystemExit(
                f"FATAL: {plan['label']} assignment does not cover sentences "
                f"exactly once. have {len(sents)} sentences, assigned {used}"
            )

        for rid in ids:
            before = by_id[rid]["textLa"]
            after = " ".join(sents[i] for i in assign[rid])
            by_id[rid]["textLa"] = after
            en, la = words(by_id[rid]["textEn"]), words(after)
            dev = (la / en) / MEDIAN_RATIO if en else 0
            log.append(
                f"SPLIT id {rid:3d} [{plan['label']}]: La {words(before):4d} -> "
                f"{la:4d} words, En {en:4d}, ratio {la/en:.2f}, dev {dev:.2f}"
            )

    # 3. Post-repair validation
    failures = []
    for r in readings:
        en, la = words(r["textEn"]), words(r["textLa"])
        if not en:
            failures.append(f"id {r['id']}: empty textEn")
            continue
        dev = (la / en) / MEDIAN_RATIO
        if dev < 0.6 or dev > 1.6:
            failures.append(f"id {r['id']}: La:En dev {dev:.2f} outside [0.60, 1.60]")

    # calendar coverage must be untouched
    common = [k for r in readings for k in r["dateKeysCommon"]]
    leap = [k for r in readings for k in r["dateKeysLeap"]]
    if len(common) != 365 or len(set(common)) != 365:
        failures.append(f"common-year coverage broken: {len(common)} keys, {len(set(common))} distinct")
    if len(leap) != 366 or len(set(leap)) != 366:
        failures.append(f"leap-year coverage broken: {len(leap)} keys, {len(set(leap))} distinct")

    log.append("")
    log.append(f"OCR corrections applied: {ocr_count}")
    log.append(f"records re-split:        {sum(len(p['ids']) for p in PLANS)}")
    log.append(f"validation failures:     {len(failures)}")
    for f in failures:
        log.append(f"  FAIL {f}")

    report = "\n".join(log)
    if args.report:
        open(args.report, "w", encoding="utf-8").write(report + "\n")
    print(report)

    if failures:
        sys.exit(1)

    json.dump(data, open(args.dst, "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    print(f"\nwrote {args.dst}")


if __name__ == "__main__":
    main()
