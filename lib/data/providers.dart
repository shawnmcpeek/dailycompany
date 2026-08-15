import 'package:benedictdaily/core/iap/iap_controller.dart';
import 'package:benedictdaily/core/notifications/bell_scheduler.dart';
import 'package:benedictdaily/data/content_catalog.dart';
import 'package:benedictdaily/data/isar/app_isar.dart';
import 'package:benedictdaily/data/isar/lectio_journal_entry.dart';
import 'package:benedictdaily/data/isar/reading_completion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final contentCatalogProvider = FutureProvider<ContentCatalog>((ref) async {
  return ContentCatalog.load();
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

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

  String timeForOffice(String id) =>
      officeTimes[id] ?? BellScheduler.defaultTimes[id] ?? '12:00';

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
  }) =>
      AppSettings(
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
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    (await SharedPreferences.getInstance()).setBool('onboardingComplete', true);
  }

  Future<void> resetOnboarding() async {
    state = state.copyWith(onboardingComplete: false);
    (await SharedPreferences.getInstance()).setBool('onboardingComplete', false);
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
    (await SharedPreferences.getInstance())
        .setString('officeTimes', jsonEncode(next));
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

final isarProvider = Provider<Isar>((ref) => AppIsar.instance);

final journalProvider =
    StateNotifierProvider<JournalController, List<JournalEntry>>((ref) {
  return JournalController(ref.watch(isarProvider), ref);
});

/// Cross-cycle note for a reading, if one exists older than ~30 days.
final priorJournalProvider =
    FutureProvider.family<JournalEntry?, int>((ref, readingId) async {
  return ref.read(journalProvider.notifier).previousFor(readingId);
});

class JournalController extends StateNotifier<List<JournalEntry>> {
  JournalController(this._isar, this._ref) : super(const []) {
    _load();
  }

  final Isar _isar;
  final Ref _ref;

  Future<void> _load() async {
    final rows = await _isar.lectioJournalEntrys
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    state = rows.map(JournalEntry.fromIsar).toList();
  }

  Future<void> add(int readingId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final entry = LectioJournalEntry()
      ..readingId = readingId
      ..text = trimmed
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.lectioJournalEntrys.put(entry);
    });
    await _load();
    _ref.invalidate(priorJournalProvider(readingId));
  }

  /// Cross-cycle resurfacing: older than ~30 days for the same reading.
  Future<JournalEntry?> previousFor(int readingId, {DateTime? before}) async {
    final cutoff = (before ?? DateTime.now()).subtract(const Duration(days: 30));
    final found = await _isar.lectioJournalEntrys
        .filter()
        .readingIdEqualTo(readingId)
        .createdAtLessThan(cutoff)
        .sortByCreatedAtDesc()
        .findFirst();
    return found == null ? null : JournalEntry.fromIsar(found);
  }
}

final completionProvider =
    StateNotifierProvider<CompletionController, Set<String>>((ref) {
  return CompletionController(ref.watch(isarProvider));
});

class CompletionController extends StateNotifier<Set<String>> {
  CompletionController(this._isar) : super(const {}) {
    _load();
  }

  final Isar _isar;

  Future<void> _load() async {
    final rows = await _isar.readingCompletions.where().findAll();
    state = {for (final r in rows) r.dateKey};
  }

  static String keyFor(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> markRead(DateTime day, {int? readingId}) async {
    final key = keyFor(day);
    await _isar.writeTxn(() async {
      final existing = await _isar.readingCompletions
          .filter()
          .dateKeyEqualTo(key)
          .findFirst();
      if (existing != null) {
        existing
          ..completedAt = DateTime.now()
          ..readingId = readingId;
        await _isar.readingCompletions.put(existing);
      } else {
        final row = ReadingCompletion()
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
    (await SharedPreferences.getInstance()).setString('lastIlluminatedDate', key);
    return true;
  }
}
