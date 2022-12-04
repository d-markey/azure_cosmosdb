import '../indexing/data_type.dart';

/// Class represengin a position
class Point {
  /// The position's X coordinate.
  final double? x;

  /// The position's Y coordinate.
  final double? y;

  /// The position's latitude.
  final double? latitude;

  /// The position's longitude.
  final double? longitude;

  /// The position's altitude.
  final double? altitude;

  /// `(x, y)` position.
  const Point.geometry(this.x, this.y, [this.altitude])
      : assert(x != null),
        assert(y != null),
        latitude = null,
        longitude = null;

  /// `(lat, long)` position.
  const Point.geography(this.latitude, this.longitude, [this.altitude])
      : assert(latitude != null),
        assert(longitude != null),
        x = null,
        y = null;

  /// Coordinates pair, either `(x, y)` or `(lat, long)`.
  List<double> get coordinates =>
      isGeometry ? [x!, y!] : [latitude!, longitude!];

  /// `true` iif [x] and [y] are non-null.
  bool get isGeometry => (x != null && y != null);

  /// `true` iif [latitude] and [longitude] are non-null.
  bool get isGeographic => (latitude != null && longitude != null);

  /// The position's Z coordinate. Returns the [altitude] (which may be `null`)
  /// if the position is geometrical, `null` otherwise.
  double? get z => isGeometry ? altitude : null;

  Map<String, dynamic> toJson() => {
        'type': DataType.point.name,
        'coordinates': coordinates,
      };
}
