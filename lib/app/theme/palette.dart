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

/// Accent shifts with the Book of the Imitation — spec §9.4.
/// Distinct from [CycleAccent] and [DesalesAccent].
abstract final class KempisAccent {
  static const bookI = Color(0xFF3F4A52); // Ascesis — slate
  static const bookII = Color(0xFF5A4638); // Inner life — umber
  static const bookIII = Color(0xFF6A4854); // Dialogue — muted rose-brown
  static const bookIV = Color(0xFF7A6A3E); // Sacrament — antique gold

  static Color forBook(int book) => switch (book) {
        1 => bookI,
        2 => bookII,
        3 => bookIII,
        4 => bookIV,
        _ => bookI,
      };
}

/// Fixed accent — spec §6. Distinct from [CycleAccent], [DesalesAccent],
/// and [KempisAccent].
abstract final class LiguoriAccent {
  static const visit = Color(0xFF5B3D4A); // dusk wine
}

/// Fixed accent — spec §6. Distinct from [CycleAccent] summer and
/// [KempisAccent] umber.
abstract final class FrancisAccent {
  static const woodland = Color(0xFF3E5548);
}

/// Fixed accent — spec §6.
abstract final class JohnCrossAccent {
  static const night = Color(0xFF3A3F5C);
}

/// Fixed accent — spec §6.
abstract final class GregoryAccent {
  static const stone = Color(0xFF5A5850);
}

/// Fixed accent — spec §6.
abstract final class AugustineAccent {
  static const hearth = Color(0xFF6A4038);
}

/// Accent shifts with the seven mansions — spec §6. Way of Perfection
/// uses a threshold colour (approaching the castle). Distinct from
/// [CycleAccent], [DesalesAccent], [KempisAccent], and the fixed set.
abstract final class TeresaAccent {
  static const way = Color(0xFF6B5344);
  static const mansion1 = Color(0xFF7A6B4A);
  static const mansion2 = Color(0xFF5A6A4E);
  static const mansion3 = Color(0xFF4A5A62);
  static const mansion4 = Color(0xFF5A4A62);
  static const mansion5 = Color(0xFF6A3E48);
  static const mansion6 = Color(0xFF3E4A6A);
  static const mansion7 = Color(0xFF8A6A2C);

  static Color forPart(int part) => switch (part) {
        1 => way,
        2 => mansion1,
        3 => mansion2,
        4 => mansion3,
        5 => mansion4,
        6 => mansion5,
        7 => mansion6,
        8 => mansion7,
        _ => way,
      };
}

/// Accent by Exercises Week — spec §10.3.
abstract final class IgnatiusAccent {
  static const disposition = Color(0xFF6E655A);
  static const first = Color(0xFF4A4266);
  static const second = Color(0xFF4F6146);
  static const third = Color(0xFF8C2F26);
  static const fourth = Color(0xFFA8802C);

  static Color forPart(int part) => switch (part) {
        0 => disposition,
        1 => first,
        2 => second,
        3 => third,
        4 => fourth,
        _ => disposition,
      };
}

/// Fixed accent — spec §6.
abstract final class ThereseAccent {
  static const rose = Color(0xFF8A5A62);
}

abstract final class CatherineAccent {
  static const fire = Color(0xFF7A4A32);
}

abstract final class MontfortAccent {
  static const lily = Color(0xFF4A5A72);
}

abstract final class ScupoliAccent {
  static const steel = Color(0xFF4A5458);
}

abstract final class LawrenceAccent {
  static const hearth = Color(0xFF6A5840);
}

abstract final class CassianAccent {
  static const desert = Color(0xFF8A7048);
}

Color portalAccent(String portalId, int part) => switch (portalId) {
      'desales' => DesalesAccent.forPart(part),
      'kempis' => KempisAccent.forBook(part),
      'liguori' => LiguoriAccent.visit,
      'francis' => FrancisAccent.woodland,
      'john-cross' => JohnCrossAccent.night,
      'gregory' => GregoryAccent.stone,
      'augustine' => AugustineAccent.hearth,
      'teresa-avila' => TeresaAccent.forPart(part),
      'ignatius' => IgnatiusAccent.forPart(part),
      'therese' => ThereseAccent.rose,
      'catherine' => CatherineAccent.fire,
      'montfort' => MontfortAccent.lily,
      'scupoli' => ScupoliAccent.steel,
      'lawrence' => LawrenceAccent.hearth,
      'cassian' => CassianAccent.desert,
      _ => CycleAccent.winter,
    };

/// Drop-cap liturgical colors (v1 resolver).
abstract final class LiturgicalColor {
  static const green = Color(0xFF4F6146);
  static const violet = Color(0xFF4A4266);
  static const red = Color(0xFF8C2F26);
  static const gold = Color(0xFFA8802C);
  static const rose = Color(0xFFB07A85);
  static const black = Color(0xFF211D1A);
}
