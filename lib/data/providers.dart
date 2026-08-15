import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:benedictdaily/data/content_catalog.dart';

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

class AppSettings {
  const AppSettings({
    this.ready = false,
    this.onboardingComplete = false,
    this.hapticsEnabled = true,
    this.oraEtLabora = false,
    this.showLatin = false,
    this.themeMode = 'vellum',
    this.fontScale = 1.0,
    this.boldReading = false,
  });

  /// False until SharedPreferences have been read.
  final bool ready;
  final bool onboardingComplete;
  final bool hapticsEnabled;
  final bool oraEtLabora;
  final bool showLatin;

  /// paper | vellum | compline | system
  final String themeMode;
  final double fontScale;
  final bool boldReading;

  AppSettings copyWith({
    bool? ready,
    bool? onboardingComplete,
    bool? hapticsEnabled,
    bool? oraEtLabora,
    bool? showLatin,
    String? themeMode,
    double? fontScale,
    bool? boldReading,
  }) =>
      AppSettings(
        ready: ready ?? this.ready,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        oraEtLabora: oraEtLabora ?? this.oraEtLabora,
        showLatin: showLatin ?? this.showLatin,
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        boldReading: boldReading ?? this.boldReading,
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
    state = AppSettings(
      ready: true,
      onboardingComplete: prefs.getBool('onboardingComplete') ?? false,
      hapticsEnabled: prefs.getBool('hapticsEnabled') ?? true,
      oraEtLabora: prefs.getBool('oraEtLabora') ?? false,
      showLatin: prefs.getBool('showLatin') ?? false,
      themeMode: theme,
      fontScale: prefs.getDouble('fontScale') ?? 1.0,
      boldReading: prefs.getBool('boldReading') ?? false,
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

  Future<void> setOraEtLabora(bool v) async {
    state = state.copyWith(oraEtLabora: v);
    (await SharedPreferences.getInstance()).setBool('oraEtLabora', v);
  }

  Future<void> setShowLatin(bool v) async {
    state = state.copyWith(showLatin: v);
    (await SharedPreferences.getInstance()).setBool('showLatin', v);
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
}

class JournalEntry {
  JournalEntry({
    required this.readingId,
    required this.text,
    required this.createdAt,
  });

  final int readingId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'readingId': readingId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        readingId: json['readingId'] as int,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

final journalProvider =
    StateNotifierProvider<JournalController, List<JournalEntry>>((ref) {
  return JournalController();
});

class JournalController extends StateNotifier<List<JournalEntry>> {
  JournalController() : super(const []) {
    _load();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/lectio_journal.json');
  }

  Future<void> _load() async {
    final file = await _file();
    if (!await file.exists()) return;
    final raw = jsonDecode(await file.readAsString()) as List;
    state = raw
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final file = await _file();
    await file.writeAsString(jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> add(int readingId, String text) async {
    if (text.trim().isEmpty) return;
    state = [
      ...state,
      JournalEntry(
        readingId: readingId,
        text: text.trim(),
        createdAt: DateTime.now(),
      ),
    ];
    await _save();
  }

  JournalEntry? previousFor(int readingId, {DateTime? before}) {
    final cutoff = before ?? DateTime.now();
    final matches = state
        .where(
          (e) =>
              e.readingId == readingId &&
              e.createdAt.isBefore(cutoff.subtract(const Duration(days: 30))),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
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
    state = key;
    (await SharedPreferences.getInstance()).setString('lastIlluminatedDate', key);
    return true;
  }
}
