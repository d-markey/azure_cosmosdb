import '../_internal/_linq_extensions.dart';
import '../indexing/data_type.dart';
import '../indexing/geospatial_config.dart';
import 'line_string.dart';
import 'point.dart';
import 'shape.dart';

class Polygon extends Shape {
  @override
  final type = DataType.polygon;

  final _rings = <LineString>[];

  Polygon();

  @override
  List get coordinates => rings.map((r) {
        final coords = r.coordinates;
        coords.add(coords[0]);
        return coords;
      }).toList();

  /// `true` iif the polygon contains no ring.
  bool get isEmpty => rings.isEmpty;

  /// `true` iif the polygon contains one or more rings.
  bool get isNotEmpty => rings.isNotEmpty;

  @override
  Iterable<Iterable<Point>> get paths =>
      rings.map((r) => r.points.followedBy(r.points.take(1)));

  /// List of rings. Rings are represented by line-strings and should not repeat
  /// first/last points. During serialization, the first point of each ring is
  /// repeated automatically to meet GeoJSON requirements.
  Iterable<LineString> get rings => _rings.asIterable();

  /// Adds a ring to the polygon.
  void add(LineString ring) => _rings.add(ring);

  /// Adds a set of rings to the polygon.
  void addAll(Iterable<LineString> rings) => _rings.addAll(rings);

  /// Inverts the polygon by copying the rings of the current instance, only
  /// walking the ring points in reversed order.
  Polygon invert() => Polygon()
    ..addAll(
      rings.map(
        (r) => LineString()..addAll(r.reversed),
      ),
    );

  static Polygon fromGeoJson(Map geoJson, GeospatialConfig config) =>
      Shape.fromGeoJson<Polygon>(geoJson, config);

  static Polygon loadGeographyCoords(Iterable coords) => Polygon()
    ..addAll(
      coords.cast<Iterable>().map(_Ring.loadGeographyCoords),
    );

  static Polygon loadGeometryCoords(Iterable coords) => Polygon()
    ..addAll(
      coords.cast<Iterable>().map(_Ring.loadGeometryCoords),
    );
}

class _Ring {
  static LineString loadGeographyCoords(Iterable coords) =>
      LineString.loadGeographyCoords(coords.skipLast());

  static LineString loadGeometryCoords(Iterable coords) =>
      LineString.loadGeometryCoords(coords.skipLast());
}
