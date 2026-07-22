#!/usr/bin/env python3
"""Rebuild Jadwal Quran JSON assets from QUL databases only."""

from __future__ import annotations

import json
import sqlite3
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "assets" / "databases"
OUT = ROOT / "assets" / "generated"

# Standard 30 Juz start verse keys (Madani mushaf convention)
JUZ_STARTS = [
    "1:1",
    "2:142",
    "2:253",
    "3:93",
    "4:24",
    "4:148",
    "5:82",
    "6:111",
    "7:88",
    "8:41",
    "9:93",
    "11:6",
    "12:53",
    "15:1",
    "17:1",
    "18:75",
    "21:1",
    "23:1",
    "25:21",
    "27:56",
    "29:46",
    "33:31",
    "36:28",
    "39:32",
    "41:47",
    "46:1",
    "51:31",
    "58:1",
    "67:1",
    "78:1",
]

ARABIC_INDIC = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")

# Standalone pause / tajweed marks in uthmani text (not separate mushaf script words)
PAUSE_MARKS = frozenset("ۖۗۚۛۜۙۘ")


def verse_sort_key(key: str) -> tuple[int, int]:
    s, a = key.split(":")
    return int(s), int(a)


def uthmani_slots_for_script(text: str) -> list[str]:
    """Map uthmani tokens onto mushaf script content words.

    Pause marks are merged onto the previous word; a leading rubʿ el-ḥizb (۞)
    is merged onto the following word. Result length is script_word_count or
    script_word_count - 1 (when the final script glyph is the ayah marker).
    """
    tokens = text.split()
    slots: list[str] = []
    pending_rub = False
    for tok in tokens:
        if tok in PAUSE_MARKS and slots:
            slots[-1] = f"{slots[-1]} {tok}"
        elif tok == "۞":
            pending_rub = True
        else:
            if pending_rub:
                slots.append(f"۞ {tok}")
                pending_rub = False
            else:
                slots.append(tok)
    if pending_rub:
        slots.append("۞")
    return slots


def build_verse_script_pieces(
    text: str, script_word_count: int, ayah_number: int
) -> list[str]:
    """One unicode piece per script word index (1-based list, index 0 unused)."""
    slots = uthmani_slots_for_script(text)
    ayah_mark = str(ayah_number).translate(ARABIC_INDIC)
    pieces = [""] * (script_word_count + 1)  # 1-based
    if script_word_count == len(slots) + 1:
        for i, slot in enumerate(slots, start=1):
            pieces[i] = slot
        pieces[script_word_count] = ayah_mark
    elif script_word_count == len(slots):
        for i, slot in enumerate(slots, start=1):
            pieces[i] = slot
        # No dedicated marker glyph — append ayah number on the last word
        if script_word_count >= 1:
            pieces[script_word_count] = f"{pieces[script_word_count]} {ayah_mark}"
    else:
        raise ValueError(
            f"Cannot align uthmani ({len(slots)} slots) to script "
            f"({script_word_count} words) for ayah {ayah_number}"
        )
    return pieces


def build_juz_map(all_keys: list[str]) -> dict[str, int]:
    starts = [verse_sort_key(k) for k in JUZ_STARTS]
    juz_for: dict[str, int] = {}
    juz = 1
    for key in sorted(all_keys, key=verse_sort_key):
        vk = verse_sort_key(key)
        while juz < 30 and vk >= starts[juz]:
            juz += 1
        juz_for[key] = juz
    return juz_for


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    print("Loading QUL databases...")
    with open(DB / "uthmani.json", encoding="utf-8") as f:
        uthmani: dict = json.load(f)
    with open(DB / "surahnames.json", encoding="utf-8") as f:
        surahnames: dict = json.load(f)
    with open(DB / "script.json", encoding="utf-8") as f:
        script: dict = json.load(f)

    # word_index -> location; script word counts per ayah
    idx_to_loc: dict[int, str] = {}
    script_word_count: dict[str, int] = {}
    for loc, meta in script.items():
        wi = int(meta["word_index"])
        location = meta.get("location", loc)
        idx_to_loc[wi] = location
        parts = location.split(":")
        if len(parts) == 3:
            vkey = f"{parts[0]}:{parts[1]}"
            wnum = int(parts[2])
            if wnum > script_word_count.get(vkey, 0):
                script_word_count[vkey] = wnum

    # One unicode piece per script word (includes ayah marker where present)
    verse_pieces: dict[str, list[str]] = {}
    for key, entry in uthmani.items():
        n_script = script_word_count.get(key)
        if not n_script:
            raise RuntimeError(f"No script words for {key}")
        ayah_num = int(key.split(":")[1])
        verse_pieces[key] = build_verse_script_pieces(
            entry["text"], n_script, ayah_num
        )

    conn = sqlite3.connect(DB / "layout.db")
    ayah_lines = conn.execute(
        """
        SELECT page_number, line_number, first_word_id, last_word_id
        FROM pages
        WHERE line_type = 'ayah'
          AND first_word_id != ''
          AND last_word_id != ''
        ORDER BY page_number, line_number
        """
    ).fetchall()
    conn.close()

    print(f"uthmani ayahs={len(uthmani)} script_words={len(script)} ayah_lines={len(ayah_lines)}")

    # Per-verse length and first page; also build page structures
    verse_length: dict[str, float] = defaultdict(float)
    verse_page: dict[str, int] = {}
    page_ayah_lines: dict[int, list[str]] = defaultdict(list)
    page_verse_keys: dict[int, list[str]] = defaultdict(list)
    page_verse_seen: dict[int, set[str]] = defaultdict(set)

    for page_number, _line_number, first_word_id, last_word_id in ayah_lines:
        a = int(first_word_id)
        b = int(last_word_id)
        lo, hi = min(a, b), max(a, b)
        word_ids = list(range(lo, hi + 1))
        if not word_ids:
            continue

        # Map each word_id -> (verse_key, word_in_ayah)
        line_words: list[tuple[str, int]] = []
        for wid in word_ids:
            loc = idx_to_loc.get(wid)
            if not loc:
                continue
            parts = loc.split(":")
            if len(parts) != 3:
                continue
            s, ay, w = parts
            vkey = f"{s}:{ay}"
            line_words.append((vkey, int(w)))
            if vkey not in verse_page:
                verse_page[vkey] = int(page_number)
            if vkey not in page_verse_seen[int(page_number)]:
                page_verse_seen[int(page_number)].add(vkey)
                page_verse_keys[int(page_number)].append(vkey)

        if not line_words:
            continue

        total_on_line = len(line_words)
        counts: dict[str, int] = defaultdict(int)
        for vkey, _w in line_words:
            counts[vkey] += 1
        for vkey, count in counts.items():
            verse_length[vkey] += count / total_on_line

        # Build unicode line text from script-aligned uthmani pieces
        pieces: list[str] = []
        for vkey, w in line_words:
            vp = verse_pieces.get(vkey)
            if vp and 1 <= w < len(vp) and vp[w]:
                pieces.append(vp[w])
        page_ayah_lines[int(page_number)].append(" ".join(pieces))

    all_keys = sorted(uthmani.keys(), key=verse_sort_key)
    juz_map = build_juz_map(all_keys)

    # --- verses.json ---
    verses_col: dict[str, dict] = {}
    for key in all_keys:
        entry = uthmani[key]
        doc_id = str(entry["id"])
        surah_num = int(entry["surah"])
        surah_meta = surahnames.get(str(surah_num), {})
        surah_name = surah_meta.get("name_simple", f"Surah{surah_num}")
        length = round(float(verse_length.get(key, 0.0)), 4)
        page = int(verse_page.get(key, 1))
        verses_col[doc_id] = {
            "key": key,
            "text": entry["text"],
            "length": length,
            "page": page,
            "juz": int(juz_map[key]),
            "surah": surah_name,
            "__collections__": {},
        }

    verses_out = {"__collections__": {"verses": verses_col}}

    # --- surahs.json ---
    surahs_col: dict[str, dict] = {}
    for sid in range(1, 115):
        meta = surahnames[str(sid)]
        keys = [k for k in all_keys if int(k.split(":")[0]) == sid]
        total_lines = round(sum(verse_length[k] for k in keys), 4)
        surahs_col[str(sid)] = {
            "surah": meta["name_simple"],
            "totalLines": total_lines,
            "tempCompletedLines": 0,
            "completedLines": 0,
            "verses": int(meta.get("verses_count", len(keys))),
            "surahNumber": sid,
            "__collections__": {},
        }
    surahs_out = {"__collections__": {"surahs": surahs_col}}

    # --- quran_pages_complete.json ---
    pages_obj: dict[str, dict] = {}
    for page in range(1, 605):
        vkeys = page_verse_keys.get(page, [])
        pages_obj[str(page)] = {
            "page_number": page,
            "verses": [
                {"verseKey": k, "text": uthmani[k]["text"]} for k in vkeys
            ],
            "all_lines": page_ayah_lines.get(page, []),
            "__collections__": {},
        }
    pages_out = {"pages": pages_obj}

    # --- data.json ---
    data_out = {
        "__collections__": {
            "verses": verses_col,
            "surahs": surahs_col,
            "pages": pages_obj,
        }
    }

    print("Writing outputs...")
    (OUT / "verses.json").write_text(
        json.dumps(verses_out, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT / "surahs.json").write_text(
        json.dumps(surahs_out, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT / "quran_pages_complete.json").write_text(
        json.dumps(pages_out, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT / "data.json").write_text(
        json.dumps(data_out, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # Validation
    sum_len = sum(verse_length.values())
    print("\n=== Validation ===")
    print(f"verses={len(verses_col)} (expect 6236)")
    print(f"surahs={len(surahs_col)} (expect 114)")
    print(f"pages={len(pages_obj)} (expect 604)")
    print(f"sum(length)={sum_len:.4f} (expect ~8820)")
    print(f"ayah_lines={len(ayah_lines)} (expect 8820)")
    print(f"1:1 text match uthmani: {verses_col['1']['text'] == uthmani['1:1']['text']}")
    print(f"1:1 sample: {verses_col['1']}")
    mismatches = 0
    for page in range(1, 605):
        if len(pages_obj[str(page)]["all_lines"]) != len(
            [1 for p, *_ in ayah_lines if p == page]
        ):
            # recount
            n_layout = sum(1 for p, *_ in ayah_lines if p == page)
            if len(pages_obj[str(page)]["all_lines"]) != n_layout:
                mismatches += 1
    print(f"pages with all_lines count != layout ayah lines: {mismatches}")

    # all_lines content checks
    import re

    all_text = "\n".join(
        line
        for page in range(1, 605)
        for line in pages_obj[str(page)]["all_lines"]
    )
    ayah_marks = len(re.findall(r"[٠-٩]+", all_text))
    print(f"ayah markers in all_lines: {ayah_marks} (expect 6236)")
    missing_words = 0
    for key, entry in uthmani.items():
        # every non-pause content token should appear somewhere in page lines
        # (rough check: joined page text for the verse's page)
        page = int(verse_page.get(key, 1))
        page_text = " ".join(pages_obj[str(page)]["all_lines"])
        for tok in uthmani_slots_for_script(entry["text"]):
            # strip merged pause for containment of core — use full slot
            if tok not in page_text:
                # verse may span 2 pages
                found = tok in page_text
                if not found and page < 604:
                    found = tok in " ".join(
                        pages_obj[str(page + 1)]["all_lines"]
                    )
                if not found and page > 1:
                    found = tok in " ".join(
                        pages_obj[str(page - 1)]["all_lines"]
                    )
                if not found:
                    missing_words += 1
                    if missing_words <= 5:
                        print(f"  missing slot on pages near {page}: {key} {tok!r}")
    print(f"uthmani slots missing from nearby page all_lines: {missing_words}")
    print(f"Wrote files to {OUT}")


if __name__ == "__main__":
    main()
