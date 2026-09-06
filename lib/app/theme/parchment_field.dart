import 'dart:math';

import 'package:dailycompany/app/theme/parchment.dart';
import 'package:flutter/material.dart';

/// Plain paper ground behind the whole app — the desk.
///
/// Fiber lives on the reading leaf, not here.
class ParchmentField extends StatelessWidget {
  const ParchmentField({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ParchmentTheme.of(context).ground,
      child: child,
    );
  }
}

/// Wash and fiber for the reading leaf only.
class ParchmentPagePainter extends CustomPainter {
  ParchmentPagePainter(this.parchment, {required this.textDirection});

  final ParchmentTheme parchment;
  final TextDirection textDirection;

  static const _seed = 7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = parchment.ground);
    _paintWash(canvas, size);
    _paintGrain(canvas, size);
    _paintAge(canvas, size);
  }

  void _paintWash(Canvas canvas, Size size) {
    final vertical = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          parchment.washTop.withValues(alpha: 0.11),
          parchment.ground.withValues(alpha: 0),
          parchment.washBound.withValues(alpha: 0.08),
        ],
        stops: const [0, 0.42, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vertical);

    final boundIsStart = textDirection == TextDirection.ltr;
    final bound = Paint()
      ..shader = LinearGradient(
        begin: boundIsStart ? Alignment.centerLeft : Alignment.centerRight,
        end: boundIsStart ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          parchment.washBound.withValues(alpha: 0.1),
          parchment.ground.withValues(alpha: 0),
          parchment.ground.withValues(alpha: 0),
        ],
        stops: const [0, 0.28, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bound);

    final edge = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 1.15,
        colors: [
          parchment.ground.withValues(alpha: 0),
          parchment.washBound.withValues(alpha: 0.07),
        ],
        stops: const [0.62, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edge);
  }

  void _paintGrain(Canvas canvas, Size size) {
    final rnd = Random(_seed);
    final area = size.width * size.height;
    final fibers = min(4200, (area / 220 * parchment.grainDensity).round());
    final flecks = min(1800, (area / 520 * parchment.grainDensity).round());
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final speck = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < fibers; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 5 + rnd.nextDouble() * 12;
      final angle = (rnd.nextDouble() - 0.5) * 0.55;
      final alpha =
          parchment.grainOpacity * (0.72 + rnd.nextDouble() * 0.28);
      stroke
        ..strokeWidth = parchment.grainStroke * (0.85 + rnd.nextDouble() * 0.4)
        ..color = parchment.fiber.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len * cos(angle), y + len * sin(angle)),
        stroke,
      );
    }

    for (var i = 0; i < flecks; i++) {
      final alpha =
          parchment.grainOpacity * (0.45 + rnd.nextDouble() * 0.35);
      speck.color = parchment.fiber.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.55 + rnd.nextDouble() * 0.7,
        speck,
      );
    }
  }

  /// Tea-stain at the rim. Strongest on the open edge, quiet at the gutter.
  void _paintAge(Canvas canvas, Size size) {
    final tan = parchment.edgeTan;
    final strength = parchment.edgeTanOpacity;
    final ltr = textDirection == TextDirection.ltr;
    final rect = Offset.zero & size;

    void band({
      required Alignment begin,
      required Alignment end,
      required double opacity,
      required List<double> stops,
    }) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: [
              tan.withValues(alpha: opacity),
              tan.withValues(alpha: opacity * 0.45),
              tan.withValues(alpha: 0),
            ],
            stops: stops,
          ).createShader(rect),
      );
    }

    band(
      begin: ltr ? Alignment.centerRight : Alignment.centerLeft,
      end: ltr ? Alignment.centerLeft : Alignment.centerRight,
      opacity: strength,
      stops: const [0, 0.04, 0.18],
    );
    band(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      opacity: strength * 0.55,
      stops: const [0, 0.03, 0.1],
    );
    band(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      opacity: strength * 0.55,
      stops: const [0, 0.03, 0.1],
    );
    band(
      begin: ltr ? Alignment.centerLeft : Alignment.centerRight,
      end: ltr ? Alignment.centerRight : Alignment.centerLeft,
      opacity: strength * 0.28,
      stops: const [0, 0.02, 0.07],
    );
  }

  @override
  bool shouldRepaint(covariant ParchmentPagePainter oldDelegate) {
    return oldDelegate.parchment != parchment ||
        oldDelegate.textDirection != textDirection;
  }
}

Widget parchmentAppBuilder(BuildContext context, Widget? child) {
  return ParchmentField(child: child ?? const SizedBox.shrink());
}
