import '../indexing/data_type.dart';
import '../indexing/geospatial_config.dart';
import 'shape.dart';

/// Class represengin a position.
class Point extends Shape {
  @override
  final type = DataType.point;

  /// The position's X coordinate.
  final num? x;

  /// The position's Y coordinate.
  final num? y;

  /// The position's latitude.
  final num? latitude;

  /// The position's longitude.
  final num? longitude;

  /// The position's altitude.
  final num? altitude;

  /// `(lat, long)` position.
  const Point.geography(this.latitude, this.longitude, [this.altitude])
      : assert(latitude != null),
        assert(longitude != null),
        x = null,
        y = null;

  /// `(x, y)` position.
  const Point.geometry(this.x, this.y, [num? z])
      : assert(x != null),
        assert(y != null),
        latitude = null,
        longitude = null,
        altitude = z;

  /// Coordinates pair, either `(x, y)` or `(long, lat)`.
  @override
  List<num> get coordinates => isGeometry
      ? [x!, y!, if (altitude != null) altitude!]
      : [longitude!, latitude!, if (altitude != null) altitude!];

  /// `true` iif [latitude] and [longitude] are non-null.
  bool get isGeographic => (latitude != null && longitude != null);

  /// `true` iif [x] and [y] are non-null.
  bool get isGeometry => (x != null && y != null);

  @override
  Iterable<Iterable<Point>> get paths => [
        [this]
      ];

  /// The position's Z coordinate. Returns the [altitude] (which may be `null`)
  /// if the position is geometrical, `null` otherwise.
  num? get z => isGeometry ? altitude : null;

  /// Hydrates a new [Point] instance using the JSON data in [geoJson].
  static Point fromGeoJson(Map geoJson, GeospatialConfig config) =>
      Shape.fromGeoJson<Point>(geoJson, config);

  static Point loadGeographyCoords(Iterable coords) {
    final c = (coords is List) ? coords : coords.toList();
    final lat = c[1];
    final long = c[0];
    final alt = (c.length >= 3) ? c[2] : null;
    return Point.geography(lat, long, alt);
  }

  static Point loadGeometryCoords(Iterable coords) {
    final c = (coords is List) ? coords : coords.toList();
    final x = c[0];
    final y = c[1];
    final alt = (c.length >= 3) ? c[2] : null;
    return Point.geometry(x, y, alt);
  }
}
