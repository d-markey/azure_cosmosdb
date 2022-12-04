import 'line.dart';
import 'point.dart';

abstract class DistanceCalculator {
  const DistanceCalculator();

  double? distance(Point from, Point to);

  /// Computes the length of a line or polygon by adding up distances between
  /// consecutive [Point]s making it up. Returns `null` if [distance] return
  /// `null` for any two consecutive [Point]s.
  double? measure(Line lineOrPolygon) {
    double dist = 0;
    var current = lineOrPolygon.points.first;
    for (var next in lineOrPolygon.points.skip(1)) {
      var d = distance(current, next);
      if (d == null) return null;
      dist += d;
      current = next;
    }
    return dist;
  }
}
