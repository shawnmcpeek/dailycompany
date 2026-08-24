import 'package:dailycompany/core/cycle/life_track.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

LifeEpisode ep(int chapter) => LifeEpisode(
      chapter: chapter,
      title: 'Title $chapter',
      textEn: 'Text $chapter',
    );

void main() {
  final episodes = [for (var i = 0; i <= 38; i++) ep(i)];
  final start = DateTime(2026, 8, 15);

  test('day one is the prologue', () {
    final got = LifeTrack.episodeFor(
      episodes: episodes,
      day: start,
      start: start,
    );
    expect(got.chapter, 0);
    expect(LifeTrack.dayNumber(episodes: episodes, day: start, start: start), 1);
  });

  test('day six is episode 5, still in the free stretch', () {
    final day = DateTime(2026, 8, 20);
    final got = LifeTrack.episodeFor(
      episodes: episodes,
      day: day,
      start: start,
    );
    expect(got.chapter, 5);
  });

  test('day seven is episode 6 — the Oblate wall', () {
    final day = DateTime(2026, 8, 21);
    final got = LifeTrack.episodeFor(
      episodes: episodes,
      day: day,
      start: start,
    );
    expect(got.chapter, 6);
  });

  test('the book loops after 39 days', () {
    final day = DateTime(2026, 9, 23);
    expect(LifeTrack.offset(day, start), 39);
    final got = LifeTrack.episodeFor(
      episodes: episodes,
      day: day,
      start: start,
    );
    expect(got.chapter, 0);
  });

  test('days before the start clamp to the prologue', () {
    final got = LifeTrack.episodeFor(
      episodes: episodes,
      day: DateTime(2026, 8, 1),
      start: start,
    );
    expect(got.chapter, 0);
  });

  test('journal ids do not collide with Rule readings', () {
    expect(LifeTrack.journalId(0), 10000);
    expect(LifeTrack.journalId(38), 10038);
    expect(LifeTrack.isJournalId(122), isFalse);
    expect(LifeTrack.isJournalId(10000), isTrue);
  });
}
