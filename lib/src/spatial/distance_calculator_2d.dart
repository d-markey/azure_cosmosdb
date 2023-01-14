import 'dart:math';

import 'distance_calculator.dart';
import 'distance_calculator_3d.dart';
import 'point.dart';
import 'shape.dart';

/// Euclidean distance calculator for points in a 2D plane (X/Y coordinates).
class DistanceCalculator2D extends DistanceCalculator {
  /// Computes the 2D distance between [from] and [to] positions. This
  /// implementation ignores all [Point.altitude] values. [from] and [to]
  /// must have geometry-based coordinates; if this is not the case, the
  /// function returns `null`. See also [DistanceCalculator3D].
  @override
  double? distance(Point from, Point to) {
    if (!from.isGeometry || !to.isGeometry) return null;
    var dx = to.x! - from.x!;
    var dy = to.y! - from.y!;
    return sqrt(dx * dx + dy * dy);
  }

  /// Computes the 2D length of a line string or polygon. `null` is returned iif
  /// any [Point] in the lines or polygon is not geometry-based.
  @override
  double? measure(Shape shape) => super.measure(shape);
}
