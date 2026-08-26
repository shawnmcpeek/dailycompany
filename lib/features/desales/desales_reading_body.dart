import 'package:flutter/material.dart';

/// The Bouquet gesture (spec §8.2): select any sentence, then tap "Keep"
/// in the selection toolbar — the same gesture as copying text, so it
/// needs no explanation. [onKeep] receives the trimmed selected text.
class BouquetReadingBody extends StatelessWidget {
  const BouquetReadingBody({
    super.key,
    required this.text,
    required this.onKeep,
    this.style,
  });

  final String text;
  final ValueChanged<String> onKeep;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SelectableText(
              p,
              style: base,
              contextMenuBuilder: (context, editableTextState) {
                final selection = editableTextState.textEditingValue.selection;
                final selected = selection.textInside(
                  editableTextState.textEditingValue.text,
                );
                final buttons = [
                  ...editableTextState.contextMenuButtonItems,
                  if (selected.trim().isNotEmpty)
                    ContextMenuButtonItem(
                      label: 'Keep',
                      onPressed: () {
                        onKeep(selected.trim());
                        editableTextState.hideToolbar();
                      },
                    ),
                ];
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: buttons,
                );
              },
            ),
          ),
      ],
    );
  }
}
