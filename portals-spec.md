# Daily Company — Portals Spec (v2)

**Companion to `benedict-daily-spec.md`.** That document specifies the Benedict portal and the shared design system. This one specifies the *portal abstraction* the other saints plug into, the cadence rules for fitting a corpus to a calendar, and the full build spec for portal #2.

---

## 0. What changed from v1

v1 proposed five spine types, one per saint's "native" corpus structure. That was authenticity at the expense of the founding principle. **A constructed calendar beats a faithful program, because a calendar cannot be fallen behind on.**

| v1 | v2 |
| --- | --- |
| Five spines | **Two** — `CycleSpine` and `ProgramSpine` |
| `MonthSpine` for Liguori | Collapsed into `CycleSpine` — `dateKeys` is already a list; a monthly cycle is twelve keys per entry |
| `SerialSpine` for six saints | Gone as a spine. Survives as an optional **Read Through** reading mode (§3.4) |
| `CardSpine` for John of the Cross | Gone. His corpus is 275k words — it fills two years, it doesn't need shuffling |
| Build Ignatius second | **Build de Sales second.** Ignatius is now a lone exception; build the common case first |

The dominant cost across eight portals is no longer spine machinery. It's **cutting ~100k words into 365 pieces**, eight times. §11 specifies that pipeline; it is the thing to derisk.

---

## 1. Two spines

```dart
sealed class Spine {
  DailyEntry? resolve(DateTime date, PortalProgress progress);
  String positionLabel(DateTime date, PortalProgress progress);
}
```

### `CycleSpine` — eight of nine portals

Date-keyed, repeating, identical to what Benedict already runs. `DailyEntry.dateKeys` is a `List<String>` of `"MM-DD"` values, and the number of keys per entry is just the cycle's repeat count:

| Portal | Entries | Repeats/yr | Keys per entry |
| --- | --- | --- | --- |
| Benedict | 122 | 3 | 3 |
| de Sales | 365 | 1 | 1 |
| Liguori | 31 | ~12 | 12 |
| Gregory | 183 | 2 | 2 |
| John of the Cross | 730 | 0.5 (two-year) | 1, plus a `cycleYear` field |

No new lookup code for any of these. Benedict's existing `byDate` map and its 366-day coverage test cover the whole set.

**Two-year cycles** are the one genuine addition: `DailyEntry` gains `int? cycleYear` (1 or 2), and the resolver picks the arm by `date.year.isEven`. Anchor it to an explicit epoch year in `portal.json` rather than to parity alone, so a reinstall on a different device lands on the same arm.

**Leap day.** Emit 366 keys. In common years, merge `02-29` into `02-28` and stack the two portions with a hairline divider. You already have this code path for Benedict's Feb 24.

### `ProgramSpine` — Ignatius only

Start date plus elapsed weeks. Justified once, in §9, and confined to a single module. Everything else in the Ignatius portal runs on a cycle like every other portal.

---

## 2. Cadence — fitting a corpus to the year

The rule: **`entries × repeats ≈ 365`, chosen so daily length lands in 250–400 words.** Benedict's own cadence (122 × 3 ≈ 366, ~330 words) is the calibration point.

| Portal | Corpus | ~Words | Cadence | ~Words/day |
| --- | --- | --- | --- | --- |
| **de Sales** | *Devout Life*, ~119 ch | ~120k | 365 × 1 | ~330 |
| **Augustine** | *Confessions* I–X | ~100k | 365 × 1 | ~275 |
| **Teresa** | *Interior Castle* + *Way of Perfection* | ~135k | 365 × 1 | ~370 |
| **Thérèse** | *Story of a Soul* + letters | ~90k | 365 × 1 | ~245 |
| **Francis** | *Fioretti* + Writings + Admonitions | ~80k | 365 × 1 | ~220 |
| **Gregory** | *Pastoral Rule*, 65 ch | ~75k | **183 × 2** | ~410 |
| **Liguori** | *Visits*, 31 | ~30k | **31 × 12** | ~950/visit |
| **John of the Cross** | *Ascent*, *Dark Night*, *Canticle*, *Flame* | ~275k | **730 × 1** (two-year) | ~375 |
| Benedict | *Rule* | ~40k | 122 × 3 | ~330 |

Word counts are estimates from page counts and want verifying — have `01_fetch.py` print a real count per source before anyone commits to a cadence.

**Thin corpora take a repeat rather than padding.** Gregory at 365 × 1 is ~205 words a day, which reads as scraps. At 183 × 2 it's ~410 and he's read twice a year — which is closer to how the *Pastoral Rule* was actually used anyway. Never pad a short text to 365 with filler commentary; take the repeat.

**Liguori's ~950-word Visits are the author's own unit** and shouldn't be cut down. A monthly cycle also means his portal is the only one where a lapsed user returns to something they recognise, which is a quietly good property for the cheapest portal to build.

**Francis at ~220 is borderline.** The *Fioretti* are narrative, and narrative tolerates short days better than argument does — an episode that ends on "and the wolf laid its paw in his hand" is fine at 200 words. Leave him at 365 × 1 and let the cutter's chapter-boundary preference do the work.

---

## 3. Designing for the user who misses days

This is the point of the cycle model, and it needs to be enforced in the UI, not just the data layer. A calendar that quietly keeps score is a streak counter wearing a disguise.

### 3.1 Today is always today

**Never compute or display a backlog.** No "4 readings missed," no catch-up queue, no badge count, no "you're behind" copy anywhere in the app. Someone who opens the app after six weeks away sees today's reading, full stop, exactly as if they'd been there all along.

### 3.2 The last week, without accounting

A quiet horizontal strip of the previous seven days above the reading, each showing the date and chapter — tappable, so a missed day is one tap away. **Unmarked by completion state.** No checkmarks, no dimming, no dots. It reads as a shelf, not a ledger.

Completion tracking, if it exists at all, stays where the Benedict spec put it: a calendar heatmap under More, opt-in, never on Today.

### 3.3 Nothing expires

Any entry in the cycle is reachable at any time through the index. The calendar is the default path, not a gate.

### 3.4 Read Through mode

The real cost of a calendar is that a three-days-a-week reader sees ~150 of 365 entries and never finishes the book. So offer the straight path as an alternative *mode*, not an alternative spine:

- Same content, same 1..N ordering, one persisted cursor per portal
- Toggle lives on the Today screen, low-contrast, under the position line
- Switching modes never resets or penalises the other
- Position label changes accordingly: *"Part III · Chapter 12 of 41"* rather than *"Day 47"*

This is cheap — the entries are already ordered — and it's the correct answer for the reader who wants Augustine's Book VIII tonight rather than in October. It also quietly serves the one audience the calendar can't: someone who found the app *because* they wanted to read that specific book.

### 3.5 Notifications

One per portal per day, off by default, at a user-set time. Body text carries the actual chapter title, never a nudge — *"Part III, Chapter 12 · Of Patience"*, not *"You haven't read today."* No re-engagement notification of any kind after a lapse.

---

## 4. The provenance note

Eight of nine cycles are the app's own construction. That should be stated plainly, findable in one tap from any reading, and given no more visual weight than that.

### 4.1 Placement

**The cycle position line is the affordance.** It's already on every Today screen, it's already the thing a curious user's eye lands on, and it's already exactly the claim in question.

```
Part III · Chapter 12 of 41 · Of Patience          ⓘ
Day 47 of 365
```

Set in `secondary`, 11–12px letterspaced small caps, per the existing chapter-heading style. The `ⓘ` is a 1.5px line glyph at the same optical weight as the text — not a filled badge, no accent color, no tint. Tapping the line opens a small sheet.

Also linked from the Sources screen, which carries the full paragraph.

### 4.2 Copy — constructed cycles

> **About this reading cycle**
>
> This year-long cycle was made for this app. It is not a traditional division of the text: Francis de Sales did not write the *Devout Life* to be read a page a day, and no religious order or published edition assigns these passages to these dates. We cut the book into 365 readings at paragraph and chapter boundaries so it could be kept company with daily.
>
> The text itself is unaltered — Dom Henry Benedict Mackey's 1885 translation, complete.
>
> If you'd rather read it straight through as it was written, turn on Read Through under the reading.

Swap the saint, work, and translator per portal. Keep the last line — pointing at Read Through is what makes the disclosure useful rather than merely honest.

### 4.3 Copy — Benedict

Same affordance, opposite content, and worth the parallel:

> **About this reading cycle**
>
> This cycle is traditional. The Rule has been read in this division — the whole of it three times a year, on these dates — in monastic houses for centuries. The dates are that custom's, not ours.
>
> The translation is Boniface Verheyen's, 1902.

### 4.4 Why bother

This audience checks. Someone who reads the Rule already knows the Jan/May/Sept cycle is real, and they will assume the Augustine cycle is real too unless told otherwise — and then find out. Saying it first costs one tap of screen real estate and buys credibility for every claim the app *does* make about tradition, including the ones that matter more (the Medal blessing being reserved to a priest, the Exercises wanting a director).

---

## 5. Portal registry

```dart
class SaintPortal {
  final String id;                 // 'benedict', 'desales'
  final String displayName;        // 'Francis de Sales'
  final String tagline;            // 'Be who you are, and be that well.'
  final Spine spine;
  final CycleProvenance provenance; // .traditional | .constructed
  final AnchorPractice anchor;
  final PortalPalette palette;      // accent set only — see §6
  final List<ModuleId> modules;
  final String disclaimer;          // verbatim, store + About
  final String? unlockSku;
}
```

`CycleProvenance` drives §4's sheet copy. It's an enum rather than a bool so a future portal can be `.partlyTraditional` without a schema change — Liguori is arguably that, since the 31 Visits are the author's own division even though the month mapping is ours.

### Asset layout — do this refactor first

```
assets/content/
  benedict/    portal.json  readings.json  dialogues.json  tools.json  medal.json
  desales/     portal.json  entries.json  meditations.json  letters.json
  _shared/     psalter.json  prayers.json
```

Move the existing flat `assets/content/*.json` under `benedict/`, add the manifest, and keep Benedict's 366-day test green through the move. Retrofitting a portal id through a flat loader on portal five is the expensive version of this task.

### Routing

```
/                        portal picker, quick-resume to last active
/p/:portalId/today
/p/:portalId/practice    Compline | Examen | The Bouquet | The Visit
/p/:portalId/life
/p/:portalId/index       full cycle index + Read Through cursor
/p/:portalId/sources
```

`portalId` as a `go_router` path param, one shell route per portal, scoped through Riverpod so no feature widget reads a global "current saint."

### Isar

Every user-state entity gets a `portalId` and a compound index on `(portalId, entryId)`. Journal entries especially — resurfacing is per-portal, and a Benedict lectio note appearing inside an Ignatian examen is a bug users would notice and dislike. Add `readThroughCursor` per portal to the settings entity.

---

## 6. Shared vs per-portal

**Shared, non-negotiable:** EB Garamond for reading text; the sans confined to chrome; vellum/Compline backgrounds; 1.5px line icons; 400–600ms `easeOutCubic`; the drop cap widget; the audio controller; the guided-timer widget.

Resist per-portal typefaces. Nine saints × a "fitting" face each is +12 MB of fonts and an app that looks like nine apps. **Portals differentiate through accent, ornament, and rhythm — not type.**

**Per-portal:** the accent set and its driver.

| Portal | Accent driver |
| --- | --- |
| Benedict | reading cycle (winter / summer / autumn) |
| de Sales | Part of the *Devout Life* (I–V) |
| Teresa | the seven mansions |
| Ignatius | Week of the Exercises |
| Liguori, Augustine, Francis, Gregory, Thérèse | fixed |

The drop cap stays as the shared "one saturated element," each portal supplying its own color resolver. **Only Benedict gets the liturgical resolver and its computus** — it's the most expensive component in the app and eight portals don't need it.

**Per-portal haptics.** This matters more than it sounds. Benedict's six bells exist because the Benedictine day *is* a horarium. Ignatius gets two Examens. de Sales gets three or four light aspirations. Liguori gets one Visit. If every portal fires six bells you've flattened the one thing that makes these feel like different lives — **the rhythm is the characterization.**

---

## 7. Identity guardrails, per order

The app reads as *about* the saint, never as *from* the order.

| Portal | Never in name / icon / marketing | Icon trap | Incumbents |
| --- | --- | --- | --- |
| de Sales | Salesian, Salesians of Don Bosco, SDB, Visitation, Order of the Visitation | Salesian crest; the Visitation heart-and-thorns | none dominant |
| Ignatius | Jesuit, Society of Jesus, SJ, Manresa, Gesù, Loyola (university marks), "Ignatian Spirituality" (jesuits.org) | **IHS monogram** — same problem as the Benedictine medal | Sacred Space, Pray as You Go, Reimagining the Examen (Loyola Press) — the last is a direct competitor for the anchor feature |
| Liguori | Redemptorist, CSsR, **Liguori Publications** | — | Liguori Publications is an active trademark holder publishing this exact genre |
| Teresa / John | Carmelite, OCD, Discalced, ICS Publications | Carmelite shield, brown scapular | — |
| Francis | Franciscan, OFM, Assisi, Portiuncula, San Damiano | Tau cross reads as an OFM imprimatur | crowded aisle |
| Augustine | Augustinian, OSA, Villanova | — | — |
| Gregory | — | papal tiara / crossed keys | — |
| Thérèse | Carmelite, OCD, Lisieux (shrine), Society of the Little Flower | — | — |

**Disclaimer template**, verbatim in store description and About:

> An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by [ORDER], any of its provinces or houses, or any shrine or publisher associated with it.

Two to watch. **Liguori Publications** is the Redemptorists' US publishing house and the only name here where a portal could plausibly be read as that publisher's product. And **the Salesians of Don Bosco** are named *after* de Sales but were founded 250 years later — users conflate them constantly, so the de Sales disclaimer should name both them and the Visitation.

---

## 8. Portal #2 — Francis de Sales

**id:** `desales` · **Display:** Francis de Sales · **Tagline:** *Be who you are, and be that well.*
**Provenance:** `.constructed` · **Cadence:** 365 × 1, ~330 words/day

**Disclaimer:** *An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by the Salesians of Don Bosco, the Order of the Visitation, any Salesian or Visitandine province or house, or any shrine or publisher associated with them.*

Chosen over Ignatius because it's the pure common case: one cycle, no program machinery, and a text already written as a daily formation manual for lay people with jobs and families. It proves the multi-portal refactor and the content cutter at the same time. Ignatius, now a lone exception, comes after.

### 8.1 Why the calendar suits this text

The *Devout Life* (1609) is structured as directive letters to "Philothea" and moves in a deliberate order: Part I purifies, II establishes prayer, III builds the virtues, IV meets temptation, V renews. On a Jan 1 start, Part I's purification lands in January by itself — the start-date affordance I argued for in v1 solves itself, and the annual renewal of Part V lands in December where it belongs.

### 8.2 Anchor practice — the Bouquet

De Sales' own instruction (Part II, ch. 7): at the end of meditation, pick one or two thoughts and carry them through the day, as someone leaving a garden takes a few flowers.

This is the portal's Compline — fixed, no calendar logic, free forever, ships in an afternoon:

- After the day's reading, a **select-to-keep** gesture on any sentence
- The kept line pins to the top of Today, and to the lock-screen widget if one ships
- Saved against the date; resurfaces a year later on the same day
- One soft `selectionClick` on keep, nothing more

It's one tap, it makes the reading sticky, and it's a genuinely different interaction from Benedict's lectio timer — good evidence that the shared widget layer isn't over-fitted.

Supporting practices, both from Part II: the **Morning Exercise** (ch. 10 — thank, foresee the day's occasions, prepare, ask grace) and the **Evening Examination** (ch. 11). Short guided forms on the existing timer, 3 and 4 minutes.

### 8.3 Haptics — aspirations, not bells

De Sales' rhythm is "retirement" (Part II, ch. 12): brief returns to God scattered through an ordinary working day. Not a horarium.

| Event | Pattern | Intent |
| --- | --- | --- |
| Aspiration | one soft tap, low amplitude | a glance, not a summons |
| Bouquet kept | `selectionClick` | acknowledgement |
| Movement change | one soft tick | reuse from Lectio |

Three or four a day, user-set, default 10:00 / 14:00 / 17:00, **jittered ±10 minutes** so they don't read as an alarm. No long decay envelope — that's Benedict's Compline and borrowing it blurs the portals.

### 8.4 Modules and tiers

| Module | Content | Tier |
| --- | --- | --- |
| Practice | Bouquet, Morning Exercise, Evening Examination | free |
| Meditations | Part I's ten meditations, standalone guided | free |
| Today | the 365-day cycle | unlock |
| Letters | selections from *Letters to Persons in the World* | unlock |
| Read Through | continuous mode | unlock |

Part I's ten meditations (creation, the end for which we are made, God's gifts, sin, death, judgment, hell, paradise, the choice of paradise, the choice of the devout life) are self-contained, are explicitly the "begin here," and make a strong free tier that stands on its own.

**"Companion — de Sales", $4.99 one-time,** sku `desales_companion`.

Once portal 3 exists, add **"Daily Company — All Saints", $14.99**. Scaffold the entitlement hierarchy in RevenueCat *now*, on portal 2 — retrofitting it after users hold individual SKUs is unpleasant.

### 8.5 Sources

| Source | Use | Status |
| --- | --- | --- |
| *Introduction to the Devout Life*, trans. Dom Henry Benedict Mackey OSB (1885) | Primary display text | PD — Mackey d. 1906 |
| *Letters to Persons in the World*, Mackey (1892) | Letters module | PD |
| *Treatise on the Love of God*, Mackey (1884) | Reserved for a possible year 2 | PD |

**Do not use:** John K. Ryan (1950, Image/Doubleday — the best-selling English text and therefore the tempting one); Michael Day (Burns & Oates, 1956); Armind Nazareth; any TAN or Sophia Institute edition's apparatus, notes, or chapter titles.

### 8.6 Build order

1. **Portal abstraction** — asset refactor, registry, routing, `portalId` on Isar, portal picker, provenance sheet. Benedict's 366-day test green at the end. *No de Sales content yet.*
2. **Content cutter** (§11) — run it on Mackey, review the sheet, commit `entries.json`.
3. **Bouquet + the two exercises** — free, shippable alone.
4. **Today** on the shared widgets, Part-driven accent, provenance sheet wired.
5. **Read Through** — cursor, toggle, position labels.
6. **Aspiration haptics + notifications.**
7. **IAP** — `desales_companion` plus the bundle entitlement.
8. **Audio** — same TTS pipeline, ~120k words, same $5–15 range.

---

## 9. Portal #3 — Ignatius of Loyola (the exception)

**id:** `ignatius` · **Tagline:** *Find God in all things.*
**Disclaimer:** *An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by the Society of Jesus, any Jesuit province or house, or any Ignatian retreat centre or publisher.*

The only portal that keeps `ProgramSpine`, and only for one module.

### 9.1 Why he's exempt

The *Exercises* are progressive by method — the Weeks are meant to do their work in order, and a first-ever day landing on the Third Week's Passion is wrong in a way that Augustine's Book VII on a random Tuesday is not. Ignatius says so himself in the Annotations. The Nineteenth Annotation is his own provision for someone who can't leave their work for thirty days: the Exercises spread over months of daily prayer. **30 weeks, 7 entries per week, 210 entries**, with a start date, pause, resume and restart.

Everything else in this portal runs on a cycle:

| Module | Spine | Tier |
| --- | --- | --- |
| Examen | fixed practice, no spine | free |
| Discernment — 22 rules | `CycleSpine`, 22 × 16 | free |
| Autobiography, 11 ch | `CycleSpine`, 365 × 1 (cut like any other) | first 3 free |
| Prayers — Anima Christi, Suscipe, Generosity | none | free |
| **Exercises** | **`ProgramSpine`** | unlock |

### 9.2 Anchor — the Examen

Five movements on the existing timer, soft tick between each. Two forms: **Full** 12 min (2/1/5/2/2 — presence, light, review, sorrow, resolve) and **Short** 5 min. Ignatius held the Examen was the one thing never to be dropped, so the short form is the point rather than a compromise; default to it.

Journal at the end, saved against the date, resurfacing by date — *"a year ago tonight you wrote…"* — which is a different query from Benedict's cross-cycle one. Budget for it.

**Haptics: two beats.** Midday Examen, soft double tap ~80ms apart. Evening Examen, double tap with a longer second beat. Defaults 12:30 and 21:00.

### 9.3 Accent by Week

Disposition `#6E655A` ash → First Week `#4A4266` violet → Second `#4F6146` green → Third `#8C2F26` red → Fourth `#A8802C` gold.

**Repetition is structural, not filler.** Roughly one entry in four repeats the previous day's points, by design. Don't let a content pass "helpfully" replace them with new material — it breaks the method.

### 9.4 Pastoral note — required

Handle it like the Medal blessing: clear, unhedged, shown once before the program starts and available in About.

> These Exercises were written to be given by a director, one person to another. This app can carry the text and keep the days, but it cannot listen to you. If you find yourself in real desolation, or moving toward a serious decision, find a spiritual director — many dioceses and retreat houses will connect you with one at no cost.

Not a legal disclaimer. It's the honest description of the product, and this audience will trust everything else more for it.

### 9.5 Sources

*Spiritual Exercises*, trans. Elder Mullan SJ (1909) — PD, Mullan d. 1925; literal from the Autograph, keeps Ignatius's numbering. *Autobiography*, trans. J. F. X. O'Conor SJ (1900) — PD. *Letters and Instructions*, trans. Rickaby SJ (1914) — PD. Autograph Spanish for side-by-side — PD.

**Do not use:** Puhl (1951, Loyola Press — still in copyright and still the best-selling English text); Ganss (1992, IJS); Fleming (1978/1996); any Loyola Press or IJS apparatus.

---

## 10. The remaining six

| Saint | Cadence | Primary text (PD) | Anchor | Note |
| --- | --- | --- | --- | --- |
| **Liguori** | 31 × 12 | *Visits to the Blessed Sacrament*, Coffin (1855) | The Visit | Cheapest portal here — 31 entries, no cutting pass, resets monthly. Provenance is `.partlyTraditional`: the 31 Visits are his own division, the month mapping is ours. |
| **Augustine** | 365 × 1 | *Confessions*, Pusey (1838) | Evening reading | Ship Books I–X; XI–XIII are philosophical and lose people. Treat them as an appendix reachable from the index and Read Through. |
| **Teresa** | 365 × 1 | *Interior Castle* + *Way of Perfection*, David Lewis | Recollection timer | The seven mansions drive the accent — the one fixed-corpus portal that earns a moving accent. |
| **Francis** | 365 × 1 | *Fioretti*, T. W. Arnold / Heywood (1906) + Writings | Canticle of the Creatures | The 28 Admonitions make a strong free tier. Highest name recognition, most crowded aisle. |
| **Gregory** | **183 × 2** | *Book of Pastoral Rule*, Barmby, NPNF II.12 (1895) | — | **Overlaps Benedict** — *Dialogues* Bk II already ships there as Life of Benedict. Cross-link the same JSON, don't duplicate. The *Pastoral Rule* is a book about leadership and is what Gregory brings that Benedict's portal doesn't. |
| **Thérèse** | 365 × 1 | *Story of a Soul* — **see flag** | The Little Way offering | **Rights flag.** The standard PD English text is Thomas Taylor's 1912 translation; Taylor appears to have died in 1963, which clears the US but *not* life+70 until ~2034 — the exact Doyle problem the Benedict spec avoids. Verify the translator's dates before scheduling. The 1898 French *Histoire d'une Âme* is clear for Thérèse's own words, but Mother Agnes's editorial hand (d. 1951) complicates the edition. **Build last.** |

Public-domain status is jurisdiction-specific and I'm not a lawyer — the caveat closing the Benedict spec applies to every row above, the Thérèse row especially.

---

## 11. The content cutter

`tools/content/cut.py`. This runs eight times and is the long pole of the whole project. Build it once, properly.

**Algorithm.** Greedy paragraph packing to a target word count.

- Target from `portal.json` (250–400 typical); hard bounds 150 and 600
- **Never split mid-paragraph.** A paragraph longer than the hard max becomes its own entry and is flagged for review
- **Prefer chapter boundaries** — end an entry at a chapter end if within ±35% of target
- Never let an entry span more than two chapters
- Carry chapter, chapter title, part/book, and portion-in-chapter onto every entry, so the position line reads *"Part III · Ch. 12 of 41 · reading 2 of 3"*

**Output.** `entries.json` plus `review.html` — every entry with its word count, its first and last line, and the boundary type, with out-of-bounds entries highlighted. Eyeball it once. One afternoon, done permanently, same as the Verheyen alignment.

**Determinism.** Same input, same output, byte for byte. Commit the emitted JSON; don't run this in CI.

**Cadence solver.** Given a word count and a target, print the candidate `entries × repeats` combinations and their resulting words/day, so the §2 table is derived rather than asserted.

**Tests.**
- Every day of a leap year and a common year resolves to ≥1 entry
- Every entry is reachable
- Entry ordering is contiguous, 1..N, no gaps
- Concatenating all entries reproduces the source text exactly, whitespace normalized — **this is the important one**, and it's what proves the app isn't silently dropping the middle of a chapter

---

## 12. Open questions

1. **One active saint, or grazing?** Grazing is the easy build and the weaker product. Suggestion: the app remembers one active portal and opens straight to it; switching is two taps under More. "Keep company with a saint" is singular and the tagline is doing real work.
2. **Cross-portal streaks.** Don't. The Benedict spec's argument holds harder across nine portals — someone who moves from Benedict to Ignatius has broken nothing.
3. **Audio at scale.** Nine portals is ~900k words of TTS. Cheap in absolute terms, but "download all" must be per-portal or the install balloons. Hold the line at anchor practice + current week bundled, everything else cached.
4. **Does Read Through cannibalise the calendar?** It might, for a minority. That's an acceptable trade for honesty, and worth instrumenting once — if most users switch, the premise needs revisiting rather than defending.
