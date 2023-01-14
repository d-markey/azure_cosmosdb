import 'dart:math';

import 'distance_calculator.dart';
import 'distance_calculator_2d.dart';
import 'point.dart';
import 'shape.dart';

/// Euclidean distance calculator for points in a 3D space (X/Y/Z coordinates).
class DistanceCalculator3D extends DistanceCalculator {
  /// Computes the distance between [from] and [to] positions. Returns a 3D
  /// distance when [Point.altitude] are set in both positions, otherwise
  /// a 2D distance is returned. [from] and [to] must have geometry-based
  /// coordinates; if this is not the case, the function returns `null`. See
  /// also [DistanceCalculator2D].
  @override
  double? distance(Point from, Point to) {
    if (!from.isGeometry || !to.isGeometry) return null;
    var dx = to.x! - from.x!;
    var dy = to.y! - from.y!;
    var dz = (from.z != null && to.z != null) ? (to.z! - from.z!) : 0;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Computes the 3D length of a line or polygon. `null` is returned iif any
  /// [Point] in the line or polygon is not geometry-based. If all points have a
  /// `null` `altitude`, returns a 2D distance. If some points have their altitude
  /// set while some others do not, the resulting distance may be inconsistent as
  /// some segments will be measured in 2D and others in 3D.
  @override
  double? measure(Shape shape) => super.measure(shape);
}
