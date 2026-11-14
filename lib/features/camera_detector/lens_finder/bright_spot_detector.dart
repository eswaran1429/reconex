import 'dart:math' as math;
import 'dart:typed_data';

/// A small bright blob. [x], [y] are the centre in 0..1 of the image; [size] is its extent as a fraction of
/// the image's longer side.
class BrightSpot {
  final double x;
  final double y;
  final double size;

  const BrightSpot(this.x, this.y, this.size);

  @override
  String toString() => 'BrightSpot(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${size.toStringAsFixed(3)})';
}

/// Finds small, very bright blobs in a luminance (Y) plane.
///
/// The frame is reduced to a coarse grid (~[gridWidth] cells wide, each cell the max of its block, so a 2 px
/// LED isn't averaged away). Cells at or above max([minLevel], mean + [k]·stddev), capped at [maxLevel], are
/// grouped into 8-connected blobs; blobs wider or taller than [maxCells] cells (lamps, windows) are dropped.
/// Returns at most [maxSpots], smallest first.
List<BrightSpot> findBrightSpots(
  Uint8List y,
  int width,
  int height,
  int bytesPerRow, {
  int gridWidth = 64,
  double k = 4,
  int minLevel = 240,
  int maxLevel = 250,
  int maxCells = 3,
  int maxSpots = 8,
}) {
  final cell = math.max(1, width ~/ gridWidth);
  final gw = width ~/ cell, gh = height ~/ cell;
  if (gw == 0 || gh == 0) return const [];

  final grid = Uint8List(gw * gh);
  for (var gy = 0; gy < gh; gy++) {
    for (var gx = 0; gx < gw; gx++) {
      var m = 0;
      for (var py = gy * cell; py < (gy + 1) * cell; py++) {
        final row = py * bytesPerRow;
        for (var px = gx * cell; px < (gx + 1) * cell; px++) {
          final v = y[row + px];
          if (v > m) m = v;
        }
      }
      grid[gy * gw + gx] = m;
    }
  }

  var sum = 0.0, sq = 0.0;
  for (final v in grid) {
    sum += v;
    sq += v * v;
  }
  final mean = sum / grid.length;
  final std = math.sqrt(math.max(0, sq / grid.length - mean * mean));
  final threshold = (mean + k * std).clamp(minLevel.toDouble(), maxLevel.toDouble());

  final seen = Uint8List(gw * gh);
  final spots = <BrightSpot>[];
  final stack = <int>[];
  for (var i = 0; i < grid.length; i++) {
    if (seen[i] == 1 || grid[i] < threshold) continue;
    // Flood-fill one blob.
    var count = 0, sx = 0, sy = 0, minX = gw, maxX = 0, minY = gh, maxY = 0;
    seen[i] = 1;
    stack.add(i);
    while (stack.isNotEmpty) {
      final j = stack.removeLast();
      final cx = j % gw, cy = j ~/ gw;
      count++;
      sx += cx;
      sy += cy;
      minX = math.min(minX, cx);
      maxX = math.max(maxX, cx);
      minY = math.min(minY, cy);
      maxY = math.max(maxY, cy);
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = cx + dx, ny = cy + dy;
          if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue;
          final n = ny * gw + nx;
          if (seen[n] == 0 && grid[n] >= threshold) {
            seen[n] = 1;
            stack.add(n);
          }
        }
      }
    }
    final extent = math.max(maxX - minX, maxY - minY) + 1;
    if (extent > maxCells) continue;
    spots.add(
      BrightSpot(
        (sx / count + 0.5) * cell / width,
        (sy / count + 0.5) * cell / height,
        extent * cell / math.max(width, height),
      ),
    );
  }
  spots.sort((a, b) => a.size.compareTo(b.size));
  return spots.length > maxSpots ? spots.sublist(0, maxSpots) : spots;
}

/// Keeps only spots seen in at least [minHits] of the last [window] frames within [radius] (normalized).
/// Cuts one-frame highlights; a lens glint stays put while the user sweeps slowly.
class SpotTracker {
  final int window;
  final int minHits;
  final double radius;
  final List<List<BrightSpot>> _history = [];

  SpotTracker({this.window = 6, this.minHits = 3, this.radius = 0.05});

  List<BrightSpot> update(List<BrightSpot> current) {
    _history.add(current);
    if (_history.length > window) _history.removeAt(0);
    final r2 = radius * radius;
    bool near(BrightSpot a, BrightSpot b) => (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) <= r2;
    return [
      for (final s in current)
        if (_history.where((frame) => frame.any((o) => near(s, o))).length >= minHits) s,
    ];
  }

  void reset() => _history.clear();
}

/// Maps a normalized image point to the upright preview: rotate clockwise by [quarterTurns] × 90°, then
/// flip horizontally if [mirror] (front camera).
(double, double) toPreview(double x, double y, int quarterTurns, {bool mirror = false}) {
  final (u, v) = switch (quarterTurns % 4) {
    1 => (1 - y, x),
    2 => (1 - x, 1 - y),
    3 => (y, 1 - x),
    _ => (x, y),
  };
  return (mirror ? 1 - u : u, v);
}
