import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

class SectionRule extends StatelessWidget {
  const SectionRule({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color ?? Theme.of(context).dividerColor);
  }
}

class ChromeLabel extends StatelessWidget {
  const ChromeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: 'EBGaramond',
        fontSize: 12,
        height: 1.3,
        letterSpacing: 0.96,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.labelSmall?.color,
        fontFeatures: const [FontFeature.enable('smcp')],
      ),
    );
  }
}

class EmptyLoading extends StatelessWidget {
  const EmptyLoading({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class ReadingBody extends StatelessWidget {
  const ReadingBody({super.key, required this.text, this.style});

  final String text;
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
            child: Text(p, style: base),
          ),
      ],
    );
  }
}

/// Full-width hub destination — reads as navigation, not a checklist item.
class HubNavButton extends StatelessWidget {
  const HubNavButton({
    super.key,
    required this.title,
    required this.subtitle,
    this.onPressed,
    this.actionLabel = 'Open',
  });

  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final rule = Theme.of(context).dividerColor;
    final secondary = Theme.of(context).textTheme.bodySmall?.color;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        side: BorderSide(color: rule),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            actionLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: secondary),
          ),
          Icon(Icons.chevron_right, size: 20, color: secondary),
        ],
      ),
    );
  }
}
