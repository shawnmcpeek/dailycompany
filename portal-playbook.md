# Portal playbook

Engineering recipe for opening a house. Product law lives in `portals-spec.md` and `benedict-daily-spec.md`. Texts and rights live in `portal-texts.md`. This file is the checklist extracted from how de Sales was actually built — not the idealized spec.

Benedict is the traditional exception. Every later house copies the **de Sales shape**, not the Rule.

Copy the house sheet from `portal-texts.md` into this decision record. Do not invent an edition.

---

## 0. Before any code

Fill this decision record. Do not start a pipeline until the PD source and translator dates are named. Rights in `portal-texts.md` must read CLEAR (or CONDITIONAL with the cost accepted).

| Field | Notes |
| --- | --- |
| `id` | Folder name, route param, registry key. Lowercase, no spaces. Matches `Companions` id if the house is already listed. |
| Display name | Hallway + About. Never prefix *St.* / *Saint* unless they are canonized. Writers: `HouseKind.writer`. |
| Tagline | One line, from the saint if possible. |
| Provenance | `traditional` / `constructed` / `partlyTraditional`. Drives the ⓘ sheet. |
| Cadence | `entries × repeats`. Run the cutter's `cadence_candidates` on a **real** word count before locking this. Spec §2 and `portal-texts.md` are starting guesses; de Sales' 120k estimate was 78k. |
| Primary text | Work, translator, year, death date, edition URL — from `portal-texts.md`, then confirmed against the copy in hand. |
| Do not use | In-copyright editions, trademarked apparatus, the tempting bestseller. |
| Identity never-list | Order names, crests, shrine brands. Spec §7. Non-saints: never "St." |
| Disclaimer | Verbatim, store + About. Template in spec §7. |
| Anchor | The free practice that is this house's Compline. Different interaction from every other house. |
| Haptics | The rhythm *is* the characterization. Do not reuse Benedict's six bells or de Sales' jittered aspirations unless that is actually this saint's day. |
| Modules + tiers | Free vs unlock. One SKU, `$4.99` one-time, `id_companion`. |
| Accent driver | Part / book / mansion / fixed. New hues, distinct from `CycleAccent` and `DesalesAccent`. |

Hallway `open` is automatic once `PortalRegistry.byId(id)` is non-null. Add the `Companion` row first if the house is not already in `lib/data/companion.dart`.

### Filled — `liguori`

| | |
| --- | --- |
| `id` | `liguori` |
| Display | Alphonsus Liguori |
| Tagline | *My Jesus, I will love Thee only.* |
| Provenance | `partlyTraditional` |
| Cadence | **31 × 12**, day-of-month. Real count 18,872 words (~608/visit). No cutter. |
| Primary text | Grimm, Centenary Edition, Benziger 1887. Grimm d. 1891. |
| Do not use | Liguori Publications; 1949 CBPC (Spellman). |
| Never-list | Redemptorist, CSsR (except translator credit), Liguori Publications. |
| Disclaimer | Spec §7, naming the Congregation of the Most Holy Redeemer and Liguori Publications. |
| Anchor | The Visit. |
| Haptics | One Visit reminder. |
| Modules | Free: The Visit. Unlock: 31 daily Visits + Read Through. SKU `liguori_companion`. |
| Accent | Fixed `LiguoriAccent.visit`. |

### Filled — `francis`

| | |
| --- | --- |
| `id` | `francis` |
| Display | Francis of Assisi |
| Tagline | *Most high, omnipotent, good Lord.* |
| Provenance | `constructed` |
| Cadence | **85 × ~4.3**, repeating. Real count 27,804 words (~327/entry). Do not pad. |
| Primary text | Paschal Robinson OFM, Dolphin Press, Philadelphia, 1905. Robinson d. 1948; 1905 is US PD. |
| Second shelf | *Fioretti*, W. Heywood, Methuen 1906. Labeled “Stories told about him.” |
| Do not use | Modern Franciscan / ICS editions. Do not put Fioretti in the daily slot. |
| Never-list | Franciscan, OFM (except translator credit), Capuchin, Conventual emblems. Tau as ornament is fine. |
| Disclaimer | Spec §7, naming OFM, Capuchins, Conventuals. |
| Anchor | Canticle of the Creatures. |
| Haptics | One optional Canticle reminder, off by default. |
| Modules | Free: 28 Admonitions + Canticle. Unlock: writings + Fioretti + Read Through. SKU `francis_companion`. |
| Accent | Fixed `FrancisAccent.woodland`. |

### Filled — `john-cross`

| | |
| --- | --- |
| `id` | `john-cross` |
| Display | John of the Cross |
| Tagline | *There is no progress but in the imitation of Christ.* |
| Provenance | `constructed` |
| Cadence | **366 × 1**, unique year. 374 natural sayings (~16,270 words, ~43/saying); 8 closing pieces sit in the index. Atomic — one saying a day, never bundled. |
| Primary text | David Lewis, *Complete Works* vol. 2 (Longman, 1864): Precautions and Spiritual Maxims. |
| Do not use | Kavanaugh–Rodriguez ICS (1964–). Treatises are a later shelf. |
| Never-list | Carmelite, OCD, Discalced emblem. |
| Disclaimer | Spec §7, naming the Order of Discalced Carmelites and ICS Publications. |
| Anchor | Sit with today’s saying. Free: Precautions. |
| Haptics | One optional saying reminder, off by default. |
| Modules | Free: Precautions + Practice. Unlock: sayings + Read Through. SKU `john-cross_companion`. |
| Accent | Fixed `JohnCrossAccent.night`. |

### Filled — `gregory`

| | |
| --- | --- |
| `id` | `gregory` |
| Display | Gregory the Great |
| Tagline | *The government of souls is the art of arts.* |
| Provenance | `constructed` |
| Cadence | **183 × 2.00**. Real count 64,649 words (~353/entry). Thin days over padding. |
| Primary text | James Barmby, NPNF II.12 (1895), *Book of Pastoral Rule*. |
| Do not recut | *Dialogues* Book II already ships as Benedict’s Life. |
| Never-list | Papal tiara / crossed keys. |
| Disclaimer | Spec §7, naming no diocese or papal household. |
| Anchor | Sit with today’s counsel. |
| Haptics | One optional Pastoral Rule reminder, off by default. |
| Modules | Free: Practice. Unlock: the Rule twice a year + Read Through. SKU `gregory_companion`. |
| Accent | Fixed `GregoryAccent.stone`. |

### Filled — `augustine`

| | |
| --- | --- |
| `id` | `augustine` |
| Display | Augustine of Hippo |
| Tagline | *Our heart is restless, until it repose in Thee.* |
| Provenance | `constructed` |
| Cadence | **366 × 1** for Books I–X. Real count 79,569 words (~217/day). Books XI–XIII are a 100-entry appendix (ids 367–466), not mapped onto the calendar. |
| Primary text | E. B. Pusey (1838), *Confessions*. |
| Do not use | *City of God* as the daily book. |
| Never-list | Augustinian, OSA. |
| Disclaimer | Spec §7, naming the Order of Saint Augustine. |
| Anchor | Evening reading. |
| Haptics | One optional evening reminder, off by default. Default 21:00. |
| Modules | Free: Evening. Unlock: I–X through the year + appendix from the index + Read Through. SKU `augustine_companion`. |
| Accent | Fixed `AugustineAccent.hearth`. |

### Filled — `teresa-avila`

| | |
| --- | --- |
| `id` | `teresa-avila` |
| Display | Teresa of Avila |
| Tagline | *Let nothing disturb thee.* |
| Provenance | `constructed` |
| Cadence | **366 × 1**. Real count 104,096 words (~284/day). A dwelling is never split across an entry. |
| Primary text | Benedictines of Stanbrook / Benedict Zimmerman (1911–12), *Way of Perfection* + *Interior Castle*. |
| Do not use | E. Allison Peers (1946–); ICS Kavanaugh–Rodriguez. |
| Never-list | Carmelite, OCD. |
| Disclaimer | Spec §7, naming the Order of Discalced Carmelites and ICS Publications. |
| Anchor | Recollection timer (quotes from the Way). |
| Haptics | One optional recollection reminder, off by default. |
| Modules | Free: Recollection. Unlock: Way + Castle through the year + Read Through. SKU `teresa-avila_companion`. |
| Accent | `TeresaAccent.forPart` — Way, then mansions 1–7. |

---

## 1. Content

Offline, committed JSON. Never run the cutter in CI.

```
tools/content/{id}/
  fetch.py          # download the PD source into raw/
  parse.py          # → work/chapters.json in cut.py's input shape
  emit.py           # cut + calendar + review.html + assets
  raw/              # gitignored or committed if small; source of truth for a re-run
  work/chapters.json
  review/review.html
assets/content/{id}/
  portal.json       # documentation; Dart registry is runtime truth
  entries.json
  calendar.json
  …module JSON
```

**Parse shape** (`tools/content/cut.py`):

```json
{
  "parts": [{
    "part": 1,
    "title": "…",
    "chapters": [{
      "chapter": 1,
      "title": "…",
      "paragraphs": ["…"]
    }]
  }]
}
```

Strip TOC, running heads, translator preface, footnote markers, apparatus. Paragraphs are clean prose. A Book of the Imitation is a `part`.

**Emit.** Search for a target word count that yields the cadence you locked (for constructed year-cycles: prefer **exactly 366**). Date map:

- 366 entries → 1:1 onto a leap year; common years merge the last two entries onto Dec 31.
- 365 entries → 1:1 onto a common year; leap day shares Feb 28.

Name the translator in `entries.json` and `portal.json` on the first emit. Do not ship "unverified."

**Must hold before commit:**

- Entry ids contiguous `1..N`
- Concatenating `textEn` reconstructs the parsed source, whitespace-normalized
- Every day of 2024 and 2025 resolves to ≥1 entry
- Every entry is reachable in at least one year type
- Eyeball `review.html` once for flagged rows

Register the folder in `pubspec.yaml` (`assets/content/{id}/`).

---

## 2. Dart

Order matters. Do the shared cycle/shell work **before** a third copy of de Sales.

1. **Registry** — `SaintPortal` in `lib/data/models/portal.dart`, append to `PortalRegistry.all`. Provenance paragraphs already substituted. Disclaimer verbatim.
2. **Palette** — accent class in `lib/app/theme/palette.dart`. Wire the resolver in `lib/main.dart` from today's entry (or a fixed colour).
3. **Cycle loader** — `CycleCalendar.load(portalId)` reads `assets/content/{id}/entries.json` + `calendar.json`. Do not add `FooCalendar`.
4. **Settings** — Read Through mode and cursor are per-`portalId` maps. Never add `fooReadThrough`. Migrate any old portal-prefixed keys on load.
5. **Shell** — Benedict keeps `_benedictShell`. Every other open house uses a shell built from `SaintPortal.modules`. Add a module id → branch mapping in `app_router.dart`; add path builders in `portal_routes.dart`.
6. **Today** — Shared cycle Today: week-unmarked strip is not required if de Sales doesn't have it yet; provenance ⓘ, drop cap, Read Through toggle, position line. Bouquet / select-to-keep is **de Sales only**.
7. **Free module + Practice** — House-specific screens. Reuse `guided_timer.dart` and `drop_cap_text.dart`.
8. **IAP** — flags, entitlement, paywall screen, unlock provider. Scaffold `all_saints` when touching IAP. `IapFlags.enabled` stays false until RevenueCat is live; while false, unlock everything.
9. **Notifications** — one channel, off by default, body is the chapter title not a nudge. Sync from a provider in `main.dart` the way bells/aspirations do.
10. **Sources / More** — gate Benedict-only rows (bells, Latin, Oblate, Life track) on `currentPortalIdProvider == 'benedict'`. Sources lists the active portal's texts, not Benedict's by default.
11. **Tests** — `test/{id}_cycle_test.dart` mirroring `test/desales_cycle_test.dart`. Update `test/companion_test.dart` open set.

Landing route: Benedict → `/hub`; everyone else → `/p/{id}/today`.

---

## 3. What not to copy from Benedict

- Hub dashboard
- Liturgical computus / drop-cap Ordo (Benedict only)
- Latin column
- Six office bells and the Hours module
- `ContentCatalog` (Rule/Life/Tools/Medal/Psalms)
- Traditional 122 × 3 date tables unless this house actually has that custom

---

## 4. Shared vs per-portal

**Shared, non-negotiable:** EB Garamond for reading text; sans confined to chrome; vellum / Compline / Paper surfaces; 1.5px line icons; 400–600ms `easeOutCubic`; drop cap widget; guided timer; audio controller when it exists.

**Per-portal:** accent set and its driver, ornament, haptic rhythm, free-tier module, disclaimer, provenance copy, SKU.

Never compute or display a reading backlog. No streak counters.

---

## 5. Store

Leave `store/listing.yml` alone until the house is actually open and you are asked to update listings. Hallway copy and the in-app disclaimer ship with the portal; store copy is a separate pass.
