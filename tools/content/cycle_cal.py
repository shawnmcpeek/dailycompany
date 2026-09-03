#!/usr/bin/env python3
"""Shared date maps for constructed cycles."""

from __future__ import annotations

import calendar
import datetime


def mmdd(month: int, day: int) -> str:
    return f"{month:02d}-{day:02d}"


def mmdd_ordinal(year: int, ordinal: int) -> str:
    date = datetime.date(year, 1, 1) + datetime.timedelta(days=ordinal - 1)
    return f"{date.month:02d}-{date.day:02d}"


def map_modulo(n: int) -> tuple[dict[str, list[int]], dict[str, list[int]]]:
    """Leap year 1:1 onto 366 days via modulo; common years skip Feb 29."""

    def map_year(leap: bool) -> dict[str, list[int]]:
        year = 2024 if leap else 2025
        out: dict[str, list[int]] = {}
        ordinal = 0
        for month in range(1, 13):
            dim = calendar.monthrange(year, month)[1]
            for day in range(1, dim + 1):
                ordinal += 1
                out[mmdd(month, day)] = [((ordinal - 1) % n) + 1]
        return out

    return map_year(False), map_year(True)


def map_unique(n: int) -> tuple[dict[str, list[int]], dict[str, list[int]]]:
    """365 unique days (leap shares Feb 28) or 366 (common merges Dec 31)."""
    if n == 366:
        by_date_leap = {mmdd_ordinal(2024, i + 1): [i + 1] for i in range(n)}
        by_date_common = {mmdd_ordinal(2025, i + 1): [i + 1] for i in range(n - 2)}
        by_date_common["12-31"] = [n - 1, n]
        return by_date_common, by_date_leap
    if n == 365:
        by_date_common = {mmdd_ordinal(2025, i + 1): [i + 1] for i in range(n)}
        by_date_leap = dict(by_date_common)
        by_date_leap["02-29"] = by_date_common["02-28"]
        return by_date_common, by_date_leap
    raise SystemExit(f"unique calendar only handles 365 or 366, got {n}")
