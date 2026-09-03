import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:dailycompany/core/cycle/life_track.dart';
import 'package:dailycompany/data/models/desales_letter.dart';
import 'package:dailycompany/data/models/desales_meditation.dart';
import 'package:dailycompany/data/models/francis_admonition.dart';
import 'package:dailycompany/data/models/francis_canticle.dart';
import 'package:dailycompany/data/models/francis_story.dart';
import 'package:dailycompany/data/models/john_precaution.dart';
import 'package:dailycompany/data/models/ignatius_content.dart';
import 'package:dailycompany/data/models/kempis_admonition.dart';
import 'package:dailycompany/data/models/liguori_manner.dart';
import 'package:dailycompany/core/diagnostics/diagnostics_log.dart';
import 'package:dailycompany/core/diagnostics/journal_failure_reporter.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/notifications/aspiration_scheduler.dart';
import 'package:dailycompany/core/notifications/bell_scheduler.dart';
import 'package:dailycompany/core/notifications/canticle_scheduler.dart';
import 'package:dailycompany/core/notifications/cell_scheduler.dart';
import 'package:dailycompany/core/notifications/cycle_reminder_scheduler.dart';
import 'package:dailycompany/core/notifications/visit_scheduler.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/isar/app_isar.dart';
import 'package:dailycompany/data/isar/bouquet.dart';
import 'package:dailycompany/data/isar/lectio_journal_entry.dart';
import 'package:dailycompany/data/isar/reading_completion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// The one portal in play right now. Derives from the chosen house until
/// there's a picker that can set it to something other than 'benedict'.
final currentPortalIdProvider = Provider<String>((ref) {
  final companionId = ref.watch(settingsProvider).companionId;
  return companionId.isEmpty ? 'benedict' : companionId;
});

/// Benedict's content only — RuleReading/Latin/Life/Tools/Hours/Medal don't
/// apply to any other portal. Cycle portals use [cycleCalendarProvider].
final contentCatalogProvider = FutureProvider<ContentCatalog>((ref) async {
  final portalId = ref.watch(currentPortalIdProvider);
  return ContentCatalog.load(portalId);
});

final cycleCalendarProvider = FutureProvider.family<CycleCalendar, String>((
  ref,
  portalId,
) async {
  return CycleCalendar.load(portalId);
});

final desalesCalendarProvider = FutureProvider<CycleCalendar>((ref) async {
  return ref.watch(cycleCalendarProvider('desales').future);
});

final desalesMeditationsProvider = FutureProvider<List<DesalesMeditation>>((
  ref,
) async {
  return DesalesMeditation.loadFromAssets();
});

final desalesLettersProvider = FutureProvider<List<DesalesLetterBook>>((
  ref,
) async {
  return DesalesLetterBook.loadFromAssets();
});

final kempisAdmonitionsProvider = FutureProvider<KempisAdmonitions>((
  ref,
) async {
  return KempisAdmonitions.loadFromAssets();
});

final liguoriMannerProvider = FutureProvider<LiguoriManner>((ref) async {
  return LiguoriManner.loadFromAssets();
});

final francisAdmonitionsProvider = FutureProvider<FrancisAdmonitions>((
  ref,
) async {
  return FrancisAdmonitions.loadFromAssets();
});

final francisStoriesProvider = FutureProvider<FrancisStories>((ref) async {
  return FrancisStories.loadFromAssets();
});

final francisCanticleProvider = FutureProvider<FrancisCanticle>((ref) async {
  return FrancisCanticle.loadFromAssets();
});

final johnPrecautionsProvider = FutureProvider<JohnPrecautions>((ref) async {
  return JohnPrecautions.loadFromAssets();
});

final ignatiusRulesProvider = FutureProvider<IgnatiusRules>((ref) async {
  return IgnatiusRules.loadFromAssets();
});

final ignatiusProgramProvider = FutureProvider<IgnatiusProgram>((ref) async {
  return IgnatiusProgram.loadFromAssets();
});

final ignatiusPrayersProvider = FutureProvider<IgnatiusPrayers>((ref) async {
  return IgnatiusPrayers.loadFromAssets();
});

/// Unlock for the active portal's paid cycle (Today + Read Through).
final cycleUnlockedProvider = Provider<bool>((ref) {
  final portalId = ref.watch(currentPortalIdProvider);
  return switch (portalId) {
    'benedict' => ref.watch(oblateUnlockedProvider),
    'desales' => ref.watch(desalesCompanionUnlockedProvider),
    'kempis' => ref.watch(kempisCompanionUnlockedProvider),
    'liguori' => ref.watch(liguoriCompanionUnlockedProvider),
    'francis' => ref.watch(francisCompanionUnlockedProvider),
    'john-cross' => ref.watch(johnCrossCompanionUnlockedProvider),
    'gregory' => ref.watch(gregoryCompanionUnlockedProvider),
    'augustine' => ref.watch(augustineCompanionUnlockedProvider),
    'teresa-avila' => ref.watch(teresaAvilaCompanionUnlockedProvider),
    'ignatius' => ref.watch(ignatiusCompanionUnlockedProvider),
    'therese' => ref.watch(thereseCompanionUnlockedProvider),
    'catherine' => ref.watch(catherineCompanionUnlockedProvider),
    'montfort' => ref.watch(montfortCompanionUnlockedProvider),
    'scupoli' => ref.watch(scupoliCompanionUnlockedProvider),
    'lawrence' => ref.watch(lawrenceCompanionUnlockedProvider),
    'cassian' => ref.watch(cassianCompanionUnlockedProvider),
    _ => false,
  };
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    return SettingsController();
  },
);

/// Keeps scheduled office bells aligned with settings and Oblate unlock.
final bellSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    BellScheduler.instance.reschedule(
      settings,
      hasOblate: ref.read(oblateUnlockedProvider),
    );
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
  ref.listen<bool>(oblateUnlockedProvider, (_, _) => sync());
});

/// Keeps de Sales' aspiration notifications topped up — see
/// [AspirationScheduler] for why this reschedules a rolling window
/// rather than one exact recurring time per slot.
final desalesAspirationSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    AspirationScheduler.instance.reschedule(settings);
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
});

/// Keeps Kempis' Cell hour aligned with settings.
final kempisCellSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    CellScheduler.instance.reschedule(settings);
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
});

/// Keeps Liguori's Visit hour aligned with settings.
final liguoriVisitSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    VisitScheduler.instance.reschedule(settings);
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
});

/// Keeps Francis' Canticle reminder aligned with settings.
final francisCanticleSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    CanticleScheduler.instance.reschedule(settings);
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
});

/// Keeps John / Gregory / Augustine / Teresa reminders aligned.
final cycleReminderSyncProvider = Provider<void>((ref) {
  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.ready) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    for (final spec in CycleReminderScheduler.specs.values) {
      final portalId = spec.portalId;
      String? body = spec.title;
      if (portalId != 'ignatius' && portalId != 'ignatius-evening') {
        final cal = ref.read(cycleCalendarProvider(portalId)).valueOrNull;
        if (cal != null) {
          final entries = cal.resolveFor(day);
          if (entries.isNotEmpty) body = entries.first.chapterTitle;
        }
      }
      CycleReminderScheduler.instance.reschedule(
        settings,
        portalId: portalId,
        body: body,
      );
    }
  }

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    if (!next.ready) return;
    sync();
  });
  for (final id in CycleReminderScheduler.specs.keys) {
    if (id == 'ignatius-evening') continue;
    ref.listen(cycleCalendarProvider(id), (_, _) => sync());
  }
});

class AppSettings {
  const AppSettings({
    this.ready = false,
    this.onboardingComplete = false,
    this.hapticsEnabled = true,
    this.bellsEnabled = false,
    this.oraEtLabora = false,
    this.showLatin = false,
    this.themeMode = 'vellum',
    this.fontScale = 1.0,
    this.boldReading = false,
    this.officeTimes = const {},
    this.lectioMinutes = 4,
    this.meditatioMinutes = 4,
    this.oratioMinutes = 4,
    this.contemplatioMinutes = 8,
    this.showReadingRun = true,
    this.medalOpened = false,
    this.companionId = '',
    this.dailyTrack = DailyTrack.life,
    this.lifeTrackStart = '',
    this.desalesAspirationsEnabled = false,
    this.aspirationTimes = const {},
    this.readThroughByPortal = const {},
    this.readThroughCursorByPortal = const {},
    this.kempisCellEnabled = false,
    this.kempisCellTime = '20:00',
    this.liguoriVisitEnabled = false,
    this.liguoriVisitTime = '12:00',
    this.francisCanticleEnabled = false,
    this.francisCanticleTime = '07:00',
    this.cycleReminderEnabled = const {},
    this.cycleReminderTime = const {},
    this.ignatiusProgramStart = '',
    this.ignatiusProgramPaused = false,
    this.ignatiusElapsedWhenPaused = 0,
    this.ignatiusDirectorAcked = false,
  });

  /// False until SharedPreferences have been read.
  final bool ready;
  final bool onboardingComplete;
  final bool hapticsEnabled;
  final bool bellsEnabled;
  final bool oraEtLabora;
  final bool showLatin;

  /// paper | vellum | compline | system
  final String themeMode;
  final double fontScale;
  final bool boldReading;

  /// Office id → `HH:mm`. Missing keys fall back to [BellScheduler.defaultTimes].
  final Map<String, String> officeTimes;

  final int lectioMinutes;
  final int meditatioMinutes;
  final int oratioMinutes;
  final int contemplatioMinutes;

  /// Quiet present/longest run under the reading calendar (never on Today).
  final bool showReadingRun;

  /// True after the header medal has been opened once.
  final bool medalOpened;

  /// Chosen house in the hallway. Empty until the first enter.
  final String companionId;

  /// Life (default), Rule, or both on Today.
  final DailyTrack dailyTrack;

  /// `yyyy-MM-dd` the Life cycle began. Empty until prefs load.
  final String lifeTrackStart;

  /// de Sales only — three or four light "aspiration" reminders a day.
  final bool desalesAspirationsEnabled;

  /// Slot id (`a1`, `a2`, `a3`) → `HH:mm`. Missing keys fall back to
  /// [AspirationScheduler.defaultTimes].
  final Map<String, String> aspirationTimes;

  /// Read Through mode, keyed by portal id. Spec §3.4: switching never
  /// resets the calendar path.
  final Map<String, bool> readThroughByPortal;

  /// 1-indexed Read Through cursor per portal.
  final Map<String, int> readThroughCursorByPortal;

  /// Kempis only — the Cell hour of withdrawal.
  final bool kempisCellEnabled;

  /// `HH:mm` for the Cell notification. Default 20:00.
  final String kempisCellTime;

  /// Liguori only — one Visit reminder a day.
  final bool liguoriVisitEnabled;

  /// `HH:mm` for the Visit notification. Default 12:00.
  final String liguoriVisitTime;

  /// Francis only — one Canticle reminder a day.
  final bool francisCanticleEnabled;

  /// `HH:mm` for the Canticle notification. Default 07:00.
  final String francisCanticleTime;

  /// Optional daily reminder, keyed by portal id. Off by default.
  final Map<String, bool> cycleReminderEnabled;

  /// `HH:mm` per portal. Missing keys fall back to [reminderDefaultFor].
  final Map<String, String> cycleReminderTime;

  /// Ignatius Exercises program — ISO `yyyy-MM-dd`, empty until begun.
  final String ignatiusProgramStart;
  final bool ignatiusProgramPaused;
  final int ignatiusElapsedWhenPaused;
  final bool ignatiusDirectorAcked;

  static const reminderDefaults = <String, String>{
    'john-cross': '07:00',
    'gregory': '08:00',
    'augustine': '21:00',
    'teresa-avila': '07:00',
    'ignatius': '12:30',
    'ignatius-evening': '21:00',
    'therese': '07:00',
    'catherine': '07:00',
    'montfort': '07:00',
    'scupoli': '07:00',
    'lawrence': '08:00',
    'cassian': '08:00',
  };

  bool reminderEnabledFor(String portalId) =>
      cycleReminderEnabled[portalId] ?? false;

  String reminderTimeFor(String portalId) =>
      cycleReminderTime[portalId] ?? reminderDefaults[portalId] ?? '08:00';

  /// Days since program start, frozen while paused. `-1` if not started.
  int ignatiusElapsedDays(DateTime today) {
    if (ignatiusProgramStart.isEmpty) return -1;
    if (ignatiusProgramPaused) return ignatiusElapsedWhenPaused;
    final parts = ignatiusProgramStart.split('-');
    if (parts.length != 3) return -1;
    final start = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final day = DateTime(today.year, today.month, today.day);
    return day.difference(start).inDays;
  }

  static String _isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool readThroughFor(String portalId) =>
      readThroughByPortal[portalId] ?? false;

  int readThroughCursorFor(String portalId) =>
      readThroughCursorByPortal[portalId] ?? 1;

  /// de Sales only — straight-through reading instead of the calendar.
  bool get desalesReadThrough => readThroughFor('desales');

  int get desalesReadThroughCursor => readThroughCursorFor('desales');

  DateTime get lifeStart {
    if (lifeTrackStart.isEmpty) {
      final n = DateTime.now();
      return DateTime(n.year, n.month, n.day);
    }
    return LifeTrack.parseStart(lifeTrackStart);
  }

  String timeForOffice(String id) =>
      officeTimes[id] ?? BellScheduler.defaultTimes[id] ?? '12:00';

  String timeForAspiration(String id) =>
      aspirationTimes[id] ?? AspirationScheduler.defaultTimes[id] ?? '12:00';

  int minutesForMovement(String key) => switch (key) {
    'lectio' => lectioMinutes,
    'meditatio' => meditatioMinutes,
    'oratio' => oratioMinutes,
    'contemplatio' => contemplatioMinutes,
    _ => 4,
  };

  AppSettings copyWith({
    bool? ready,
    bool? onboardingComplete,
    bool? hapticsEnabled,
    bool? bellsEnabled,
    bool? oraEtLabora,
    bool? showLatin,
    String? themeMode,
    double? fontScale,
    bool? boldReading,
    Map<String, String>? officeTimes,
    int? lectioMinutes,
    int? meditatioMinutes,
    int? oratioMinutes,
    int? contemplatioMinutes,
    bool? showReadingRun,
    bool? medalOpened,
    String? companionId,
    DailyTrack? dailyTrack,
    String? lifeTrackStart,
    bool? desalesAspirationsEnabled,
    Map<String, String>? aspirationTimes,
    Map<String, bool>? readThroughByPortal,
    Map<String, int>? readThroughCursorByPortal,
    bool? kempisCellEnabled,
    String? kempisCellTime,
    bool? liguoriVisitEnabled,
    String? liguoriVisitTime,
    bool? francisCanticleEnabled,
    String? francisCanticleTime,
    Map<String, bool>? cycleReminderEnabled,
    Map<String, String>? cycleReminderTime,
    String? ignatiusProgramStart,
    bool? ignatiusProgramPaused,
    int? ignatiusElapsedWhenPaused,
    bool? ignatiusDirectorAcked,
  }) => AppSettings(
    ready: ready ?? this.ready,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    bellsEnabled: bellsEnabled ?? this.bellsEnabled,
    oraEtLabora: oraEtLabora ?? this.oraEtLabora,
    showLatin: showLatin ?? this.showLatin,
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    boldReading: boldReading ?? this.boldReading,
    officeTimes: officeTimes ?? this.officeTimes,
    lectioMinutes: lectioMinutes ?? this.lectioMinutes,
    meditatioMinutes: meditatioMinutes ?? this.meditatioMinutes,
    oratioMinutes: oratioMinutes ?? this.oratioMinutes,
    contemplatioMinutes: contemplatioMinutes ?? this.contemplatioMinutes,
    showReadingRun: showReadingRun ?? this.showReadingRun,
    medalOpened: medalOpened ?? this.medalOpened,
    companionId: companionId ?? this.companionId,
    dailyTrack: dailyTrack ?? this.dailyTrack,
    lifeTrackStart: lifeTrackStart ?? this.lifeTrackStart,
    desalesAspirationsEnabled:
        desalesAspirationsEnabled ?? this.desalesAspirationsEnabled,
    aspirationTimes: aspirationTimes ?? this.aspirationTimes,
    readThroughByPortal: readThroughByPortal ?? this.readThroughByPortal,
    readThroughCursorByPortal:
        readThroughCursorByPortal ?? this.readThroughCursorByPortal,
    kempisCellEnabled: kempisCellEnabled ?? this.kempisCellEnabled,
    kempisCellTime: kempisCellTime ?? this.kempisCellTime,
    liguoriVisitEnabled: liguoriVisitEnabled ?? this.liguoriVisitEnabled,
    liguoriVisitTime: liguoriVisitTime ?? this.liguoriVisitTime,
    francisCanticleEnabled:
        francisCanticleEnabled ?? this.francisCanticleEnabled,
    francisCanticleTime: francisCanticleTime ?? this.francisCanticleTime,
    cycleReminderEnabled: cycleReminderEnabled ?? this.cycleReminderEnabled,
    cycleReminderTime: cycleReminderTime ?? this.cycleReminderTime,
    ignatiusProgramStart: ignatiusProgramStart ?? this.ignatiusProgramStart,
    ignatiusProgramPaused: ignatiusProgramPaused ?? this.ignatiusProgramPaused,
    ignatiusElapsedWhenPaused:
        ignatiusElapsedWhenPaused ?? this.ignatiusElapsedWhenPaused,
    ignatiusDirectorAcked: ignatiusDirectorAcked ?? this.ignatiusDirectorAcked,
  );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var theme = prefs.getString('themeMode') ?? 'vellum';
    // Migrate old "light" key to vellum.
    if (theme == 'light') theme = 'vellum';

    final times = Map<String, String>.from(BellScheduler.defaultTimes);
    final rawTimes = prefs.getString('officeTimes');
    if (rawTimes != null) {
      final decoded = jsonDecode(rawTimes) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        times[e.key] = e.value as String;
      }
    }

    final aspTimes = Map<String, String>.from(AspirationScheduler.defaultTimes);
    final rawAspTimes = prefs.getString('aspirationTimes');
    if (rawAspTimes != null) {
      final decoded = jsonDecode(rawAspTimes) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        aspTimes[e.key] = e.value as String;
      }
    }

    var lifeStart = prefs.getString('lifeTrackStart') ?? '';
    if (lifeStart.isEmpty) {
      lifeStart = CompletionController.keyFor(DateTime.now());
      await prefs.setString('lifeTrackStart', lifeStart);
    }

    state = AppSettings(
      ready: true,
      onboardingComplete: prefs.getBool('onboardingComplete') ?? false,
      hapticsEnabled: prefs.getBool('hapticsEnabled') ?? true,
      bellsEnabled: prefs.getBool('bellsEnabled') ?? false,
      oraEtLabora: prefs.getBool('oraEtLabora') ?? false,
      showLatin: prefs.getBool('showLatin') ?? false,
      themeMode: theme,
      fontScale: prefs.getDouble('fontScale') ?? 1.0,
      boldReading: prefs.getBool('boldReading') ?? false,
      officeTimes: times,
      lectioMinutes: prefs.getInt('lectioMinutes') ?? 4,
      meditatioMinutes: prefs.getInt('meditatioMinutes') ?? 4,
      oratioMinutes: prefs.getInt('oratioMinutes') ?? 4,
      contemplatioMinutes: prefs.getInt('contemplatioMinutes') ?? 8,
      showReadingRun: prefs.getBool('showReadingRun') ?? true,
      medalOpened: prefs.getBool('medalOpened') ?? false,
      companionId: prefs.getString('companionId') ?? '',
      dailyTrack: DailyTrackX.fromStorage(prefs.getString('dailyTrack')),
      lifeTrackStart: lifeStart,
      desalesAspirationsEnabled:
          prefs.getBool('desalesAspirationsEnabled') ?? false,
      aspirationTimes: aspTimes,
      readThroughByPortal: _loadReadThroughMap(prefs),
      readThroughCursorByPortal: _loadReadThroughCursorMap(prefs),
      kempisCellEnabled: prefs.getBool('kempisCellEnabled') ?? false,
      kempisCellTime: prefs.getString('kempisCellTime') ?? '20:00',
      liguoriVisitEnabled: prefs.getBool('liguoriVisitEnabled') ?? false,
      liguoriVisitTime: prefs.getString('liguoriVisitTime') ?? '12:00',
      francisCanticleEnabled: prefs.getBool('francisCanticleEnabled') ?? false,
      francisCanticleTime: prefs.getString('francisCanticleTime') ?? '07:00',
      cycleReminderEnabled: _loadBoolMap(prefs, 'cycleReminderEnabled'),
      cycleReminderTime: _loadStringMap(prefs, 'cycleReminderTime'),
      ignatiusProgramStart: prefs.getString('ignatiusProgramStart') ?? '',
      ignatiusProgramPaused: prefs.getBool('ignatiusProgramPaused') ?? false,
      ignatiusElapsedWhenPaused:
          prefs.getInt('ignatiusElapsedWhenPaused') ?? 0,
      ignatiusDirectorAcked: prefs.getBool('ignatiusDirectorAcked') ?? false,
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    (await SharedPreferences.getInstance()).setBool('onboardingComplete', true);
  }

  Future<void> resetOnboarding() async {
    state = state.copyWith(onboardingComplete: false);
    (await SharedPreferences.getInstance()).setBool(
      'onboardingComplete',
      false,
    );
  }

  Future<void> setHaptics(bool v) async {
    state = state.copyWith(hapticsEnabled: v);
    (await SharedPreferences.getInstance()).setBool('hapticsEnabled', v);
  }

  Future<void> setBellsEnabled(bool v) async {
    state = state.copyWith(bellsEnabled: v);
    (await SharedPreferences.getInstance()).setBool('bellsEnabled', v);
  }

  Future<void> setOraEtLabora(bool v) async {
    state = state.copyWith(oraEtLabora: v);
    (await SharedPreferences.getInstance()).setBool('oraEtLabora', v);
  }

  Future<void> setShowLatin(bool v) async {
    state = state.copyWith(showLatin: v);
    (await SharedPreferences.getInstance()).setBool('showLatin', v);
  }

  Future<void> setShowReadingRun(bool v) async {
    state = state.copyWith(showReadingRun: v);
    (await SharedPreferences.getInstance()).setBool('showReadingRun', v);
  }

  Future<void> markMedalOpened() async {
    if (state.medalOpened) return;
    state = state.copyWith(medalOpened: true);
    (await SharedPreferences.getInstance()).setBool('medalOpened', true);
  }

  Future<void> setCompanion(String id) async {
    state = state.copyWith(companionId: id);
    (await SharedPreferences.getInstance()).setString('companionId', id);
  }

  Future<void> setDailyTrack(DailyTrack v) async {
    state = state.copyWith(dailyTrack: v);
    (await SharedPreferences.getInstance()).setString('dailyTrack', v.name);
  }

  Future<void> restartLifeTrack() async {
    final key = CompletionController.keyFor(DateTime.now());
    state = state.copyWith(lifeTrackStart: key);
    (await SharedPreferences.getInstance()).setString('lifeTrackStart', key);
  }

  Future<void> setDesalesReadThrough(bool v) => setReadThrough('desales', v);

  Future<void> setDesalesReadThroughCursor(int v) =>
      setReadThroughCursor('desales', v);

  Future<void> setReadThrough(String portalId, bool v) async {
    final next = Map<String, bool>.from(state.readThroughByPortal)
      ..[portalId] = v;
    state = state.copyWith(readThroughByPortal: next);
    (await SharedPreferences.getInstance()).setString(
      'readThroughByPortal',
      jsonEncode(next),
    );
  }

  Future<void> setReadThroughCursor(String portalId, int v) async {
    final next = Map<String, int>.from(state.readThroughCursorByPortal)
      ..[portalId] = v;
    state = state.copyWith(readThroughCursorByPortal: next);
    (await SharedPreferences.getInstance()).setString(
      'readThroughCursorByPortal',
      jsonEncode(next),
    );
  }

  Future<void> setDesalesAspirationsEnabled(bool v) async {
    state = state.copyWith(desalesAspirationsEnabled: v);
    (await SharedPreferences.getInstance()).setBool(
      'desalesAspirationsEnabled',
      v,
    );
  }

  Future<void> setAspirationTime(String slotId, TimeOfDayCompat time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final next = Map<String, String>.from(state.aspirationTimes)
      ..[slotId] = '$hh:$mm';
    state = state.copyWith(aspirationTimes: next);
    (await SharedPreferences.getInstance()).setString(
      'aspirationTimes',
      jsonEncode(next),
    );
  }

  Future<void> setThemeMode(String v) async {
    state = state.copyWith(themeMode: v);
    (await SharedPreferences.getInstance()).setString('themeMode', v);
  }

  Future<void> setFontScale(double v) async {
    final clamped = v.clamp(0.85, 1.45);
    state = state.copyWith(fontScale: clamped);
    (await SharedPreferences.getInstance()).setDouble('fontScale', clamped);
  }

  Future<void> setBoldReading(bool v) async {
    state = state.copyWith(boldReading: v);
    (await SharedPreferences.getInstance()).setBool('boldReading', v);
  }

  Future<void> setOfficeTime(String officeId, TimeOfDayCompat time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final next = Map<String, String>.from(state.officeTimes)
      ..[officeId] = '$hh:$mm';
    state = state.copyWith(officeTimes: next);
    (await SharedPreferences.getInstance()).setString(
      'officeTimes',
      jsonEncode(next),
    );
  }

  Future<void> setKempisCellEnabled(bool v) async {
    state = state.copyWith(kempisCellEnabled: v);
    (await SharedPreferences.getInstance()).setBool('kempisCellEnabled', v);
  }

  Future<void> setKempisCellTime(TimeOfDayCompat time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final next = '$hh:$mm';
    state = state.copyWith(kempisCellTime: next);
    (await SharedPreferences.getInstance()).setString('kempisCellTime', next);
  }

  Future<void> setLiguoriVisitEnabled(bool v) async {
    state = state.copyWith(liguoriVisitEnabled: v);
    (await SharedPreferences.getInstance()).setBool('liguoriVisitEnabled', v);
  }

  Future<void> setLiguoriVisitTime(TimeOfDayCompat time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final next = '$hh:$mm';
    state = state.copyWith(liguoriVisitTime: next);
    (await SharedPreferences.getInstance()).setString('liguoriVisitTime', next);
  }

  Future<void> setFrancisCanticleEnabled(bool v) async {
    state = state.copyWith(francisCanticleEnabled: v);
    (await SharedPreferences.getInstance()).setBool(
      'francisCanticleEnabled',
      v,
    );
  }

  Future<void> setFrancisCanticleTime(TimeOfDayCompat time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final next = '$hh:$mm';
    state = state.copyWith(francisCanticleTime: next);
    (await SharedPreferences.getInstance()).setString(
      'francisCanticleTime',
      next,
    );
  }

  Future<void> setCycleReminderEnabled(String portalId, bool v) async {
    final next = Map<String, bool>.from(state.cycleReminderEnabled)
      ..[portalId] = v;
    state = state.copyWith(cycleReminderEnabled: next);
    (await SharedPreferences.getInstance()).setString(
      'cycleReminderEnabled',
      jsonEncode(next),
    );
  }

  Future<void> setCycleReminderTime(
    String portalId,
    TimeOfDayCompat time,
  ) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final value = '$hh:$mm';
    final next = Map<String, String>.from(state.cycleReminderTime)
      ..[portalId] = value;
    state = state.copyWith(cycleReminderTime: next);
    (await SharedPreferences.getInstance()).setString(
      'cycleReminderTime',
      jsonEncode(next),
    );
  }

  Future<void> ackIgnatiusDirector() async {
    state = state.copyWith(ignatiusDirectorAcked: true);
    (await SharedPreferences.getInstance()).setBool(
      'ignatiusDirectorAcked',
      true,
    );
  }

  Future<void> startIgnatiusProgram(DateTime today) async {
    final start = AppSettings._isoDay(today);
    state = state.copyWith(
      ignatiusProgramStart: start,
      ignatiusProgramPaused: false,
      ignatiusElapsedWhenPaused: 0,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ignatiusProgramStart', start);
    await prefs.setBool('ignatiusProgramPaused', false);
    await prefs.setInt('ignatiusElapsedWhenPaused', 0);
  }

  Future<void> pauseIgnatiusProgram(DateTime today) async {
    final elapsed = state.ignatiusElapsedDays(today);
    final frozen = elapsed < 0 ? 0 : elapsed;
    state = state.copyWith(
      ignatiusProgramPaused: true,
      ignatiusElapsedWhenPaused: frozen,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ignatiusProgramPaused', true);
    await prefs.setInt('ignatiusElapsedWhenPaused', frozen);
  }

  Future<void> resumeIgnatiusProgram(DateTime today) async {
    final elapsed = state.ignatiusElapsedWhenPaused;
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: elapsed));
    final iso = AppSettings._isoDay(start);
    state = state.copyWith(
      ignatiusProgramStart: iso,
      ignatiusProgramPaused: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ignatiusProgramStart', iso);
    await prefs.setBool('ignatiusProgramPaused', false);
  }

  Future<void> restartIgnatiusProgram() async {
    state = state.copyWith(
      ignatiusProgramStart: '',
      ignatiusProgramPaused: false,
      ignatiusElapsedWhenPaused: 0,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ignatiusProgramStart', '');
    await prefs.setBool('ignatiusProgramPaused', false);
    await prefs.setInt('ignatiusElapsedWhenPaused', 0);
  }

  Future<void> setLectioMinutes({
    int? lectio,
    int? meditatio,
    int? oratio,
    int? contemplatio,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      lectioMinutes: lectio ?? state.lectioMinutes,
      meditatioMinutes: meditatio ?? state.meditatioMinutes,
      oratioMinutes: oratio ?? state.oratioMinutes,
      contemplatioMinutes: contemplatio ?? state.contemplatioMinutes,
    );
    if (lectio != null) await prefs.setInt('lectioMinutes', lectio);
    if (meditatio != null) await prefs.setInt('meditatioMinutes', meditatio);
    if (oratio != null) await prefs.setInt('oratioMinutes', oratio);
    if (contemplatio != null) {
      await prefs.setInt('contemplatioMinutes', contemplatio);
    }
  }
}

/// Tiny time holder so providers.dart doesn't import Flutter material.
class TimeOfDayCompat {
  const TimeOfDayCompat({required this.hour, required this.minute});
  final int hour;
  final int minute;
}

Map<String, bool> _loadBoolMap(SharedPreferences prefs, String key) {
  final raw = prefs.getString(key);
  if (raw == null) return {};
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return {for (final e in decoded.entries) e.key: e.value as bool};
}

Map<String, String> _loadStringMap(SharedPreferences prefs, String key) {
  final raw = prefs.getString(key);
  if (raw == null) return {};
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return {for (final e in decoded.entries) e.key: e.value as String};
}

Map<String, bool> _loadReadThroughMap(SharedPreferences prefs) {
  final raw = prefs.getString('readThroughByPortal');
  if (raw != null) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in decoded.entries) e.key: e.value as bool};
  }
  if (prefs.containsKey('desalesReadThrough')) {
    return {'desales': prefs.getBool('desalesReadThrough') ?? false};
  }
  return {};
}

Map<String, int> _loadReadThroughCursorMap(SharedPreferences prefs) {
  final raw = prefs.getString('readThroughCursorByPortal');
  if (raw != null) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in decoded.entries) e.key: (e.value as num).toInt()};
  }
  if (prefs.containsKey('desalesReadThroughCursor')) {
    return {'desales': prefs.getInt('desalesReadThroughCursor') ?? 1};
  }
  return {};
}

/// UI-facing journal row (backed by Isar [LectioJournalEntry]).
class JournalEntry {
  const JournalEntry({
    required this.readingId,
    required this.text,
    required this.createdAt,
    this.id,
  });

  final int? id;
  final int readingId;
  final String text;
  final DateTime createdAt;

  factory JournalEntry.fromIsar(LectioJournalEntry e) => JournalEntry(
    id: e.id,
    readingId: e.readingId,
    text: e.text,
    createdAt: e.createdAt,
  );
}

/// Unsaved journal draft held across navigation after a failed save.
class JournalDraftState {
  const JournalDraftState({
    this.text = '',
    this.readingId,
    this.saveFailed = false,
    this.retryCount = 0,
    this.lastErrorCode,
  });

  final String text;
  final int? readingId;
  final bool saveFailed;
  final int retryCount;
  final String? lastErrorCode;

  bool get hasUnsavedText => text.trim().isNotEmpty;

  JournalDraftState copyWith({
    String? text,
    int? readingId,
    bool? saveFailed,
    int? retryCount,
    String? lastErrorCode,
    bool clearError = false,
  }) {
    return JournalDraftState(
      text: text ?? this.text,
      readingId: readingId ?? this.readingId,
      saveFailed: saveFailed ?? this.saveFailed,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
    );
  }
}

final journalDraftProvider =
    StateNotifierProvider<JournalDraftController, JournalDraftState>((ref) {
      return JournalDraftController(ref);
    });

class JournalDraftController extends StateNotifier<JournalDraftState> {
  JournalDraftController(this._ref) : super(const JournalDraftState());

  final Ref _ref;

  void updateText(String text, {int? readingId}) {
    JournalFailureReporter.rememberDraft(text);
    state = state.copyWith(text: text, readingId: readingId ?? state.readingId);
  }

  void bindReading(int readingId) {
    if (state.readingId == readingId) return;
    // Keep failed draft text when returning to the same session reading.
    state = state.copyWith(readingId: readingId);
  }

  Future<bool> save({required int readingId}) async {
    JournalFailureReporter.rememberDraft(state.text);
    final ok = await _ref
        .read(journalProvider.notifier)
        .add(readingId, state.text, retryCount: state.retryCount);
    if (ok) {
      state = const JournalDraftState();
      return true;
    }
    state = state.copyWith(
      readingId: readingId,
      saveFailed: true,
      retryCount: state.retryCount + 1,
      lastErrorCode: 'journal_save_failed',
    );
    return false;
  }

  Future<bool> retry() async {
    final readingId = state.readingId;
    if (readingId == null) return false;
    return save(readingId: readingId);
  }
}

final isarProvider = Provider<Isar>((ref) => AppIsar.instance);

final journalProvider =
    StateNotifierProvider<JournalController, List<JournalEntry>>((ref) {
      return JournalController(ref.watch(isarProvider), ref);
    });

/// Cross-cycle note for a reading, if one exists older than ~30 days.
final priorJournalProvider = FutureProvider.family<JournalEntry?, int>((
  ref,
  readingId,
) async {
  return ref.read(journalProvider.notifier).previousFor(readingId);
});

class JournalController extends StateNotifier<List<JournalEntry>> {
  JournalController(this._isar, this._ref) : super(const []) {
    // Fire-and-forget load; failures are reported, UI stays empty.
    _load();
    // Re-load when the active portal changes, so a Benedict lectio note
    // never lingers on screen inside a different portal's journal list.
    _ref.listen<String>(currentPortalIdProvider, (_, _) => _load());
  }

  final Isar _isar;
  final Ref _ref;

  static const _forceSaveFail = bool.fromEnvironment(
    'JOURNAL_FORCE_SAVE_FAIL',
    defaultValue: false,
  );

  Future<void> _load() async {
    try {
      final rows = await _isar.lectioJournalEntrys
          .filter()
          .portalIdEqualTo(_ref.read(currentPortalIdProvider))
          .sortByCreatedAtDesc()
          .findAll();
      state = rows.map(JournalEntry.fromIsar).toList();
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'journal_load_failed',
        characterCount: 0,
        error: e,
        stackTrace: st,
        asException: true,
      );
    }
  }

  /// Returns `true` when the entry is persisted. Never swallows failures.
  Future<bool> add(int readingId, String text, {int retryCount = 0}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    JournalFailureReporter.rememberDraft(trimmed);

    try {
      if (_forceSaveFail) {
        throw StateError('Forced journal save failure');
      }
      if (!AppIsar.isOpen) {
        throw StateError('Isar is not open');
      }

      final entry = LectioJournalEntry()
        ..portalId = _ref.read(currentPortalIdProvider)
        ..readingId = readingId
        ..text = trimmed
        ..createdAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.lectioJournalEntrys.put(entry);
      });
      await _load();
      _ref.invalidate(priorJournalProvider(readingId));
      await DiagnosticsLog.instance.record(
        operation: 'journal_save_ok',
        metadata: {
          'character_count': trimmed.length,
          'reading_id': readingId,
          'retry_count': retryCount,
        },
      );
      return true;
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'journal_save_failed',
        characterCount: trimmed.length,
        readingId: readingId,
        retryCount: retryCount,
        error: e,
        stackTrace: st,
        asException: true,
      );
      return false;
    }
  }

  /// Cross-cycle resurfacing: older than ~30 days for the same reading.
  Future<JournalEntry?> previousFor(int readingId, {DateTime? before}) async {
    try {
      final cutoff = (before ?? DateTime.now()).subtract(
        const Duration(days: 30),
      );
      final found = await _isar.lectioJournalEntrys
          .filter()
          .portalIdEqualTo(_ref.read(currentPortalIdProvider))
          .readingIdEqualTo(readingId)
          .createdAtLessThan(cutoff)
          .sortByCreatedAtDesc()
          .findFirst();
      return found == null ? null : JournalEntry.fromIsar(found);
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'journal_prior_lookup_failed',
        characterCount: 0,
        readingId: readingId,
        error: e,
        stackTrace: st,
        asException: true,
      );
      return null;
    }
  }
}

final completionProvider =
    StateNotifierProvider<CompletionController, Set<String>>((ref) {
      final ctrl = CompletionController(ref.watch(isarProvider), ref);
      ref.listen<String>(currentPortalIdProvider, (_, _) => ctrl.reload());
      return ctrl;
    });

class CompletionController extends StateNotifier<Set<String>> {
  CompletionController(this._isar, this._ref) : super(const {}) {
    _load();
  }

  final Isar _isar;
  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    final portalId = _ref.read(currentPortalIdProvider);
    final rows = await _isar.readingCompletions
        .filter()
        .portalIdEqualTo(portalId)
        .findAll();
    state = {for (final r in rows) r.dateKey};
  }

  static String keyFor(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> markRead(DateTime day, {int? readingId}) async {
    final key = keyFor(day);
    final portalId = _ref.read(currentPortalIdProvider);
    await _isar.writeTxn(() async {
      final existing = await _isar.readingCompletions
          .filter()
          .portalIdEqualTo(portalId)
          .dateKeyEqualTo(key)
          .findFirst();
      if (existing != null) {
        existing
          ..completedAt = DateTime.now()
          ..readingId = readingId;
        await _isar.readingCompletions.put(existing);
      } else {
        final row = ReadingCompletion()
          ..portalId = _ref.read(currentPortalIdProvider)
          ..dateKey = key
          ..completedAt = DateTime.now()
          ..readingId = readingId;
        await _isar.readingCompletions.put(row);
      }
    });
    state = {...state, key};
  }

  bool isComplete(DateTime day) => state.contains(keyFor(day));

  /// Consecutive marked days ending today (or yesterday if today is still open).
  static int presentRun(Set<String> keys, DateTime now) {
    var cursor = DateTime(now.year, now.month, now.day);
    if (!keys.contains(keyFor(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (keys.contains(keyFor(cursor))) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Longest consecutive run in the set.
  static int longestRun(Set<String> keys) {
    if (keys.isEmpty) return 0;
    final days = keys.map(DateTime.parse).toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else if (gap > 1) {
        run = 1;
      }
    }
    return best;
  }
}

final illuminatedDateProvider =
    StateNotifierProvider<IlluminationController, String?>((ref) {
      return IlluminationController();
    });

class IlluminationController extends StateNotifier<String?> {
  IlluminationController() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('lastIlluminatedDate');
  }

  Future<bool> shouldIlluminate(DateTime day) async {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    if (state == key) return false;
    // Defer write so callers from post-frame / async paths stay safe.
    await Future<void>.delayed(Duration.zero);
    state = key;
    (await SharedPreferences.getInstance()).setString(
      'lastIlluminatedDate',
      key,
    );
    return true;
  }
}

/// de Sales' Bouquet — see lib/data/isar/bouquet.dart.
final bouquetProvider = StateNotifierProvider<BouquetController, List<Bouquet>>(
  (ref) {
    return BouquetController(ref.watch(isarProvider), ref);
  },
);

class BouquetController extends StateNotifier<List<Bouquet>> {
  BouquetController(this._isar, this._ref) : super(const []) {
    _load();
    _ref.listen<String>(currentPortalIdProvider, (_, _) => _load());
  }

  final Isar _isar;
  final Ref _ref;

  static String keyFor(DateTime day) =>
      '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final rows = await _isar.bouquets
        .filter()
        .portalIdEqualTo(_ref.read(currentPortalIdProvider))
        .sortByCreatedAtDesc()
        .findAll();
    state = rows;
  }

  Future<void> keep(DateTime day, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final row = Bouquet()
      ..portalId = _ref.read(currentPortalIdProvider)
      ..dateKey = keyFor(day)
      ..text = trimmed
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.bouquets.put(row);
    });
    await _load();
  }

  /// The line kept today, if any — pins to the top of Today.
  Bouquet? forToday(DateTime day) {
    for (final b in state) {
      if (b.dateKey == keyFor(day) &&
          b.createdAt.year == day.year &&
          b.createdAt.month == day.month &&
          b.createdAt.day == day.day) {
        return b;
      }
    }
    return null;
  }

  /// A bouquet kept on this same calendar day in a prior year.
  Future<Bouquet?> fromLastYear(DateTime day) async {
    final cutoff = DateTime(day.year, day.month, day.day);
    final rows = await _isar.bouquets
        .filter()
        .portalIdEqualTo(_ref.read(currentPortalIdProvider))
        .dateKeyEqualTo(keyFor(day))
        .createdAtLessThan(cutoff)
        .sortByCreatedAtDesc()
        .findAll();
    return rows.isEmpty ? null : rows.first;
  }
}
