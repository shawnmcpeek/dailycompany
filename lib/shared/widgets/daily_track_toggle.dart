import 'package:benedictdaily/core/cycle/life_track.dart';
import 'package:flutter/material.dart';

class DailyTrackToggle extends StatelessWidget {
  const DailyTrackToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DailyTrack value;
  final ValueChanged<DailyTrack> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option(context, 'Life', DailyTrack.life),
        const SizedBox(width: 8),
        _option(context, 'Rule', DailyTrack.rule),
        const SizedBox(width: 8),
        _option(context, 'Both', DailyTrack.both),
      ],
    );
  }

  Widget _option(BuildContext context, String label, DailyTrack track) {
    final selected = value == track;
    final child = Text(label);
    return Expanded(
      child: selected
          ? FilledButton(
              onPressed: () => onChanged(track),
              child: child,
            )
          : OutlinedButton(
              onPressed: () => onChanged(track),
              child: child,
            ),
    );
  }
}
