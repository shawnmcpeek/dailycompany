# Portal texts

Content ledger: editions, rights, cadence *guesses*, free practices, never-lists.

Architecture and IAP stay in `portals-spec.md`. Engineering stays in `portal-playbook.md`. Fill the playbook decision record from this sheet, then confirm cadence with a real word count before cutting.

**Do not use this file as a second engine.** Constructed houses copy de Sales (`entries.json` + `calendar.json`). Benedict keeps the traditional date table. IDs match `lib/data/companion.dart`. Per-house SKU `$4.99` + later All Saints — not a single `full_access`.

Rights: **CLEAR** / **VERIFY** / **CONDITIONAL**. Do not start a pipeline until CLEAR, or CONDITIONAL with the cost accepted in the decision record. Status is a working label, not a legal opinion. Test is translator death + edition publication date, not the author's.

Display names never prefix *St.* / *Saint* unless the person is actually canonized. Non-saints use `HouseKind.writer` so hallway chrome reads *Writer*, not an implied saint. App tagline stays *Keep company with a saint*; listing body already says *a saint or spiritual master*.

---

## Shipped

### Benedict of Nursia — `benedict` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *The Rule*, Boniface Verheyen O.S.B. (1902 / 1906; 1949 reprint of 1902). Verheyen d. 1925. |
| Cadence | **122 × 3**, traditional Jan / May / Sept. Benedict is the exception — do not copy this shape. |
| Latin | *Regula*, Latin Library / Butler 1912 base. |
| Anchor | Hours + Lectio (already shipped). |
| Do not use | Doyle's English wording (dates only). Do not ship a 1949 *revision* as if it were 1902. |
| Never-list | Order of Saint Benedict, congregation names, crests, abbey brands. |
| Latin | Latin Library text (Butler 1912 family). Alignment of ch. 2 and 7 repaired in place. Lexical OCR patched against published witnesses (Dysinger / IntraText): `carnis`, `furtum`, `omnino`, footer stripped. Walk: `tools/content/benedict/walk_latin.py`. Pre-repair: `tools/content/benedict/rule_readings.v1-preRepair.json`. |

### Alphonsus Liguori — `liguori` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Visits to the Blessed Sacrament*, Eugene Grimm CSsR, Centenary Edition (Benziger, 1887). **31 visits, no cutter.** 18,872 words (~608/visit). |
| Cadence | **31 × 12**, day-of-month. Provenance `.partlyTraditional`. |
| Short months | Visits 29–31 simply do not occur. **Do not merge.** |
| Anchor | The Visit (manner + spiritual communion + remain). |
| Never-list | Redemptorist, Congregation of the Most Holy Redeemer, order emblem, **Liguori Publications**. "CSsR" only in the translator credit. |
| Also CLEAR | Grimm *Uniformity with God's Will*, *Preparation for Death* — side path, not the daily slot. |

### Francis de Sales — `desales` — VERIFY

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Introduction to the Devout Life*, 366 × 1 (shipped). |
| Translator | **Anonymous.** Rivingtons 1876, *Library of Spiritual Works for English Catholics* (“A New Translation”). Title page names no translator. CCEL hosts this text. **Not Mackey.** Not Ryan (1950). CLEAR — 1876. |
| Also CLEAR | Mackey *Treatise on the Love of God* (1884), *Letters* (1894), *Conferences* (1906) — Letters module uses Mackey. |
| Anchor | Bouquet (select-to-keep). |
| Never-list | Salesian, Visitation, Don Bosco. |

### Thomas à Kempis — `kempis` — CLEAR

| | |
| --- | --- |
| Kind | **Writer.** Never canonized or beatified. Never "St. Thomas à Kempis" in app, store, commentary, or hallway. |
| Daily text | *The Imitation of Christ*, Rev. William Benham (1886), Gutenberg #1653. Benham d. 1910. All four books, including Book IV. |
| Cadence | **366 × 1** (shipped). 114 chapters, 59,423 words. Not Benedict's 122 × 3. |
| Anchor | The Cell (I.20), unguided silence. |
| Commemoration | Death 25 July 1471 — optional later; no feast-driven accent now (accent is by book). |
| Do not use | Croft & Bolton (1940, Image); Knox; Creasy; Tylenda; TAN / Sophia apparatus or chapter titles. |
| Never-list | Canons Regular of St. Augustine, Windesheim, Brothers of the Common Life, shrine/publisher brands. "St." / "Saint" on this name. |
| Authorship | Received attribution. One sentence in Sources is enough. |

---

## Next houses (editorial plan)

Cadence below is a **guess**. Playbook: print `cadence_candidates` on a real count, then lock. Thin books take a repeat or unique thin days — never pad with filler commentary. Copy de Sales unless a traditional division actually exists (Liguori's 31 Visits; Ignatius's program).

### Francis of Assisi — `francis` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | Authentic writings, Paschal Robinson OFM (Dolphin Press, 1905): Admonitions, Rules, Testament, letters, Canticle, etc. Short corpus — **do not pad to 365.** |
| Cadence | **85 × ~4.3.** Real count 27,804 words (~327/entry). Natural units, repeating. The Office of the Passion is five seasonal offices. |
| Second shelf | *Fioretti* (Heywood / Arnold, 1906) as **"Stories told about him"** — never interleaved with the daily writings. Highest name recognition, most crowded aisle. |
| Anchor | Canticle of the Creatures. Free tier: the 28 Admonitions. |
| Never-list | Franciscan, OFM, Capuchin, Conventual emblems. Tau as ornament is fine. |
| Voice | Neutral commentary. A reader should not be able to tell which house the developer likes best. |

### John of the Cross — `john-cross` — CLEAR *(daily-unit call)*

| | |
| --- | --- |
| Kind | Saint |
| Daily text | **Sayings of Light and Love** (and kindred maxims: Precautions, Counsels), David Lewis (1864 / 1889). Atomic — one saying a day, do not bundle to fatten the word count. |
| Not the daily cut | *Ascent*, *Dark Night*, *Canticle*, *Flame* (~275k). A later shelf if wanted — not the opening daily unit. A 300-word slice of the Ascent is close to meaningless. |
| Cadence | **366 × 1**, unique year. Real count 16,270 words (~43/saying); 8 overflow pieces in the index. |
| Do not use | Kavanaugh–Rodriguez ICS (1964–). |
| Never-list | Carmelite, OCD, Discalced emblem. |

### Gregory the Great — `gregory` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Book of Pastoral Rule*, James Barmby, NPNF II.12 (1895). |
| Cadence | **183 × 2.00**. Real count 64,649 words (~353/entry). |
| Do not recut | *Dialogues* Book II already ships as Benedict's Life. **Cross-link the same JSON; do not duplicate.** |
| Optional later | *Moralia* selections (Library of the Fathers, 1844–50) — editorial selection, not a mechanical cut. Homilies if needed. |
| Never-list | None active (predates the orders). |

### Augustine of Hippo — `augustine` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Confessions* I–X, E. B. Pusey (1838). XI–XIII as appendix / Read Through, not the daily year. |
| Cadence | **366 × 1** for I–X after a real count (79,569 words, ~217/day). XI–XIII are a 100-entry appendix, not calendar days. |
| Also CLEAR | Homilies on 1 John (Browne, NPNF I.7, 1888); selected sermons (MacMullen, NPNF I.6, 1888). |
| Do not use | *City of God* as the daily book. |
| Note | Pusey is dense. Clear, and the portal most likely to draw "hard to read" reviews. |
| Never-list | Augustinian, OSA. |

### Teresa of Avila — `teresa-avila` — CLEAR

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Way of Perfection* + *Interior Castle*, Benedictines of Stanbrook / Benedict Zimmerman (1911–12). *Life*, David Lewis (1870), if the year needs a third work. |
| Cadence | **366 × 1** after a real count (104,096 words, ~284/day). Accent by mansion. Never split a dwelling across an entry. |
| Do not use | E. Allison Peers (1946–); ICS Kavanaugh–Rodriguez. Peers is the one a casual search will offer. |
| Anchor | Recollection timer. |
| Never-list | Carmelite, OCD. |

### Ignatius of Loyola — `ignatius` — CLEAR

The `ProgramSpine` exception. Full module table and director note: `portals-spec.md` §10. Do not calendar the Exercises.

| | |
| --- | --- |
| Kind | Saint |
| Program text | *Spiritual Exercises*, Elder Mullan SJ (1909 / 1914 Kenedy). Mullan d. 1925. |
| Also CLEAR | Autobiography, J. F. X. O'Conor SJ (1900); Letters, Rickaby (1914). Autograph Spanish for parallel. |
| Anchor | Examen (short form is the point). |
| Do not use | Puhl (1951); Ganss; Fleming; Loyola Press / IJS apparatus. |
| Never-list | Jesuit, Society of Jesus, IHS emblem. Do not advertise the word "Company" as an Ignatian wink. |
| Required | Director disclaimer before the program starts, kept in About. |

### Thérèse of Lisieux — `therese` — CONDITIONAL — **build last**

| | |
| --- | --- |
| Kind | Saint |
| Daily text | *Story of a Soul*, Thomas N. Taylor (1912) of the **1898 Pauline** *Histoire d'une Âme*. |
| The cost | This is the historically famous edited text, not the 1956 manuscript restoration. State that in provenance, unhedged. |
| Do not use | 1956 *Manuscrits autobiographiques*; Clarke ICS (1975); Knox (1958); any translation of the critical edition. French parallel must be 1898, not a modern manuscript text. |
| Cadence | 365 × 1 after a real count. Letters only from a CLEAR edition. |
| Alternative | License ICS — a real negotiation; do not block other houses on it. |
| Never-list | Carmelite, OCD, Lisieux shrine photography and Office Central de Lisieux imagery. |

---

## Still in the hallway

Listed in `Companions`. No pipeline until a sheet like the ones above is filled and Rights is CLEAR.

| id | Display | Work (hallway) | Kind | Notes |
| --- | --- | --- | --- | --- |
| `catherine` | Catherine of Siena | *The Dialogue* | Saint | |
| `montfort` | Louis de Montfort | *True Devotion to Mary* | Saint | |
| `scupoli` | Lorenzo Scupoli | *The Spiritual Combat* | Writer | Not canonized. |
| `lawrence` | Brother Lawrence | *The Practice of the Presence of God* | Writer | Not canonized. |
| `cassian` | John Cassian | *The Conferences* | Saint | |

Serra is a different content type (`serra.md`) — after the writer houses.

---

## Rights snapshot

| House | Translation | Status |
| --- | --- | --- |
| `benedict` | Verheyen 1902 | CLEAR (shipped) |
| `kempis` | Benham 1886 | CLEAR (shipped) |
| `desales` | Rivingtons 1876 anonymous; Mackey Letters | CLEAR (shipped) |
| `liguori` | Grimm Centenary 1887 | CLEAR (shipped) |
| `francis` | Robinson 1905; Heywood 1906 for Fioretti shelf | CLEAR |
| `john-cross` | Lewis 1864/89 | CLEAR |
| `gregory` | Barmby 1895 | CLEAR |
| `augustine` | Pusey 1838 | CLEAR |
| `teresa-avila` | Stanbrook–Zimmerman 1911–12 | CLEAR |
| `ignatius` | Mullan 1909/14 | CLEAR |
| `therese` | Taylor 1912 / Pauline 1898 | CONDITIONAL |

Foreign first publication after 1900: confirm a US printing of the same edition (Benziger / Kenedy co-pubs are typical). Record the copy in `portal.json`.
