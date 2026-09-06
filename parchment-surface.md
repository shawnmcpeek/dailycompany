# Parchment surface — review note

A proposal, not product law. For review with a reader who has lived in the app.

The app already *implies* paper by color. The question is whether the page should also *feel* like a leaf from an old book, without turning into a costume.

---

## What we have now

Three reading surfaces, all flat fills:

| Name | Role |
|---|---|
| **Vellum** (default) | Warm parchment, iron-gall ink |
| **Paper** | Brighter, still off-white — never pure white |
| **Compline** | Night. Warm near-black, not blue-grey |

EB Garamond on the reading. Sans only on chrome. One illuminated drop cap. Screen changes fade with a slight drift — page-turn-*adjacent*, not a curl.

That reads as a well-set breviary. It does not yet read as **material**: grain, edge, gutter, wear.

---

## The rule for going further

Restraint stays the expressive move.

- No saturated fills
- No leather covers, dust, or animated foxing
- No literal page curl
- Texture belongs on the **page**, not on buttons, nav, or More
- Every house shares one book. Saints’ doors can carry identity later; the leaf does not change color per house

If you can describe the pattern out loud, it is too loud.

---

## What “more like a book” would actually be

### 1. Grain + a slight field *(do this first)*

One looping, low-contrast fiber texture over the whole scaffold, about 4–8% opacity, tinted to match Vellum / Paper / Compline.

Plus a very soft vignette or a two–three stop wash — a hair warmer at the top, cooler toward the bound side. Real parchment is not one hex.

Compline gets a darker, less fibrous grain so night does not look like dirty glass.

This is the single biggest “this is a page” move.

### 2. The reading leaf *(do this second)*

Treat chrome (hallway, tabs, More) as the **cover**. Treat Today, Life, letters, and other readings as a **leaf**:

- Slightly inset from the screen edge
- A 1px hairline
- A 2px inner shadow on the bound (left) side — the gutter
- Optional: a 4–6px fore-edge strip on the right of a reading, stacked page-color, no animation

Margins that behave like a book do more than another cream shade.

### 3. Wear only where a book wears *(optional, later)*

Softer corners on the leaf. A barely-there deckle or foxing on the **right edge of reading screens only**. Not on settings, not on the heatmap.

### 4. Type we already asked for

EB Garamond is doing the age work. Oldstyle figures and small-caps headings (already in the spec) help more than a “medieval” display face. Ink can go a hair warmer than near-black. Junicode stays optional, Latin only.

### 5. Motion we already refused

Keep the fade + drift. If a chapter change ever needs more, an 8px leaf-lift (the next page peeks, then settles) is enough. No curl.

---

## What not to do

- Brown the whole UI
- Texture nav, chips, or paywalls
- Give each saint a different paper
- Full-bleed illuminated borders
- Fantasy-manuscript chrome

Those fight “breviary, not wellness app,” and they will date faster than door portraits.

---

## How it would live in the app

Grain + vignette live in the **theme**, switched with Paper / Vellum / Compline, not painted per screen.

The gutter/edge wrap is only on reading pages (`ReadingScrollView` / `ReadingPage`), not on the hallway or More.

One shared texture asset (or three tints of the same grain). No new fonts required for this pass.

---

## Suggested order, if we do it

1. Grain + vignette on the three surfaces  
2. Reading-leaf gutter and optional fore-edge  
3. Stop. Live with it. Wear only if the leaf still feels like a slab  

Door portraits, when they come, sit on the cover. The text still sits on a page.
