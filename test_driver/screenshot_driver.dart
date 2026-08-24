import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of [binding.takeScreenshot]. Writes PNGs to `screenshots/raw/<device>/`.
Future<void> main() async {
  final device = Platform.environment['SCREENSHOT_DEVICE'] ?? 'unknown_device';
  final dir = Directory('screenshots/raw/$device');

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(bytes, flush: true);
      stdout.writeln('Wrote ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
