#!/usr/bin/env python3
"""Conservative OCR tidy for nineteenth-century English scans."""

from __future__ import annotations

import re

_WORD_FIXES = (
    (re.compile(r"\btliey\b", re.I), "they"),
    (re.compile(r"\btlie\b", re.I), "the"),
    (re.compile(r"\btbe\b", re.I), "the"),
    (re.compile(r"\bwbicb\b", re.I), "which"),
    (re.compile(r"\bwitb\b", re.I), "with"),
    (re.compile(r"\bheauty\b", re.I), "beauty"),
    (re.compile(r"\bfeehngs\b", re.I), "feelings"),
    (re.compile(r"\bfeehng\b", re.I), "feeling"),
    (re.compile(r"\bGk\)d\b"), "God"),
    (re.compile(r"\bQt\)d\b"), "God"),
)


def clean_ocr_english(text: str) -> str:
    for pat, repl in _WORD_FIXES:
        text = pat.sub(repl, text)
    # Collapse OCR space-before-punctuation. Leave ellipses (" . . .") alone.
    text = re.sub(r" +([,;:!])", r"\1", text)
    text = re.sub(r"(?<![.])\s+\.(?!\s*\.)", ".", text)
    text = re.sub(r"\s+,", ",", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text.strip()
