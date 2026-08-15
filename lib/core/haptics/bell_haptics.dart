import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

enum BellKind { little, major, compline, lectioTick, complete }

abstract final class BellHaptics {
  static const _channel = MethodChannel('pro.daddoodev.benedictdaily/haptics');

  static Future<void> play(BellKind kind) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _channel.invokeMethod<void>('play', kind.name);
        return;
      } catch (_) {
        // Fall through to Flutter feedback if the channel is unavailable.
      }
    }

    switch (kind) {
      case BellKind.little:
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.lightImpact();
      case BellKind.major:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
      case BellKind.compline:
        await _complineDecay();
      case BellKind.lectioTick:
        await HapticFeedback.selectionClick();
      case BellKind.complete:
        await HapticFeedback.selectionClick();
    }
  }

  static Future<void> _complineDecay() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Soft envelope ~900ms — amplitude taper on Android API 26+.
      await Vibration.vibrate(
        pattern: [0, 180, 80, 160, 80, 140, 80, 120, 80, 100],
        intensities: [0, 180, 0, 140, 0, 100, 0, 70, 0, 40],
      );
    } else {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.lightImpact();
    }
  }
}
