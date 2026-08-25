import 'package:dailycompany/features/medal/medal_hotspots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MedalDiagram extends StatelessWidget {
  const MedalDiagram({
    super.key,
    required this.face,
    required this.selectedId,
    required this.onSelect,
    required this.obverseAsset,
    required this.reverseAsset,
  });

  final MedalFace face;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String obverseAsset;
  final String reverseAsset;

  @override
  Widget build(BuildContext context) {
    final image = MedalHotspots.sizeFor(face);
    final gold = Theme.of(context).colorScheme.secondary;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final p = medalImagePoint(
                local: details.localPosition,
                widget: widgetSize,
                image: image,
              );
              if (p == null) return;
              final id = MedalHotspots.hitTest(face, p);
              if (id != null) onSelect(id);
            },
            child: CustomPaint(
              foregroundPainter: _OutlinePainter(
                face: face,
                selectedId: selectedId,
                color: gold,
                widgetSize: widgetSize,
              ),
              child: face == MedalFace.reverse
                  ? SvgPicture.asset(reverseAsset, fit: BoxFit.contain)
                  : Image.asset(
                      obverseAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter({
    required this.face,
    required this.selectedId,
    required this.color,
    required this.widgetSize,
  });

  final MedalFace face;
  final String? selectedId;
  final Color color;
  final Size widgetSize;

  @override
  void paint(Canvas canvas, Size size) {
    final id = selectedId;
    if (id == null) return;
    final outline = MedalHotspots.outline(id);
    if (outline == null) return;

    final image = MedalHotspots.sizeFor(face);
    final scale = size.width / image.width < size.height / image.height
        ? size.width / image.width
        : size.height / image.height;
    final dx = (size.width - image.width * scale) / 2;
    final dy = (size.height - image.height * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / scale
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    switch (outline.kind) {
      case MedalOutlineKind.rect:
        final r = RRect.fromRectAndRadius(
          outline.rect!,
          const Radius.circular(6),
        );
        canvas.drawRRect(r, fill);
        canvas.drawRRect(r, stroke);
      case MedalOutlineKind.circles:
        for (final c in outline.circles!) {
          canvas.drawCircle(c.$1, c.$2, fill);
          canvas.drawCircle(c.$1, c.$2, stroke);
        }
      case MedalOutlineKind.annulus:
        final path = Path()
          ..addOval(Rect.fromCircle(
            center: outline.center!,
            radius: outline.outer!,
          ))
          ..addOval(Rect.fromCircle(
            center: outline.center!,
            radius: outline.inner!,
          ))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(path, fill);
        canvas.drawCircle(outline.center!, outline.outer!, stroke);
        canvas.drawCircle(outline.center!, outline.inner!, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OutlinePainter old) =>
      old.selectedId != selectedId ||
      old.face != face ||
      old.color != color ||
      old.widgetSize != widgetSize;
}
