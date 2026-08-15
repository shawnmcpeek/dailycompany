import 'package:benedictdaily/app/theme/palette.dart';
import 'package:benedictdaily/core/cycle/reading_calendar.dart';
import 'package:flutter/material.dart';

ThemeData buildPaperTheme({
  required DateTime day,
  double fontScale = 1,
  bool boldReading = false,
}) {
  final accent = ReadingCalendar.accentForStatic(day);
  return _base(
    brightness: Brightness.light,
    bg: Paper.bg,
    ink: Paper.ink,
    secondary: Paper.secondary,
    rule: Paper.rule,
    gold: Paper.gold,
    accent: accent,
    fontScale: fontScale,
    boldReading: boldReading,
  );
}

ThemeData buildVellumTheme({
  required DateTime day,
  double fontScale = 1,
  bool boldReading = false,
}) {
  final accent = ReadingCalendar.accentForStatic(day);
  return _base(
    brightness: Brightness.light,
    bg: Vellum.bg,
    ink: Vellum.ink,
    secondary: Vellum.secondary,
    rule: Vellum.rule,
    gold: Vellum.gold,
    accent: accent,
    fontScale: fontScale,
    boldReading: boldReading,
  );
}

ThemeData buildComplineTheme({
  required DateTime day,
  double fontScale = 1,
  bool boldReading = false,
}) {
  final accent = ReadingCalendar.accentForStatic(day);
  return _base(
    brightness: Brightness.dark,
    bg: Compline.bg,
    ink: Compline.ink,
    secondary: Compline.secondary,
    rule: Compline.rule,
    gold: Compline.gold,
    accent: accent,
    fontScale: fontScale,
    boldReading: boldReading,
  );
}

ThemeData themeForReadingSurface({
  required String surface,
  required DateTime day,
  required double fontScale,
  required bool boldReading,
  required Brightness platformBrightness,
}) {
  final resolved = switch (surface) {
    'paper' => 'paper',
    'compline' => 'compline',
    'system' =>
      platformBrightness == Brightness.dark ? 'compline' : 'vellum',
    _ => 'vellum',
  };
  return switch (resolved) {
    'paper' => buildPaperTheme(
        day: day,
        fontScale: fontScale,
        boldReading: boldReading,
      ),
    'compline' => buildComplineTheme(
        day: day,
        fontScale: fontScale,
        boldReading: boldReading,
      ),
    _ => buildVellumTheme(
        day: day,
        fontScale: fontScale,
        boldReading: boldReading,
      ),
  };
}

ThemeData _base({
  required Brightness brightness,
  required Color bg,
  required Color ink,
  required Color secondary,
  required Color rule,
  required Color gold,
  required Color accent,
  required double fontScale,
  required bool boldReading,
}) {
  final scale = fontScale.clamp(0.85, 1.45);
  final readingWeight = boldReading ? FontWeight.w600 : FontWeight.w400;

  TextStyle reading(double size, {double height = 1.7}) => TextStyle(
        fontFamily: 'EBGaramond',
        fontSize: size * scale,
        height: height,
        fontWeight: readingWeight,
        color: ink,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: bg,
      secondary: gold,
      onSecondary: bg,
      error: LiturgicalColor.red,
      onError: bg,
      surface: bg,
      onSurface: ink,
    ),
    dividerColor: rule,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04,
        color: secondary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: accent.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 11,
          letterSpacing: 0.04,
          color: secondary,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: reading(46, height: 0.85),
      headlineMedium: reading(28, height: 1.25),
      titleMedium: reading(18, height: 1.35),
      bodyLarge: reading(17),
      bodyMedium: reading(16),
      bodySmall: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 12,
        height: 1.4,
        letterSpacing: 0.02,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 11,
        letterSpacing: 0.08,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      side: BorderSide(color: rule),
      labelStyle: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 12,
        color: ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    iconTheme: IconThemeData(color: secondary, size: 22),
  );
  return base;
}
