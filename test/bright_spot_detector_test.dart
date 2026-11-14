import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reconex/features/camera_detector/lens_finder/bright_spot_detector.dart';

const int w = 640, h = 480, stride = 704; // stride > width, like real Android Y planes

/// Dark frame with optional bright rectangles (x, y, width, height in pixels).
Uint8List frame([List<(int, int, int, int)> rects = const []]) {
  final y = Uint8List(stride * h)..fillRange(0, stride * h, 20);
  for (final (rx, ry, rw, rh) in rects) {
    for (var py = ry; py < ry + rh; py++) {
      y.fillRange(py * stride + rx, py * stride + rx + rw, 255);
    }
  }
  return y;
}

void main() {
  group('findBrightSpots', () {
    test('dark frame has no spots', () {
      expect(findBrightSpots(frame(), w, h, stride), isEmpty);
    });

    test('one small dot is found at its position', () {
      final spots = findBrightSpots(frame([(480, 120, 3, 3)]), w, h, stride);
      expect(spots, hasLength(1));
      expect(spots.single.x, closeTo(481 / w, 0.02));
      expect(spots.single.y, closeTo(121 / h, 0.02));
      expect(spots.single.size, lessThan(0.05));
    });

    test('big bright area is rejected', () {
      expect(findBrightSpots(frame([(100, 100, 200, 150)]), w, h, stride), isEmpty);
    });

    test('small dot is still found next to a big bright area', () {
      final spots = findBrightSpots(frame([(0, 0, 320, 240), (500, 400, 3, 3)]), w, h, stride);
      expect(spots, hasLength(1));
      expect(spots.single.x, closeTo(501 / w, 0.02));
    });
  });

  group('SpotTracker', () {
    test('keeps a persistent spot and drops a one-frame flicker', () {
      final tracker = SpotTracker(window: 6, minHits: 3);
      const lens = BrightSpot(0.5, 0.5, 0.01);
      const flicker = BrightSpot(0.2, 0.8, 0.01);
      expect(tracker.update([lens]), isEmpty);
      expect(tracker.update([const BrightSpot(0.51, 0.5, 0.01), flicker]), isEmpty);
      final kept = tracker.update([const BrightSpot(0.52, 0.49, 0.01)]);
      expect(kept, hasLength(1));
      expect(kept.single.x, 0.52);
      expect(tracker.update([lens, flicker]).map((s) => s.x), [0.5]);
    });
  });

  group('toPreview', () {
    test('rear camera, sensor 90: image top-left lands top-right', () {
      expect(toPreview(0, 0, 1), (1.0, 0.0));
    });

    test('front camera, sensor 270, mirrored: image top-left lands bottom-right', () {
      expect(toPreview(0, 0, 3, mirror: true), (1.0, 1.0));
      expect(toPreview(0.25, 0.5, 3, mirror: true), (0.5, 0.75));
    });
  });
}
