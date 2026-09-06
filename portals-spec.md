# Daily Company — Portals Spec (v2)

**Companion to `benedict-daily-spec.md`.** That document specifies the Benedict portal and the shared design system. This one specifies the *portal abstraction* the other saints plug into, the cadence rules for fitting a corpus to a calendar, and the full build specs for de Sales and Kempis.

**Opening a house:** follow `portal-playbook.md`. That file is the engineering checklist (how de Sales was actually built). This file remains product law.

**Texts and rights:** `portal-texts.md`. Editions, do-not-use lists, and per-house identity. Not a second engine — IDs, spines, and IAP in this file still win.

---

## 0. What changed from v1

v1 proposed five spine types, one per saint's "native" corpus structure. That was authenticity at the expense of the founding principle. **A constructed calendar beats a faithful program, because a calendar cannot be fallen behind on.**

| v1 | v2 |
| --- | --- |
| Five spines | **Two** — `CycleSpine` and `ProgramSpine` |
| `MonthSpine` for Liguori | Collapsed into `CycleSpine` — `dateKeys` is already a list; a monthly cycle is twelve keys per entry |
| `SerialSpine` for six saints | Gone as a spine. Survives as an optional **Read Through** reading mode (§3.4) |
| `CardSpine` for John of the Cross | Gone. Opening daily unit is the *Sayings*, not two years of treatise slices (`portal-texts.md`) |
| Build Ignatius second | **Build de Sales second.** Ignatius is now a lone exception; build the common case first |

The dominant cost across eight portals is no longer spine machinery. It's **cutting ~100k words into 365 pieces**, eight times. §12 specifies that pipeline; it is the thing to derisk.

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
| de Sales | 366 | 1 | 1 |
| Liguori | 31 | ~12 | 12 |
| Gregory | 183 | 2 | 2 |
| John of the Cross | 366 | 1 | unique + 8 appendix |
| Augustine | 366 | 1 | 1 |
| Teresa | 366 | 1 | 1 |

No new lookup code for any of these. Benedict's existing `byDate` map and its 366-day coverage test cover the whole set. John of the Cross opens on the *Sayings* (366 unique days; overflow in the index), not a two-year treatise cut. de Sales uses a `cycleYear` switch for the Treatise as year 2 of Today.

**Leap day.** Emit 366 keys. In common years, merge `02-29` into `02-28` and stack the two portions with a hairline divider. You already have this code path for Benedict's Feb 24.

### `ProgramSpine` — Ignatius only

Start date plus elapsed weeks. Justified once, in §10, and confined to a single module. Everything else in the Ignatius portal runs on a cycle like every other portal.

---

## 2. Cadence — fitting a corpus to the year

The rule: **`entries × repeats ≈ 365`, chosen so daily length lands in 250–400 words.** Benedict's own cadence (122 × 3 ≈ 366, ~330 words) is the calibration point.

| Portal | Corpus | ~Words | Cadence | ~Words/day |
| --- | --- | --- | --- | --- |
| **de Sales** | *Devout Life*, ~119 ch | ~78k (was ~120k) | 366 × 1 | ~215 |
| **Kempis** | *Imitation of Christ*, 4 books | ~63k | **366 × 1** | ~170 |
| **Augustine** | *Confessions* I–X | 79.6k | **366 × 1** | ~217 |
| **Teresa** | *Interior Castle* + *Way of Perfection* | 104k | **366 × 1** | ~284 |
| **Thérèse** | *Story of a Soul* + letters + prayers | 88.7k | **366 × 1** | ~242 |
| **Francis** | Writings (Robinson); *Fioretti* is a second shelf | 27.8k | **85 × ~4.3** | ~327 |
| **Gregory** | *Pastoral Rule*, 65 ch | ~75k | **183 × 2** | ~410 |
| **Liguori** | *Visits*, 31 | ~19k | **31 × 12** | ~610/visit |
| **John of the Cross** | *Sayings* / Precautions + Maxims (Lewis) | 16.3k | **366 × 1** + 8 appendix | ~43 |
| **Ignatius** | Autobiography (O'Conor); Exercises are a program | 18.0k | **60 × 6.1** | ~300 |
| **Catherine** | *Dialogue* (Thorold) | 79.3k | **365 × 1** | ~217 |
| **Montfort** | *True Devotion* (Faber) | 47.2k | **120 × 3.05** | ~393 |
| **Scupoli** | *Spiritual Combat* + Supplement | 53.9k | **120 × 3.05** | ~449 |
| **Lawrence** | Conversations + letters | 10.7k | **19 × ~19.3** | ~562 |
| **Cassian** | *Conferences* I–XXIV except XII, XXII | 160k | **366 × 1** | ~438 |
| Benedict | *Rule* | ~40k | 122 × 3 | ~330 |

Word counts are estimates from page counts and want verifying — have `01_fetch.py` print a real count per source before anyone commits to a cadence.

**Thin corpora take a repeat rather than padding.** Gregory at 365 × 1 is ~205 words a day, which reads as scraps. At 183 × 2 it's ~410 and he's read twice a year — which is closer to how the *Pastoral Rule* was actually used anyway. Never pad a short text to 365 with filler commentary; take the repeat.

**Liguori's ~950-word Visits are the author's own unit** and shouldn't be cut down. A monthly cycle also means his portal is the only one where a lapsed user returns to something they recognise, which is a quietly good property for the cheapest portal to build.

**Francis's writings are thin.** Do not pad them to 365 and do not put the *Fioretti* in the daily slot to fatten the year. Take a repeat after the real count. The *Fioretti* are a labeled second shelf — stories told about him, not his voice.

**Kempis at ~170 is the same trade de Sales already made.** The Imitation is thinner than the word-count band; a 183 × 2 repeat would land ~340 words and is the spec-correct default. The product choice for this house is daily freshness — a unique passage every calendar day — over the band. Thin days, never padding, never a repeat. Confirm the real count in the parse step before locking the cutter target.

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
> The text itself is unaltered — the 1876 Rivingtons edition (Library of Spiritual Works for English Catholics). The title page names no translator.
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
  final String id;                 // 'benedict', 'desales', 'kempis'
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
  kempis/      portal.json  entries.json  calendar.json
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
| Kempis | Book of the *Imitation* (I–IV) |
| Teresa | the seven mansions |
| Ignatius | Week of the Exercises |
| Liguori, Augustine, Francis, Gregory, Thérèse | fixed |

The drop cap stays as the shared "one saturated element," each portal supplying its own color resolver. **Only Benedict gets the liturgical resolver and its computus** — it's the most expensive component in the app and eight portals don't need it.

**Per-portal haptics.** This matters more than it sounds. Benedict's six bells exist because the Benedictine day *is* a horarium. Ignatius gets two Examens. de Sales gets three or four light aspirations. Liguori gets one Visit. Francis gets one Canticle reminder. If every portal fires six bells you've flattened the one thing that makes these feel like different lives — **the rhythm is the characterization.**

---

## 7. Identity guardrails, per order

The app reads as *about* the saint, never as *from* the order.

| Portal | Never in name / icon / marketing | Icon trap | Incumbents |
| --- | --- | --- | --- |
| de Sales | Salesian, Salesians of Don Bosco, SDB, Visitation, Order of the Visitation | Salesian crest; the Visitation heart-and-thorns | none dominant |
| Kempis | Windesheim, Brothers of the Common Life, Mount Saint Agnes, Devotio Moderna (as a brand), Canons Regular / Augustinian (collides with the Augustine house) | Canons Regular crest; a printed-book "Imitation" wordmark that reads as a publisher | crowded aisle — most-printed Christian book after the Bible |
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

Once portal 3 exists, add **"Daily Company — All Saints", $14.99**. Scaffold the entitlement id `all_saints` when touching IAP — retrofitting it after users hold individual SKUs is unpleasant.

### 8.5 Sources

| Source | Use | Status |
| --- | --- | --- |
| *Introduction to the Devout Life*, anonymous Rivingtons 1876 (*Library of Spiritual Works for English Catholics*) | Primary display text | PD — 1876. Not Mackey. |
| *Letters to Persons in the World*, Mackey (1892) | Letters module | PD — Mackey d. 1906 |
| *Treatise on the Love of God*, Mackey (1884) | Year 2 of Today | PD |

**Do not use:** John K. Ryan (1950, Image/Doubleday — the best-selling English text and therefore the tempting one); Michael Day (Burns & Oates, 1956); Armind Nazareth; any TAN or Sophia Institute edition's apparatus, notes, or chapter titles.

### 8.6 Build order

1. **Portal abstraction** — asset refactor, registry, routing, `portalId` on Isar, portal picker, provenance sheet. Benedict's 366-day test green at the end. *No de Sales content yet.*
2. **Content cutter** (§12) — run it on the 1876 Rivingtons text, review the sheet, commit `entries.json`.
3. **Bouquet + the two exercises** — free, shippable alone.
4. **Today** on the shared widgets, Part-driven accent, provenance sheet wired.
5. **Read Through** — cursor, toggle, position labels.
6. **Aspiration haptics + notifications.**
7. **IAP** — `desales_companion` plus the bundle entitlement.
8. **Audio** — same TTS pipeline, ~120k words, same $5–15 range.

---

## 9. Portal #3 — Thomas à Kempis

**id:** `kempis` · **Display:** Thomas à Kempis · **Tagline:** *Love God, and serve Him only.* (I.1)
**Provenance:** `.constructed` · **Cadence:** 366 × 1, ~170 words/day

**Disclaimer:** *An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by the Canons Regular of St. Augustine, the Congregation of Windesheim, the Brothers of the Common Life, any house associated with them, or any shrine or publisher of the Imitation.*

Already a closed house in the hallway, listed ahead of de Sales. Opening it is the common-case path a second time — same `entries.json` + `calendar.json` shape, same leap/common handling — so the work is extracting the cycle loader and non-Benedict shell, not cloning de Sales. Ignatius remains the later `ProgramSpine` exception.

There is no living traditional date-map for the Imitation comparable to the Rule's Jan/May/Sept cycle. The year is this app's construction.

**Not a saint.** Thomas à Kempis has never been canonized or beatified. Display name, store copy, commentary, and hallway chrome never read "St. Thomas à Kempis." `HouseKind.writer` so the row is *Writer · The Imitation of Christ*. The app tagline can stay *Keep company with a saint*; this house is the exception the listing already hedges as *a saint or spiritual master*.

### 9.1 Why 366 × 1

The Imitation is thinner than the 250–400 word band (~63k in Benham). Spec §2 would take a repeat (183 × 2 ≈ 340 words). The product choice is the same trade de Sales already made: **a unique passage every calendar day**, thin days over merging or padding. 366 maps 1:1 onto a leap year; common years merge the last two entries onto Dec 31.

Confirm the real word count in the parse step before locking the cutter target. Search `cut.py` for a target that yields exactly 366.

### 9.2 Anchor practice — The Cell

Kempis' own instruction, Book I chapter 20: *Of the love of solitude and silence.* Withdraw into the inner cell.

This is the portal's Compline — fixed, no calendar logic, free forever:

- After the day's reading, an unguided silence on the existing timer. No lectio movements. No select-to-keep (that is de Sales' Bouquet).
- One persisted hour of withdrawal, **off by default**, user-set time.
- At most one soft tap at that hour. Near-silence is the characterization.

### 9.3 Haptics — almost none

| Event | Pattern | Intent |
| --- | --- | --- |
| Cell hour | one soft tap, if enabled | a glance into the cell |
| Movement change | one soft tick | reuse from Lectio, only if a timer is running |

No jittered aspirations. No office bells. Borrowing either blurs the house.

### 9.4 Accent by book

Book I ascesis → slate. Book II inner life → umber. Book III dialogue → muted rose-brown. Book IV sacrament → antique gold. Hues must be distinct from `CycleAccent` and `DesalesAccent`.

### 9.5 Modules and tiers

| Module | Content | Tier |
| --- | --- | --- |
| Practice | The Cell | free |
| Admonitions | Book I's 25 chapters, as written, indexed | free |
| Today | the 366-day cycle of Books I–IV | unlock |
| Read Through | continuous mode | unlock |

No Latin, no Life, no second corpus (letters, soliloquies) in this opening. Book I is the "begin here" — complete in itself, the famous short book.

**"Companion — Kempis", $4.99 one-time,** sku `kempis_companion`.

Scaffold **"Daily Company — All Saints"** entitlement `all_saints` in the same IAP pass.

### 9.6 Sources

| Source | Use | Status |
| --- | --- | --- |
| *The Imitation of Christ*, trans. Rev. William Benham (1886), Project Gutenberg #1653 | Primary display text, all four books | PD — Benham d. 1910 |

Book IV (the Blessed Sacrament) ships. This app is Catholic; Protestant editions that drop it are not the text.

Authorship has been debated (Gerson, Gersen, Hilton). The house follows the received attribution: Thomas à Kempis. One sentence in Sources is enough; do not hedge the hallway name.

**Do not use:** Aloysius Croft and Harold Bolton (1940, Image — the tempting Catholic edition); Ronald Knox; William Creasy; Joseph Tylenda SJ; any TAN or Sophia Institute edition's apparatus, notes, or chapter titles.

### 9.7 Build order

1. Decision record in this section + `portal-playbook.md`.
2. Content cutter on Benham — fetch, parse four books, 366 entries, `review.html`, concatenation test. Translator named in `portal.json` from day one.
3. Generic `CycleCalendar` + portal-scoped Read Through settings + registry-driven non-Benedict shell. de Sales tests stay green. Benedict stays on its loaders.
4. The Cell + Book I Admonitions — free.
5. Today on the shared cycle widgets, book-driven accent, provenance sheet, Read Through. No Bouquet gesture.
6. Cell notification, IAP (`kempis_companion` + `all_saints` entitlement id).

---

## 10. Portal #4 — Ignatius of Loyola (the exception)

**id:** `ignatius` · **Tagline:** *Find God in all things.*
**Disclaimer:** *An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by the Society of Jesus, any Jesuit province or house, or any Ignatian retreat centre or publisher.*

The only portal that keeps `ProgramSpine`, and only for one module.

### 10.1 Why he's exempt

The *Exercises* are progressive by method — the Weeks are meant to do their work in order, and a first-ever day landing on the Third Week's Passion is wrong in a way that Augustine's Book VII on a random Tuesday is not. Ignatius says so himself in the Annotations. The Nineteenth Annotation is his own provision for someone who can't leave their work for thirty days: the Exercises spread over months of daily prayer. **30 weeks, 7 entries per week, 210 entries**, with a start date, pause, resume and restart.

Everything else in this portal runs on a cycle:

| Module | Spine | Tier |
| --- | --- | --- |
| Examen | fixed practice, no spine | free |
| Discernment — 22 rules | `CycleSpine`, 22 × 16 | free |
| Autobiography, 8 ch | `CycleSpine`, **60 × 6.1** (real count 18,018 words; do not pad) | first 3 free |
| Prayers — Anima Christi, Suscipe | none | free |
| **Exercises** | **`ProgramSpine`**, 210 sequential | unlock |

### 10.2 Anchor — the Examen

Five movements on the existing timer, soft tick between each. Two forms: **Full** 12 min (2/1/5/2/2 — presence, light, review, sorrow, resolve) and **Short** 5 min. Ignatius held the Examen was the one thing never to be dropped, so the short form is the point rather than a compromise; default to it.

Journal at the end, saved against the date, resurfacing by date — *"a year ago tonight you wrote…"* — which is a different query from Benedict's cross-cycle one. Budget for it.

**Haptics: two beats.** Midday Examen, soft double tap ~80ms apart. Evening Examen, double tap with a longer second beat. Defaults 12:30 and 21:00.

### 10.3 Accent by Week

Disposition `#6E655A` ash → First Week `#4A4266` violet → Second `#4F6146` green → Third `#8C2F26` red → Fourth `#A8802C` gold.

**Repetition is structural, not filler.** A thirty-day retreat repeats roughly one entry in four. The 210-day Nineteenth Annotation expansion repeats more often, by design — do not replace those days with new material.

The Prayer for Generosity is not in the Autograph or in Mullan and is not shipped. Anima Christi is the traditional public-domain English; Mullan only names it as a rubric.

### 10.4 Pastoral note — required

Handle it like the Medal blessing: clear, unhedged, shown once before the program starts and available in About.

> These Exercises were written to be given by a director, one person to another. This app can carry the text and keep the days, but it cannot listen to you. If you find yourself in real desolation, or moving toward a serious decision, find a spiritual director — many dioceses and retreat houses will connect you with one at no cost.

Not a legal disclaimer. It's the honest description of the product, and this audience will trust everything else more for it.

### 10.5 Sources

*Spiritual Exercises*, trans. Elder Mullan SJ (1909) — PD, Mullan d. 1925; literal from the Autograph, keeps Ignatius's numbering. *Autobiography*, trans. J. F. X. O'Conor SJ (1900) — PD. *Letters and Instructions*, trans. Rickaby SJ (1914) — PD. Autograph Spanish for side-by-side — PD.

**Do not use:** Puhl (1951, Loyola Press — still in copyright and still the best-selling English text); Ganss (1992, IJS); Fleming (1978/1996); any Loyola Press or IJS apparatus.

---

## 11. The remaining houses

Editions, do-not-use, and identity never-lists: `portal-texts.md`. Cadence for every house in `Companions` is locked from a real count.

| Saint | Cadence | Primary text (PD) | Anchor | Note |
| --- | --- | --- | --- | --- |
| **Liguori** | 31 × 12 | *Visits to the Blessed Sacrament*, Grimm Centenary (Benziger, 1886–97) | The Visit | Cheapest portal here — 31 entries, no cutting pass, resets monthly. Short months omit visits 29–31; do not merge them. Provenance is `.partlyTraditional`: the 31 Visits are his own division, the month mapping is ours. |
| **Augustine** | **366 × 1** | *Confessions*, Pusey (1838) | Evening reading | Ship Books I–X in 366 readings; XI–XIII are a 100-entry appendix reachable from the index and Read Through. |
| **Teresa** | **366 × 1** | *Interior Castle* + *Way of Perfection*, Stanbrook / Zimmerman (1911–12) | Recollection timer | The seven mansions drive the accent — the one fixed-corpus portal that earns a moving accent. Never Peers or ICS. A dwelling is never split across an entry. |
| **Francis** | **85 × ~4.3** | Writings, Robinson (1905). *Fioretti* (Heywood 1906) is a second shelf | Canticle of the Creatures | Do not pad a short corpus to 365. 85 natural units cycle through the year. The Office of the Passion is five seasonal offices, not mashed hour-scraps. The 28 Admonitions and the Canticle stay free. Highest name recognition, most crowded aisle. |
| **Gregory** | **183 × 2** | *Book of Pastoral Rule*, Barmby, NPNF II.12 (1895) | Sit with today’s counsel | **Overlaps Benedict** — *Dialogues* Bk II already ships there as Life of Benedict. Cross-link the same JSON, don't duplicate. The *Pastoral Rule* is a book about leadership and is what Gregory brings that Benedict's portal doesn't. |
| **John of the Cross** | **366 × 1** + 8 appendix | Precautions + Spiritual Maxims, Lewis (1864) | Sit with the saying | Daily unit is the sayings, not slices of the *Ascent*. 366 unique days; overflow sits in the index. Treatises (~275k) are a later shelf. Never Kavanaugh–Rodriguez. The Precautions stay free. |
| **Ignatius** | Autobiography **60 × 6.1**; Exercises **210** sequential | Mullan 1914; O'Conor 1900 | Examen | Do not calendar the Exercises. 22 rules stay free. Prayer for Generosity omitted — not in Autograph/Mullan. |
| **Thérèse** | **366 × 1** | *Story of a Soul* — Taylor 1912 of 1898 Pauline | The Little Way offering | **Rights flag, cost accepted.** The historically famous edited Thérèse, not the 1956 manuscripts. Never Clarke / Knox / ICS. |
| **Catherine** | **365 × 1** | *Dialogue*, Thorold 1907 | Four requests | Four treatises as parts. |
| **Montfort** | **120 × 3.05** | *True Devotion*, Faber 1863 | To Jesus through Mary | Not a 33-day program. Consecration is the last chapter. |
| **Scupoli** | **120 × 3.05** | *Spiritual Combat* + Supplement, Rivingtons 1875 anonymous | The combat | Writer, never “St.” Path of Paradise skipped (scan not clean). |
| **Lawrence** | **19 × ~19.3** | Conversations and letters, Revell from the French | Remain in the presence | Writer, never “St.” Natural units, repeating — do not pad. |
| **Cassian** | **366 × 1** | *Conferences*, Gibson NPNF II.11 1894 | Sit with the elder | Conferences I–XXIV except XII and XXII (Gibson left them untranslated). Not the Institutes. |

Public-domain status is jurisdiction-specific and I'm not a lawyer — the caveat closing the Benedict spec applies to every row above, the Thérèse row especially.

---

## 12. The content cutter

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

## 13. Open questions

1. **One active saint, or grazing?** Grazing is the easy build and the weaker product. Suggestion: the app remembers one active portal and opens straight to it; switching is two taps under More. "Keep company with a saint" is singular and the tagline is doing real work.
2. **Cross-portal streaks.** Don't. The Benedict spec's argument holds harder across nine portals — someone who moves from Benedict to Ignatius has broken nothing.
3. **Audio at scale.** Nine portals is ~900k words of TTS. Cheap in absolute terms, but "download all" must be per-portal or the install balloons. Hold the line at anchor practice + current week bundled, everything else cached.
4. **Does Read Through cannibalise the calendar?** It might, for a minority. That's an acceptable trade for honesty, and worth instrumenting once — if most users switch, the premise needs revisiting rather than defending.
