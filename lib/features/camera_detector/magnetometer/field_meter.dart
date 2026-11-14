import 'dart:math' as math;

/// How far the field is above the calibrated room baseline.
enum FieldLevel { normal, raised, strong }

/// Turns raw magnetometer samples (µT) into a smoothed reading against a
/// room baseline. Pure: no I/O, no timers.
///
/// Uses the field magnitude, which doesn't change when the phone is turned,
/// so only nearby magnets and electronics move it. Earth's field alone is
/// ~25–65 µT depending on location, hence the baseline.
class FieldMeter {
  /// µT above baseline that counts as raised / strong.
  static const double raisedDelta = 15;
  static const double strongDelta = 40;

  /// Weight of the newest sample in the smoothed value (0–1).
  final double alpha;

  FieldMeter({this.alpha = 0.3});

  double? _smoothed;
  double? _baseline;
  double _peak = 0;
  List<double>? _calibration;

  static double magnitude(double x, double y, double z) => math.sqrt(x * x + y * y + z * z);

  /// Smoothed field in µT, or null before the first sample.
  double? get current => _smoothed;

  /// Room field in µT, or null until calibrated.
  double? get baseline => _baseline;

  bool get isCalibrating => _calibration != null;

  /// Distance from baseline in µT (either direction: a magnet can also
  /// cancel part of Earth's field). Null until calibrated.
  double? get delta {
    final s = _smoothed, b = _baseline;
    return s == null || b == null ? null : (s - b).abs();
  }

  /// Largest [delta] since the last calibration or [resetPeak].
  double get peak => _peak;

  FieldLevel get level => levelFor(delta ?? 0);

  static FieldLevel levelFor(double delta) {
    if (delta >= strongDelta) return FieldLevel.strong;
    if (delta >= raisedDelta) return FieldLevel.raised;
    return FieldLevel.normal;
  }

  /// Feeds one sample; returns the smoothed magnitude.
  double add(double x, double y, double z) {
    final m = magnitude(x, y, z);
    _calibration?.add(m);
    final s = _smoothed == null ? m : _smoothed! + alpha * (m - _smoothed!);
    _smoothed = s;
    final d = delta;
    if (d != null && !isCalibrating && d > _peak) _peak = d;
    return s;
  }

  /// Starts collecting samples for a new baseline.
  void startCalibration() => _calibration = [];

  /// Sets the baseline to the average raw magnitude collected since
  /// [startCalibration]. Returns false (baseline unchanged) if none came in.
  bool finishCalibration() {
    final samples = _calibration;
    _calibration = null;
    if (samples == null || samples.isEmpty) return false;
    _baseline = samples.reduce((a, b) => a + b) / samples.length;
    _peak = 0;
    return true;
  }

  void resetPeak() => _peak = 0;
}
