#!/usr/bin/env python3
"""Emit Serra PlaceSaint JSON: journey, missions, prayers, portal."""

from __future__ import annotations

import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent.parent
sys.path.insert(0, str(ROOT.parent))
sys.path.insert(0, str(ROOT))

from ocr_clean import clean_ocr_english  # noqa: E402
from missions import MISSIONS  # noqa: E402
from parse_journey import palou_expedition, portola_days  # noqa: E402

ASSETS = REPO / "assets" / "content" / "serra"
REVIEW = ROOT / "review"

START = (3, 28)
END = (7, 1)

PRAYER = "alabado"

TAGLINE = "I have put all my trust in God."
DISCLAIMER = (
    "An independent app from Daddoo Dev. Not affiliated with, endorsed "
    "by, or produced by the Order of Friars Minor, the Franciscan Friars "
    "of California, Serra International, any California mission parish, "
    "or any shrine or publisher associated with them."
)


def words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def daterange() -> list[str]:
    keys = []
    d = date(2024, START[0], START[1])  # non-leap window; 2024 is leap but window has no Feb 29
    end = date(2024, END[0], END[1])
    while d <= end:
        keys.append(f"{d.month:02d}-{d.day:02d}")
        d += timedelta(days=1)
    return keys


def tidy(text: str) -> str:
    text = clean_ocr_english(text)
    text = text.replace("Vellicatd", "Velicatá")
    text = text.replace("Vellicatá", "Velicatá")
    text = re.sub(r"Velicatá", "Velicatá", text)
    text = text.replace("Junipero", "Junípero")
    text = text.replace("Cerra", "Serra")
    text = re.sub(r"\[\s*,\s*\]", "", text)
    text = re.sub(r"l~ T ~'", "", text)
    text = re.sub(r"\bsight of the July port\b", "sight of the port", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def palou_paras() -> list[str]:
    text = palou_expedition()
    return [tidy(p) for p in text.split("\n\n")]


def find_para(ps: list[str], needle: str) -> str:
    n = needle.lower()
    for p in ps:
        if n in p.lower():
            return p
    raise SystemExit(f"Palóu paragraph not found: {needle}")


def join_needles(ps: list[str], needles: list[str]) -> str:
    seen: list[str] = []
    for n in needles:
        p = find_para(ps, n)
        if p not in seen:
            seen.append(p)
    return "\n\n".join(seen)


def unique_days() -> list[dict]:
    ps = palou_paras()
    out: list[dict] = []

    def add(date_key: str, location: str, text: str, source: str) -> None:
        text = tidy(text)
        if words(text) < 40:
            return
        out.append(
            {
                "dateKey": date_key,
                "location": location,
                "textEn": text,
                "prayerKey": PRAYER,
                "source": source,
            }
        )

    add(
        "03-28",
        "Loreto",
        join_needles(ps, ["On the 28th of March"]),
        "palou",
    )
    add(
        "03-29",
        "San Francisco Xavier (Palóu’s mission)",
        join_needles(
            ps,
            [
                "He remained with me in the Mission for three days",
                "Let us not talk about it",
            ],
        ),
        "palou",
    )
    add(
        "04-01",
        "On the road north of Loreto",
        join_needles(ps, ["from Mission to Mission visiting the Fathers"]),
        "palou",
    )
    add(
        "05-01",
        "Our Lady of the Angels, the frontier",
        join_needles(ps, ["camp of Our Lady of the Angels on the frontier"]),
        "palou",
    )

    overlays = {
        "05-14": (
            "Velicatá",
            join_needles(
                ps,
                [
                    "next day (May 14th), which was Pentecost",
                    "vested in alb and cope, blessed the water",
                ],
            ),
        ),
        "05-15": (
            "Velicatá",
            join_needles(
                ps,
                [
                    "The 15th of May, second of the Feast",
                    "completely naked as was",
                    "fifth part of the cattle",
                ],
            ),
        ),
        "05-16": (
            "San Juan de Dios",
            join_needles(
                ps,
                [
                    "not felt any inconvenience from his foot",
                    "you cannot accompany the expedition",
                    "I am one of your beasts of burden",
                    "crushed it between two stones",
                ],
            ),
        ),
        "07-01": (
            "San Diego",
            join_needles(
                ps,
                [
                    "came in view of the harbor",
                    "Thanks to God, I arrived here at this port of San Diego",
                ],
            ),
        ),
    }
    trail = join_needles(
        ps,
        [
            "following the trail of the first section",
            "taking to the northwest",
        ],
    )

    by_portola = {d["dateKey"]: d for d in portola_days()}
    for key, loc_text in overlays.items():
        loc, text = loc_text
        extra = ""
        if key in by_portola:
            extra = "\n\n" + tidy(by_portola[key]["textEn"])
        add(key, loc, text + extra, "palou+portola")

    for d in portola_days():
        if d["dateKey"] in overlays:
            continue
        loc = d["location"]
        loc = re.split(r",", loc, maxsplit=1)[0].strip()
        if loc.lower().startswith("the place called "):
            loc = loc[17:]
        if loc.lower().startswith("with father"):
            loc = "Velicatá"
        if "undecided" in loc.lower() or loc.lower().startswith("them "):
            loc = "San Diego"
        text = tidy(d["textEn"])
        # Hold Palóu's trail paragraph on thin march days so the reading is Serra's
        # company, not only the engineer's hours of travel.
        if words(text) < 150 and d["dateKey"] >= "05-21" and d["dateKey"] < "07-01":
            if trail:
                text = text + "\n\n" + trail
        add(d["dateKey"], loc, text, "portola")

    out.sort(key=lambda x: x["dateKey"])
    return out


def fill_calendar(unique: list[dict]) -> list[dict]:
    by = {d["dateKey"]: d for d in unique}
    last = None
    days = []
    for i, key in enumerate(daterange(), start=1):
        if key in by:
            last = by[key]
        if last is None:
            raise SystemExit(f"no journey text for {key}")
        days.append(
            {
                "dayIndex": i,
                "dateKey": key,
                "location": last["location"],
                "textEn": last["textEn"],
                "prayerKey": PRAYER,
            }
        )
    return days


def prayers() -> dict:
    alabado_es = (
        "Alabado sea el Santísimo Sacramento del Altar, "
        "y Bendita sea la Inmaculada Concepción de la Beatísima Virgen María."
    )
    alabado_en = (
        "Praised be the Most Holy Sacrament of the Altar, "
        "and blessed be the Immaculate Conception of the most Blessed Virgin Mary."
    )
    angelus = (
        "The Angel of the Lord declared unto Mary.\n"
        "And she conceived of the Holy Spirit.\n"
        "Hail Mary.\n\n"
        "Behold the handmaid of the Lord.\n"
        "Be it done unto me according to thy word.\n"
        "Hail Mary.\n\n"
        "And the Word was made flesh.\n"
        "And dwelt among us.\n"
        "Hail Mary.\n\n"
        "Pray for us, O holy Mother of God.\n"
        "That we may be made worthy of the promises of Christ.\n\n"
        "Pour forth, we beseech Thee, O Lord, Thy grace into our hearts, "
        "that we, to whom the Incarnation of Christ Thy Son was made known "
        "by the message of an angel, may by His Passion and Cross be brought "
        "to the glory of His Resurrection. Through the same Christ our Lord. Amen."
    )
    joys = [
        {
            "order": 1,
            "title": "The Annunciation",
            "prompt": "The Angel of the Lord declared unto Mary.",
        },
        {
            "order": 2,
            "title": "The Visitation",
            "prompt": "Mary arose and went with haste into the hill country.",
        },
        {
            "order": 3,
            "title": "The Nativity",
            "prompt": "She brought forth her firstborn Son.",
        },
        {
            "order": 4,
            "title": "The Adoration of the Magi",
            "prompt": "They found the Child with Mary His Mother.",
        },
        {
            "order": 5,
            "title": "The Finding in the Temple",
            "prompt": "They found Him in the temple, sitting in the midst of the teachers.",
        },
        {
            "order": 6,
            "title": "The Resurrection",
            "prompt": "The Lord is risen, as He said.",
        },
        {
            "order": 7,
            "title": "The Assumption",
            "prompt": "The Queen stands at Thy right hand, in gold of Ophir.",
        },
    ]
    return {
        "version": 1,
        "prayers": [
            {
                "key": "alabado",
                "title": "The Alabado",
                "note": (
                    "Sung at the missions at dawn and at the end of work. "
                    "Spanish as printed by Engelhardt; English is the sense of that acclamation."
                ),
                "textEs": alabado_es,
                "textEn": alabado_en,
            },
            {
                "key": "angelus",
                "title": "The Angelus",
                "note": "The bell moment. Traditional English.",
                "textEn": angelus,
            },
            {
                "key": "crown",
                "title": "The Franciscan Crown",
                "note": (
                    "Seven decades, the Seven Joys. Opt-in, not a daily default. "
                    "Two Hail Marys follow the seventh decade for the seventy-two years "
                    "of Mary’s life — that closing is named, not timed here."
                ),
                "joys": joys,
            },
        ],
    }


def quiet_copy(ps: list[str]) -> dict:
    text = join_needles(
        ps,
        [
            "came in view of the harbor",
            "Thanks to God, I arrived here at this port of San Diego",
        ],
    )
    return {
        "title": "The party has reached San Diego",
        "location": "San Diego",
        "textEn": text
        + "\n\nThe overland journey sits quiet until the twenty-eighth of March. "
        "The missions remain.",
    }


def portal() -> dict:
    return {
        "id": "serra",
        "displayName": "Junípero Serra",
        "tagline": TAGLINE,
        "provenance": "traditional",
        "spine": {
            "type": "journey",
            "note": (
                "Not a page-a-day of Serra’s letters. The journey follows the "
                "historical dates of the 1769 overland expedition from Loreto to "
                "San Diego. Palóu, Relación Histórica, trans. C. Scott Williams "
                "(1913); Portolá’s diary, Smith and Teggart, Academy of Pacific "
                "Coast History vol. 1 (1909). The twenty-one missions are a gallery."
            ),
        },
        "anchor": None,
        "modules": ["journey", "missions", "practice"],
        "disclaimer": DISCLAIMER,
        "unlockSku": "serra_companion",
        "sourceNote": (
            "Journey: Palóu/Williams 1913 and Portolá/Smith–Teggart 1909. "
            "Missions: Engelhardt (d. 1934), Palóu/Williams, Catholic Encyclopedia 1913. "
            "Engelhardt is a Franciscan partisan. Alabado: Engelhardt’s Spanish. "
            "Not used: Tibesar, Writings of Junípero Serra; Geiger 1955; Hackel; "
            "contemporary mission photographs."
        ),
    }


def main() -> None:
    unique = unique_days()
    days = fill_calendar(unique)
    ps = palou_paras()
    journey = {
        "version": 1,
        "saintId": "serra",
        "startDateKey": "03-28",
        "endDateKey": "07-01",
        "quiet": quiet_copy(ps),
        "days": days,
        "uniqueDays": len(unique),
        "sources": [
            "Palóu, Relación Histórica, trans. C. Scott Williams (1913)",
            "Diary of Gaspar de Portolá, Smith and Teggart (1909)",
        ],
    }
    missions = {
        "version": 1,
        "saintId": "serra",
        "label": "The California Missions",
        "stops": [
            {
                **m,
                "prayerKey": PRAYER,
                "textEn": m["textEn"].strip(),
            }
            for m in MISSIONS
        ],
    }

    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (ASSETS / "journey.json").write_text(
        json.dumps(journey, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (ASSETS / "missions.json").write_text(
        json.dumps(missions, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (ASSETS / "prayers.json").write_text(
        json.dumps(prayers(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (ASSETS / "portal.json").write_text(
        json.dumps(portal(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    rows = []
    for d in days:
        flag = ""
        if words(d["textEn"]) < 80:
            flag = "thin"
        rows.append(
            f"<tr><td>{d['dayIndex']}</td><td>{d['dateKey']}</td>"
            f"<td>{d['location']}</td><td>{words(d['textEn'])}</td>"
            f"<td>{flag}</td></tr>"
        )
    html = (
        "<!doctype html><meta charset=utf-8><title>Serra journey</title>"
        "<p>Unique dated readings: "
        + str(len(unique))
        + " · Calendar days: "
        + str(len(days))
        + "</p><table border=1 cellpadding=4><tr>"
        "<th>#</th><th>date</th><th>location</th><th>words</th><th></th></tr>"
        + "\n".join(rows)
        + "</table>"
    )
    (REVIEW / "review.html").write_text(html, encoding="utf-8")

    assert len(days) == 96, len(days)
    assert days[0]["dateKey"] == "03-28"
    assert days[-1]["dateKey"] == "07-01"
    assert len(missions["stops"]) == 21
    acts = [s["act"] for s in missions["stops"]]
    assert acts[:9] == [1] * 9
    assert acts[9:18] == [2] * 9
    assert acts[18:] == [3] * 3
    print(f"journey {len(days)} days, {len(unique)} unique, missions {len(missions['stops'])}")
    print(f"wrote {ASSETS}")


if __name__ == "__main__":
    main()
