import '../cosmos_db_exceptions.dart';
import '../indexing/data_type.dart';
import '../indexing/geospatial_config.dart';
import 'line_string.dart';
import 'multi_polygon.dart';
import 'point.dart';
import 'polygon.dart';

typedef ShapeLoader = Shape Function(Iterable geoJson);

/// Base class for shapes.
abstract class Shape {
  static const _map = {
    Point: DataType.point,
    LineString: DataType.lineString,
    Polygon: DataType.polygon,
    MultiPolygon: DataType.multiPolygon,
  };

  /// Loaders for DataType and GeospatialConfig
  static const _loaders = <DataType, Map<GeospatialConfig, ShapeLoader>>{
    DataType.point: {
      GeospatialConfig.geography: Point.loadGeographyCoords,
      GeospatialConfig.geometry: Point.loadGeometryCoords,
    },
    DataType.lineString: {
      GeospatialConfig.geography: LineString.loadGeographyCoords,
      GeospatialConfig.geometry: LineString.loadGeometryCoords,
    },
    DataType.polygon: {
      GeospatialConfig.geography: Polygon.loadGeographyCoords,
      GeospatialConfig.geometry: Polygon.loadGeometryCoords,
    },
    DataType.multiPolygon: {
      GeospatialConfig.geography: MultiPolygon.loadGeographyCoords,
      GeospatialConfig.geometry: MultiPolygon.loadGeometryCoords,
    },
  };

  const Shape();

  /// The shape's coordinates that will be serialized as the `coordinates`
  /// GeoJSON field.
  List get coordinates;

  /// The shape's sets of points.
  Iterable<Iterable<Point>> get paths;

  /// The shape's data type that will be serialized as the `type` GeoJSON field.
  DataType get type;

  /// Serializes this instance to a JSON object (GeoJson).
  Map<String, dynamic> toJson() => toGeoJson();

  /// Serializes to GeoJSON.
  Map<String, dynamic> toGeoJson() => {
        'type': type.name,
        'coordinates': coordinates,
      };

  /// Deserializes from GeoJSON.
  static T fromGeoJson<T>(Map json, GeospatialConfig config) {
    final spatialType = _map[T]!;
    final type = json['type']?.toString() ?? '';
    if (type.toLowerCase() != spatialType.name.toLowerCase()) {
      throw BadResponseException(
          'Invalid type "$type". Expected ${spatialType.name}.');
    }
    final coords = json['coordinates'] as List?;
    if (coords == null) {
      throw BadResponseException(
          'Invalid GeoJSON: missing entry "coordinates".');
    }
    final loader = _loaders[spatialType]?[config];
    if (loader == null) {
      throw BadResponseException('No loader for type "${spatialType.name}".');
    }
    return loader(coords) as T;
  }
}
