import 'package:benedictdaily/app/brand.dart';
import 'package:benedictdaily/app/theme/palette.dart';
import 'package:benedictdaily/data/content_catalog.dart';
import 'package:flutter/material.dart';

/// Fixed share canvas — vellum, brand-first, one instrument.
class ToolShareCard extends StatelessWidget {
  const ToolShareCard({
    super.key,
    required this.tool,
    required this.total,
    this.width = 1080,
    this.height = 1350,
  });

  final ToolOfGoodWorks tool;
  final int total;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Vellum.bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 80, 72, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Brand.studio.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 22,
                  letterSpacing: 3.2,
                  color: Vellum.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Benedict Daily',
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 56,
                  height: 1.05,
                  color: Vellum.ink,
                ),
              ),
              const SizedBox(height: 28),
              Container(height: 2, color: Vellum.gold.withValues(alpha: 0.55)),
              const Spacer(flex: 2),
              Text(
                '№ ${tool.number}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 28,
                  letterSpacing: 2.4,
                  color: Vellum.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tool.text,
                style: const TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 54,
                  height: 1.35,
                  color: Vellum.ink,
                ),
              ),
              const Spacer(flex: 3),
              Container(height: 1, color: Vellum.rule),
              const SizedBox(height: 28),
              Text(
                'Rule of St. Benedict · chapter 4',
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 26,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                  color: Vellum.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Instrument ${tool.number} of $total',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 22,
                  letterSpacing: 0.6,
                  color: Vellum.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
