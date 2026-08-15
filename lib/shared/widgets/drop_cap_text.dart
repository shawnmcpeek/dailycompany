import 'package:flutter/material.dart';

/// Illuminated drop cap — stroke then fill once per day.
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

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trimLeft();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final first = trimmed.characters.first;
    final rest = trimmed.characters.skip(1).toString().trimLeft();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: SizedBox(
                    width: 42,
                    height: 52,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: (1 - _fill.value).clamp(0, 1),
                          child: Text(
                            first,
                            style: widget.style.copyWith(
                              fontSize: 46,
                              height: 0.85,
                              color: widget.color.withValues(alpha: 0),
                              shadows: [
                                Shadow(
                                  color: widget.color.withValues(
                                    alpha: _stroke.value,
                                  ),
                                  blurRadius: 0.4,
                                ),
                              ],
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1.2
                                ..color = widget.color.withValues(
                                  alpha: _stroke.value,
                                ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _fill.value,
                          child: Text(
                            first,
                            style: widget.style.copyWith(
                              fontSize: 46,
                              height: 0.85,
                              color: widget.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextSpan(text: rest, style: widget.style),
            ],
          ),
        );
      },
    );
  }
}
