# Daily Company — Build Spec

**Studio:** Daddoo Dev
**Bundle ID:** `pro.daddoodev.dailycompany`
**Platform:** Flutter · Android + iOS · offline-first
**Store subtitle:** *Keep company with a saint.*

Drop this file at the repo root as `SPEC.md` and reference it from `.cursorrules`.

---

## 0. Brief

Hallow and its competitors are meditation apps with saint content bolted on. Daily Company is a **formation app**: it runs the actual Benedictine daily cycle — the whole Rule of St. Benedict read three times a year, on the calendar Benedictines have used for centuries — plus a lay-scaled horarium and a lectio divina practice.

Three constraints that everything else follows from:

1. **The calendar is the app.** Open it on any day of the year and it already knows which portion of the Rule you read today. No "start a plan" onboarding. No streaks-as-guilt.
2. **Offline-first, no backend.** All text ships as assets; audio caches on first play. Unlike Conclavium or Peek, there is no user data in v1 worth syncing.
3. **Under four minutes.** Daily reading plus commentary plus audio fits in a coffee break. Depth is opt-in.

### Identity guardrails

The app must read as *about* Benedict, never as *from* a Benedictine institution.

- **Never use** in the name, icon, or marketing: Abbey, Monastery, Priory, Order of Saint Benedict, OSB, Benedictine (also a Bacardi trademark), Monte Cassino, Nursia/Norcia, Subiaco, Cluny, Solesmes, Collegeville.
- **Keep the Benedictine medal off the app icon.** A medal or a habited figure on the icon reads as an order's imprimatur far more strongly than any wordmark. The medal appears only *inside* the Medal module, as subject matter.
- **Disclaimer** — verbatim, in both the store description and the About screen:

  > An independent app from Daddoo Dev. Not affiliated with, endorsed by, or produced by any Benedictine monastery, abbey, congregation, or the Order of Saint Benedict.

- Adjacent app to be aware of: **Benedictus** (Sophia Institute) — traditional Latin Mass companion. Different focus, but the Benedict- prefix is partly occupied in this aisle. Do not imitate its branding.

---

## 1. Design system

The reference is a well-set breviary, not a wellness app. Restraint is the expressive move. Color and motion are permitted in exactly two places: the illuminated drop cap, and the bell.

### 1.1 Palette

```dart
// lib/app/theme/palette.dart
abstract final class Vellum {
  static const bg          = Color(0xFFF3EDE1); // vellum
  static const ink         = Color(0xFF211D1A); // iron gall
  static const secondary   = Color(0xFF6E655A);
  static const rule        = Color(0xFFD9CFBE); // hairlines
  static const gold        = Color(0xFFA8802C); // illumination
}

abstract final class Compline {                 // dark mode
  static const bg          = Color(0xFF16130F);
  static const ink         = Color(0xFFE6DCCB);
  static const secondary   = Color(0xFF9C9084);
  static const rule        = Color(0xFF332D26);
  static const gold        = Color(0xFFC9A14E);
}

/// Accent shifts three times a year with the reading cycle.
abstract final class CycleAccent {
  static const winter = Color(0xFF4A4266); // Jan 1 – May 1
  static const summer = Color(0xFF4F6146); // May 2 – Aug 31
  static const autumn = Color(0xFF7A3A2C); // Sep 1 – Dec 31
}
```

Backgrounds are never pure white; text is never pure black. Dark mode is a warm near-black, not blue-grey.

The cycle accent is used sparingly — active nav item, progress hairline, section rules. It is not a fill color. Nothing on this app has a saturated background.

### 1.2 The drop cap — the one saturated element

Each day's reading opens with a single illuminated capital. It is the only saturated color on the page, and it takes the **liturgical color of the day**, not the cycle accent.

```dart
abstract final class LiturgicalColor {
  static const green  = Color(0xFF4F6146); // Ordinary Time
  static const violet = Color(0xFF4A4266); // Advent, Lent
  static const red    = Color(0xFF8C2F26); // Palm Sun, Good Fri, Pentecost, martyrs
  static const gold   = Color(0xFFA8802C); // Christmas, Easter, solemnities
  static const rose   = Color(0xFFB07A85); // Gaudete, Laetare
  static const black  = Color(0xFF211D1A); // All Souls (optional)
}
```

**v1 scope for the color resolver:** do not attempt a full Ordo. Implement:
- Season ranges (Advent, Christmas, Lent, Easter, Ordinary Time), which requires a computus — use the Meeus/Jones/Butcher algorithm for Easter, ~15 lines, well documented.
- A short fixed-date table for the feasts this audience cares about: **Jul 11** (Solemnity of St. Benedict, gold), **Mar 21** (Passing of St. Benedict, gold), **Feb 10** (St. Scholastica, gold), plus Christmas and the fixed solemnities.
- Default green.

A user should gradually notice the letter changes color by a rule, then be unable to unsee it. That is the vibrancy budget, spent entirely.

### 1.3 Typography

```
Reading text  EB Garamond (variable) — body, display, Latin
Chrome        Inter or IBM Plex Sans — timers, buttons, settings only
Latin column  Junicode (optional, audition it — built for medievalists)
```

Rules:
- **The sans never touches the Rule text.** It is confined to chrome.
- Chapter headings: letterspaced small caps, 11–12px, `letter-spacing: 0.08em`, in `secondary`.
- Body: 16–17px, `height: 1.7`. Oldstyle figures on.
- Drop cap: ~46px, `height: 0.85`, floated, 8px right padding.
- One drop cap per screen. Resist adding more illumination.

### 1.4 Motion

- Duration 400–600ms. `Curves.easeOutCubic`. Nothing springs, nothing bounces.
- Screen transitions cross-fade with a slight horizontal drift — page-turn-adjacent, not a literal page curl.
- **The one animated moment:** the drop cap illuminates on open. Stroke draws, then fill. 1200ms. Once per day, on first open only — persist `lastIlluminatedDate` so it doesn't replay on every navigation.
- Respect `MediaQuery.disableAnimations` / reduce-motion. Skip the illumination, keep the fade.

### 1.5 Haptics — the bell

This is where the app earns its keep. RB 47, *On Giving the Signal for the Time of the Work of God*, means the Benedictine day is literally organized around a physical signal. Haptics are not decoration here; they are the bell.

| Event | Pattern | Intent |
|---|---|---|
| Terce / Sext / None | short double tap, ~60ms apart | glance-free "a little hour" |
| Lauds / Vespers | triple, longer spacing | a major hour |
| Compline | single slow decay, ~900ms envelope | the day is closed |
| Lectio movement change | one soft tick | do not startle |
| Reading marked complete | `selectionClick` | acknowledgement only |

Implementation:
- Baseline: `HapticFeedback.lightImpact` / `mediumImpact` / `selectionClick`.
- Android: `VibrationEffect.createWaveform` with amplitude arrays (API 26+) via the `vibration` package for the real envelopes.
- iOS: `CHHapticEngine` through a platform channel for the Compline decay. `HapticFeedback` alone cannot produce a fade.
- Ship a Settings toggle. Some users pray in company.

A user should be able to tell which hour it is from their pocket, without looking. That is the whole design goal.

### 1.6 Iconography

Thin-stroke line icons only, 1.5px, in `ink` or `secondary`. No filled glyphs, no duotone. Five bottom-nav destinations: Today, Hours, Life, Tools, More.

---

## 2. Content pipeline — build this first

Do this as an **offline build-time step**, not runtime parsing. Nothing in the app works if this is wrong.

### 2.1 The daily-portion discovery

Project Gutenberg ebook **#50040** (Doyle translation, Collegeville 1948) contains the complete traditional daily-portion divisions as inline headers:

```
### Jan. 1—May 2—Sept. 1
### Jan. 2—May 3—Sept. 2
...
### (Feb. 24 in leap year; otherwise added to the preceding)—June 25—Oct. 25
### Feb. 24 (25)—June 26—Oct. 26
...
### Feb. 28 (29)—June 30—Oct. 30
### Mar. 1—July 1—Oct. 31
```

That gives you **122 canonical readings** and their three date keys each, for free. Do not hand-key this table.

### 2.2 Cycle arithmetic

| Cycle | Range | Days |
|---|---|---|
| 1 · Winter | Jan 1 – May 1 | 121 common / 122 leap |
| 2 · Summer | May 2 – Aug 31 | 122 |
| 3 · Autumn | Sep 1 – Dec 31 | 122 |

**Leap-year rule.** Cycles 2 and 3 are unaffected. In cycle 1:
- Common year: reading #56 (the tail of RB 18) merges into the same day as #55. 121 days, 122 readings.
- Leap year: #56 takes Feb 24 alone, and readings #57–#61 shift forward one day (`Feb. 24 (25)` means Feb 24 normally, Feb 25 in a leap year). Mar 1 realigns in both cases.

Write a test that walks all 366 days of a leap year and all 365 of a common year, asserting every day resolves to at least one reading and every reading is reachable.

### 2.3 Translation strategy — read this before you bundle anything

Gutenberg #50040 (Doyle) is public domain **in the United States only**, by copyright non-renewal. The app ships globally. **Do not bundle Doyle.**

Instead:
- **Boniface Verheyen, OSB** (St. Benedict's Abbey, Atchison KS, 1902/1906; 1949 reprint) is the display text. Verheyen died in 1925, so it clears life+70 jurisdictions as well as the US.
- **Doyle #50040 supplies the date table only.** The Jan/May/Sept division is a centuries-old monastic custom, not Collegeville's authorship, and a table of dates is a system rather than protectable expression. Parse the breakpoints from Doyle; apply them to Verheyen.

This means the parser needs an **alignment step**. Chapter boundaries align exactly. The ~60 intra-chapter breaks need matching — do it semi-automatically, then eyeball them once. One afternoon, done permanently.

Ship the **Latin** alongside for the side-by-side mode. Fully public domain.

### 2.4 Pipeline layout

```
tools/content/
  01_fetch.py         # pull raw sources → tools/content/raw/
  02_parse_dates.py   # Doyle → date_table.json (122 readings × 3 date keys)
  03_align.py         # map breakpoints onto Verheyen + Latin
  04_emit.py          # → assets/content/*.json
  05_tts.py           # → audio manifest + mp3s
test/cycle_test.dart  # 366-day coverage assertion
```

Commit the emitted JSON. The pipeline is reproducible but must not run in CI on every build.

---

## 3. Data model

```dart
class RuleReading {
  final int id;                 // 1..122, canonical order
  final int chapter;            // 0 = Prologue, 1..73
  final String chapterTitle;
  final int portionInChapter;   // for "reading 2 of 3"
  final int portionsInChapter;
  final String textEn;          // Verheyen
  final String textLa;
  final String? commentary;
  final String? audioKeyEn;
  final List<String> dateKeys;  // ["01-18","05-19","09-18"]
}

class ReadingCalendar {
  Map<String, List<int>> byDate;        // "MM-DD" → reading ids
  List<int> resolveFor(DateTime d);
  int cycleNumber(DateTime d);          // 1 | 2 | 3
  String cycleLabel(DateTime d);        // "Winter cycle · day 18 of 121"
  Color accentFor(DateTime d);
}

class LifeEpisode {                     // Gregory, Dialogues Bk II
  final int chapter;                    // 1..38
  final String title;
  final String textEn;
  final String? audioKey;
}

class Tool {                            // RB 4
  final int number;                     // 1..72
  final String text;
  final String? gloss;
}

class HourOffice {
  final CanonicalHour hour;
  final List<Psalm> psalms;
  final String hymnKey;
  final String? antiphon;
  final HapticPattern bell;
}
```

Content is bundled JSON, versioned with the app. User state (bookmarks, journal, completion) goes in Isar. **Do not put content in the database.**

---

## 4. Architecture

- **State:** Riverpod (`flutter_riverpod`), a provider per module.
- **Routing:** `go_router`, five bottom-nav destinations.
- **Storage:** `isar` for user state, `shared_preferences` for settings.
- **Audio:** `just_audio` + `audio_service`. Background playback, lock screen, CarPlay, Android Auto. Non-negotiable — much of the listening happens in a car.
- **Notifications:** `flutter_local_notifications`, zoned scheduling for the bells.
- **Haptics:** `vibration` plus a platform channel for iOS Core Haptics.
- **IAP:** RevenueCat, matching the Ridewealth / My Prayer Cards setup.
- **No Firebase, no Supabase in v1.**

```
lib/
  app/            # router, theme, palette, bootstrap
  core/           # date math, cycle resolver, computus, haptics
  data/           # content loaders, isar entities, repositories
  features/
    today/  rule/  life/  hours/  lectio/  tools/  medal/  journal/
  shared/         # widgets, audio controller, typography, drop cap
assets/
  content/  audio/  fonts/
tools/content/
```

---

## 5. Features

### 5.1 Today (home)

Above the fold:
- Date and cycle position: *"Winter cycle · Chapter 7, The Fourth Step of Humility · reading 2 of 3"*
- Illuminated drop cap in the day's liturgical color
- Reading text, typically 100–400 words
- Play button
- Three chips: **Commentary** · **Latin** · **Lectio**

**No streak counter on the home screen.** If completion is tracked at all, put it in a quiet calendar heatmap under More. The Rule is not a habit tracker, and a broken-streak badge is theologically wrong for this app.

Handle the merged day (common-year Feb 24) by stacking both portions with a hairline divider.

### 5.2 Commentary

Two to four sentences per reading. **Do not ship unreviewed LLM output in a devotional app.** Draft from **Paul Delatte OSB, *The Rule of St. Benedict: A Commentary*, trans. Justin McCann (1921)** — public domain, Benedictine, thorough — and write original short glosses from it.

### 5.3 The Hours

Not the full Liturgy of the Hours. That is a separate product.

- Bell notifications at Lauds, Terce, Sext, None, Vespers, Compline. User-set times; lay default 7:00, 9:00, 12:00, 15:00, 18:00, 21:00.
- Each bell opens a **60-second office**: *Deus, in adiutorium meum intende* → one psalm → Glory Be → close.
- **Compline is the anchor and should be built first.** RB 18 fixes it at Psalms 4, 90, and 133 (Vulgate numbering), every day, forever. No calendar logic at all — it is a complete shippable feature in an afternoon.
- **Ora et Labora mode:** surfaces only Terce/Sext/None on weekdays, with a "return to your work" dismissal instead of a full office.

**Psalter: Douay-Rheims (Challoner, 1899).** Public domain, Catholic, and it uses Vulgate numbering — which is what the Rule's psalm numbers refer to. Ship a settings note explaining that RB's "Psalm 90" is the modern Psalm 91; users will ask. Do not use the Grail or the Abbey Psalms and Canticles.

Test scheduled notifications on physical Android hardware early. OEM battery optimization will bite you.

### 5.4 Lectio Divina

Four-movement guided timer over the day's passage: *lectio* → *meditatio* → *oratio* → *contemplatio*. Default 4/4/4/8 minutes, adjustable, soft haptic tick between movements.

Optional journal entry at the end, saved against the reading id so it resurfaces next cycle: *"Four months ago you wrote…"* This is the strongest retention mechanic in the app and it costs almost nothing.

### 5.5 Life of Benedict

Gregory the Great's *Dialogues* Book II, 38 chapters, serialized. Each is 300–900 words. Genuinely gripping — the poisoned loaf and the crow, the broken sieve, Scholastica's storm. Present as a season: *"Episode 12 of 38."* Runs at its own pace, independent of the Rule cycle.

### 5.6 Tools of Good Works

RB 4's 72 instruments as a rotating daily card. Cheap to build, and the most shareable surface in the app. An export-to-image button here is the organic acquisition channel.

### 5.7 The Medal

Highest-search-volume Benedict topic, and nobody has done it well.

- Tap a region of the medal, get the expansion:
  - **C S P B** — *Crux Sancti Patris Benedicti*
  - **C S S M L** — *Crux Sacra Sit Mihi Lux*
  - **N D S M D** — *Non Draco Sit Mihi Dux*
  - **V R S N S M V · S M Q L I V B** — *Vade Retro Satana, Nunquam Suade Mihi Vana; Sunt Mala Quae Libas, Ipse Venena Bibas*
  - **PAX**
- The Jubilee Medal blessing, Latin and English, with a clear note that it is **reserved to a priest**. People get this wrong constantly.
- The Litany of St. Benedict (traditional, PD).
- Short history: Monte Cassino, the 1880 Jubilee Medal, why the medal looks the way it does.

---

## 6. Audio

Reuse the Conclavium tutorial pipeline — OpenAI TTS, `cedar` or a similarly low-warmth voice. At those rates the full library lands in the **$5–15** range:

- 122 Rule readings (~40k words)
- 38 Dialogues episodes (~25k words)
- Compline plus the six short offices
- 72 Tools cards (optional)

**Delivery:** bundle Compline and the current week. Stream and cache the rest from daddoodev.pro or a cheap CDN, with a "download all" on Wi-Fi. Keeps the install under 50 MB.

**Human-voice option:** LibriVox has public-domain recordings — *The Rule of St. Benedict* (English), *Regula Sancti Benedicti* (Latin, read by "bedwere"), Gregory's *Life of St. Benedict* (McMahon), and Forbes' *Saint Benedict*. Quality varies by reader; audition first. LibriVox for the *Life* plus TTS for the daily readings is a reasonable split.

**Chant:** the melodies are public domain, but Solesmes' modern editions carry typographic copyright claims and every individual recording is separately copyrighted. Commission it or use explicitly CC-licensed recordings. Do not assume a chant MP3 is free because the melody is 1,200 years old.

---

## 7. Monetization

**Free forever:** daily Rule reading and audio, Compline, Tools of Good Works, the Medal module.

**One-time unlock — "Oblate", $4.99** (`benedict_daily_oblate`):
- Full horarium, all six bells
- Life of Benedict, all 38 episodes (free tier gets the first 5)
- Lectio journal and cross-cycle resurfacing
- Latin side-by-side
- Full offline audio download

No subscription. This audience will resent one and there is no recurring server cost to justify it.

---

## 8. Build phases

**Phase 0 — Content pipeline.** Scripts written, date table parsed, Verheyen alignment done, JSON emitted, 366-day test green. *No Flutter code yet.*

**Phase 1 — Theme and Today.** Palette, EB Garamond, drop cap widget with the illumination animation, liturgical color resolver with computus, Riverpod, go_router, content loading, Today screen. Ship-quality typography from the start; it is most of the perceived quality.

**Phase 2 — Audio.** `just_audio` + `audio_service`, background playback, lock screen, download manager, TTS batch generated.

**Phase 3 — Compline, then the Hours.** Compline first (no calendar logic), then the haptic bell patterns, then the notification scheduler, then the remaining offices.

**Phase 4 — Lectio and journal.** Timer, movement ticks, Isar journal, cross-cycle resurfacing.

**Phase 5 — Life, Tools, Medal.** Content-heavy, low-risk, mostly reading screens.

**Phase 6 — IAP and polish.** RevenueCat, paywall placement, two-screen onboarding, store assets. Proofread the store listing before submitting — see the "Ridwealth" incident.

---

## 9. Sources

| Source | Use | Status |
|---|---|---|
| Rule, trans. Verheyen (1902/06; 1949 rpt) | Primary display text | PD — Verheyen d. 1925 |
| Rule, trans. Doyle (Collegeville 1948), Gutenberg #50040 | **Date table only** | PD in US via non-renewal |
| Rule, Latin (*Regula Sancti Benedicti*) | Side-by-side | PD |
| Butler, *Sancti Benedicti Regula Monachorum* (1912) | Latin base | PD |
| Gregory, *Dialogues* Bk II, ed. Gardner (1911) | Life of Benedict | PD |
| Delatte, *Commentary*, trans. McCann (1921) | Commentary research | PD |
| Douay-Rheims (Challoner 1899) | Psalter, Vulgate numbering | PD |
| LibriVox: Rule (EN), Regula (LA), Life of St. Benedict, Forbes' *Saint Benedict* | Optional human audio | PD (US) |

**Do not use:** RB 1980 (Liturgical Press), Kardong, McCann's 1952 translation, Zimmerman's 1959 *Dialogues*, the Grail Psalter, the Abbey Psalms and Canticles (2018, USCCB), Solesmes modern chant editions, any commercial chant recording.

**Attribution:** a Sources screen naming every text, translator, and edition, with LibriVox attribution where used. Gutenberg's license requires either keeping its header or stripping all Project Gutenberg branding — since only a date table is extracted, strip it and do not reference the trademark in-app.

I am not a lawyer, and public domain status is jurisdiction-specific. The Verheyen / Gardner / Delatte set is conservative and should be safe for global distribution, but if this becomes a revenue product it is worth an hour with an IP attorney before launch.
