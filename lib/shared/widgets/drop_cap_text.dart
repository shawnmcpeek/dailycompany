import 'package:flutter/material.dart';

/// Illuminated drop cap — stroke then fill once per day.
///
/// Laid out as inline [TextSpan]s (not a fixed-size [WidgetSpan]) so the
/// initial keeps normal kerning with the next letter and body line height.
class DropCapText extends StatefulWidget {
  const DropCapText({
    super.key,
    required this.text,
    required this.color,
    required this.style,
    this.animate = true,
  });

  final String text;
  final Color color;
  final TextStyle style;
  final bool animate;

  @override
  State<DropCapText> createState() => _DropCapTextState();
}

class _DropCapTextState extends State<DropCapText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _stroke;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _stroke = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    _fill = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _capStyle(TextStyle base, double bodySize) {
    final capSize = bodySize * 1.85;
    final fill = _fill.value;
    final stroke = _stroke.value;

    TextStyle sized({Color? color, Paint? foreground, List<Shadow>? shadows}) {
      // Build without inheriting base.color when using foreground (mutually exclusive).
      return TextStyle(
        inherit: false,
        fontFamily: base.fontFamily,
        fontFamilyFallback: base.fontFamilyFallback,
        fontSize: capSize,
        fontWeight: base.fontWeight,
        fontStyle: base.fontStyle,
        letterSpacing: base.letterSpacing,
        wordSpacing: base.wordSpacing,
        height: base.height,
        locale: base.locale,
        color: color,
        foreground: foreground,
        shadows: shadows,
      );
    }

    if (fill >= 0.99) {
      return sized(color: widget.color);
    }

    if (fill > 0) {
      return sized(
        color: widget.color.withValues(alpha: fill),
        shadows: [
          Shadow(
            color: widget.color.withValues(alpha: (1 - fill) * stroke),
            blurRadius: 0.4,
          ),
        ],
      );
    }

    return sized(
      shadows: [
        Shadow(
          color: widget.color.withValues(alpha: stroke),
          blurRadius: 0.4,
        ),
      ],
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = widget.color.withValues(alpha: stroke),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trimLeft();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final first = trimmed.characters.first;
    // Keep the rest intact so spacing/kerning after the initial stays natural.
    final rest = trimmed.characters.skip(1).toString();
    final bodySize = widget.style.fontSize ?? 16;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: first,
                style: _capStyle(widget.style, bodySize),
              ),
              TextSpan(text: rest, style: widget.style),
            ],
          ),
          strutStyle: StrutStyle.fromTextStyle(
            widget.style,
            forceStrutHeight: true,
          ),
        );
      },
    );
  }
}
