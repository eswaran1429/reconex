import 'package:flutter_test/flutter_test.dart';
import 'package:reconex/features/camera_detector/magnetometer/field_meter.dart';

void main() {
  /// Meter calibrated to a 50 µT room field, smoothing off.
  FieldMeter calibrated() {
    final m = FieldMeter(alpha: 1)..startCalibration();
    for (var i = 0; i < 10; i++) {
      m.add(30, 40, 0); // |v| = 50
    }
    m.finishCalibration();
    return m;
  }

  group('FieldMeter', () {
    test('magnitude of x/y/z', () {
      expect(FieldMeter.magnitude(3, 4, 12), 13);
    });

    test('no baseline means no delta and normal level', () {
      final m = FieldMeter()..add(0, 0, 80);
      expect(m.baseline, isNull);
      expect(m.delta, isNull);
      expect(m.level, FieldLevel.normal);
      expect(m.peak, 0);
    });

    test('baseline is the average over calibration', () {
      final m = FieldMeter()..startCalibration();
      m.add(0, 0, 40);
      m.add(0, 0, 60);
      expect(m.isCalibrating, isTrue);
      expect(m.finishCalibration(), isTrue);
      expect(m.isCalibrating, isFalse);
      expect(m.baseline, 50);
    });

    test('calibration with no samples keeps old baseline', () {
      final m = calibrated()..startCalibration();
      expect(m.finishCalibration(), isFalse);
      expect(m.baseline, 50);
    });

    test('delta is distance from baseline in either direction', () {
      final m = calibrated();
      expect(m.delta, 0);
      m.add(0, 0, 70);
      expect(m.delta, 20);
      m.add(0, 0, 35);
      expect(m.delta, 15);
    });

    test('levels follow the thresholds', () {
      expect(FieldMeter.levelFor(0), FieldLevel.normal);
      expect(FieldMeter.levelFor(14.9), FieldLevel.normal);
      expect(FieldMeter.levelFor(15), FieldLevel.raised);
      expect(FieldMeter.levelFor(39.9), FieldLevel.raised);
      expect(FieldMeter.levelFor(40), FieldLevel.strong);
      final m = calibrated()..add(0, 0, 100);
      expect(m.level, FieldLevel.strong);
    });

    test('smoothing moves part way to a new sample', () {
      final m = FieldMeter(alpha: 0.5);
      expect(m.add(0, 0, 50), 50);
      expect(m.add(0, 0, 70), 60);
      expect(m.add(0, 0, 70), 65);
    });

    test('peak holds the largest delta until reset', () {
      final m = calibrated();
      m.add(0, 0, 95);
      m.add(0, 0, 55);
      expect(m.delta, 5);
      expect(m.peak, 45);
      m.resetPeak();
      expect(m.peak, 0);
      m.add(0, 0, 60);
      expect(m.peak, 10);
    });

    test('recalibrating clears the peak', () {
      final m = calibrated()..add(0, 0, 95);
      m.startCalibration();
      m.add(0, 0, 95);
      m.finishCalibration();
      expect(m.peak, 0);
      expect(m.baseline, 95);
    });
  });
}
