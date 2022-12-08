import 'point.dart';
import 'shape.dart';

abstract class DistanceCalculator {
  const DistanceCalculator();

  double? distance(Point from, Point to);

  /// Computes the length of a line or polygon by adding up distances between
  /// consecutive [Point]s making it up. Returns `null` if [distance] return
  /// `null` for any two consecutive [Point]s.
  double? measure(Shape shape) {
    double dist = 0;
    for (var path in shape.paths) {
      var current = path.first;
      for (var next in path.skip(1)) {
        var d = distance(current, next);
        if (d == null) return null;
        dist += d;
        current = next;
      }
    }
    return dist;
  }
}
