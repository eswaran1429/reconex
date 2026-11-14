import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:reconex/features/camera_detector/magnetometer/field_meter.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Live magnetometer reading against a calibrated room baseline.
class MagnetometerController extends GetxController {
  static const Duration calibrationTime = Duration(seconds: 2);
  static const Duration _historySpan = Duration(seconds: 5);
  static final int historyLength = _historySpan.inMicroseconds ~/ SensorInterval.uiInterval.inMicroseconds;

  final FieldMeter _meter = FieldMeter();

  final RxnDouble current = RxnDouble();
  final RxnDouble delta = RxnDouble();
  final Rx<FieldLevel> level = FieldLevel.normal.obs;
  final RxDouble peak = 0.0.obs;
  final RxBool calibrating = false.obs;
  final RxnString error = RxnString();

  /// Smoothed magnitudes (µT) for the last ~5 s, oldest first.
  final RxList<double> history = <double>[].obs;

  StreamSubscription<MagnetometerEvent>? _sub;
  Timer? _calibrationTimer;

  @override
  void onInit() {
    super.onInit();
    _sub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
      _onSample,
      onError: (Object e) {
        error.value = e is PlatformException && e.code == 'NO_SENSOR'
            ? 'This phone has no magnetic sensor, so the field meter can\'t work here.'
            : 'Couldn\'t read the magnetic sensor.';
        _sub?.cancel();
      },
      cancelOnError: true,
    );
  }

  @override
  void onClose() {
    _calibrationTimer?.cancel();
    _sub?.cancel();
    super.onClose();
  }

  void _onSample(MagnetometerEvent e) {
    final value = _meter.add(e.x, e.y, e.z);
    current.value = value;
    delta.value = _meter.delta;
    level.value = _meter.level;
    peak.value = _meter.peak;
    if (history.length >= historyLength) history.removeAt(0);
    history.add(value);
  }

  /// Collects [calibrationTime] of samples and makes their average the baseline.
  void calibrate() {
    if (calibrating.value || error.value != null) return;
    calibrating.value = true;
    _meter.startCalibration();
    _calibrationTimer = Timer(calibrationTime, () {
      _meter.finishCalibration();
      calibrating.value = false;
      delta.value = _meter.delta;
      level.value = _meter.level;
      peak.value = _meter.peak;
    });
  }

  void resetPeak() {
    _meter.resetPeak();
    peak.value = 0;
  }
}
