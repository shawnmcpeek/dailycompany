import 'dart:math' as math;
import 'dart:ui';

enum MedalFace { obverse, reverse }

/// Hit regions in each face's native image coordinates.
abstract final class MedalHotspots {
  static const reverseSize = Size(334, 326);
  static const obverseSize = Size(250, 245);

  static Size sizeFor(MedalFace face) =>
      face == MedalFace.reverse ? reverseSize : obverseSize;

  static String? hitTest(MedalFace face, Offset p) {
    if (face == MedalFace.reverse) return _hitReverse(p);
    return _hitObverse(p);
  }

  static MedalOutline? outline(String id) => _outlines[id];

  static String? _hitReverse(Offset p) {
    if (_inRect(p, _pax)) return 'pax';
    for (final c in _cspb) {
      if (_inCircle(p, c.$1, c.$2)) return 'cspb';
    }
    final onV = _inRect(p, _cssml);
    final onH = _inRect(p, _ndsmd);
    if (onV && onH) {
      final dx = (p.dx - _reverseCenter.dx).abs();
      final dy = (p.dy - _reverseCenter.dy).abs();
      return dy >= dx ? 'cssml' : 'ndsmd';
    }
    if (onV) return 'cssml';
    if (onH) return 'ndsmd';
    if (_inAnnulus(p, _reverseCenter, 112, 150)) return 'vrsnsmv_smqlivb';
    return null;
  }

  static String? _hitObverse(Offset p) {
    if (_inRect(p, _casino)) return 'casino';
    if (_inRect(p, _cup)) return 'cup';
    if (_inRect(p, _raven)) return 'raven';
    if (_inRect(p, _benedict)) return 'benedict';
    if (_inAnnulus(p, _obverseCenter, 92, 122)) return 'obitu';
    return null;
  }

  static bool _inRect(Offset p, Rect r) => r.contains(p);

  static bool _inCircle(Offset p, Offset c, double r) =>
      (p - c).distance <= r;

  static bool _inAnnulus(Offset p, Offset c, double inner, double outer) {
    final d = (p - c).distance;
    return d >= inner && d <= outer;
  }

  static const _reverseCenter = Offset(168.72, 163.34);
  static const _obverseCenter = Offset(125, 122);

  static final _pax = Rect.fromLTWH(118, 14, 100, 42);
  static final _cssml = Rect.fromLTWH(148, 58, 38, 210);
  static final _ndsmd = Rect.fromLTWH(55, 145, 224, 40);
  static const _cspb = <(Offset, double)>[
    (Offset(116.4, 111.2), 24),
    (Offset(220.6, 111.2), 24),
    (Offset(116.5, 215.5), 24),
    (Offset(220.8, 215.4), 24),
  ];

  static final _benedict = Rect.fromLTWH(78, 42, 94, 155);
  static final _cup = Rect.fromLTWH(22, 52, 62, 128);
  static final _raven = Rect.fromLTWH(166, 52, 62, 128);
  static final _casino = Rect.fromLTWH(68, 198, 114, 32);

  static final Map<String, MedalOutline> _outlines = {
    'pax': MedalOutline.rect(_pax),
    'cssml': MedalOutline.rect(_cssml),
    'ndsmd': MedalOutline.rect(_ndsmd),
    'cspb': MedalOutline.circles(_cspb),
    'vrsnsmv_smqlivb': MedalOutline.annulus(_reverseCenter, 112, 150),
    'benedict': MedalOutline.rect(_benedict),
    'cup': MedalOutline.rect(_cup),
    'raven': MedalOutline.rect(_raven),
    'casino': MedalOutline.rect(_casino),
    'obitu': MedalOutline.annulus(_obverseCenter, 92, 122),
  };
}

enum MedalOutlineKind { rect, circles, annulus }

class MedalOutline {
  const MedalOutline._(this.kind, {this.rect, this.circles, this.center, this.inner, this.outer});

  factory MedalOutline.rect(Rect rect) =>
      MedalOutline._(MedalOutlineKind.rect, rect: rect);

  factory MedalOutline.circles(List<(Offset, double)> circles) =>
      MedalOutline._(MedalOutlineKind.circles, circles: circles);

  factory MedalOutline.annulus(Offset center, double inner, double outer) =>
      MedalOutline._(
        MedalOutlineKind.annulus,
        center: center,
        inner: inner,
        outer: outer,
      );

  final MedalOutlineKind kind;
  final Rect? rect;
  final List<(Offset, double)>? circles;
  final Offset? center;
  final double? inner;
  final double? outer;
}

/// Maps a tap in the widget to native image coordinates under BoxFit.contain.
Offset? medalImagePoint({
  required Offset local,
  required Size widget,
  required Size image,
}) {
  final scale = math.min(widget.width / image.width, widget.height / image.height);
  final w = image.width * scale;
  final h = image.height * scale;
  final dx = (widget.width - w) / 2;
  final dy = (widget.height - h) / 2;
  final x = (local.dx - dx) / scale;
  final y = (local.dy - dy) / scale;
  if (x < 0 || y < 0 || x > image.width || y > image.height) return null;
  return Offset(x, y);
}
