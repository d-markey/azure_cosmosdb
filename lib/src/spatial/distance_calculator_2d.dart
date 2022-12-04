import 'dart:math';

import 'distance_calculator.dart';
import 'distance_calculator_3d.dart';
import 'line.dart';
import 'point.dart';

class DistanceCalculator2D extends DistanceCalculator {
  /// Computes the 2D distance between [from] and [to] positions. This
  /// implementation ignores all [Point.altitude] values. [from] and [to]
  /// must have coordinate-based positions; if this is not the case, the
  /// function returns `null`. See also [DistanceCalculator3D].
  @override
  double? distance(Point from, Point to) {
    if (!from.isGeometry || !to.isGeometry) return null;
    var dx = to.x! - from.x!;
    var dy = to.y! - from.y!;
    return sqrt(dx * dx + dy * dy);
  }

  /// Computes the 2D length of a line or polygon. `null` is returned iif any
  /// [Point] in the line or polygon does not have a coordinate-based [Point].
  @override
  double? measure(Line lineOrPolygon) => super.measure(lineOrPolygon);
}
