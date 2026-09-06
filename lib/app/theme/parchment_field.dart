import 'dart:math';

import 'package:dailycompany/app/theme/parchment.dart';
import 'package:flutter/material.dart';

/// Paper ground, fiber grain, and a soft wash behind the whole app.
class ParchmentField extends StatelessWidget {
  const ParchmentField({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parchment = ParchmentTheme.of(context);
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: parchment.ground),
        RepaintBoundary(
          child: CustomPaint(
            painter: ParchmentFieldPainter(
              parchment,
              textDirection: textDirection,
            ),
            isComplex: true,
            willChange: false,
          ),
        ),
        child,
      ],
    );
  }
}

class ParchmentFieldPainter extends CustomPainter {
  ParchmentFieldPainter(this.parchment, {required this.textDirection});

  final ParchmentTheme parchment;
  final TextDirection textDirection;

  static const _seed = 7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _paintWash(canvas, size);
    _paintGrain(canvas, size);
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
    final count = min(820, (area / 980 * parchment.grainDensity).round());
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 2.5 + rnd.nextDouble() * 8;
      final angle = (rnd.nextDouble() - 0.5) * 0.5;
      final alpha =
          parchment.grainOpacity * (0.35 + rnd.nextDouble() * 0.65);
      stroke
        ..strokeWidth = 0.45 + rnd.nextDouble() * 0.35
        ..color = parchment.fiber.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len * cos(angle), y + len * sin(angle)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParchmentFieldPainter oldDelegate) {
    return oldDelegate.parchment != parchment ||
        oldDelegate.textDirection != textDirection;
  }
}

Widget parchmentAppBuilder(BuildContext context, Widget? child) {
  return ParchmentField(child: child ?? const SizedBox.shrink());
}
