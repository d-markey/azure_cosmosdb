import '../_internal/_extensions.dart';
import '../indexing/data_type.dart';
import '../indexing/geospatial_config.dart';
import 'point.dart';
import 'polygon.dart';
import 'shape.dart';

/// Class representing a list of polygons.
class MultiPolygon extends Shape {
  final _polygons = <Polygon>[];

  @override
  final type = DataType.multiPolygon;

  MultiPolygon();

  @override
  List get coordinates => polygons.map((p) => p.coordinates).toList();

  /// `true` iif the multi-polygon contains no polygon.
  bool get isEmpty => polygons.isEmpty;

  /// `true` iif the multi-polygon contains one or more polygons.
  bool get isNotEmpty => polygons.isNotEmpty;

  @override
  Iterable<Iterable<Point>> get paths => polygons.expand((p) => p.paths);

  /// The list of polygons.
  Iterable<Polygon> get polygons => _polygons.asIterable();

  /// Adds a polygon to the multi-polygon.
  void add(Polygon polygon) => _polygons.add(polygon);

  /// Adds a set of polygons to the multi-polygon.
  void addAll(Iterable<Polygon> polygons) => _polygons.addAll(polygons);

  static MultiPolygon fromGeoJson(Map geoJson, GeospatialConfig config) =>
      Shape.fromGeoJson<MultiPolygon>(geoJson, config);

  static MultiPolygon loadGeographyCoords(Iterable coords) => MultiPolygon()
    ..addAll(
      coords.cast<Iterable>().map(Polygon.loadGeographyCoords),
    );

  static MultiPolygon loadGeometryCoords(Iterable coords) => MultiPolygon()
    ..addAll(
      coords.cast<Iterable>().map(Polygon.loadGeometryCoords),
    );
}
