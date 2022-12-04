/// Constants for data types.
class DataType {
  const DataType._(this.name);

  final String name;

  /// String type.
  static const string = DataType._('String');

  /// Numeric type.
  static const number = DataType._('Number');

  /// Point type.
  static const point = DataType._('Point');

  /// Polygon type.
  static const polygon = DataType._('Polygon');

  /// Multi-polygon type.
  static const multiPolygon = DataType._('MultiPolygon');

  /// Line-string type.
  static const lineString = DataType._('LineString');

  /// List of spatial data types.
  static const spatialTypes = [point, polygon, multiPolygon, lineString];
}
