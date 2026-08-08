#!/usr/bin/env python3
"""Build assets/quran_distractors.json from assets/verses.json using bigram twins.

Twin rule: if the same previous word is followed by different next words
across the mushaf (e.g. لقوم + يوقنون / يعقلون), those next words are
distractors for each other.
"""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSES_PATH = ROOT / "assets" / "verses.json"
OUT_PATH = ROOT / "assets" / "quran_distractors.json"

STRUCTURAL = {
    "۞",
    "۩",
    "ۜ",
    "ۘ",
    "ۙ",
    "ۚ",
    "ۛ",
    "ۖ",
    "ۗ",
}
PAUSE_MARKS = {"ۜ", "ۘ", "ۙ", "ۚ", "ۛ", "ۖ", "ۗ"}

REMOVE_CHARS = [
    "\u064B",
    "\u064C",
    "\u064D",
    "\u064E",
    "\u064F",
    "\u0650",
    "\u0651",
    "\u0652",
    "\u0653",
    "\u0654",
    "\u0655",
    "\u0656",
    "\u0657",
    "\u0658",
    "\u0670",
    "\u06D6",
    "\u06D7",
    "\u06D8",
    "\u06D9",
    "\u06DA",
    "\u06DB",
    "\u06DC",
    "\u06DF",
    "\u06E0",
    "\u06E1",
    "\u06E2",
    "\u06E3",
    "\u06E4",
    "\u06E5",
    "\u06E6",
    "\u06E7",
    "\u06E8",
    "\u06EA",
    "\u06EB",
    "\u06EC",
    "\u06ED",
    "\u0640",
    "\u06DE",
    "\u06E9",
]

LETTER_RE = re.compile(
    r"[\u0621-\u063A\u0641-\u064A\u066E\u066F\u0671-\u06D3\u06FA-\u06FF]"
)

MAX_DISTRACTORS = 12
MAX_AFTER_NEXTS = 20


def normalize(text: str) -> str:
    s = text.strip()
    for c in REMOVE_CHARS:
        s = s.replace(c, "")
    return (
        s.replace("آ", "ا")
        .replace("أ", "ا")
        .replace("إ", "ا")
        .replace("ٱ", "ا")
    )


def is_non_spoken(token: str) -> bool:
    t = token.strip()
    if not t or t in STRUCTURAL:
        return True
    without = re.sub(r"[\s\u0640]", "", t)
    if not without:
        return True
    if all(ch in PAUSE_MARKS or ch in STRUCTURAL for ch in without):
        return True
    return LETTER_RE.search(t) is None


def split_verse(text: str) -> list[str]:
    """Mirror app splitter: attach standalone pause marks to previous word."""
    raw = text.split(" ")
    processed: list[str] = []
    for w in raw:
        if not w:
            continue
        if any(m in w for m in PAUSE_MARKS) and processed and is_non_spoken(w):
            processed[-1] = f"{w} {processed[-1]}"
        else:
            processed.append(w)
    return [w for w in processed if not is_non_spoken(w)]


def main() -> None:
    data = json.loads(VERSES_PATH.read_text(encoding="utf-8"))
    verses = data["__collections__"]["verses"]

    # after[prev_norm][next_norm] = Counter of display forms
    after: dict[str, dict[str, Counter[str]]] = defaultdict(
        lambda: defaultdict(Counter)
    )
    # display preference for any norm
    display_forms: dict[str, Counter[str]] = defaultdict(Counter)
    # twin_score[word_norm][distractor_norm] = shared-prev occurrences
    twin_score: dict[str, Counter[str]] = defaultdict(Counter)

    verse_count = 0
    bigram_count = 0

    for verse in verses.values():
        text = verse.get("text") or ""
        words = split_verse(text)
        if len(words) < 2:
            continue
        verse_count += 1
        for w in words:
            display_forms[normalize(w)][w] += 1
        for i in range(len(words) - 1):
            prev, nxt = words[i], words[i + 1]
            pn, nn = normalize(prev), normalize(nxt)
            if not pn or not nn or pn == nn:
                continue
            after[pn][nn][nxt] += 1
            bigram_count += 1

    # Build twin scores from prev contexts with 2+ distinct nexts
    for prev_norm, nexts in after.items():
        next_norms = list(nexts.keys())
        if len(next_norms) < 2:
            continue
        # weight by how often each next appears after this prev
        for a in next_norms:
            for b in next_norms:
                if a == b:
                    continue
                weight = min(sum(nexts[a].values()), sum(nexts[b].values()))
                twin_score[a][b] += weight

    def best_display(norm: str) -> str:
        forms = display_forms.get(norm)
        if not forms:
            return norm
        return forms.most_common(1)[0][0]

    words_out: dict[str, dict] = {}
    for word_norm, scores in twin_score.items():
        if not scores:
            continue
        ranked = scores.most_common(MAX_DISTRACTORS)
        distractors = [
            best_display(d_norm)
            for d_norm, _ in ranked
            if d_norm and d_norm != word_norm
        ]
        if not distractors:
            continue
        words_out[word_norm] = {
            "display": best_display(word_norm),
            "distractors": distractors,
        }

    # Context lookup: prev → list of possible next displays (for runtime)
    after_out: dict[str, list[str]] = {}
    for prev_norm, nexts in after.items():
        ranked_nexts = sorted(
            nexts.items(),
            key=lambda kv: sum(kv[1].values()),
            reverse=True,
        )[:MAX_AFTER_NEXTS]
        if len(ranked_nexts) < 2:
            continue  # no twins in this context
        after_out[prev_norm] = [
            nexts[nn].most_common(1)[0][0] for nn, _ in ranked_nexts
        ]

    out = {
        "version": 1,
        "method": "bigram_twins",
        "source": "assets/verses.json",
        "stats": {
            "versesProcessed": verse_count,
            "bigrams": bigram_count,
            "wordsWithTwins": len(words_out),
            "prevContextsWithTwins": len(after_out),
        },
        "words": words_out,
        "after": after_out,
    }

    OUT_PATH.write_text(
        json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT_PATH}")
    print(json.dumps(out["stats"], indent=2))
    lq = normalize("لِّقَوْمٍ")
    if lq in after_out:
        print("Sample after لقوم:", after_out[lq][:8])


if __name__ == "__main__":
    main()
