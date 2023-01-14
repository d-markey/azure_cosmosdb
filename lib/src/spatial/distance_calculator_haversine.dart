import 'dart:math' as math;

import 'distance_calculator.dart';
import 'point.dart';

/// The Earth's radius, in kilometers.
const double earthRadiusInKm = 6371;

/// Distance calculator for points in latitude/longitude coordinates on Earth.
const earthDistanceCalculator = DistanceCalculatorHaversine(earthRadiusInKm);

/// Distance calculator for points on a sphere (latitude/longitude coordinates),
/// based on the Haversine algorithm.
class DistanceCalculatorHaversine extends DistanceCalculator {
  const DistanceCalculatorHaversine(this.radius);

  /// The sphere's radius.
  final double radius;

  static double _rad(double degrees) => degrees * math.pi / 180;
  static double _sin(double degrees) => math.sin(_rad(degrees));
  static double _cos(double degrees) => math.cos(_rad(degrees));

  /// Computes the distance between [from] and [to] positions. Returns the
  /// great-circle distance using 'haversine' formula. [Point.altitude]
  /// values are ignored. [from] and [to] positions must be geography-based, i.e.
  /// their latitude and longitude are both set; otherwise `null` is returned.
  @override
  double? distance(Point from, Point to) {
    if (!from.isGeographic || !to.isGeographic) return null;

    final dLatSin = _sin((to.latitude! - from.latitude!) / 2);
    final dLongSin = _sin((to.longitude! - from.longitude!) / 2);
    final cosSq = _cos(from.latitude!) * _cos(to.latitude!);

    final a = dLatSin * dLatSin + cosSq * dLongSin * dLongSin;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return c * radius;
  }
}
