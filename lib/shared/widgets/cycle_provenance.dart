import 'package:flutter/material.dart';

/// The tappable cycle-position line from spec §4 — same optical weight as
/// the surrounding text; the ⓘ is a line glyph, not a filled badge, and
/// carries no accent color or tint.
class CycleProvenanceLine extends StatelessWidget {
  const CycleProvenanceLine({
    super.key,
    required this.label,
    required this.style,
    required this.sheetTitle,
    required this.sheetParagraphs,
  });

  final String label;
  final TextStyle? style;
  final String sheetTitle;
  final List<String> sheetParagraphs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showCycleProvenanceSheet(
        context,
        title: sheetTitle,
        paragraphs: sheetParagraphs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: 6),
          Icon(
            Icons.info_outline,
            size: (style?.fontSize ?? 12) + 2,
            color: style?.color,
          ),
        ],
      ),
    );
  }
}

Future<void> showCycleProvenanceSheet(
  BuildContext context, {
  required String title,
  required List<String> paragraphs,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              for (var i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Text(
                  paragraphs[i],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
