import 'package:benedictdaily/features/medal/medal_hotspots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reverse', () {
    test('PAX is at the top', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(168, 32)),
        'pax',
      );
    });

    test('vertical beam is CSSML', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(168, 80)),
        'cssml',
      );
    });

    test('horizontal beam is NDSMD', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(80, 163)),
        'ndsmd',
      );
    });

    test('centre S prefers the vertical when equally close', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(168.72, 163.34)),
        'cssml',
      );
    });

    test('four corners are CSPB', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(116.4, 111.2)),
        'cspb',
      );
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(220.6, 111.2)),
        'cspb',
      );
    });

    test('outer ring is the Vade Retro verse', () {
      expect(
        MedalHotspots.hitTest(MedalFace.reverse, const Offset(300, 163)),
        'vrsnsmv_smqlivb',
      );
    });
  });

  group('obverse', () {
    test('cup is on the left', () {
      expect(
        MedalHotspots.hitTest(MedalFace.obverse, const Offset(50, 110)),
        'cup',
      );
    });

    test('raven is on the right', () {
      expect(
        MedalHotspots.hitTest(MedalFace.obverse, const Offset(200, 110)),
        'raven',
      );
    });

    test('Benedict is in the centre', () {
      expect(
        MedalHotspots.hitTest(MedalFace.obverse, const Offset(125, 100)),
        'benedict',
      );
    });

    test('Monte Cassino sits under his feet', () {
      expect(
        MedalHotspots.hitTest(MedalFace.obverse, const Offset(125, 214)),
        'casino',
      );
    });
  });
}
