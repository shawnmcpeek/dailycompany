import 'package:dailycompany/app/theme/palette.dart';
import 'package:flutter/material.dart';

/// Quiet paper material for the three reading surfaces.
///
/// Ground fills the desk (theme). Grain, wash, and edge tan live on
/// the reading leaf — see [ReadingLeaf].
@immutable
class ParchmentTheme extends ThemeExtension<ParchmentTheme> {
  const ParchmentTheme({
    required this.ground,
    required this.fiber,
    required this.washTop,
    required this.washBound,
    required this.grainOpacity,
    required this.grainDensity,
    required this.grainStroke,
    required this.hairline,
    required this.gutter,
    required this.foreEdge,
    required this.edgeTan,
    required this.edgeTanOpacity,
    required this.leafInset,
    required this.foreEdgeWidth,
  });

  final Color ground;
  final Color fiber;
  final Color washTop;
  final Color washBound;
  final double grainOpacity;
  final double grainDensity;
  final double grainStroke;
  final Color hairline;
  final Color gutter;
  final Color foreEdge;
  final Color edgeTan;
  final double edgeTanOpacity;
  final EdgeInsets leafInset;
  final double foreEdgeWidth;

  static ParchmentTheme of(BuildContext context) {
    return Theme.of(context).extension<ParchmentTheme>() ?? vellum;
  }

  static const leafPad = EdgeInsets.fromLTRB(8, 0, 0, 4);

  static const paper = ParchmentTheme(
    ground: Paper.bg,
    fiber: Color(0xFF6A5E50),
    washTop: Color(0xFFEFE3C4),
    washBound: Color(0xFFD2C6B0),
    grainOpacity: 0.085,
    grainDensity: 1.2,
    grainStroke: 1.25,
    hairline: Paper.rule,
    gutter: Color(0x33211D1A),
    foreEdge: Color(0x66C8BBA6),
    edgeTan: Color(0xFFC4A06A),
    edgeTanOpacity: 0.22,
    leafInset: leafPad,
    foreEdgeWidth: 5,
  );

  static const vellum = ParchmentTheme(
    ground: Vellum.bg,
    fiber: Color(0xFF5A4E40),
    washTop: Color(0xFFE6D3A6),
    washBound: Color(0xFFC4B49A),
    grainOpacity: 0.11,
    grainDensity: 1.45,
    grainStroke: 1.35,
    hairline: Vellum.rule,
    gutter: Color(0x3D211D1A),
    foreEdge: Color(0x73B7A88E),
    edgeTan: Color(0xFFB08958),
    edgeTanOpacity: 0.28,
    leafInset: leafPad,
    foreEdgeWidth: 5,
  );

  static const compline = ParchmentTheme(
    ground: Compline.bg,
    fiber: Color(0xFFC9B8A0),
    washTop: Color(0xFF2A2218),
    washBound: Color(0xFF0C0A08),
    grainOpacity: 0.06,
    grainDensity: 0.55,
    grainStroke: 1.15,
    hairline: Compline.rule,
    gutter: Color(0x66000000),
    foreEdge: Color(0x59E6DCCB),
    edgeTan: Color(0xFF3D2A18),
    edgeTanOpacity: 0.2,
    leafInset: leafPad,
    foreEdgeWidth: 5,
  );

  @override
  ParchmentTheme copyWith({
    Color? ground,
    Color? fiber,
    Color? washTop,
    Color? washBound,
    double? grainOpacity,
    double? grainDensity,
    double? grainStroke,
    Color? hairline,
    Color? gutter,
    Color? foreEdge,
    Color? edgeTan,
    double? edgeTanOpacity,
    EdgeInsets? leafInset,
    double? foreEdgeWidth,
  }) {
    return ParchmentTheme(
      ground: ground ?? this.ground,
      fiber: fiber ?? this.fiber,
      washTop: washTop ?? this.washTop,
      washBound: washBound ?? this.washBound,
      grainOpacity: grainOpacity ?? this.grainOpacity,
      grainDensity: grainDensity ?? this.grainDensity,
      grainStroke: grainStroke ?? this.grainStroke,
      hairline: hairline ?? this.hairline,
      gutter: gutter ?? this.gutter,
      foreEdge: foreEdge ?? this.foreEdge,
      edgeTan: edgeTan ?? this.edgeTan,
      edgeTanOpacity: edgeTanOpacity ?? this.edgeTanOpacity,
      leafInset: leafInset ?? this.leafInset,
      foreEdgeWidth: foreEdgeWidth ?? this.foreEdgeWidth,
    );
  }

  @override
  ParchmentTheme lerp(ThemeExtension<ParchmentTheme>? other, double t) {
    if (other is! ParchmentTheme) return this;
    return ParchmentTheme(
      ground: Color.lerp(ground, other.ground, t) ?? ground,
      fiber: Color.lerp(fiber, other.fiber, t) ?? fiber,
      washTop: Color.lerp(washTop, other.washTop, t) ?? washTop,
      washBound: Color.lerp(washBound, other.washBound, t) ?? washBound,
      grainOpacity: _lerp(grainOpacity, other.grainOpacity, t),
      grainDensity: _lerp(grainDensity, other.grainDensity, t),
      grainStroke: _lerp(grainStroke, other.grainStroke, t),
      hairline: Color.lerp(hairline, other.hairline, t) ?? hairline,
      gutter: Color.lerp(gutter, other.gutter, t) ?? gutter,
      foreEdge: Color.lerp(foreEdge, other.foreEdge, t) ?? foreEdge,
      edgeTan: Color.lerp(edgeTan, other.edgeTan, t) ?? edgeTan,
      edgeTanOpacity: _lerp(edgeTanOpacity, other.edgeTanOpacity, t),
      leafInset: EdgeInsets.lerp(leafInset, other.leafInset, t) ?? leafInset,
      foreEdgeWidth: _lerp(foreEdgeWidth, other.foreEdgeWidth, t),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
