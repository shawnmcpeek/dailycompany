Daily Company — Serra & the Missions Module
===========================================

Status: Deferred. Build after the nine Writer saints ship. Depends on: Life-of-Benedict module (format validation), calendar/cycle resolver, haptic bell engine. Parent spec: `benedict-daily-spec.md`

0. Brief
--------

Serra breaks the app's premise, and that is the point of this document.

"Keep company with a saint and their writing" works for Benedict, Augustine, Teresa, John of the Cross — writers whose legacy is a text. Serra left no treatise, no rule, no method. His corpus is roughly 200 administrative letters, a 1769 expedition diary, and the 1773 Representación to Viceroy Bucareli. Genuine devotion runs through it, but it is threaded into supply requests and personnel disputes with Governor Fages. It cannot carry a daily-portion slot, and the only usable English edition is under copyright anyway (see §7).

He built in stone. So the module is built in stone.

This introduces a second content format. Do not build it as "the Serra screen." Build it as a reusable saint type, or saint #11 forces a rebuild.

Format

Spine

Examples

Writer

Serialized primary text

Benedict, Augustine, Teresa, de Sales, Liguori

Place

Ordered sites + dated journey

Serra, James/Compostela, Xavier, Kateri, Pio

The Place format has legs well past Serra. Design the schema for the second and third one now.

1. Non-goals
------------

-   No geofencing in v1. Considered and cut. This is an armchair pilgrimage — the user travels in the app, not in a car. Geofencing is a possible v2 for the passport (§4.3), never a requirement for the journey.
-   No streak counter on the journey. See §4.4 — the counter rule is specific and non-obvious.
-   No Serra "daily reading." There is no text to serialize. Resist the temptation to portion out his letters; it produces 122 excerpts from mail.
-   No adjudication of the canonization debate. The Sources screen names its editions and their bias plainly (§7). That is the whole treatment.

2. The annual journey
---------------------

The spine is the 1769 overland expedition: Loreto in Baja to San Diego, on foot, with an ulcerated leg Serra refused to have treated.

It runs in real time, once a year, on the historical dates. Same thesis as the Rule cycle — open the app on a day in May and it already knows where he is. No "start journey" button, no plan onboarding, no way to grind ahead.

Departs Loreto

late March 1769

Arrives San Diego

July 1, 1769

Duration

~95 days

Sits alongside

Winter cycle tail + Summer cycle opening

> VERIFY BEFORE EMIT. Exact departure date and the day-by-day leg breakdown must be pulled from Bolton, not from this document. Treat every date here as a placeholder pending that pass.

Each journey day is 150–400 words: where the party is, what happened, one short prayer. Under four minutes, same as everything else.

After July 1 the journey screen goes quiet until the following March. It does not loop. A pilgrimage that repeats immediately is a treadmill.

3. The twenty-one missions
--------------------------

Three acts. The middle act is the answer to "what happened after him," and Lasuén — the better administrator of the two, and unknown to almost everyone — is the reason to build it.

### Act I — Serra's nine (1769–1782)

#

Mission

Founded

Note

1

San Diego de Alcalá

1769

Mother of the Missions

2

San Carlos Borromeo de Carmelo

1770

Serra's headquarters; he is buried under the sanctuary floor

3

San Antonio de Padua

1771

4

San Gabriel Arcángel

1771

Why Los Angeles exists

5

San Luis Obispo de Tolosa

1772

Origin of the red tile roof — see §5

6

San Francisco de Asís (Dolores)

1776

Founded by Palóu under Serra's direction

7

San Juan Capistrano

1776

First attempt 1775 abandoned after the San Diego revolt; refounded by Serra

8

Santa Clara de Asís

1777

Founded by Tomás de la Peña under Serra's direction

9

San Buenaventura

1782

His last

Phrase #6 and #8 deliberately. The nine is conventionally Serra's as founder and president, but two were physically founded by others under his direction, and a sharp-eyed user will write in.

### Act II — Lasuén's nine (1786–1798)

Santa Bárbara · La Purísima Concepción · Santa Cruz · Nuestra Señora de la Soledad · San José · San Juan Bautista · San Miguel Arcángel · San Fernando Rey de España · San Luis Rey de Francia

### Act III — the last three (1804–1823)

Santa Inés · San Rafael Arcángel · San Francisco Solano

> VERIFY BEFORE EMIT. Founding dates and founder attributions for Acts II and III are from general knowledge and have not been checked against Engelhardt. Do a full verification pass before any of this is emitted to JSON.

4. Features
-----------

### 4.1 The journey screen (seasonal, ~95 days/yr)

Today's leg. Position on the route. One prayer. Same typographic treatment as Today — drop cap, EB Garamond, one illuminated capital.

The drop cap here takes the liturgical color of the day, as everywhere else. Do not invent a second color rule for this module.

### 4.2 The mission gallery (always available)

Twenty-one entries, each a reading screen: founding, the site, one or two things worth knowing, the prayer proper to it. Serialized like the Dialogues — "8 of 21."

Free tier: Act I. Oblate unlock: Acts II and III.

### 4.3 The passport (optional, v2)

A lifetime record of missions visited in the world. Manual check-off in v2; geofencing only if it ever justifies the location permission.

### 4.4 The counter rule

Count what the user did. Never count what they read on schedule.

-   "8 of 21 missions" — an episode counter over evergreen content. Fine. Already shipped as a pattern in the Dialogues.
-   "Day 47 of 95" — a calendar counter you can fall behind on. Do not ship. Miss two weeks in June and the number tells the user they failed at a devotion, which is exactly the theological wrongness ruled out for streaks in the parent spec.

The journey screen states where Serra is today. It does not state where the user should have been.

5. Content that carries itself
------------------------------

Load-bearing material, not filler. A partial list to seed the writing pass:

-   San Juan Capistrano — Bouchard's raid, December 1818, sailing under the flag of the United Provinces of Río de la Plata after burning Monterey. The cliff swallows returning around St. Joseph's Day, March 19. The Great Stone Church collapsing in the December 1812 earthquake during Mass, with roughly forty dead, most of them Indian women and children; the ruins still stand. Serra's Chapel — oldest standing building in California, and the only surviving church where he is known to have said Mass.
-   San Luis Obispo — thatch roofs burned by fire arrows, so they fired clay tile instead. That is the origin of the red tile roof, spread from here to the whole chain and eventually to half the state's architecture. Everyone has seen it; nobody knows where it came from.
-   San Juan Bautista — sits directly on the San Andreas fault.
-   San Rafael Arcángel — founded as a hospital, the only one established for medical reasons, for sick neophytes moved out of the San Francisco fog.
-   San Miguel Arcángel — original unretouched interior murals by Esteban Munras.
-   San Gabriel Arcángel — the reason Los Angeles is where it is.
-   San Francisco Solano (Sonoma) — 1823, under Mexico rather than Spain, founded by Altimira without proper authorization and ratified only after the fact. The odd one out, and worth saying so.

6. Prayers
----------

Three, all authentic to the mission tradition rather than imported. Nothing devotional gets invented for this module.

Prayer

Why

Notes

The Alabado

Sung at the missions daily, at dawn and at the end of work. The one devotional artifact genuinely of the place.

Source a PD Spanish text and English translation — Engelhardt prints it. Attribution traditionally to Margil de Jesús; verify.

The Angelus

The bell moment. Reuses the existing haptic engine and notification scheduler at no build cost.

PD.

The Franciscan Crown

Seven decades, the Seven Joys. Properly Franciscan rather than generic.

PD. Long-form; make it opt-in, not a daily default.

The Angelus should fire on the same bell infrastructure as the hours, with its own haptic pattern. Do not build a second scheduler.

7. Sources
----------

Source

Use

Status

Engelhardt, OFM — per-mission monographs (1920s) and The Missions and Missionaries of California (4 vols)

Primary research for §3 and §5

PD — Engelhardt d. 1934

Bolton, ed., Historical Memoirs of New California (UC Press, 1926)

Journey spine; carries Crespí's and Palóu's expedition diaries

PD — US since 2022 (95 yr); life+70 since 2024 (Bolton d. 1953)

Palóu, Relación Histórica (1787), trans. C. Scott Williams (1913)

Biographical framing; more retrospective than Bolton

PD in US

Bancroft, History of California

Second voice / counterweight

PD

HABS measured drawings & photographs (Library of Congress)

Mission imagery

PD — US federal government work

Do not use: Tibesar, Writings of Junípero Serra (1955–66) — vols 1–3 are PD in the US via non-renewal, but Tibesar d. 1992 puts them under copyright in life+70 jurisdictions until ~2062, and vol. 4 is in copyright everywhere. This is the same trap as Doyle. Also excluded: Geiger's Palou's Life of Junípero Serra (1955), Hackel, any modern mission guidebook, and any contemporary photograph of a mission — these are active parishes and the images belong to whoever took them. HABS is the clean route, and its line quality suits the thin-stroke iconography better than photography would.

Attribution note for the Sources screen. Engelhardt is a Franciscan partisan and the app should say so in one line — not as a disclaimer, as scholarship. Naming an editor's standpoint is what a serious sources page does, and it costs nothing.

8. Data model
-------------

Generalized. `PlaceSaint` is the type; Serra is the first instance.

    enum SaintFormat { writer, place }
    
    class SaintModule {
      final String id;                    // 'benedict', 'serra'
      final SaintFormat format;
      final String displayName;
    }
    
    class PlaceSaint {
      final String saintId;
      final List<PlaceStop> stops;        // the 21
      final Journey? journey;             // null for place-saints without a dated route
      final List<PrayerRef> prayers;
    }
    
    class PlaceStop {
      final int order;                    // 1..21
      final String name;
      final int foundedYear;
      final String foundedBy;
      final int act;                      // 1 | 2 | 3
      final String textEn;
      final String? prayerKey;
      final String? audioKey;
      final String? habsImageKey;
      final double lat, lon;              // gallery map + possible v2 passport
    }
    
    class Journey {
      final String saintId;
      final String startDateKey;          // "MM-DD"
      final String endDateKey;
      final List<JourneyDay> days;
      bool isActiveOn(DateTime d);
      JourneyDay? resolveFor(DateTime d);
    }
    
    class JourneyDay {
      final int dayIndex;
      final String dateKey;               // "MM-DD"
      final String location;
      final String textEn;
      final String? prayerKey;
    }
    

Journey progress is derived from the date, not stored. Gallery completion goes in Isar alongside Dialogues episode state — same table if the shape allows.

9. Pipeline additions
---------------------

    tools/content/
      06_missions.py      # Engelhardt → mission_stops.json (21 entries)
      07_journey.py       # Bolton → journey_days.json (~95 entries)
      08_habs.py          # LoC HABS fetch → assets/img/missions/
    test/journey_test.dart  # every day in the window resolves; window is inert outside it
    

Same rule as the parent spec: commit the emitted JSON, do not run the pipeline in CI.

10. Build phases
----------------

Phase 7 — Gallery. The 21 as reading screens, Act I free. Content-heavy, low-risk, no new machinery. Ships on its own.

Phase 8 — Journey. Date window resolver, journey screen, the seasonal go-quiet behavior.

Phase 9 — Prayers. Alabado, Angelus on the existing bell engine, Franciscan Crown.

Phase 10 — Passport. Manual check-off. Geofencing only if it earns the permission prompt.

11. Open questions
------------------

1.  Does the Life-of-Benedict module actually hold attention past episode 12? If not, reconsider this whole format before writing 21 entries.
2.  Alabado text — is there a clean PD English translation, or does one need commissioning?
3.  Does the journey want audio? ~95 days at 150–400 words is roughly 25k words of TTS, comparable to the Dialogues, so cost is not the blocker — attention is.
4.  Should Act I ship free and Acts II–III paid, or the whole gallery free with the journey as the unlock? The journey is the differentiated thing.