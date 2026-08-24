import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Reads Android captures from screenshots/raw/ and writes store files:
///   Play  — same pixels, cropped to ≤2:1 if needed
///   iOS   — resized from those Android PNGs to Apple's exact sizes
void main() {
  final root = Directory.current.path;
  final rawRoot = Directory('$root/screenshots/raw');
  if (!rawRoot.existsSync()) {
    stderr.writeln('No screenshots/raw/. Run tool/screenshots.sh first.');
    exit(1);
  }

  final androidDir = _androidRawDir(rawRoot);
  if (androidDir == null) {
    stderr.writeln('No Android PNGs under screenshots/raw/.');
    exit(1);
  }

  final pngs = androidDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (pngs.isEmpty) {
    stderr.writeln('No PNGs in ${androidDir.path}');
    exit(1);
  }

  final rows = <List<String>>[];

  for (final file in pngs) {
    final shot = file.uri.pathSegments.last.replaceAll('.png', '');
    final src = img.decodePng(file.readAsBytesSync());
    if (src == null) {
      stderr.writeln('Not a PNG: ${file.path}');
      exit(1);
    }

    for (final target in _targets) {
      final out = _fit(src, target.width, target.height, cropToRatio: target.playRatio);
      final dest = target.path(root, shot);
      Directory(File(dest).parent.path).createSync(recursive: true);
      File(dest).writeAsBytesSync(img.encodePng(out));
      rows.add([
        shot,
        target.label,
        '${out.width}×${out.height}',
        dest,
      ]);
    }
  }

  stdout.writeln(
    '${'screen'.padRight(24)}${'device'.padRight(22)}'
    '${'size'.padRight(14)}path',
  );
  for (final r in rows) {
    stdout.writeln(
      '${r[0].padRight(24)}${r[1].padRight(22)}${r[2].padRight(14)}${r[3]}',
    );
  }
}

Directory? _androidRawDir(Directory rawRoot) {
  Directory? named;
  Directory? any;
  for (final dir in rawRoot.listSync().whereType<Directory>()) {
    final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final hasPng = dir.listSync().whereType<File>().any((f) => f.path.endsWith('.png'));
    if (!hasPng) continue;
    any ??= dir;
    if (name.startsWith('pixel') || name.startsWith('android')) {
      named = dir;
    }
  }
  return named ?? any;
}

/// Cover-scale, then crop. Keeps the top; trims sides or bottom.
img.Image _fit(img.Image src, int tw, int th, {required bool cropToRatio}) {
  var image = src;
  if (cropToRatio) {
    final maxH = image.width * 2;
    if (image.height > maxH) {
      image = img.copyCrop(image, x: 0, y: 0, width: image.width, height: maxH);
    }
    if (image.width == tw && image.height == th) return image;
    // Play accepts any legal size; only resize when a target size is set.
    if (tw == 0 || th == 0) return image;
  }

  if (image.width == tw && image.height == th) return image;

  final scale = math.max(tw / image.width, th / image.height);
  final nw = math.max(tw, (image.width * scale).ceil());
  final nh = math.max(th, (image.height * scale).ceil());
  final sized = img.copyResize(
    image,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.cubic,
  );
  final x = ((sized.width - tw) / 2).round().clamp(0, math.max(0, sized.width - tw));
  const y = 0;
  return img.copyCrop(
    sized,
    x: x.toInt(),
    y: y,
    width: tw,
    height: th,
  );
}

class _Target {
  const _Target({
    required this.label,
    required this.width,
    required this.height,
    required this.playRatio,
    required this.path,
  });

  final String label;
  final int width;
  final int height;
  final bool playRatio;
  final String Function(String root, String shot) path;
}

final _targets = <_Target>[
  _Target(
    label: 'Pixel 7 Pro',
    width: 1440,
    height: 2880,
    playRatio: true,
    path: (root, shot) =>
        '$root/fastlane/metadata/android/en-US/images/phoneScreenshots/$shot.png',
  ),
  _Target(
    label: 'iPhone 16 Pro Max',
    width: 1320,
    height: 2868,
    playRatio: false,
    path: (root, shot) =>
        '$root/fastlane/screenshots/en-US/iPhone 16 Pro Max-$shot.png',
  ),
  _Target(
    label: 'iPhone 15 Plus',
    width: 1290,
    height: 2796,
    playRatio: false,
    path: (root, shot) =>
        '$root/fastlane/screenshots/en-US/iPhone 15 Plus-$shot.png',
  ),
];
