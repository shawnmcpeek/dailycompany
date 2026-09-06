import 'dart:ui' as ui;

import 'package:dailycompany/app/theme/app_theme.dart';
import 'package:dailycompany/app/theme/parchment.dart';
import 'package:dailycompany/app/theme/parchment_field.dart';
import 'package:dailycompany/shared/widgets/reading_leaf.dart';
import 'package:dailycompany/shared/widgets/reading_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    expect(ParchmentTheme.paper.grainOpacity, inInclusiveRange(0.07, 0.13));
    expect(ParchmentTheme.vellum.grainOpacity, inInclusiveRange(0.07, 0.13));
    expect(ParchmentTheme.vellum.grainStroke, greaterThanOrEqualTo(1));
    expect(
      ParchmentTheme.compline.edgeTanOpacity,
      lessThan(ParchmentTheme.vellum.edgeTanOpacity),
    );
    expect(ParchmentTheme.vellum.edgeTanOpacity, greaterThan(0.15));
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

  testWidgets('desk is plain; leaf grain marks the page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<int> markedPixels(Widget body) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVellumTheme(accent: const Color(0xFF4A4266)),
          home: RepaintBoundary(key: key, child: body),
        ),
      );
      await tester.pump();
      return (await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.rawRgba);
            if (bytes == null) return 0;
            const ground = Color(0xFFF3EDE1);
            var count = 0;
            const origin = 180 * 2;
            const span = 80 * 2;
            for (var y = origin; y < origin + span; y++) {
              for (var x = origin; x < origin + span; x++) {
                final i = (y * image.width + x) * 4;
                final r = bytes.getUint8(i);
                final g = bytes.getUint8(i + 1);
                final b = bytes.getUint8(i + 2);
                if ((r - ground.r * 255).abs() > 2 ||
                    (g - ground.g * 255).abs() > 2 ||
                    (b - ground.b * 255).abs() > 2) {
                  count++;
                }
              }
            }
            return count;
          })) ??
          0;
    }

    final desk = await markedPixels(
      const ParchmentField(child: SizedBox.expand()),
    );
    final page = await markedPixels(
      const ReadingLeaf(child: SizedBox.expand()),
    );
    expect(desk, 0);
    expect(page, greaterThan(80));
  });
}
