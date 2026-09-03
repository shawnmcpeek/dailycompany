import 'package:dailycompany/app/theme/palette.dart';
import 'package:dailycompany/data/models/place_saint.dart';
import 'package:flutter/material.dart';

/// Offline California with the twenty-one missions. Equirectangular, no tiles.
class CaliforniaMissionsMap extends StatelessWidget {
  const CaliforniaMissionsMap({
    super.key,
    required this.stops,
    required this.unlocked,
    this.selectedOrder,
    required this.onSelect,
  });

  final List<PlaceStop> stops;
  final bool unlocked;
  final int? selectedOrder;
  final ValueChanged<PlaceStop> onSelect;

  static const _west = -124.6;
  static const _east = -113.8;
  static const _north = 42.15;
  static const _south = 32.35;

  /// Simplified state outline, west coast then Mexico, Colorado, Nevada, Oregon.
  static const _outline = <Offset>[
    Offset(-124.41, 42.00),
    Offset(-124.25, 41.05),
    Offset(-124.15, 40.25),
    Offset(-123.82, 39.20),
    Offset(-123.75, 38.55),
    Offset(-123.02, 38.02),
    Offset(-122.50, 37.78),
    Offset(-122.38, 37.10),
    Offset(-121.95, 36.55),
    Offset(-121.50, 35.70),
    Offset(-120.88, 35.18),
    Offset(-120.64, 34.58),
    Offset(-119.78, 34.45),
    Offset(-119.20, 34.10),
    Offset(-118.52, 33.76),
    Offset(-117.40, 33.20),
    Offset(-117.13, 32.54),
    Offset(-114.72, 32.72),
    Offset(-114.52, 34.05),
    Offset(-114.05, 35.00),
    Offset(-114.05, 36.20),
    Offset(-117.50, 37.50),
    Offset(-120.00, 39.00),
    Offset(-120.00, 42.00),
  ];

  /// South-to-north along the Camino, not founding order.
  static const _camino = <int>[
    1, 18, 7, 4, 17, 9, 10, 19, 11, 5, 16, 3, 13, 2, 15, 12, 8, 14, 6, 20, 21,
  ];

  static Offset project(double lat, double lon, Size size) {
    final x = (lon - _west) / (_east - _west) * size.width;
    final y = (_north - lat) / (_north - _south) * size.height;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final byOrder = {for (final s in stops) s.order: s};
    return AspectRatio(
      aspectRatio: 0.72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onTapDown: (details) {
              PlaceStop? hit;
              var best = 22.0;
              for (final s in stops) {
                final p = project(s.lat, s.lon, size);
                final d = (p - details.localPosition).distance;
                if (d < best) {
                  best = d;
                  hit = s;
                }
              }
              if (hit != null) onSelect(hit);
            },
            child: CustomPaint(
              size: size,
              painter: _MapPainter(
                stops: stops,
                byOrder: byOrder,
                unlocked: unlocked,
                selectedOrder: selectedOrder,
                outlineColor: Theme.of(context).dividerColor,
                ink: Theme.of(context).colorScheme.onSurface,
                adobe: SerraAccent.adobe,
                lasuen: SerraAccent.lasuen,
                last: SerraAccent.last,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.stops,
    required this.byOrder,
    required this.unlocked,
    required this.selectedOrder,
    required this.outlineColor,
    required this.ink,
    required this.adobe,
    required this.lasuen,
    required this.last,
  });

  final List<PlaceStop> stops;
  final Map<int, PlaceStop> byOrder;
  final bool unlocked;
  final int? selectedOrder;
  final Color outlineColor;
  final Color ink;
  final Color adobe;
  final Color lasuen;
  final Color last;

  Color _actColor(int act) => switch (act) {
        1 => adobe,
        2 => lasuen,
        _ => last,
      };

  void _strokeOrders(
    Canvas canvas,
    Size size,
    List<int> orders,
    Color color,
    double width,
  ) {
    final pts = <Offset>[];
    for (final order in orders) {
      final s = byOrder[order];
      if (s != null) {
        pts.add(CaliforniaMissionsMap.project(s.lat, s.lon, size));
      }
    }
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addPolygon(
        [
          for (final o in CaliforniaMissionsMap._outline)
            CaliforniaMissionsMap.project(o.dy, o.dx, size),
        ],
        true,
      );
    canvas.drawPath(
      outline,
      Paint()
        ..color = outlineColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = ink.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _strokeOrders(
      canvas,
      size,
      CaliforniaMissionsMap._camino,
      adobe.withValues(alpha: 0.22),
      1.1,
    );

    final through = selectedOrder ?? 0;
    if (through >= 2) {
      _strokeOrders(
        canvas,
        size,
        [for (var i = 1; i <= through; i++) i],
        adobe.withValues(alpha: 0.85),
        1.8,
      );
    }

    for (final s in stops) {
      final p = CaliforniaMissionsMap.project(s.lat, s.lon, size);
      final locked = !unlocked && !s.free;
      final selected = s.order == selectedOrder;
      final founded = selectedOrder == null || s.order <= selectedOrder!;
      final color = locked
          ? ink.withValues(alpha: 0.28)
          : founded
              ? _actColor(s.act)
              : _actColor(s.act).withValues(alpha: 0.22);
      canvas.drawCircle(p, selected ? 6.5 : 4.5, Paint()..color = color);
      if (selected) {
        canvas.drawCircle(
          p,
          8.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.unlocked != unlocked ||
      old.selectedOrder != selectedOrder ||
      old.stops != stops;
}
