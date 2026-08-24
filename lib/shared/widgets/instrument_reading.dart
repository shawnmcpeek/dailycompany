import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';

/// Today's instrument: the work, then Scripture when Benedict is echoing it.
class InstrumentReading extends StatelessWidget {
  const InstrumentReading({
    super.key,
    required this.tool,
    required this.total,
    this.showLabel = true,
    this.onTap,
  });

  final ToolOfGoodWorks tool;
  final int total;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabel) ...[
          ChromeLabel("Today's Rule"),
          const SizedBox(height: 8),
        ],
        Text(
          'Instrument ${tool.number} of $total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          tool.text,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (tool.hasScripture) ...[
          const SizedBox(height: 16),
          Text(
            tool.scripture!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tool.citation!,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
        if (tool.gloss?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            tool.gloss!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );

    if (onTap == null) return body;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: body,
      ),
    );
  }
}
