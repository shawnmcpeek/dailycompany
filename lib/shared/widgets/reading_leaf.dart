import 'package:dailycompany/app/theme/parchment.dart';
import 'package:dailycompany/app/theme/parchment_field.dart';
import 'package:flutter/material.dart';

/// A reading page: inset leaf, fiber, hairline, gutter, stacked fore-edge.
///
/// Chrome stays on the desk. Only wrap [ReadingScrollView].
class ReadingLeaf extends StatelessWidget {
  const ReadingLeaf({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parchment = ParchmentTheme.of(context);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final textDirection = Directionality.of(context);

    final page = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: parchment.hairline, width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ParchmentPagePainter(
              parchment,
              textDirection: textDirection,
            ),
            isComplex: true,
            willChange: false,
            child: const SizedBox.expand(),
          ),
          child,
          Positioned(
            top: 0,
            bottom: 0,
            left: ltr ? 0 : null,
            right: ltr ? null : 0,
            width: 2,
            child: ColoredBox(color: parchment.gutter),
          ),
        ],
      ),
    );

    final edge = SizedBox(
      width: parchment.foreEdgeWidth,
      child: CustomPaint(
        painter: _ForeEdgePainter(parchment, ltr: ltr),
        child: const SizedBox.expand(),
      ),
    );

    final inset = parchment.leafInset;
    return Padding(
      padding: EdgeInsets.only(
        left: ltr ? inset.left : inset.right,
        right: ltr ? inset.right : inset.left,
        top: inset.top,
        bottom: inset.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ltr
            ? [Expanded(child: page), edge]
            : [edge, Expanded(child: page)],
      ),
    );
  }
}

class _ForeEdgePainter extends CustomPainter {
  _ForeEdgePainter(this.parchment, {required this.ltr});

  final ParchmentTheme parchment;
  final bool ltr;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = parchment.foreEdge;
    final xs = ltr
        ? [size.width * 0.25, size.width * 0.55, size.width * 0.85]
        : [size.width * 0.15, size.width * 0.45, size.width * 0.75];
    for (final x in xs) {
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ForeEdgePainter oldDelegate) {
    return oldDelegate.parchment != parchment || oldDelegate.ltr != ltr;
  }
}
