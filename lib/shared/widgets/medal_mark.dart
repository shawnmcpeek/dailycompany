import 'package:benedictdaily/features/medal/medal_hotspots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reverse of the medal (letter side). Reads at small sizes; invert on dark paper.
class MedalMark extends StatelessWidget {
  const MedalMark({super.key, this.size = 36, this.onTap, this.invite = false});

  final double size;
  final VoidCallback? onTap;
  final bool invite;

  // dart format off
  static const _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);
  // dart format on

  @override
  Widget build(BuildContext context) {
    Widget mark = SvgPicture.asset(
      MedalHotspots.assetFor(MedalFace.reverse),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (Theme.of(context).brightness == Brightness.dark) {
      mark = ColorFiltered(colorFilter: _invert, child: mark);
    }
    if (onTap == null) return mark;
    final button = IconButton(
      tooltip: 'The Medal',
      onPressed: onTap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: mark,
    );
    if (!invite) return button;
    return _MedalGlow(child: button);
  }
}

class _MedalGlow extends StatefulWidget {
  const _MedalGlow({required this.child});

  final Widget child;

  @override
  State<_MedalGlow> createState() => _MedalGlowState();
}

class _MedalGlowState extends State<_MedalGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.4;
      return;
    }
    _breathe();
  }

  Future<void> _breathe() async {
    const curve = Curves.easeInOut;
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      await _controller.animateTo(1, curve: curve);
      if (!mounted) return;
      await _controller.animateTo(0, curve: curve);
    }
    if (!mounted) return;
    await _controller.animateTo(0.4, curve: curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: 0.2 + 0.55 * t),
                blurRadius: 6 + 10 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
