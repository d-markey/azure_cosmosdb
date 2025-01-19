import '../_internal/_extensions.dart';
import '../indexing/data_type.dart';
import '../indexing/geospatial_config.dart';
import 'point.dart';
import 'shape.dart';

/// Class representing a line.
class LineString extends Shape {
  final _points = <Point>[];

  @override
  final type = DataType.lineString;

  LineString();

  /// Returns a list where each entry represents a point's coordinates.
  @override
  List<List<num>> get coordinates => points.map((p) => p.coordinates).toList();

  /// `true` iif the line string contains no points.
  bool get isEmpty => points.isEmpty;

  /// `true` iif the line string contains one or more points.
  bool get isNotEmpty => points.isNotEmpty;

  /// Collection of paths. A `LineString` has only one path which contains all
  /// of its points.
  @override
  Iterable<Iterable<Point>> get paths => [points];

  /// Collection of points making up the line string.
  Iterable<Point> get points => _points.asIterable();

  /// Collection of points making up the line string, in reverse order.
  Iterable<Point> get reversed => _points.reversed;

  /// Adds a point to the line string.
  void add(Point point) => _points.add(point);

  /// Adds a set of points to the line string.
  void addAll(Iterable<Point> points) => _points.addAll(points);

  static LineString fromGeoJson(Map geoJson, GeospatialConfig config) =>
      Shape.fromGeoJson<LineString>(geoJson, config);

  static LineString loadGeographyCoords(Iterable coords) => LineString()
    ..addAll(
      coords.cast<List>().map(Point.loadGeographyCoords),
    );

  static LineString loadGeometryCoords(Iterable coords) => LineString()
    ..addAll(
      coords.cast<List>().map(Point.loadGeometryCoords),
    );
}
