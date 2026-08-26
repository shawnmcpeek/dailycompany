import 'dart:async';

import 'package:dailycompany/core/haptics/bell_haptics.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerMovement {
  const TimerMovement({
    required this.label,
    required this.prompt,
    required this.seconds,
  });

  final String label;
  final String prompt;
  final int seconds;
}

/// A fixed-movement guided timer — the shared mechanic behind Lectio's
/// four movements and de Sales' Morning Exercise / Evening Examination.
/// Movements are fixed (not user-adjustable), unlike Lectio's sliders.
class GuidedTimer extends ConsumerStatefulWidget {
  const GuidedTimer({super.key, required this.movements});

  final List<TimerMovement> movements;

  @override
  ConsumerState<GuidedTimer> createState() => _GuidedTimerState();
}

class _GuidedTimerState extends ConsumerState<GuidedTimer> {
  int _index = 0;
  late int _remaining = widget.movements.first.seconds;
  Timer? _timer;
  bool _running = false;

  TimerMovement get _current => widget.movements[_index];

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _advance();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _advance() {
    _timer?.cancel();
    if (ref.read(settingsProvider).hapticsEnabled) {
      BellHaptics.play(BellKind.lectioTick);
    }
    if (_index >= widget.movements.length - 1) {
      setState(() {
        _running = false;
        _remaining = 0;
      });
      return;
    }
    setState(() {
      _index += 1;
      _remaining = _current.seconds;
    });
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _remaining -= 1;
          if (_remaining <= 0) _advance();
        });
      });
    }
  }

  String _fmt(int seconds) {
    final s = seconds.clamp(0, 999);
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= widget.movements.length - 1 && _remaining <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _current.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        Text(
          _current.prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Text(
          _fmt(_remaining),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!done) ...[
              FilledButton(
                onPressed: _running ? _pause : _start,
                child: Text(_running ? 'Pause' : 'Begin'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _advance,
                child: const Text('Next movement'),
              ),
            ] else
              Text(
                'Complete.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ],
    );
  }
}
