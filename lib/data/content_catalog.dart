import 'dart:convert';

import 'package:benedictdaily/core/cycle/reading_calendar.dart';
import 'package:flutter/services.dart';

class LifeEpisode {
  const LifeEpisode({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory LifeEpisode.fromJson(Map<String, dynamic> json) => LifeEpisode(
        chapter: json['chapter'] as int,
        title: json['title'] as String,
        textEn: json['textEn'] as String,
      );
}

class ToolOfGoodWorks {
  const ToolOfGoodWorks({
    required this.number,
    required this.text,
    this.gloss,
  });

  final int number;
  final String text;
  final String? gloss;

  factory ToolOfGoodWorks.fromJson(Map<String, dynamic> json) =>
      ToolOfGoodWorks(
        number: json['number'] as int,
        text: json['text'] as String,
        gloss: json['gloss'] as String?,
      );
}

class PsalmVerse {
  const PsalmVerse({required this.n, required this.text});
  final int n;
  final String text;
}

class Psalm {
  const Psalm({
    required this.number,
    required this.title,
    required this.verses,
  });

  final int number;
  final String title;
  final List<PsalmVerse> verses;

  factory Psalm.fromJson(Map<String, dynamic> json) => Psalm(
        number: json['number'] as int,
        title: json['title'] as String? ?? '',
        verses: (json['verses'] as List)
            .map(
              (e) => PsalmVerse(
                n: (e as Map<String, dynamic>)['n'] as int,
                text: e['text'] as String,
              ),
            )
            .toList(),
      );

  String get fullText => verses.map((v) => v.text).join('\n\n');
}

class OfficeLine {
  const OfficeLine({required this.latin, required this.english});
  final String latin;
  final String english;

  factory OfficeLine.fromJson(Map<String, dynamic> json) => OfficeLine(
        latin: json['latin'] as String,
        english: json['english'] as String,
      );
}

class HourOffice {
  const HourOffice({
    required this.id,
    required this.label,
    required this.defaultTime,
    required this.haptic,
    required this.opening,
    required this.response,
    required this.gloryBe,
    required this.psalmNumbers,
    required this.closing,
  });

  final String id;
  final String label;
  final String defaultTime;
  final String haptic;
  final OfficeLine opening;
  final OfficeLine response;
  final OfficeLine gloryBe;
  final List<int> psalmNumbers;
  final OfficeLine closing;

  factory HourOffice.fromJson(Map<String, dynamic> json) => HourOffice(
        id: json['id'] as String,
        label: json['label'] as String,
        defaultTime: json['defaultTime'] as String,
        haptic: json['haptic'] as String? ?? 'little',
        opening: OfficeLine.fromJson(json['opening'] as Map<String, dynamic>),
        response: OfficeLine.fromJson(json['response'] as Map<String, dynamic>),
        gloryBe: OfficeLine.fromJson(json['gloryBe'] as Map<String, dynamic>),
        psalmNumbers: (json['psalmNumbers'] as List).cast<int>(),
        closing: OfficeLine.fromJson(json['closing'] as Map<String, dynamic>),
      );
}

class MedalRegion {
  const MedalRegion({
    required this.id,
    required this.label,
    required this.expansion,
    required this.meaning,
  });

  final String id;
  final String label;
  final String expansion;
  final String meaning;

  factory MedalRegion.fromJson(Map<String, dynamic> json) => MedalRegion(
        id: json['id'] as String,
        label: json['label'] as String,
        expansion: json['expansion'] as String,
        meaning: json['meaning'] as String,
      );
}

class MedalContent {
  const MedalContent({
    required this.regions,
    required this.blessingLatin,
    required this.blessingEnglish,
    required this.blessingNote,
    required this.litany,
    required this.history,
  });

  final List<MedalRegion> regions;
  final String blessingLatin;
  final String blessingEnglish;
  final String blessingNote;
  final List<({String invocation, String response})> litany;
  final String history;

  factory MedalContent.fromJson(Map<String, dynamic> json) {
    final blessing = json['blessing'] as Map<String, dynamic>;
    return MedalContent(
      regions: (json['regions'] as List)
          .map((e) => MedalRegion.fromJson(e as Map<String, dynamic>))
          .toList(),
      blessingLatin: blessing['latin'] as String,
      blessingEnglish: blessing['english'] as String,
      blessingNote: blessing['note'] as String,
      litany: (json['litany'] as List)
          .map((e) {
            final m = e as Map<String, dynamic>;
            return (
              invocation: m['invocation'] as String,
              response: m['response'] as String? ?? 'Pray for us.',
            );
          })
          .toList(),
      history: json['history'] as String,
    );
  }
}

class ContentCatalog {
  ContentCatalog({
    required this.calendar,
    required this.life,
    required this.tools,
    required this.psalms,
    required this.offices,
    required this.psalterNote,
    required this.medal,
  });

  final ReadingCalendar calendar;
  final List<LifeEpisode> life;
  final List<ToolOfGoodWorks> tools;
  final Map<int, Psalm> psalms;
  final List<HourOffice> offices;
  final String psalterNote;
  final MedalContent medal;

  static Future<ContentCatalog> load() async {
    final calendar = await ReadingCalendar.loadFromAssets();

    Future<Map<String, dynamic>> loadJson(String path) async =>
        jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;

    final lifeJson = await loadJson('assets/content/life_episodes.json');
    final toolsJson = await loadJson('assets/content/tools_of_good_works.json');
    final psalmsJson = await loadJson('assets/content/psalms.json');
    final hoursJson = await loadJson('assets/content/hours.json');
    final medalJson = await loadJson('assets/content/medal.json');

    final psalms = <int, Psalm>{
      for (final e in (psalmsJson['psalms'] as List))
        (e as Map<String, dynamic>)['number'] as int: Psalm.fromJson(e),
    };

    return ContentCatalog(
      calendar: calendar,
      life: (lifeJson['episodes'] as List)
          .map((e) => LifeEpisode.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.chapter.compareTo(b.chapter)),
      tools: (toolsJson['tools'] as List)
          .map((e) => ToolOfGoodWorks.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number)),
      psalms: psalms,
      offices: (hoursJson['offices'] as List)
          .map((e) => HourOffice.fromJson(e as Map<String, dynamic>))
          .toList(),
      psalterNote: hoursJson['psalterNote'] as String? ?? '',
      medal: MedalContent.fromJson(medalJson),
    );
  }

  HourOffice? officeById(String id) {
    for (final o in offices) {
      if (o.id == id) return o;
    }
    return null;
  }

  ToolOfGoodWorks toolForDay(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final idx = dayOfYear % tools.length;
    return tools[idx];
  }
}
