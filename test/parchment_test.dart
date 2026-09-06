import 'package:dailycompany/app/theme/app_theme.dart';
import 'package:dailycompany/app/theme/parchment.dart';
import 'package:dailycompany/app/theme/parchment_field.dart';
import 'package:dailycompany/shared/widgets/reading_leaf.dart';
import 'package:dailycompany/shared/widgets/reading_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compline grain is darker and less fibrous than vellum', () {
    expect(
      ParchmentTheme.compline.grainOpacity,
      lessThan(ParchmentTheme.vellum.grainOpacity),
    );
    expect(
      ParchmentTheme.compline.grainDensity,
      lessThan(ParchmentTheme.vellum.grainDensity),
    );
    expect(ParchmentTheme.paper.grainOpacity, inInclusiveRange(0.04, 0.08));
    expect(ParchmentTheme.vellum.grainOpacity, inInclusiveRange(0.04, 0.08));
  });

  test('themeForReadingSurface attaches the matching parchment', () {
    const accent = Color(0xFF4A4266);
    ParchmentTheme ext(String surface, Brightness brightness) {
      return themeForReadingSurface(
        surface: surface,
        accent: accent,
        fontScale: 1,
        boldReading: false,
        platformBrightness: brightness,
      ).extension<ParchmentTheme>()!;
    }

    expect(ext('paper', Brightness.light), same(ParchmentTheme.paper));
    expect(ext('vellum', Brightness.light), same(ParchmentTheme.vellum));
    expect(ext('compline', Brightness.dark), same(ParchmentTheme.compline));
    expect(ext('system', Brightness.light), same(ParchmentTheme.vellum));
    expect(ext('system', Brightness.dark), same(ParchmentTheme.compline));
  });

  testWidgets('reading leaf and field paint on a reading scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildVellumTheme(accent: const Color(0xFF4A4266)),
          builder: parchmentAppBuilder,
          home: const Scaffold(
            body: ReadingScrollView(
              title: 'Test',
              snippet: 's',
              route: '/more',
              children: [Text('leaf body')],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ParchmentField), findsOneWidget);
    expect(find.byType(ReadingLeaf), findsOneWidget);
    expect(find.text('leaf body'), findsOneWidget);
  });
}
