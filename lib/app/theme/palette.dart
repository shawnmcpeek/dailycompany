import 'package:flutter/material.dart';

/// Brighter day reading surface (Libby-style “light”, never pure white).
abstract final class Paper {
  static const bg = Color(0xFFF7F2E8);
  static const ink = Color(0xFF1F1B18);
  static const secondary = Color(0xFF6A635A);
  static const rule = Color(0xFFE0D6C6);
  static const gold = Color(0xFFA8802C);
}

/// Light mode — vellum / iron gall (Libby-style sepia).
abstract final class Vellum {
  static const bg = Color(0xFFF3EDE1);
  static const ink = Color(0xFF211D1A);
  static const secondary = Color(0xFF6E655A);
  static const rule = Color(0xFFD9CFBE);
  static const gold = Color(0xFFA8802C);
}

/// Dark mode — warm near-black (Libby-style night).
abstract final class Compline {
  static const bg = Color(0xFF16130F);
  static const ink = Color(0xFFE6DCCB);
  static const secondary = Color(0xFF9C9084);
  static const rule = Color(0xFF332D26);
  static const gold = Color(0xFFC9A14E);
}

/// Accent shifts three times a year with the reading cycle.
abstract final class CycleAccent {
  static const winter = Color(0xFF4A4266); // Jan 1 – May 1
  static const summer = Color(0xFF4F6146); // May 2 – Aug 31
  static const autumn = Color(0xFF7A3A2C); // Sep 1 – Dec 31
}

/// Accent shifts with the Part of the Devout Life being read — spec §6.
/// Distinct hues from CycleAccent/LiturgicalColor so a glance never
/// confuses which portal you're in.
abstract final class DesalesAccent {
  static const partI = Color(0xFF564264); // Purification — muted plum
  static const partII = Color(0xFF8C6A2C); // Prayer & sacraments — amber
  static const partIII = Color(0xFF5C6B4A); // Practice of virtue — sage
  static const partIV = Color(0xFF8C4A2C); // Temptations — muted rust
  static const partV = Color(0xFF3A6B6E); // Renewal — teal

  static Color forPart(int part) => switch (part) {
        1 => partI,
        2 => partII,
        3 => partIII,
        4 => partIV,
        5 => partV,
        _ => partI,
      };
}

/// Drop-cap liturgical colors (v1 resolver).
abstract final class LiturgicalColor {
  static const green = Color(0xFF4F6146);
  static const violet = Color(0xFF4A4266);
  static const red = Color(0xFF8C2F26);
  static const gold = Color(0xFFA8802C);
  static const rose = Color(0xFFB07A85);
  static const black = Color(0xFF211D1A);
}
