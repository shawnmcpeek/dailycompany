# Daily Company — Device QA

Use this checklist before a store build. Automate what you can on Linux; confirm bells and haptics on real phones.

## Environment

```bash
cd ~/Documents/github/benedictdaily
flutter devices
flutter analyze
flutter test
```

Plug in Android USB debugging, or open an iOS Simulator / device from Xcode.

---

## 1. Cold start & onboarding

- [ ] Fresh install (or More → Replay welcome): Welcome → How this works → hub
- [ ] Second launch skips welcome and opens hub
- [ ] Hub shows **Go to** with clear **Open** buttons (Today / Hours / Life / Tools / More)

---

## 2. Hub & navigation

- [ ] Each hub **Open** button lands in the right area
- [ ] Bottom nav: Home / Today / Hours / Life / Tools
- [ ] More is reachable from the hub (pushed route)
- [ ] Hub Hours subtitle reflects custom Compline time (or Ora et Labora / Terce)

---

## 3. Today

- [ ] Date, cycle label, reading headline correct
- [ ] Drop cap illuminates once per day (not again after leaving and returning)
- [ ] Reduce-motion / disable animations: no illumination animation
- [ ] Commentary / Latin / Lectio chips work
- [ ] Aa sheet: Paper / Vellum / Compline / System, text size, bold reading
- [ ] Common-year Feb 24 (if testing that date): stacked portions with divider

---

## 4. Hours & bells (physical device)

Defaults: Lauds 07:00 · Terce 09:00 · Sext 12:00 · None 15:00 · Vespers 18:00 · Compline 21:00

- [ ] Hours list shows **your** times (not only JSON defaults)
- [ ] Clock icon / AppBar time opens time picker; change sticks after restart
- [ ] **Bell notifications** toggle on → OS permission prompt accepted
- [ ] Set one office **2–3 minutes ahead** → notification fires
- [ ] Tapping the notification opens that office
- [ ] Ora et Labora on → only Terce / Sext / None listed and scheduled
- [ ] Bells off → no further scheduled bells
- [ ] Compline (and other offices) open with psalms; Amen / Return to work works
- [ ] Haptic on Amen when Haptic bells is enabled

### Android-specific

- [ ] After reboot, bells still fire (boot receiver)
- [ ] If missed: OEM battery → allow unrestricted / disable battery optimization for Daily Company
- [ ] Exact alarms: Settings → Apps → Daily Company → Alarms & reminders (Android 12+)

### iOS-specific

- [ ] Notification permission granted
- [ ] Scheduled notification appears at local time
- [ ] Compline Amen: soft decaying Core Haptic (not a single tap)
- [ ] Lectio movement tick feels like a light selection pulse

### Desktop note

Linux/Windows may skip exact zoned schedules; treat mobile as source of truth for bells.

---

## 5. Lectio

- [ ] Durations 1–20 min per movement; persist across relaunch
- [ ] Pause required to adjust sliders while running
- [ ] Begin / Pause / Next movement; haptic between movements
- [ ] Journal save; “From a past cycle” after an older entry exists for that reading id

---

## 6. Life / Tools / Medal / More

- [ ] Life: episode list and reader
- [ ] Tools: today’s instrument; **Share image** preview → system share sheet; **Copy text**
- [ ] Medal: text sections (letters, blessing note, litany, history)
- [ ] More: display settings, haptic / bells / Ora et Labora / Latin
- [ ] More → Sources: editions listed; disclaimer present
- [ ] Copyright line shows current year correctly

---

## 7. Branding & chrome

- [ ] Launcher icon / splash on Android and iOS
- [ ] Display name: Daily Company
- [ ] No Abbey / OSB / medal-as-icon branding

---

## 8. Pre-submit smoke

- [ ] `flutter build appbundle` (Play) / archive from Xcode (App Store)
- [ ] Store copy from `store/listing_copy.txt` pasted and proofread
- [ ] Privacy policy URL live
- [ ] Disclaimer in store description matches About / Sources

---

## Quick “bells only” pass (5 minutes)

1. Install on phone  
2. Hours → enable bells → allow permission  
3. Set Compline to now + 2 minutes  
4. Lock phone; wait for notification  
5. Tap → Compline opens  
6. Amen with haptics on  

If that path works, notification plumbing is healthy.
