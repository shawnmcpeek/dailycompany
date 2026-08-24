import 'package:dailycompany/core/cycle/reading_calendar.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/data/content_catalog.dart';

enum DailyTrack { life, rule, both }

extension DailyTrackX on DailyTrack {
  bool get includesLife => this == DailyTrack.life || this == DailyTrack.both;

  bool get includesRule => this == DailyTrack.rule || this == DailyTrack.both;

  static DailyTrack fromStorage(String? raw) => switch (raw) {
        'rule' => DailyTrack.rule,
        'both' => DailyTrack.both,
        _ => DailyTrack.life,
      };
}

/// Sequential Life-of-Benedict cycle: one episode a day from a start date, then loop.
abstract final class LifeTrack {
  static const journalIdBase = 10000;

  static int journalId(int chapter) => journalIdBase + chapter;

  static bool isJournalId(int id) => id >= journalIdBase;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime parseStart(String yyyyMmDd) => DateTime.parse(yyyyMmDd);

  static int offset(DateTime day, DateTime start) {
    final n = dateOnly(day).difference(dateOnly(start)).inDays;
    return n < 0 ? 0 : n;
  }

  static LifeEpisode episodeFor({
    required List<LifeEpisode> episodes,
    required DateTime day,
    required DateTime start,
  }) {
    if (episodes.isEmpty) {
      throw StateError('No Life episodes');
    }
    return episodes[offset(day, start) % episodes.length];
  }

  static int dayNumber({
    required List<LifeEpisode> episodes,
    required DateTime day,
    required DateTime start,
  }) {
    if (episodes.isEmpty) return 1;
    return (offset(day, start) % episodes.length) + 1;
  }

  static String cycleLabel({
    required List<LifeEpisode> episodes,
    required DateTime day,
    required DateTime start,
  }) {
    final count = episodes.length;
    final n = dayNumber(episodes: episodes, day: day, start: start);
    return 'Life of Benedict · day $n of $count';
  }

  static String headline(LifeEpisode ep, {required int numbered}) {
    if (ep.chapter == 0) return 'Prologue';
    return 'Episode ${ep.chapter} of $numbered';
  }
}

class LectioPassage {
  const LectioPassage({
    required this.journalId,
    required this.headline,
    required this.textEn,
    this.locked = false,
  });

  final int journalId;
  final String headline;
  final String textEn;
  final bool locked;
}

LectioPassage? lectioPassageFor({
  required DailyTrack track,
  required List<LifeEpisode> life,
  required List<RuleReading> rule,
  required DateTime day,
  required DateTime lifeStart,
  required bool unlocked,
  required int numberedLife,
}) {
  if (track.includesLife && life.isNotEmpty) {
    final ep = LifeTrack.episodeFor(episodes: life, day: day, start: lifeStart);
    final free = unlocked || IapController.lifeChapterFree(ep.chapter);
    if (free) {
      return LectioPassage(
        journalId: LifeTrack.journalId(ep.chapter),
        headline:
            'Life · ${LifeTrack.headline(ep, numbered: numberedLife)} · ${ep.title}',
        textEn: ep.textEn,
      );
    }
    if (!track.includesRule) {
      return LectioPassage(
        journalId: LifeTrack.journalId(ep.chapter),
        headline: LifeTrack.headline(ep, numbered: numberedLife),
        textEn: '',
        locked: true,
      );
    }
  }
  if (track.includesRule && rule.isNotEmpty) {
    final r = rule.first;
    return LectioPassage(
      journalId: r.id,
      headline: '',
      textEn: r.textEn,
    );
  }
  return null;
}
